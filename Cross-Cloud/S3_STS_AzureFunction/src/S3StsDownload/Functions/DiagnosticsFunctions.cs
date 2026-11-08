using System.Net;
using System.Web;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using S3StsDownload.Services;

namespace S3StsDownload.Functions;

/// <summary>
/// セットアップと切り分けのための診断エンドポイント。
/// </summary>
public sealed class DiagnosticsFunctions
{
    private readonly AwsCredentialProviderFactory _providerFactory;
    private readonly AzureOidcWebIdentityProvider _oidcProvider;
    private readonly S3AccessService _s3;
    private readonly ILogger<DiagnosticsFunctions> _logger;

    public DiagnosticsFunctions(
        AwsCredentialProviderFactory providerFactory,
        AzureOidcWebIdentityProvider oidcProvider,
        S3AccessService s3,
        ILogger<DiagnosticsFunctions> logger)
    {
        _providerFactory = providerFactory;
        _oidcProvider = oidcProvider;
        _s3 = s3;
        _logger = logger;
    }

    /// <summary>
    /// GET /api/token-claims — マネージドID が発行したトークンの iss / aud / sub を返す。
    ///
    /// AWS 側の設定 (azure_token_version / azure_oidc_audience / azure_function_principal_id) を
    /// 実測値に合わせるために使う。Azure がどのバージョンのトークンを返すかは環境で変わるため、
    /// 推測せずここで確認すること。
    ///
    /// 返すのはクレームのみでトークン本体は返さない。
    /// </summary>
    [Function("TokenClaims")]
    public async Task<HttpResponseData> TokenClaimsAsync(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "token-claims")] HttpRequestData request,
        CancellationToken cancellationToken)
    {
        try
        {
            var token = await _oidcProvider.GetAzureTokenAsync(cancellationToken);
            var claims = JwtInspector.ReadClaims(token.Token);

            return await HttpResponses.JsonAsync(request, HttpStatusCode.OK, new
            {
                claims = new
                {
                    iss = claims.Issuer,
                    aud = claims.Audience,
                    sub = claims.Subject,
                    oid = claims.ObjectId,
                    tid = claims.TenantId,
                    appid = claims.AppId,
                    exp = claims.ExpiresAt?.ToString("o"),
                },
                // そのまま terraform/aws の tfvars に転記できる形
                awsTerraformValues = new
                {
                    azure_token_version = claims.Issuer?.Contains("/v2.0", StringComparison.Ordinal) == true ? "v2" : "v1",
                    azure_tenant_id = claims.TenantId,
                    azure_oidc_audience = claims.Audience,
                    azure_function_principal_id = claims.Subject,
                },
            });
        }
        catch (Exception exception)
        {
            return await HttpResponses.ErrorAsync(request, exception, _logger);
        }
    }

    /// <summary>
    /// GET /api/whoami?mode=oidc — 一時クレデンシャルで sts:GetCallerIdentity を呼ぶ。
    ///
    /// arn が "arn:aws:sts::&lt;account&gt;:assumed-role/..." になっていれば
    /// STS 経由でアクセスできていることの確認になる。
    /// userId はバケットポリシーの aws:userId 条件と突き合わせる値。
    /// </summary>
    [Function("WhoAmI")]
    public async Task<HttpResponseData> WhoAmIAsync(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "whoami")] HttpRequestData request,
        CancellationToken cancellationToken)
    {
        try
        {
            var query = HttpUtility.ParseQueryString(request.Url.Query);
            var provider = _providerFactory.Resolve(query["mode"]);
            var credentials = await provider.GetCredentialsAsync(cancellationToken);

            var identity = await _s3.GetCallerIdentityAsync(credentials, cancellationToken);

            return await HttpResponses.JsonAsync(request, HttpStatusCode.OK, new
            {
                credentials = credentials.ToSafeSummary(),
                callerIdentity = identity,
                availableModes = _providerFactory.AvailableModes,
            });
        }
        catch (Exception exception)
        {
            return await HttpResponses.ErrorAsync(request, exception, _logger);
        }
    }
}
