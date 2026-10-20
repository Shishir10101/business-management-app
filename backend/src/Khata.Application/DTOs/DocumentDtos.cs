namespace Khata.Application.DTOs;

using Khata.Domain.Enums;

/// <summary>
/// One line of an invoice or quotation. <c>Description</c> may be omitted when
/// <c>ProductId</c> is set — the product name is then used. <c>TaxRateBps</c>
/// defaults to the product's tax rate when omitted.
/// </summary>
public record DocumentLineRequest(
    string? Description,
    decimal Quantity,
    long UnitPrice,
    long? ProductId = null,
    long DiscountAmount = 0,
    int? TaxRateBps = null
);

public record DocumentLineDto(
    long Id,
    long? ProductId,
    string Description,
    decimal Quantity,
    long UnitPrice,
    long DiscountAmount,
    int TaxRateBps,
    long TaxAmount,
    long LineTotal
);

// ==============================================================
// Invoices
// ==============================================================

/// <summary>
/// Creates an invoice. With <c>SaleId</c> set the lines and totals are copied
/// from that sale and its invoice number is reused; otherwise <c>Items</c> is
/// required and a new number is allocated from the business's INV series.
/// </summary>
public record CreateInvoiceRequest(
    long? CustomerId = null,
    long? SaleId = null,
    DateOnly? IssueDate = null,
    DateOnly? DueDate = null,
    IReadOnlyList<DocumentLineRequest>? Items = null,
    long DiscountAmount = 0,
    string? Notes = null,
    string? Terms = null,
    InvoiceStatus? Status = null
);

public record UpdateInvoiceRequest(
    long? CustomerId,
    IReadOnlyList<DocumentLineRequest>? Items,
    DateOnly? IssueDate = null,
    DateOnly? DueDate = null,
    long DiscountAmount = 0,
    string? Notes = null,
    string? Terms = null,
    InvoiceStatus? Status = null
);

public record InvoiceDto(
    long Id,
    string InvoiceNumber,
    long? CustomerId,
    string? CustomerName,
    long? SaleId,
    string? SaleInvoiceNumber,
    InvoiceStatus Status,
    DateOnly IssueDate,
    DateOnly? DueDate,
    long Subtotal,
    long DiscountAmount,
    long TaxAmount,
    long TotalAmount,
    string? Notes,
    string? Terms,
    bool HasPdf,
    DateTime? PdfGeneratedAt,
    IReadOnlyList<DocumentLineDto> Items,
    DateTime CreatedAt,
    DateTime UpdatedAt
);

/// <summary>Invoice list query. Search matches invoice number and customer name.</summary>
public record InvoiceQuery(
    long? CustomerId = null,
    InvoiceStatus? Status = null,
    DateOnly? DateFrom = null,
    DateOnly? DateTo = null,
    string? Search = null,
    int Page = 1,
    int PageSize = 20
);

// ==============================================================
// Quotations
// ==============================================================

public record CreateQuotationRequest(
    long? CustomerId = null,
    DateOnly? IssueDate = null,
    DateOnly? ValidUntil = null,
    IReadOnlyList<DocumentLineRequest>? Items = null,
    long DiscountAmount = 0,
    string? Notes = null,
    string? Terms = null,
    QuotationStatus? Status = null
);

public record UpdateQuotationRequest(
    long? CustomerId,
    IReadOnlyList<DocumentLineRequest>? Items,
    DateOnly? IssueDate = null,
    DateOnly? ValidUntil = null,
    long DiscountAmount = 0,
    string? Notes = null,
    string? Terms = null,
    QuotationStatus? Status = null
);

public record QuotationDto(
    long Id,
    string QuoteNumber,
    long? CustomerId,
    string? CustomerName,
    QuotationStatus Status,
    DateOnly IssueDate,
    DateOnly? ValidUntil,
    long Subtotal,
    long DiscountAmount,
    long TaxAmount,
    long TotalAmount,
    string? Notes,
    string? Terms,
    long? ConvertedSaleId,
    bool HasPdf,
    DateTime? PdfGeneratedAt,
    IReadOnlyList<DocumentLineDto> Items,
    DateTime CreatedAt,
    DateTime UpdatedAt
);

/// <summary>Quotation list query. Search matches quote number and customer name.</summary>
public record QuotationQuery(
    long? CustomerId = null,
    QuotationStatus? Status = null,
    DateOnly? DateFrom = null,
    DateOnly? DateTo = null,
    string? Search = null,
    int Page = 1,
    int PageSize = 20
);

/// <summary>Converts an accepted quotation into a real sale.</summary>
public record ConvertQuotationRequest(
    SaleType SaleType = SaleType.Credit,
    long PaidAmount = 0,
    DateOnly? SaleDate = null,
    string? Notes = null
);
