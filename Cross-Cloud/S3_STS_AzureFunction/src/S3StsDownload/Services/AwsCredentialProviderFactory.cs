namespace S3StsDownload.Services;

/// <summary>
/// リクエストの ?mode= / 既定の CREDENTIAL_MODE に応じて方式A / 方式B を選ぶ。
/// 2 方式を同じエンドポイントで比較できるようにするためのもの。
/// </summary>
public sealed class AwsCredentialProviderFactory
{
    private readonly IReadOnlyDictionary<string, IAwsCredentialProvider> _providers;
    private readonly StsSettings _settings;

    public AwsCredentialProviderFactory(
        AccessKeyAssumeRoleProvider accessKeyProvider,
        AzureOidcWebIdentityProvider oidcProvider,
        StsSettings settings)
    {
        _settings = settings;
        _providers = new Dictionary<string, IAwsCredentialProvider>(StringComparer.OrdinalIgnoreCase)
        {
            [accessKeyProvider.Mode] = accessKeyProvider,
            [oidcProvider.Mode]      = oidcProvider,
        };
    }

    public IReadOnlyCollection<string> AvailableModes => _providers.Keys.ToArray();

    public IAwsCredentialProvider Resolve(string? requestedMode)
    {
        var mode = string.IsNullOrWhiteSpace(requestedMode) ? _settings.DefaultMode : requestedMode.Trim();

        if (!_providers.TryGetValue(mode, out var provider))
        {
            throw new ArgumentException(
                $"不明な mode '{mode}' です。指定できるのは: {string.Join(", ", AvailableModes)}");
        }

        return provider;
    }
}
