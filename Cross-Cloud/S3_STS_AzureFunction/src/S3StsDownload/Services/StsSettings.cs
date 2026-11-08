namespace S3StsDownload.Services;

/// <summary>
/// アプリ設定 (Function App の App Settings / local.settings.json) をまとめて読み取る。
///
/// 読み取り時点では何も必須にしない。セットアップは
/// 「Azure を作る → AWS を作る → Azure に AWS の値を戻す」の 3 段階で進むため、
/// 途中の段階では AWS 系の設定がまだ空になっている。
/// その状態でも /api/token-claims (方式B の設定合わせに使う) は動く必要がある。
///
/// 値の必須チェックは、実際にその値を使う直前に Require*() で行う。
/// </summary>
public sealed class StsSettings
{
    public string? AwsRegion { get; init; }
    public string? BucketName { get; init; }
    public required string Prefix { get; init; }
    public required string DefaultMode { get; init; }
    public required int SessionDurationSeconds { get; init; }

    // 方式A: アクセスキー + AssumeRole
    public string? AssumeRoleArn { get; init; }
    public string? BootstrapAccessKeyId { get; init; }
    public string? BootstrapSecretAccessKey { get; init; }
    public string? ExternalId { get; init; }

    // 方式B: OIDC + AssumeRoleWithWebIdentity
    public string? WebIdentityRoleArn { get; init; }
    public string? AzureTokenScope { get; init; }

    public static StsSettings FromEnvironment()
    {
        return new StsSettings
        {
            AwsRegion              = Optional("AWS_REGION"),
            BucketName             = Optional("AWS_S3_BUCKET"),
            Prefix                 = Optional("AWS_S3_PREFIX") ?? string.Empty,
            DefaultMode            = (Optional("CREDENTIAL_MODE") ?? "oidc").Trim().ToLowerInvariant(),
            SessionDurationSeconds = int.TryParse(Optional("AWS_STS_SESSION_DURATION_SECONDS"), out var d) ? d : 900,

            AssumeRoleArn            = Optional("AWS_ASSUME_ROLE_ARN"),
            BootstrapAccessKeyId     = Optional("BOOTSTRAP_AWS_ACCESS_KEY_ID"),
            BootstrapSecretAccessKey = Optional("BOOTSTRAP_AWS_SECRET_ACCESS_KEY"),
            ExternalId               = Optional("AWS_EXTERNAL_ID"),

            WebIdentityRoleArn = Optional("AWS_WEB_IDENTITY_ROLE_ARN"),
            AzureTokenScope    = Optional("AZURE_TOKEN_SCOPE"),
        };
    }

    public string RequireRegion() => Require(AwsRegion, "AWS_REGION");

    public string RequireBucketName() => Require(BucketName, "AWS_S3_BUCKET");

    public string RequireAssumeRoleArn() => Require(AssumeRoleArn, "AWS_ASSUME_ROLE_ARN");

    public string RequireBootstrapAccessKeyId() => Require(BootstrapAccessKeyId, "BOOTSTRAP_AWS_ACCESS_KEY_ID");

    public string RequireBootstrapSecretAccessKey() => Require(BootstrapSecretAccessKey, "BOOTSTRAP_AWS_SECRET_ACCESS_KEY");

    public string RequireWebIdentityRoleArn() => Require(WebIdentityRoleArn, "AWS_WEB_IDENTITY_ROLE_ARN");

    public string RequireAzureTokenScope() => Require(AzureTokenScope, "AZURE_TOKEN_SCOPE");

    private static string Require(string? value, string name)
        => value ?? throw new InvalidOperationException(
            $"アプリ設定 '{name}' が未設定です。terraform/azure の apply でこの値が渡っているか確認してください。");

    private static string? Optional(string name)
    {
        var value = Environment.GetEnvironmentVariable(name);
        return string.IsNullOrWhiteSpace(value) ? null : value;
    }
}
