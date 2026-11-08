using Microsoft.Extensions.Logging;

namespace S3StsDownload.Services;

/// <summary>
/// 取得した一時クレデンシャルを有効期限まで使い回すための基底クラス。
///
/// STS には API 呼び出しのスロットリングがあるため、リクエストのたびに Assume するのは
/// 実運用では悪手。期限の少し手前 (SafetyMargin) で再取得する。
/// </summary>
public abstract class CachedCredentialProvider : IAwsCredentialProvider
{
    /// <summary>期限ちょうどまで使うと通信中に失効しうるので余裕を持たせる。</summary>
    private static readonly TimeSpan SafetyMargin = TimeSpan.FromMinutes(2);

    private readonly SemaphoreSlim _gate = new(1, 1);
    private AwsTemporaryCredentials? _cached;

    protected CachedCredentialProvider(ILogger logger) => Logger = logger;

    protected ILogger Logger { get; }

    public abstract string Mode { get; }

    /// <summary>実際に STS を呼ぶ部分。派生クラスが実装する。</summary>
    protected abstract Task<AwsTemporaryCredentials> AcquireAsync(CancellationToken cancellationToken);

    public async Task<AwsTemporaryCredentials> GetCredentialsAsync(CancellationToken cancellationToken)
    {
        if (IsUsable(_cached))
        {
            return _cached!;
        }

        await _gate.WaitAsync(cancellationToken);
        try
        {
            // ロック待ちの間に別のリクエストが取得済みかもしれない
            if (IsUsable(_cached))
            {
                return _cached!;
            }

            Logger.LogInformation("STS から一時クレデンシャルを取得します (mode={Mode})", Mode);
            var credentials = await AcquireAsync(cancellationToken);

            Logger.LogInformation(
                "一時クレデンシャルを取得しました (mode={Mode}, role={Role}, accessKeyId={AccessKeyId}, expiresAtUtc={Expiry})",
                Mode, credentials.AssumedRoleArn, credentials.AccessKeyId, credentials.ExpiresAtUtc);

            _cached = credentials;
            return credentials;
        }
        finally
        {
            _gate.Release();
        }
    }

    private static bool IsUsable(AwsTemporaryCredentials? credentials)
        => credentials is not null && credentials.ExpiresAtUtc - SafetyMargin > DateTime.UtcNow;
}
