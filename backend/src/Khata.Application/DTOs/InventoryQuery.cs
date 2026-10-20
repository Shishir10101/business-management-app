namespace Khata.Application.DTOs;

/// <summary>
/// Paged inventory query. SortBy: "name" (default) or "quantity".
/// LowStockOnly restricts to products at/below their minimum quantity.
/// </summary>
public record InventoryQuery(
    string? Search = null,
    bool LowStockOnly = false,
    string? SortBy = null,
    int Page = 1,
    int PageSize = 20
);
