using Amazon;
using Amazon.S3;
using Amazon.S3.Model;
using Amazon.SecurityToken;
using Amazon.SecurityToken.Model;
using Microsoft.Extensions.Logging;

namespace S3StsDownload.Services;

public sealed record S3ObjectSummary(string Key, long SizeBytes, DateTime LastModifiedUtc);

public sealed record S3DownloadResult(
    string Key,
    string ContentType,
    long ContentLength,
    Stream Content) : IDisposable
{
    public void Dispose() => Content.Dispose();
}

/// <summary>
/// STS で取得した一時クレデンシャルだけを使って S3 を読む。
/// このクラスは長期の認証情報を一切知らない。
/// </summary>
public sealed class S3AccessService
{
    private readonly StsSettings _settings;
    private readonly ILogger<S3AccessService> _logger;

    public S3AccessService(StsSettings settings, ILogger<S3AccessService> logger)
    {
        _settings = settings;
        _logger = logger;
    }

    /// <summary>
    /// 「今どの principal として振る舞っているか」を STS に問い合わせる。
    /// 返ってくる Arn が assumed-role/... になっていれば STS 経由でのアクセスが成立している証拠。
    /// </summary>
    public async Task<object> GetCallerIdentityAsync(
        AwsTemporaryCredentials credentials, CancellationToken cancellationToken)
    {
        using var sts = new AmazonSecurityTokenServiceClient(
            credentials.ToAwsCredentials(),
            RegionEndpoint.GetBySystemName(_settings.RequireRegion()));

        var identity = await sts.GetCallerIdentityAsync(new GetCallerIdentityRequest(), cancellationToken);

        return new
        {
            account = identity.Account,
            arn     = identity.Arn,
            userId  = identity.UserId, // バケットポリシーの aws:userId 条件と突き合わせる値
        };
    }

    public async Task<IReadOnlyList<S3ObjectSummary>> ListAsync(
        AwsTemporaryCredentials credentials, CancellationToken cancellationToken)
    {
        using var s3 = CreateClient(credentials);

        var request = new ListObjectsV2Request
        {
            BucketName = _settings.RequireBucketName(),
            // IAM ポリシーの s3:prefix 条件に合わせる。ここを外すと AccessDenied になる
            Prefix     = NormalizedPrefix(),
            MaxKeys    = 100,
        };

        var response = await s3.ListObjectsV2Async(request, cancellationToken);

        return response.S3Objects
            .Select(o => new S3ObjectSummary(o.Key, o.Size, o.LastModified.ToUniversalTime()))
            .ToList();
    }

    public async Task<S3DownloadResult> DownloadAsync(
        AwsTemporaryCredentials credentials, string requestedKey, CancellationToken cancellationToken)
    {
        var key = BuildObjectKey(requestedKey);

        using var s3 = CreateClient(credentials);

        _logger.LogInformation("S3 からオブジェクトを取得します (bucket={Bucket}, key={Key})", _settings.RequireBucketName(), key);

        var response = await s3.GetObjectAsync(
            new GetObjectRequest { BucketName = _settings.RequireBucketName(), Key = key },
            cancellationToken);

        return new S3DownloadResult(
            key,
            response.Headers.ContentType ?? "application/octet-stream",
            response.ContentLength,
            response.ResponseStream);
    }

    private IAmazonS3 CreateClient(AwsTemporaryCredentials credentials)
        => new AmazonS3Client(
            credentials.ToAwsCredentials(),
            RegionEndpoint.GetBySystemName(_settings.RequireRegion()));

    private string NormalizedPrefix()
        => string.IsNullOrEmpty(_settings.Prefix) ? string.Empty : $"{_settings.Prefix.TrimEnd('/')}/";

    /// <summary>
    /// リクエストのキーを、許可されたプレフィックス配下の実キーに変換する。
    /// IAM 側でもプレフィックスを絞っているが、多層防御として呼び出し側でも検証する。
    /// </summary>
    internal string BuildObjectKey(string requestedKey)
    {
        if (string.IsNullOrWhiteSpace(requestedKey))
        {
            throw new ArgumentException("key クエリパラメータは必須です。");
        }

        var key = requestedKey.Replace('\\', '/').TrimStart('/');

        // ".." によるプレフィックス外への脱出を禁止する
        if (key.Split('/').Any(segment => segment is ".."))
        {
            throw new ArgumentException("key に '..' を含めることはできません。");
        }

        var prefix = NormalizedPrefix();

        // プレフィックス付きで指定された場合はそのまま使う (二重付与を防ぐ)
        return key.StartsWith(prefix, StringComparison.Ordinal) ? key : prefix + key;
    }
}
