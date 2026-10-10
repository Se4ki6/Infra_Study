using System.Text.Json;
using Azure.Storage.Blobs;
using OtelOrderApi.Application.Orders;
using OtelOrderApi.Domain;

namespace OtelOrderApi.Infrastructure;

/// <summary>Azure Blob Storageを使って注文を保存・取得します。</summary>
/// <param name="container">注文Blobを格納するコンテナー。</param>
public sealed class BlobOrderRepository(BlobContainerClient container) : IOrderRepository
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    /// <summary>注文をJSONにしてBlobへ保存します。</summary>
    /// <param name="order">保存する注文。</param>
    /// <param name="cancellationToken">処理を中断するためのトークン。</param>
    /// <returns>保存処理を表すタスク。</returns>
    /// <exception cref="OrderStorageException">Azure Storageへの保存に失敗した場合。</exception>
    public async Task SaveAsync(Order order, CancellationToken cancellationToken)
    {
        try
        {
            await container.CreateIfNotExistsAsync(cancellationToken: cancellationToken);
            var blob = container.GetBlobClient($"{order.Id}.json");
            var stored = new StoredOrder(order.Id, order.ProductId, order.Quantity, order.CreatedAt);
            await blob.UploadAsync(BinaryData.FromObjectAsJson(stored, JsonOptions), cancellationToken);
        }
        catch (Azure.RequestFailedException exception)
        {
            // Azure固有例外をアプリケーション共通の例外に包み、上位層へ漏らさないようにします。
            throw new OrderStorageException("Could not save the order to Blob Storage.", exception);
        }
    }

    /// <summary>IDに対応するBlobを読み込み、注文として復元します。</summary>
    /// <param name="id">取得する注文のID。</param>
    /// <param name="cancellationToken">処理を中断するためのトークン。</param>
    /// <returns>復元した注文。Blobが存在しない場合はnullです。</returns>
    /// <exception cref="OrderStorageException">Blobが見つからない場合以外のStorageエラーが発生した場合。</exception>
    public async Task<Order?> FindAsync(Guid id, CancellationToken cancellationToken)
    {
        var blob = container.GetBlobClient($"{id}.json");
        try
        {
            var response = await blob.DownloadContentAsync(cancellationToken);
            var stored = response.Value.Content.ToObjectFromJson<StoredOrder>(JsonOptions);
            return stored is null
                ? null
                : Order.Rehydrate(stored.Id, stored.ProductId, stored.Quantity, stored.CreatedAt);
        }
        catch (Azure.RequestFailedException exception) when (exception.Status == 404)
        {
            // 404は通常の「注文なし」として扱い、障害ログや503にはしません。
            return null;
        }
        catch (Azure.RequestFailedException exception)
        {
            throw new OrderStorageException("Could not retrieve the order from Blob Storage.", exception);
        }
    }

    private sealed record StoredOrder(Guid Id, string ProductId, int Quantity, DateTimeOffset CreatedAt);
}
