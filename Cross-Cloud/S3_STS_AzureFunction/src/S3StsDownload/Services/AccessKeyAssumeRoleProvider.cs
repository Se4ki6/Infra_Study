using Amazon;
using Amazon.Runtime;
using Amazon.SecurityToken;
using Amazon.SecurityToken.Model;
using Microsoft.Extensions.Logging;

namespace S3StsDownload.Services;

/// <summary>
/// 方式A: IAM ユーザーのアクセスキーで sts:AssumeRole を呼び、一時クレデンシャルを得る。
///
/// アクセスキーを持つ bootstrap ユーザーには S3 権限が一切無いのがポイント。
/// S3 に到達するには必ずここでロールを Assume する必要がある。
/// ただし長期キーが Function App の設定に残るため、本番では方式B を使うこと。
/// </summary>
public sealed class AccessKeyAssumeRoleProvider : CachedCredentialProvider
{
    private readonly StsSettings _settings;

    public AccessKeyAssumeRoleProvider(StsSettings settings, ILogger<AccessKeyAssumeRoleProvider> logger)
        : base(logger) => _settings = settings;

    public override string Mode => "accesskey";

    protected override async Task<AwsTemporaryCredentials> AcquireAsync(CancellationToken cancellationToken)
    {
        var roleArn         = _settings.RequireAssumeRoleArn();
        var accessKeyId     = _settings.RequireBootstrapAccessKeyId();
        var secretAccessKey = _settings.RequireBootstrapSecretAccessKey();

        // 長期キーは STS を呼ぶためだけに使う。S3 クライアントには絶対に渡さない。
        var longLivedCredentials = new BasicAWSCredentials(accessKeyId, secretAccessKey);
        using var sts = new AmazonSecurityTokenServiceClient(
            longLivedCredentials,
            RegionEndpoint.GetBySystemName(_settings.RequireRegion()));

        var request = new AssumeRoleRequest
        {
            RoleArn = roleArn,
            // CloudTrail に残る識別子。誰が Assume したか追えるように意味のある名前にする
            RoleSessionName = $"azure-function-{DateTime.UtcNow:yyyyMMddHHmmss}",
            DurationSeconds = _settings.SessionDurationSeconds,
        };

        // ExternalId: 混乱した代理人問題への対策。ロールの信頼ポリシー側で要求している
        if (!string.IsNullOrEmpty(_settings.ExternalId))
        {
            request.ExternalId = _settings.ExternalId;
        }

        var response = await sts.AssumeRoleAsync(request, cancellationToken);

        return new AwsTemporaryCredentials(
            response.Credentials.AccessKeyId,
            response.Credentials.SecretAccessKey,
            response.Credentials.SessionToken,
            response.Credentials.Expiration.ToUniversalTime(),
            roleArn,
            Mode);
    }
}
