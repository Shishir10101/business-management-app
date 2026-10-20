namespace Khata.Domain.Entities;

using Khata.Domain.Common;
using Khata.Domain.Enums;

/// <summary>
/// Product category. Business-scoped, supports one level of nesting via ParentId.
/// </summary>
public class ProductCategory : SoftDeletableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public long? ParentId { get; set; }
    public ProductCategory? Parent { get; set; }
    public ICollection<ProductCategory> Children { get; set; } = [];
    public bool IsActive { get; set; } = true;

    public ICollection<Product> Products { get; set; } = [];
}

/// <summary>
/// Unit of measure for products (pcs, kg, box, dozen...). Unique per business by name.
/// </summary>
public class Unit : SoftDeletableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public string Name { get; set; } = string.Empty;
    public string ShortName { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;

    public ICollection<Product> Products { get; set; } = [];
}

/// <summary>
/// Product / service sold or purchased by a business.
/// </summary>
/// <remarks>
/// Prices are integer paisa (never floating-point): 19_900 = रु 199.00.
/// </remarks>
public class Product : SoftDeletableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public long? CategoryId { get; set; }
    public ProductCategory? Category { get; set; }

    public long? UnitId { get; set; }
    public Unit? Unit { get; set; }

    public string Name { get; set; } = string.Empty;
    public string? Sku { get; set; }
    public string? Barcode { get; set; }
    public string? Description { get; set; }

    /// <summary>Cost price in paisa (रु 199.00 = 19900).</summary>
    public long CostPrice { get; set; }

    /// <summary>Selling price in paisa.</summary>
    public long SellingPrice { get; set; }

    /// <summary>Wholesale price in paisa (null = no wholesale price).</summary>
    public long? WholesalePrice { get; set; }

    /// <summary>Tax/VAT rate in basis points (1300 = 13.00%).</summary>
    public int TaxRateBps { get; set; }

    public string? ImageUrl { get; set; }
    public bool IsActive { get; set; } = true;

    public ProductStock? Stock { get; set; }
}

/// <summary>
/// Current stock level per product. Cached from stock movements for fast reads;
/// updated within the same transaction as each movement.
/// Unique per (BusinessId, ProductId).
/// </summary>
public class ProductStock : AuditableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public long ProductId { get; set; }
    public Product Product { get; set; } = null!;

    /// <summary>Current quantity (supports fractional, e.g. kg).</summary>
    public decimal Quantity { get; set; }

    /// <summary>Low-stock threshold; alert when Quantity &lt;= MinQuantity.</summary>
    public decimal MinQuantity { get; set; }
}

/// <summary>
/// Append-only log of every stock change. Never updated or deleted —
/// the DbContext enforces this for <see cref="IImmutable"/> entities.
/// </summary>
public class StockMovement : ImmutableEntity, IBusinessEntity, IImmutable
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public long ProductId { get; set; }
    public Product Product { get; set; } = null!;

    public StockMovementType MovementType { get; set; }

    /// <summary>Signed quantity: positive = in, negative = out.</summary>
    public decimal Quantity { get; set; }

    /// <summary>Stock quantity after this movement (running ledger).</summary>
    public decimal BalanceAfter { get; set; }

    /// <summary>'sale' | 'purchase' | 'adjustment' — source of the movement.</summary>
    public string? ReferenceType { get; set; }
    public long? ReferenceId { get; set; }
    public string? Notes { get; set; }

    public DateOnly MovementDate { get; set; }
}
