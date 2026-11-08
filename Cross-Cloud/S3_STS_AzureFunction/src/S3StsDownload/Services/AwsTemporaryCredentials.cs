using Amazon.Runtime;

namespace S3StsDownload.Services;

/// <summary>
/// STS から受け取った一時クレデンシャル。
/// AccessKeyId / SecretAccessKey に加えて SessionToken が付くのが長期キーとの決定的な違いで、
/// この 3 点セットでないと S3 側で認証されない。
/// </summary>
public sealed record AwsTemporaryCredentials(
    string AccessKeyId,
    string SecretAccessKey,
    string SessionToken,
    DateTime ExpiresAtUtc,
    string AssumedRoleArn,
    string Mode)
{
    /// <summary>AWS SDK のクライアントに渡せる形に変換する。</summary>
    public AWSCredentials ToAwsCredentials()
        => new SessionAWSCredentials(AccessKeyId, SecretAccessKey, SessionToken);

    /// <summary>秘匿情報を伏せた、レスポンスに載せてよい形。</summary>
    public object ToSafeSummary() => new
    {
        mode            = Mode,
        assumedRoleArn  = AssumedRoleArn,
        accessKeyId     = AccessKeyId,               // AKIA/ASIA プレフィックスの確認用 (STS 発行なら ASIA)
        hasSessionToken = !string.IsNullOrEmpty(SessionToken),
        expiresAtUtc    = ExpiresAtUtc.ToString("o"),
        expiresInSeconds = (int)Math.Max(0, (ExpiresAtUtc - DateTime.UtcNow).TotalSeconds),
    };
}
