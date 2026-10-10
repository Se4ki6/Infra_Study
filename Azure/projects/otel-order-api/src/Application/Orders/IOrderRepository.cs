using OtelOrderApi.Domain;

namespace OtelOrderApi.Application.Orders;

/// <summary>注文の永続化と取得を提供します。</summary>
public interface IOrderRepository
{
    /// <summary>注文を保存します。</summary>
    /// <param name="order">保存する注文。</param>
    /// <param name="cancellationToken">処理を中断するためのトークン。</param>
    /// <returns>保存処理を表すタスク。</returns>
    /// <exception cref="OrderStorageException">注文を保存できない場合。</exception>
    Task SaveAsync(Order order, CancellationToken cancellationToken);

    /// <summary>IDに一致する注文を取得します。見つからない場合はnullを返します。</summary>
    /// <param name="id">取得する注文のID。</param>
    /// <param name="cancellationToken">処理を中断するためのトークン。</param>
    /// <returns>見つかった注文。存在しない場合はnullです。</returns>
    /// <exception cref="OrderStorageException">ストレージへのアクセスに失敗した場合。</exception>
    Task<Order?> FindAsync(Guid id, CancellationToken cancellationToken);
}
