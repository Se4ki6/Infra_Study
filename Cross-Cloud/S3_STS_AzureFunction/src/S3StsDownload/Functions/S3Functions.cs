using System.Net;
using System.Web;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using S3StsDownload.Services;

namespace S3StsDownload.Functions;

/// <summary>
/// S3 のファイル一覧取得とダウンロード。
/// どちらも ?mode=accesskey / ?mode=oidc で認証方式を切り替えられる。
/// </summary>
public sealed class S3Functions
{
    private readonly AwsCredentialProviderFactory _providerFactory;
    private readonly S3AccessService _s3;
    private readonly ILogger<S3Functions> _logger;

    public S3Functions(
        AwsCredentialProviderFactory providerFactory,
        S3AccessService s3,
        ILogger<S3Functions> logger)
    {
        _providerFactory = providerFactory;
        _s3 = s3;
        _logger = logger;
    }

    /// <summary>GET /api/files?mode=oidc — 許可プレフィックス配下のオブジェクト一覧。</summary>
    [Function("ListFiles")]
    public async Task<HttpResponseData> ListFilesAsync(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "files")] HttpRequestData request,
        CancellationToken cancellationToken)
    {
        try
        {
            var query = HttpUtility.ParseQueryString(request.Url.Query);
            var provider = _providerFactory.Resolve(query["mode"]);
            var credentials = await provider.GetCredentialsAsync(cancellationToken);

            var objects = await _s3.ListAsync(credentials, cancellationToken);

            return await HttpResponses.JsonAsync(request, HttpStatusCode.OK, new
            {
                credentials = credentials.ToSafeSummary(),
                count = objects.Count,
                files = objects.Select(o => new
                {
                    key = o.Key,
                    sizeBytes = o.SizeBytes,
                    lastModifiedUtc = o.LastModifiedUtc.ToString("o"),
                }),
            });
        }
        catch (Exception exception)
        {
            return await HttpResponses.ErrorAsync(request, exception, _logger);
        }
    }

    /// <summary>GET /api/download?key=hello.txt&amp;mode=oidc — S3 からファイルをダウンロードして返す。</summary>
    [Function("DownloadFile")]
    public async Task<HttpResponseData> DownloadFileAsync(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "download")] HttpRequestData request,
        CancellationToken cancellationToken)
    {
        try
        {
            var query = HttpUtility.ParseQueryString(request.Url.Query);
            var provider = _providerFactory.Resolve(query["mode"]);
            var credentials = await provider.GetCredentialsAsync(cancellationToken);

            using var result = await _s3.DownloadAsync(credentials, query["key"] ?? string.Empty, cancellationToken);

            var response = request.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", result.ContentType);
            response.Headers.Add(
                "Content-Disposition",
                $"attachment; filename=\"{Path.GetFileName(result.Key)}\"");

            // どの方式で取得したかをヘッダーでも分かるようにしておく (比較検証用)
            response.Headers.Add("X-Sts-Mode", credentials.Mode);
            response.Headers.Add("X-Assumed-Role-Arn", credentials.AssumedRoleArn);

            await result.Content.CopyToAsync(response.Body, cancellationToken);

            return response;
        }
        catch (Exception exception)
        {
            return await HttpResponses.ErrorAsync(request, exception, _logger);
        }
    }
}
