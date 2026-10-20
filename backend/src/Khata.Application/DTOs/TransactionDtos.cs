namespace Khata.Application.DTOs;

using Khata.Domain.Enums;

// ==============================================================
// Sales
// ==============================================================

/// <summary>
/// One sale line. UnitPrice / TaxRateBps default to the product's current
/// selling price / tax rate when omitted.
/// </summary>
public record SaleItemRequest(
    long ProductId,
    decimal Quantity,
    long? UnitPrice = null,
    long DiscountAmount = 0,
    int? TaxRateBps = null
);

/// <summary>
/// Creates a sale. Money is paisa. SaleDate defaults to today. SaleType drives
/// the payment rules: Cash → paid must equal the total; Credit → paid must be
/// 0; Partial → 0 &lt; paid &lt; total. InvoiceNumber is auto-allocated when omitted.
/// </summary>
public record CreateSaleRequest(
    long? CustomerId,
    SaleType SaleType,
    IReadOnlyList<SaleItemRequest> Items,
    DateOnly? SaleDate = null,
    long DiscountAmount = 0,
    long PaidAmount = 0,
    string? Notes = null,
    string? InvoiceNumber = null
);

public record SaleItemDto(
    long Id,
    long ProductId,
    string ProductName,
    decimal Quantity,
    long UnitPrice,
    long DiscountAmount,
    int TaxRateBps,
    long TaxAmount,
    long LineTotal
);

/// <summary>A sale. Items are populated on the detail endpoint and empty in lists.</summary>
public record SaleDto(
    long Id,
    string InvoiceNumber,
    long? CustomerId,
    string? CustomerName,
    SaleType SaleType,
    PaymentStatus PaymentStatus,
    DateOnly SaleDate,
    long Subtotal,
    long DiscountAmount,
    long TaxAmount,
    long TotalAmount,
    long PaidAmount,
    long DueAmount,
    string? Notes,
    IReadOnlyList<SaleItemDto> Items,
    DateTime CreatedAt,
    DateTime UpdatedAt
);

/// <summary>Sale list query. Search matches invoice number and customer name.</summary>
public record SaleQuery(
    long? CustomerId = null,
    SaleType? SaleType = null,
    PaymentStatus? PaymentStatus = null,
    DateOnly? DateFrom = null,
    DateOnly? DateTo = null,
    string? Search = null,
    int Page = 1,
    int PageSize = 20
);

// ==============================================================
// Purchases
// ==============================================================

/// <summary>
/// One purchase line. UnitPrice / TaxRateBps default to the product's cost
/// price / tax rate when omitted.
/// </summary>
public record PurchaseItemRequest(
    long ProductId,
    decimal Quantity,
    long? UnitPrice = null,
    long DiscountAmount = 0,
    int? TaxRateBps = null
);

/// <summary>Creates a purchase (mirror of <see cref="CreateSaleRequest"/>).</summary>
public record CreatePurchaseRequest(
    long? SupplierId,
    PurchaseType PurchaseType,
    IReadOnlyList<PurchaseItemRequest> Items,
    DateOnly? PurchaseDate = null,
    long DiscountAmount = 0,
    long PaidAmount = 0,
    string? Notes = null,
    string? BillNumber = null
);

public record PurchaseItemDto(
    long Id,
    long ProductId,
    string ProductName,
    decimal Quantity,
    long UnitPrice,
    long DiscountAmount,
    int TaxRateBps,
    long TaxAmount,
    long LineTotal
);

public record PurchaseDto(
    long Id,
    string BillNumber,
    long? SupplierId,
    string? SupplierName,
    PurchaseType PurchaseType,
    PaymentStatus PaymentStatus,
    DateOnly PurchaseDate,
    long Subtotal,
    long DiscountAmount,
    long TaxAmount,
    long TotalAmount,
    long PaidAmount,
    long DueAmount,
    string? Notes,
    IReadOnlyList<PurchaseItemDto> Items,
    DateTime CreatedAt,
    DateTime UpdatedAt
);

/// <summary>Purchase list query. Search matches bill number and supplier name.</summary>
public record PurchaseQuery(
    long? SupplierId = null,
    PurchaseType? PurchaseType = null,
    PaymentStatus? PaymentStatus = null,
    DateOnly? DateFrom = null,
    DateOnly? DateTo = null,
    string? Search = null,
    int Page = 1,
    int PageSize = 20
);

// ==============================================================
// Expenses
// ==============================================================

public record CreateExpenseRequest(
    string Category,
    long Amount,
    DateOnly? ExpenseDate = null,
    string? Description = null,
    string? PaymentMethod = null,
    string? Reference = null,
    string? Notes = null
);

public record UpdateExpenseRequest(
    string Category,
    long Amount,
    DateOnly? ExpenseDate = null,
    string? Description = null,
    string? PaymentMethod = null,
    string? Reference = null,
    string? Notes = null
);

public record ExpenseDto(
    long Id,
    string Category,
    long Amount,
    DateOnly ExpenseDate,
    string? Description,
    string? PaymentMethod,
    string? Reference,
    string? Notes,
    DateTime CreatedAt,
    DateTime UpdatedAt
);

/// <summary>Expense list query. Search matches category, description and reference.</summary>
public record ExpenseQuery(
    string? Search = null,
    string? Category = null,
    DateOnly? DateFrom = null,
    DateOnly? DateTo = null,
    int Page = 1,
    int PageSize = 20
);

// ==============================================================
// Income
// ==============================================================

public record CreateIncomeRequest(
    string Source,
    long Amount,
    DateOnly? IncomeDate = null,
    string? Description = null,
    string? PaymentMethod = null,
    string? Reference = null,
    string? Notes = null
);

public record UpdateIncomeRequest(
    string Source,
    long Amount,
    DateOnly? IncomeDate = null,
    string? Description = null,
    string? PaymentMethod = null,
    string? Reference = null,
    string? Notes = null
);

public record IncomeDto(
    long Id,
    string Source,
    long Amount,
    DateOnly IncomeDate,
    string? Description,
    string? PaymentMethod,
    string? Reference,
    string? Notes,
    DateTime CreatedAt,
    DateTime UpdatedAt
);

/// <summary>Income list query. Search matches source, description and reference.</summary>
public record IncomeQuery(
    string? Search = null,
    string? Source = null,
    DateOnly? DateFrom = null,
    DateOnly? DateTo = null,
    int Page = 1,
    int PageSize = 20
);
