namespace Khata.Application.DTOs;

// --- Categories ---

/// <summary>Creates a product category. ParentId null = top-level category.</summary>
public record CreateCategoryRequest(
    string Name,
    string? Description = null,
    long? ParentId = null
);

/// <summary>Full update of a category.</summary>
public record UpdateCategoryRequest(
    string Name,
    string? Description = null,
    long? ParentId = null,
    bool IsActive = true
);

public record CategoryDto(
    long Id,
    string Name,
    string? Description,
    long? ParentId,
    string? ParentName,
    bool IsActive,
    int ProductCount
);

// --- Units ---

/// <summary>Creates a unit of measure. Name is unique per business.</summary>
public record CreateUnitRequest(
    string Name,
    string ShortName
);

public record UpdateUnitRequest(
    string Name,
    string ShortName,
    bool IsActive = true
);

public record UnitDto(
    long Id,
    string Name,
    string ShortName,
    bool IsActive,
    int ProductCount
);

// --- Products ---

/// <summary>
/// Creates a product. Prices are integer paisa (रु 199.00 = 19900, never
/// floating-point). TaxRateBps is basis points (1300 = 13.00%).
/// OpeningQuantity &gt; 0 records an initial "opening" stock movement in the
/// same transaction, so stock history starts from zero and stays auditable.
/// </summary>
public record CreateProductRequest(
    string Name,
    long? CategoryId = null,
    long? UnitId = null,
    string? Sku = null,
    string? Barcode = null,
    string? Description = null,
    long CostPrice = 0,
    long SellingPrice = 0,
    long? WholesalePrice = null,
    int TaxRateBps = 0,
    string? ImageUrl = null,
    bool IsActive = true,
    decimal OpeningQuantity = 0,
    decimal MinQuantity = 0
);

/// <summary>
/// Full update of a product. Stock quantity changes ONLY through
/// <c>/api/inventory/{productId}/adjust</c> (which appends a stock movement) —
/// never through product edit.
/// </summary>
public record UpdateProductRequest(
    string Name,
    long? CategoryId = null,
    long? UnitId = null,
    string? Sku = null,
    string? Barcode = null,
    string? Description = null,
    long CostPrice = 0,
    long SellingPrice = 0,
    long? WholesalePrice = null,
    int TaxRateBps = 0,
    string? ImageUrl = null,
    bool IsActive = true,
    decimal MinQuantity = 0
);

/// <summary>
/// Product with its current stock flattened in (single row for list views).
/// Quantity/MinQuantity are 0 when no stock row exists yet.
/// </summary>
public record ProductDto(
    long Id,
    string Name,
    long? CategoryId,
    string? CategoryName,
    long? UnitId,
    string? UnitShortName,
    string? Sku,
    string? Barcode,
    string? Description,
    long CostPrice,
    long SellingPrice,
    long? WholesalePrice,
    int TaxRateBps,
    string? ImageUrl,
    bool IsActive,
    decimal StockQuantity,
    decimal MinQuantity,
    bool IsLowStock,
    DateTime CreatedAt,
    DateTime UpdatedAt
);
