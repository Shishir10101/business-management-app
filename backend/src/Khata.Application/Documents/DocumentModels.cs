namespace Khata.Application.Documents;

/// <summary>Business letterhead printed at the top of a document.</summary>
public record BusinessLetterhead(
    string Name,
    string? AddressLine,
    string? City,
    string? District,
    string? PhoneNumber,
    string? Email,
    string? PanNumber
);

/// <summary>A party block ("Billed to").</summary>
public record DocumentParty(
    string? Name,
    string? PhoneNumber,
    string? AddressLine,
    string? PanNumber
);

/// <summary>One printed line item. Money is paisa.</summary>
public record DocumentLine(
    string Description,
    decimal Quantity,
    long UnitPrice,
    long DiscountAmount,
    int TaxRateBps,
    long TaxAmount,
    long LineTotal
);

/// <summary>Everything the invoice template needs to render a PDF.</summary>
public record InvoicePdfModel(
    BusinessLetterhead Business,
    string InvoiceNumber,
    string Status,
    DateOnly IssueDate,
    DateOnly? DueDate,
    DocumentParty? Customer,
    IReadOnlyList<DocumentLine> Lines,
    long Subtotal,
    long DiscountAmount,
    long TaxAmount,
    long TotalAmount,
    string? Notes,
    string? Terms,
    string Currency
);

/// <summary>Everything the quotation template needs to render a PDF.</summary>
public record QuotationPdfModel(
    BusinessLetterhead Business,
    string QuoteNumber,
    string Status,
    DateOnly IssueDate,
    DateOnly? ValidUntil,
    DocumentParty? Customer,
    IReadOnlyList<DocumentLine> Lines,
    long Subtotal,
    long DiscountAmount,
    long TaxAmount,
    long TotalAmount,
    string? Notes,
    string? Terms,
    string Currency
);
