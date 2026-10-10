using System.Diagnostics;
using Microsoft.Extensions.Logging;
using OtelOrderApi.Domain;

namespace OtelOrderApi.Application.Orders;

/// <summary>注文作成ユースケースへの入力です。</summary>
/// <param name="ProductId">注文する商品の識別子。未入力は検証エラーになります。</param>
/// <param name="Quantity">注文する数量。1以上を指定します。</param>
public sealed record CreateOrderCommand(string? ProductId, int Quantity);

/// <summary>注文作成ユースケースの結果です。</summary>
/// <param name="Order">保存に成功した注文。入力エラーの場合はnullです。</param>
/// <param name="ValidationError">入力エラーの説明。成功時はnullです。</param>
public sealed record CreateOrderResult(Order? Order, string? ValidationError)
{
    /// <summary>注文作成が成功した場合はtrueを返します。</summary>
    public bool IsValid => Order is not null;
}

/// <summary>注文作成ユースケースを実行します。</summary>
/// <param name="repository">注文の保存先。</param>
/// <param name="logger">ユースケースの出来事を記録するロガー。</param>
public sealed class CreateOrderHandler(
    IOrderRepository repository,
    ILogger<CreateOrderHandler> logger)
{
    /// <summary>入力を検証し、注文を作成してリポジトリへ保存します。</summary>
    /// <param name="command">作成する注文の内容。</param>
    /// <param name="cancellationToken">処理を中断するためのトークン。</param>
    /// <returns>注文または入力検証エラーを含む結果。</returns>
    /// <exception cref="OrderStorageException">注文を保存できない場合。</exception>
    public async Task<CreateOrderResult> HandleAsync(
        CreateOrderCommand command,
        CancellationToken cancellationToken)
    {
        // HTTPリクエストのActivityがあれば、そのトレースに子スパンとして参加します。
        using var activity = Telemetry.ActivitySource.StartActivity("orders.create");
        var stopwatch = Stopwatch.StartNew();

        try
        {
            if (string.IsNullOrWhiteSpace(command.ProductId) || command.Quantity <= 0)
            {
                // 注文IDや商品IDなど、値の種類が増え続ける属性はメトリクスに付けません。
                Telemetry.OrderRequests.Add(1, new KeyValuePair<string, object?>("result", "rejected"));
                activity?.SetTag("order.result", "rejected");
                activity?.SetStatus(ActivityStatusCode.Error, "Invalid order input");
                logger.LogWarning("Order request rejected: product ID is required and quantity must be positive");
                return new CreateOrderResult(null,
                    "productId is required and quantity must be greater than zero.");
            }

            var order = Order.Create(command.ProductId, command.Quantity);
            activity?.SetTag("order.item_count", order.Quantity);

            try
            {
                await repository.SaveAsync(order, cancellationToken);
            }
            catch (OrderStorageException exception)
            {
                Telemetry.OrderRequests.Add(1, new KeyValuePair<string, object?>("result", "storage_error"));
                activity?.SetTag("order.result", "storage_error");
                activity?.SetStatus(ActivityStatusCode.Error, exception.Message);
                logger.LogError(exception, "Could not save order {OrderId}", order.Id);
                throw;
            }

            Telemetry.OrderRequests.Add(1, new KeyValuePair<string, object?>("result", "created"));
            Telemetry.OrderItems.Record(order.Quantity);
            activity?.SetTag("order.result", "created");
            logger.LogInformation("Order {OrderId} created for product {ProductId} with quantity {Quantity}",
                order.Id, order.ProductId, order.Quantity);
            return new CreateOrderResult(order, null);
        }
        finally
        {
            stopwatch.Stop();
            Telemetry.OrderDuration.Record(stopwatch.Elapsed.TotalMilliseconds,
                new KeyValuePair<string, object?>("operation", "create"));
        }
    }
}
