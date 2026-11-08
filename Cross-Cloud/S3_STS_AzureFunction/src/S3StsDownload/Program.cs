using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using S3StsDownload.Services;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices(services =>
    {
        // Application Insights (STS 呼び出しの失敗原因を追うのに使う)
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();

        // アプリ設定は起動時に一度だけ読む
        services.AddSingleton(_ => StsSettings.FromEnvironment());

        // 一時クレデンシャルをキャッシュしたいので、いずれも Singleton にする
        services.AddSingleton<AccessKeyAssumeRoleProvider>();
        services.AddSingleton<AzureOidcWebIdentityProvider>();
        services.AddSingleton<AwsCredentialProviderFactory>();
        services.AddSingleton<S3AccessService>();
    })
    .Build();

host.Run();
