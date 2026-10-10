namespace OtelOrderApi.Domain;

/// <summary>商品と数量を持つ注文を表します。</summary>
public sealed record Order
{
    private Order(Guid id, string productId, int quantity, DateTimeOffset createdAt)
    {
        Id = id;
        ProductId = productId;
        Quantity = quantity;
        CreatedAt = createdAt;
    }

    /// <summary>注文を識別する一意のID。</summary>
    public Guid Id { get; }

    /// <summary>注文する商品の識別子。</summary>
    public string ProductId { get; }

    /// <summary>注文する数量。</summary>
    public int Quantity { get; }

    /// <summary>注文を作成した日時（UTC）。</summary>
    public DateTimeOffset CreatedAt { get; }

    /// <summary>注文を新規作成します。</summary>
    /// <param name="productId">注文する商品の識別子。</param>
    /// <param name="quantity">注文する数量。</param>
    /// <returns>作成した注文。</returns>
    /// <exception cref="ArgumentException">商品IDが空の場合。</exception>
    /// <exception cref="ArgumentOutOfRangeException">数量が0以下の場合。</exception>
    public static Order Create(string productId, int quantity)
    {
        if (string.IsNullOrWhiteSpace(productId))
        {
            throw new ArgumentException("Product ID is required.", nameof(productId));
        }

        if (quantity <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(quantity), "Quantity must be greater than zero.");
        }

        return new Order(Guid.NewGuid(), productId.Trim(), quantity, DateTimeOffset.UtcNow);
    }

    /// <summary>永続化された値から注文を復元します。</summary>
    /// <param name="id">注文ID。</param>
    /// <param name="productId">商品の識別子。</param>
    /// <param name="quantity">注文数量。</param>
    /// <param name="createdAt">注文作成日時。</param>
    /// <returns>復元した注文。</returns>
    /// <exception cref="ArgumentException">注文IDまたは商品IDが無効な場合。</exception>
    /// <exception cref="ArgumentOutOfRangeException">数量が0以下の場合。</exception>
    public static Order Rehydrate(Guid id, string productId, int quantity, DateTimeOffset createdAt)
    {
        if (id == Guid.Empty)
        {
            throw new ArgumentException("Order ID is required.", nameof(id));
        }

        if (string.IsNullOrWhiteSpace(productId))
        {
            throw new ArgumentException("Product ID is required.", nameof(productId));
        }

        if (quantity <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(quantity), "Quantity must be greater than zero.");
        }

        return new Order(id, productId, quantity, createdAt);
    }
}
