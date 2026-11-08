using System.Net;
using Amazon.Runtime;
using Amazon.S3;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace S3StsDownload.Functions;

/// <summary>HTTP レスポンス生成と例外の整形をまとめたヘルパー。</summary>
internal static class HttpResponses
{
    public static async Task<HttpResponseData> JsonAsync(
        HttpRequestData request, HttpStatusCode statusCode, object payload)
    {
        var response = request.CreateResponse(statusCode);
        await response.WriteAsJsonAsync(payload, statusCode);
        return response;
    }

    /// <summary>
    /// 例外を「何が起きたか分かる」形の JSON に変換する。
    /// この構成でよく出るエラーはほぼここに集約されるので、原因の当たりも一緒に返す。
    /// </summary>
    public static async Task<HttpResponseData> ErrorAsync(
        HttpRequestData request, Exception exception, ILogger logger)
    {
        logger.LogError(exception, "リクエストの処理に失敗しました");

        var (statusCode, hint) = Classify(exception);

        return await JsonAsync(request, statusCode, new
        {
            error     = exception.GetType().Name,
            message   = exception.Message,
            awsErrorCode = (exception as AmazonServiceException)?.ErrorCode,
            hint,
        });
    }

    private static (HttpStatusCode, string) Classify(Exception exception) => exception switch
    {
        ArgumentException =>
            (HttpStatusCode.BadRequest,
             "リクエストパラメータを確認してください。"),

        AmazonS3Exception { ErrorCode: "AccessDenied" } =>
            (HttpStatusCode.Forbidden,
             "S3 が拒否しました。バケットポリシーの Deny 例外にこのロールの userId (AROA...:*) が入っているか、"
             + "IAM ポリシーの対象プレフィックスが合っているかを確認してください。"
             + "/api/whoami で実際の userId を確認できます。"),

        AmazonS3Exception { ErrorCode: "NoSuchKey" } =>
            (HttpStatusCode.NotFound,
             "指定したキーのオブジェクトが存在しません。/api/files で一覧を確認してください。"),

        AmazonServiceException { ErrorCode: "AccessDenied" } =>
            (HttpStatusCode.Forbidden,
             "STS が AssumeRole を拒否しました。ロールの信頼ポリシー (Principal / ExternalId / aud / sub) を確認してください。"),

        AmazonServiceException { ErrorCode: "InvalidIdentityToken" } =>
            (HttpStatusCode.Forbidden,
             "AWS がトークンを検証できませんでした。IAM の OIDC プロバイダの issuer が "
             + "トークンの iss と一致しているか (/api/token-claims で確認) を見直してください。"),

        AmazonServiceException { ErrorCode: "IDPRejectedClaim" } =>
            (HttpStatusCode.Forbidden,
             "トークンのクレームが信頼ポリシーの条件と一致しません。aud / sub を /api/token-claims で確認してください。"),

        InvalidOperationException =>
            (HttpStatusCode.InternalServerError,
             "アプリ設定 (App Settings) が不足しています。terraform/azure の apply で値が渡っているか確認してください。"),

        _ => (HttpStatusCode.InternalServerError, "Application Insights のログを確認してください。"),
    };
}
