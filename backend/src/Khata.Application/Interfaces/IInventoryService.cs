namespace Khata.Application.Interfaces;

using Khata.Application.Common;
using Khata.Application.DTOs;

/// <summary>
/// Inventory: stock levels, manual stock adjustments (which append immutable
/// stock movements) and movement history. All operations are scoped to the
/// caller's ACTIVE business via the EF Core global query filter.
/// </summary>
public interface IInventoryService
{
    /// <summary>
    /// Stock list (products with their current quantity). Same shape as the
    /// product catalog so the client can reuse list widgets.
    /// </summary>
    Task<PagedResult<ProductDto>> GetInventoryAsync(InventoryQuery query, CancellationToken cancellationToken = default);

    /// <summary>Products at or below their minimum quantity (low stock alerts).</summary>
    Task<IReadOnlyList<ProductDto>> GetLowStockAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Applies a signed stock adjustment. Appends an AdjustmentIn/AdjustmentOut
    /// movement and updates the cached stock row in one transaction.
    /// Rejects adjustments that would drive stock negative (422).
    /// </summary>
    Task<AdjustStockResponse> AdjustStockAsync(long productId, AdjustStockRequest request, CancellationToken cancellationToken = default);

    /// <summary>Append-only movement history for a product, newest first.</summary>
    Task<PagedResult<StockMovementDto>> GetMovementsAsync(long productId, int page = 1, int pageSize = 20, CancellationToken cancellationToken = default);
}
