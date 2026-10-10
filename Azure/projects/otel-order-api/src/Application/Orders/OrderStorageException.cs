namespace OtelOrderApi.Application.Orders;

/// <summary>注文の保存または取得に失敗したことを表します。</summary>
/// <param name="message">失敗内容を示すメッセージ。</param>
/// <param name="innerException">元となったストレージ例外。</param>
public sealed class OrderStorageException(string message, Exception innerException)
    : Exception(message, innerException);
