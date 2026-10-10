using Azure.Monitor.OpenTelemetry.AspNetCore;
using Azure.Storage.Blobs;
using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;
using OtelOrderApi.Application;
using OtelOrderApi.Application.Orders;
using OtelOrderApi.Infrastructure;

/// <summary>注文APIの起動設定とHTTPエンドポイントを定義します。</summary>
public static class Program
{
    /// <summary>依存関係とOpenTelemetryを登録し、Web APIを起動します。</summary>
    /// <param name="args">プロセス起動時に渡された引数。</param>
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);
        var applicationInsightsConnectionString = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"];

        // 独自のMeterとActivitySourceをOpenTelemetry SDKに購読させます。
        // ここで指定する名前はApplication層のTelemetry定義と一致させます。
        builder.Services.ConfigureOpenTelemetryMeterProvider(meterBuilder =>
            meterBuilder.AddMeter(Telemetry.MeterName));
        builder.Services.ConfigureOpenTelemetryTracerProvider(traceBuilder =>
            traceBuilder.AddSource(Telemetry.ActivitySourceName));

        // SingletonのBlob clientをRepositoryへ注入し、ユースケースはインターフェースに依存させます。
        builder.Services.AddSingleton(_ => new BlobContainerClient(
            builder.Configuration["Blob:ConnectionString"] ?? "UseDevelopmentStorage=true",
            builder.Configuration["Blob:ContainerName"] ?? "orders"));
        builder.Services.AddScoped<IOrderRepository, BlobOrderRepository>();
        builder.Services.AddScoped<CreateOrderHandler>();
        builder.Services.AddScoped<GetOrderHandler>();

        if (!string.IsNullOrWhiteSpace(applicationInsightsConnectionString))
        {
            // 接続文字列があればAzure Monitor Distroが計測と送信を設定します。
            builder.Services.AddOpenTelemetry()
                .UseAzureMonitor(options => options.ConnectionString = applicationInsightsConnectionString);
        }
        else
        {
            // 接続文字列なしでも試せるよう、全シグナルをローカルのConsole Exporterへ送ります。
            Console.WriteLine("APPLICATIONINSIGHTS_CONNECTION_STRING is unset; telemetry will be printed locally.");
            builder.Logging.ClearProviders();
            builder.Services.AddOpenTelemetry()
                .WithMetrics(metrics => metrics.AddConsoleExporter())
                .WithTracing(tracing => tracing
                    // Distroを使わないローカル実行では、HTTPとAzure SDKの計測を明示的に登録します。
                    .AddAspNetCoreInstrumentation()
                    .AddSource("Azure.*")
                    .AddConsoleExporter());
            builder.Logging.AddOpenTelemetry(logging => logging.AddConsoleExporter());
        }

        var app = builder.Build();

        // 死活確認用エンドポイントです。注文処理やBlob Storageにはアクセスしません。
        app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

        // HTTP層は入力をApplicationのCommandへ変換し、ユースケースの結果をHTTP応答へ変換します。
        app.MapPost("/orders", async (
            CreateOrderRequest request,
            CreateOrderHandler handler,
            CancellationToken cancellationToken) =>
        {
            try
            {
                var result = await handler.HandleAsync(
                    new CreateOrderCommand(request.ProductId, request.Quantity), cancellationToken);

                if (!result.IsValid)
                {
                    return Results.ValidationProblem(new Dictionary<string, string[]>
                    {
                        ["request"] = [result.ValidationError!]
                    });
                }

                return Results.Created($"/orders/{result.Order!.Id}", result.Order);
            }
            catch (OrderStorageException)
            {
                // Azure固有の例外詳細はApplication/Infrastructure内に閉じ、HTTPでは503として返します。
                return Results.Problem("Order storage is unavailable.", statusCode: StatusCodes.Status503ServiceUnavailable);
            }
        });

        // Guid形式のIDで注文を取得します。未登録なら404、ストレージ障害なら503を返します。
        app.MapGet("/orders/{id:guid}", async (
            Guid id,
            GetOrderHandler handler,
            CancellationToken cancellationToken) =>
        {
            try
            {
                var order = await handler.HandleAsync(id, cancellationToken);
                return order is null ? Results.NotFound() : Results.Ok(order);
            }
            catch (OrderStorageException)
            {
                return Results.Problem("Order storage is unavailable.", statusCode: StatusCodes.Status503ServiceUnavailable);
            }
        });

        app.Run();
    }
}

/// <summary>注文作成APIが受け取るHTTPリクエストです。</summary>
/// <param name="ProductId">注文する商品の識別子。</param>
/// <param name="Quantity">注文する数量。</param>
internal sealed record CreateOrderRequest(string? ProductId, int Quantity);
