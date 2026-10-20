namespace Khata.Domain.Entities;

using Khata.Domain.Common;
using Khata.Domain.Enums;

/// <summary>
/// A formal, printable invoice. It can be created standalone or generated from
/// an existing sale (in which case it copies the sale's lines and reuses its
/// invoice number, so the printed document matches the sale).
/// </summary>
/// <remarks>
/// Invoices share the business's single <c>INV-#####</c> numbering series with
/// sales (the same <see cref="DocumentSequence"/> row), so a number is never
/// issued twice across the two. Money is integer paisa.
/// </remarks>
public class Invoice : SoftDeletableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    /// <summary>Per-business invoice number, e.g. "INV-00007".</summary>
    public string InvoiceNumber { get; set; } = string.Empty;

    public long? CustomerId { get; set; }
    public Customer? Customer { get; set; }

    /// <summary>Set when this invoice was generated from a sale.</summary>
    public long? SaleId { get; set; }
    public Sale? Sale { get; set; }

    public InvoiceStatus Status { get; set; }
    public DateOnly IssueDate { get; set; }
    public DateOnly? DueDate { get; set; }

    public long Subtotal { get; set; }
    public long DiscountAmount { get; set; }
    public long TaxAmount { get; set; }
    public long TotalAmount { get; set; }

    public string? Notes { get; set; }
    public string? Terms { get; set; }

    /// <summary>Storage key of the last generated PDF (null until first generated).</summary>
    public string? PdfPath { get; set; }
    public DateTime? PdfGeneratedAt { get; set; }

    public ICollection<InvoiceItem> Items { get; set; } = [];
}

/// <summary>One line of an invoice. Description is free text so non-catalog
/// lines (delivery, labour) are possible; ProductId is optional.</summary>
public class InvoiceItem : AuditableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public long InvoiceId { get; set; }
    public Invoice Invoice { get; set; } = null!;

    public long? ProductId { get; set; }
    public Product? Product { get; set; }

    public string Description { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public long UnitPrice { get; set; }
    public long DiscountAmount { get; set; }
    public int TaxRateBps { get; set; }
    public long TaxAmount { get; set; }
    public long LineTotal { get; set; }
}

/// <summary>
/// A price quotation (offer). Purely commercial — it never touches stock or the
/// khata; converting it to a sale does.
/// </summary>
public class Quotation : SoftDeletableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    /// <summary>Per-business quotation number, e.g. "QT-00001".</summary>
    public string QuoteNumber { get; set; } = string.Empty;

    public long? CustomerId { get; set; }
    public Customer? Customer { get; set; }

    public QuotationStatus Status { get; set; }
    public DateOnly IssueDate { get; set; }
    public DateOnly? ValidUntil { get; set; }

    public long Subtotal { get; set; }
    public long DiscountAmount { get; set; }
    public long TaxAmount { get; set; }
    public long TotalAmount { get; set; }

    public string? Notes { get; set; }
    public string? Terms { get; set; }

    /// <summary>The sale created when this quotation was converted.</summary>
    public long? ConvertedSaleId { get; set; }
    public Sale? ConvertedSale { get; set; }

    public string? PdfPath { get; set; }
    public DateTime? PdfGeneratedAt { get; set; }

    public ICollection<QuotationItem> Items { get; set; } = [];
}

/// <summary>One line of a quotation (mirror of <see cref="InvoiceItem"/>).</summary>
public class QuotationItem : AuditableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public long QuotationId { get; set; }
    public Quotation Quotation { get; set; } = null!;

    public long? ProductId { get; set; }
    public Product? Product { get; set; }

    public string Description { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public long UnitPrice { get; set; }
    public long DiscountAmount { get; set; }
    public int TaxRateBps { get; set; }
    public long TaxAmount { get; set; }
    public long LineTotal { get; set; }
}
