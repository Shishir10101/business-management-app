namespace Khata.Application.DTOs;

using Khata.Domain.Enums;

// ==============================================================
// Backup payload — faithful mirrors of the domain entities.
//
// These are NOT the read DTOs: a backup must round-trip every field
// (including soft-delete timestamps and ids) so that an export restored
// into a fresh business reproduces the dataset exactly. Read DTOs are
// lossy by design (no ids in some rows, computed names, noDeletedAt).
// ==============================================================

public record BackupProduct(
    long Id, long? CategoryId, long? UnitId, string Name, string? Sku,
    string? Barcode, string? Description, long CostPrice, long SellingPrice,
    long? WholesalePrice, int TaxRateBps, string? ImageUrl, bool IsActive,
    decimal StockQuantity, decimal MinQuantity, DateTime? DeletedAt);

public record BackupCategory(long Id, string Name, string? Description, long? ParentId, bool IsActive, DateTime? DeletedAt);
public record BackupUnit(long Id, string Name, string ShortName, bool IsActive, DateTime? DeletedAt);

public record BackupCustomer(
    long Id, string Name, string? PhoneNumber, string? Email, string? AddressLine,
    string? City, string? District, long OpeningBalance, string? PanNumber,
    long? CreditLimit, string? Notes, bool IsActive, DateTime? DeletedAt);

public record BackupSupplier(
    long Id, string Name, string? PhoneNumber, string? Email, string? AddressLine,
    string? City, string? District, long OpeningBalance, string? PanNumber,
    string? Notes, bool IsActive, DateTime? DeletedAt);

public record BackupSaleItem(
    long Id, long ProductId, string ProductName, decimal Quantity, long UnitPrice,
    long DiscountAmount, int TaxRateBps, long TaxAmount, long LineTotal);

public record BackupSale(
    long Id, string InvoiceNumber, long? CustomerId, SaleType SaleType,
    PaymentStatus PaymentStatus, DateOnly SaleDate, long Subtotal,
    long DiscountAmount, long TaxAmount, long TotalAmount, long PaidAmount,
    long DueAmount, string? Notes, IReadOnlyList<BackupSaleItem> Items,
    DateTime? DeletedAt);

public record BackupPurchaseItem(
    long Id, long ProductId, string ProductName, decimal Quantity, long UnitPrice,
    long DiscountAmount, int TaxRateBps, long TaxAmount, long LineTotal);

public record BackupPurchase(
    long Id, string BillNumber, long? SupplierId, PurchaseType PurchaseType,
    PaymentStatus PaymentStatus, DateOnly PurchaseDate, long Subtotal,
    long DiscountAmount, long TaxAmount, long TotalAmount, long PaidAmount,
    long DueAmount, string? Notes, IReadOnlyList<BackupPurchaseItem> Items,
    DateTime? DeletedAt);

public record BackupExpense(
    long Id, string Category, long Amount, DateOnly ExpenseDate, string? Description,
    string? PaymentMethod, string? Reference, string? Notes, DateTime? DeletedAt);

public record BackupIncome(
    long Id, string Source, long Amount, DateOnly IncomeDate, string? Description,
    string? PaymentMethod, string? Reference, string? Notes, DateTime? DeletedAt);

public record BackupPayment(
    long Id, PartyType PartyType, long PartyId, PaymentDirection Direction, long Amount,
    DateOnly PaymentDate, long? PaymentMethodId, string? MethodName, string? Reference,
    string? Notes, long? SaleId, long? PurchaseId, long AppliedAmount, long UnappliedAmount);

public record BackupPaymentMethod(
    long Id, string Name, string Code, string? Description, bool IsActive, bool IsDefault,
    DateTime? DeletedAt);

public record BackupInvoiceItem(
    long Id, long? ProductId, string Description, decimal Quantity, long UnitPrice,
    long DiscountAmount, int TaxRateBps, long TaxAmount, long LineTotal);

public record BackupInvoice(
    long Id, string InvoiceNumber, long? CustomerId, long? SaleId, InvoiceStatus Status,
    DateOnly IssueDate, DateOnly? DueDate, long Subtotal, long DiscountAmount,
    long TaxAmount, long TotalAmount, string? Notes, string? Terms, string? PdfPath,
    DateTime? PdfGeneratedAt, IReadOnlyList<BackupInvoiceItem> Items, DateTime? DeletedAt);

public record BackupQuotationItem(
    long Id, long? ProductId, string Description, decimal Quantity, long UnitPrice,
    long DiscountAmount, int TaxRateBps, long TaxAmount, long LineTotal);

public record BackupQuotation(
    long Id, string QuoteNumber, long? CustomerId, QuotationStatus Status,
    DateOnly IssueDate, DateOnly? ValidUntil, long Subtotal, long DiscountAmount,
    long TaxAmount, long TotalAmount, string? Notes, string? Terms, long? ConvertedSaleId,
    string? PdfPath, DateTime? PdfGeneratedAt, IReadOnlyList<BackupQuotationItem> Items,
    DateTime? DeletedAt);

/// <summary>
/// A full JSON dump of one business. Every table keeps its original ids so a
/// restore into a fresh business reproduces the dataset exactly; restoring
/// into a populated business skips ids that already exist (merge, never
/// overwrite — money rows are immutable by design).
/// </summary>
public record BackupExportDto(
    int Version,
    long BusinessId,
    string BusinessName,
    DateTime ExportedAt,
    IReadOnlyList<BackupProduct> Products,
    IReadOnlyList<BackupCategory> Categories,
    IReadOnlyList<BackupUnit> Units,
    IReadOnlyList<BackupCustomer> Customers,
    IReadOnlyList<BackupSupplier> Suppliers,
    IReadOnlyList<BackupSale> Sales,
    IReadOnlyList<BackupPurchase> Purchases,
    IReadOnlyList<BackupExpense> Expenses,
    IReadOnlyList<BackupIncome> Incomes,
    IReadOnlyList<BackupPayment> Payments,
    IReadOnlyList<BackupPaymentMethod> PaymentMethods,
    IReadOnlyList<BackupInvoice> Invoices,
    IReadOnlyList<BackupQuotation> Quotations
);
