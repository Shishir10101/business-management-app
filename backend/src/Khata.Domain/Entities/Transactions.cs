namespace Khata.Domain.Entities;

using Khata.Domain.Common;
using Khata.Domain.Enums;

/// <summary>
/// A sale of goods/services to a customer (or a walk-in, when CustomerId is
/// null). All money is integer paisa. Creating a sale decrements stock,
/// appends the credit portion to the customer's khata ledger and allocates a
/// per-business invoice number — all in one transaction.
/// </summary>
/// <remarks>
/// Deleting a sale does not remove it: the row is soft-deleted and the
/// effects are reversed (stock restored, ledger credited back), so financial
/// history stays auditable.
/// </remarks>
public class Sale : SoftDeletableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    /// <summary>Per-business sequential invoice number, e.g. "INV-00001".</summary>
    public string InvoiceNumber { get; set; } = string.Empty;

    /// <summary>Null for a walk-in / cash sale with no named customer.</summary>
    public long? CustomerId { get; set; }
    public Customer? Customer { get; set; }

    public SaleType SaleType { get; set; }
    public PaymentStatus PaymentStatus { get; set; }
    public DateOnly SaleDate { get; set; }

    /// <summary>Sum of line gross amounts (qty × unit price), before discounts.</summary>
    public long Subtotal { get; set; }

    /// <summary>Total discount: line discounts + header discount.</summary>
    public long DiscountAmount { get; set; }

    public long TaxAmount { get; set; }

    /// <summary>Subtotal − discount + tax.</summary>
    public long TotalAmount { get; set; }

    public long PaidAmount { get; set; }

    /// <summary>TotalAmount − PaidAmount (the part that hits the khata).</summary>
    public long DueAmount { get; set; }

    public string? Notes { get; set; }

    public ICollection<SaleItem> Items { get; set; } = [];
}

/// <summary>One line of a sale. Product name/price are snapshotted so history
/// survives later product edits.</summary>
public class SaleItem : AuditableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public long SaleId { get; set; }
    public Sale Sale { get; set; } = null!;

    public long ProductId { get; set; }
    public Product Product { get; set; } = null!;

    /// <summary>Product name at the time of sale.</summary>
    public string ProductName { get; set; } = string.Empty;

    public decimal Quantity { get; set; }

    /// <summary>Unit price in paisa at the time of sale.</summary>
    public long UnitPrice { get; set; }

    /// <summary>Line-level discount in paisa.</summary>
    public long DiscountAmount { get; set; }

    /// <summary>Tax rate in basis points (1300 = 13.00%).</summary>
    public int TaxRateBps { get; set; }

    public long TaxAmount { get; set; }

    /// <summary>Quantity × UnitPrice − DiscountAmount + TaxAmount.</summary>
    public long LineTotal { get; set; }
}

/// <summary>
/// A purchase of goods from a supplier. Mirror of <see cref="Sale"/>: stock
/// increases, the credit portion hits the supplier's khata ledger (we owe
/// more), and a per-business bill number is allocated atomically.
/// </summary>
public class Purchase : SoftDeletableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    /// <summary>Per-business sequential bill number, e.g. "BILL-00001".</summary>
    public string BillNumber { get; set; } = string.Empty;

    public long? SupplierId { get; set; }
    public Supplier? Supplier { get; set; }

    public PurchaseType PurchaseType { get; set; }
    public PaymentStatus PaymentStatus { get; set; }
    public DateOnly PurchaseDate { get; set; }

    public long Subtotal { get; set; }
    public long DiscountAmount { get; set; }
    public long TaxAmount { get; set; }
    public long TotalAmount { get; set; }
    public long PaidAmount { get; set; }
    public long DueAmount { get; set; }

    public string? Notes { get; set; }

    public ICollection<PurchaseItem> Items { get; set; } = [];
}

/// <summary>One line of a purchase (mirror of <see cref="SaleItem"/>).</summary>
public class PurchaseItem : AuditableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public long PurchaseId { get; set; }
    public Purchase Purchase { get; set; } = null!;

    public long ProductId { get; set; }
    public Product Product { get; set; } = null!;

    public string ProductName { get; set; } = string.Empty;

    public decimal Quantity { get; set; }
    public long UnitPrice { get; set; }
    public long DiscountAmount { get; set; }
    public int TaxRateBps { get; set; }
    public long TaxAmount { get; set; }
    public long LineTotal { get; set; }
}

/// <summary>An operating expense (rent, salary, utilities…). Amount is paisa.</summary>
public class Expense : SoftDeletableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public string Category { get; set; } = string.Empty;
    public string? Description { get; set; }

    /// <summary>Amount in paisa.</summary>
    public long Amount { get; set; }

    public DateOnly ExpenseDate { get; set; }

    /// <summary>'cash' | 'bank' | 'esewa' | 'khalti' … (free text).</summary>
    public string? PaymentMethod { get; set; }

    public string? Reference { get; set; }
    public string? Notes { get; set; }
}

/// <summary>Non-sale income (interest, rent received, misc…). Amount is paisa.</summary>
public class Income : SoftDeletableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public string Source { get; set; } = string.Empty;
    public string? Description { get; set; }

    /// <summary>Amount in paisa.</summary>
    public long Amount { get; set; }

    public DateOnly IncomeDate { get; set; }
    public string? PaymentMethod { get; set; }
    public string? Reference { get; set; }
    public string? Notes { get; set; }
}

/// <summary>
/// Per-business counter used to allocate gap-free document numbers
/// (invoice / bill). One row per (BusinessId, DocumentType); the unique index
/// on (BusinessId, DocumentType) plus the unique index on the issued number
/// guarantee no duplicates even under concurrent creates.
/// </summary>
public class DocumentSequence : AuditableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    /// <summary>'sale' | 'purchase'.</summary>
    public string DocumentType { get; set; } = string.Empty;

    /// <summary>The next number to hand out (1-based).</summary>
    public long NextValue { get; set; } = 1;
}
