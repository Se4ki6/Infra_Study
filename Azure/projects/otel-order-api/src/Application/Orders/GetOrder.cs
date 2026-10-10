using System.Diagnostics;
using Microsoft.Extensions.Logging;
using OtelOrderApi.Domain;

namespace OtelOrderApi.Application.Orders;

/// <summary>注文取得ユースケースを実行します。</summary>
/// <param name="repository">注文の取得先。</param>
/// <param name="logger">ユースケースの出来事を記録するロガー。</param>
public sealed class GetOrderHandler(IOrderRepository repository, ILogger<GetOrderHandler> logger)
{
    /// <summary>IDに一致する注文を取得します。存在しない場合はnullを返します。</summary>
    /// <param name="id">取得する注文のID。</param>
    /// <param name="cancellationToken">処理を中断するためのトークン。</param>
    /// <returns>見つかった注文。存在しない場合はnullです。</returns>
    /// <exception cref="OrderStorageException">ストレージへのアクセスに失敗した場合。</exception>
    public async Task<Order?> HandleAsync(Guid id, CancellationToken cancellationToken)
    {
        // 現在のHTTPリクエストのトレースを引き継いで、注文取得スパンを作ります。
        using var activity = Telemetry.ActivitySource.StartActivity("orders.get");
        activity?.SetTag("order.id", id.ToString());

        try
        {
            var order = await repository.FindAsync(id, cancellationToken);
            activity?.SetTag("order.result", order is null ? "not_found" : "found");
            if (order is null)
            {
                logger.LogInformation("Order {OrderId} was not found", id);
                return null;
            }

            logger.LogInformation("Order {OrderId} retrieved", id);
            return order;
        }
        catch (OrderStorageException exception)
        {
            activity?.SetStatus(ActivityStatusCode.Error, exception.Message);
            logger.LogError(exception, "Could not retrieve order {OrderId}", id);
            throw;
        }
    }
}
