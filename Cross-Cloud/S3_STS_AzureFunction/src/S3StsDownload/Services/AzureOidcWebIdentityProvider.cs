using Amazon;
using Amazon.Runtime;
using Amazon.SecurityToken;
using Amazon.SecurityToken.Model;
using Azure.Core;
using Azure.Identity;
using Microsoft.Extensions.Logging;

namespace S3StsDownload.Services;

/// <summary>
/// 方式B (推奨): Entra ID が発行した OIDC トークンで sts:AssumeRoleWithWebIdentity を呼ぶ。
///
/// 長期の AWS 認証情報がどこにも存在しないのが最大の利点。
/// Function App のマネージドID が発行してもらったトークン (数分〜1時間で失効) を
/// AWS に見せ、AWS 側は登録済み OIDC プロバイダの署名・aud・sub を検証して
/// 一時クレデンシャルを払い出す。
/// </summary>
public sealed class AzureOidcWebIdentityProvider : CachedCredentialProvider
{
    private readonly StsSettings _settings;
    private readonly TokenCredential _azureCredential;

    public AzureOidcWebIdentityProvider(StsSettings settings, ILogger<AzureOidcWebIdentityProvider> logger)
        : base(logger)
    {
        _settings = settings;

        // Azure 上ではマネージドID、ローカル実行時は az login / VS のアカウントが使われる。
        // ローカルで試す場合、そのユーザーの oid が sub になるため AWS 側の sub 条件と一致しない点に注意。
        _azureCredential = new DefaultAzureCredential();
    }

    public override string Mode => "oidc";

    /// <summary>
    /// マネージドID から Entra ID のアクセストークンを取得する。
    /// /api/token-claims からも使うので public。
    /// </summary>
    public async Task<AccessToken> GetAzureTokenAsync(CancellationToken cancellationToken)
    {
        var scope = _settings.RequireAzureTokenScope();

        // Azure.Identity は末尾の "/.default" を取り除いてリソース名として扱う。
        // ここで指定したリソースが、そのままトークンの aud クレームになる。
        return await _azureCredential.GetTokenAsync(
            new TokenRequestContext(new[] { scope }),
            cancellationToken);
    }

    protected override async Task<AwsTemporaryCredentials> AcquireAsync(CancellationToken cancellationToken)
    {
        var roleArn = _settings.RequireWebIdentityRoleArn();

        // ① Entra ID からトークンを取得
        var azureToken = await GetAzureTokenAsync(cancellationToken);

        var claims = JwtInspector.ReadClaims(azureToken.Token);
        Logger.LogInformation(
            "Entra ID トークンを取得しました (iss={Issuer}, aud={Audience}, sub={Subject})",
            claims.Issuer, claims.Audience, claims.Subject);

        // ② そのトークンを添えて AssumeRoleWithWebIdentity を呼ぶ。
        //    この API は署名不要 (呼び出し側の AWS 認証情報が存在しない) なので
        //    AnonymousAWSCredentials を渡す。ここが「キーレス」の核心。
        using var sts = new AmazonSecurityTokenServiceClient(
            new AnonymousAWSCredentials(),
            RegionEndpoint.GetBySystemName(_settings.RequireRegion()));

        var response = await sts.AssumeRoleWithWebIdentityAsync(
            new AssumeRoleWithWebIdentityRequest
            {
                RoleArn          = roleArn,
                RoleSessionName  = $"azure-mi-{DateTime.UtcNow:yyyyMMddHHmmss}",
                WebIdentityToken = azureToken.Token,
                DurationSeconds  = _settings.SessionDurationSeconds,
            },
            cancellationToken);

        return new AwsTemporaryCredentials(
            response.Credentials.AccessKeyId,
            response.Credentials.SecretAccessKey,
            response.Credentials.SessionToken,
            response.Credentials.Expiration.ToUniversalTime(),
            roleArn,
            Mode);
    }
}
