using System.Diagnostics;
using System.Diagnostics.Metrics;

namespace OtelOrderApi.Application;

/// <summary>注文ユースケースのOpenTelemetry計測器を定義します。</summary>
public static class Telemetry
{
    /// <summary>独自ActivitySourceの購読名。</summary>
    public const string ActivitySourceName = "InfraStudy.OtelOrderApi.Application";

    /// <summary>独自Meterの購読名。</summary>
    public const string MeterName = "InfraStudy.OtelOrderApi.Application";

    /// <summary>注文ユースケースのスパンを作成するActivitySource。</summary>
    public static readonly ActivitySource ActivitySource = new(ActivitySourceName);
    private static readonly Meter Meter = new(MeterName);

    /// <summary>注文作成要求数を結果別に数えるカウンター。</summary>
    /// <remarks>result属性には少数の固定値だけを使い、注文IDなどは追加しません。</remarks>
    public static readonly Counter<long> OrderRequests = Meter.CreateCounter<long>(
        "orders.requests", description: "Number of order creation attempts by result.");

    /// <summary>注文作成処理の所要時間を記録するヒストグラム（ミリ秒）。</summary>
    public static readonly Histogram<double> OrderDuration = Meter.CreateHistogram<double>(
        "order.processing.duration", unit: "ms", description: "Time spent creating an order.");

    /// <summary>作成された注文の商品数を記録するヒストグラム。</summary>
    public static readonly Histogram<long> OrderItems = Meter.CreateHistogram<long>(
        "orders.items", unit: "{item}", description: "Number of items in a created order.");
}
