namespace S3StsDownload.Services;

/// <summary>
/// AWS の一時クレデンシャルを取得する方式の共通インターフェース。
/// 方式A (アクセスキー + AssumeRole) と方式B (OIDC + AssumeRoleWithWebIdentity) を
/// 同じ形で差し替えられるようにしている。
/// </summary>
public interface IAwsCredentialProvider
{
    /// <summary>"accesskey" または "oidc"。</summary>
    string Mode { get; }

    Task<AwsTemporaryCredentials> GetCredentialsAsync(CancellationToken cancellationToken);
}
