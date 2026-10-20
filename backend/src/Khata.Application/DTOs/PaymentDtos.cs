namespace Khata.Application.DTOs;

using Khata.Domain.Enums;

/// <summary>
/// Records a payment against a party. <see cref="Direction"/> is derived from
/// <see cref="PartyType"/> when omitted (Customer → In, Supplier → Out) and a
/// mismatch is rejected. Linking <see cref="SaleId"/> / <see cref="PurchaseId"/>
/// applies the payment to that document; any excess stays as an advance.
/// </summary>
public record CreatePaymentRequest(
    PartyType PartyType,
    long PartyId,
    long Amount,
    PaymentDirection? Direction = null,
    DateOnly? PaymentDate = null,
    long? PaymentMethodId = null,
    string? MethodCode = null,
    string? Reference = null,
    string? Notes = null,
    long? SaleId = null,
    long? PurchaseId = null
);

public record PaymentDto(
    long Id,
    PartyType PartyType,
    long PartyId,
    string PartyName,
    PaymentDirection Direction,
    long Amount,
    DateOnly PaymentDate,
    long? PaymentMethodId,
    string? MethodName,
    string? Reference,
    string? Notes,
    long? SaleId,
    string? SaleInvoiceNumber,
    long? PurchaseId,
    string? PurchaseBillNumber,
    long AppliedAmount,
    long UnappliedAmount,
    DateTime CreatedAt
);

/// <summary>Payment list query. Search matches party name and reference.</summary>
public record PaymentQuery(
    PartyType? PartyType = null,
    long? PartyId = null,
    PaymentDirection? Direction = null,
    DateOnly? DateFrom = null,
    DateOnly? DateTo = null,
    string? Search = null,
    int Page = 1,
    int PageSize = 20
);

/// <summary>
/// Receivable/payable position of the active business. Advances are negative
/// balances (money the business already holds / has overpaid).
/// </summary>
public record ReceivablePayableSummaryDto(
    long TotalReceivable,
    long TotalPayable,
    long CustomerAdvances,
    long SupplierAdvances,
    int ReceivableParties,
    int PayableParties
);

// --- Payment methods ---

public record PaymentMethodDto(
    long Id,
    string Name,
    string Code,
    string? Description,
    bool IsActive,
    bool IsDefault
);

public record CreatePaymentMethodRequest(
    string Name,
    string? Code = null,
    string? Description = null,
    bool IsDefault = false
);

public record UpdatePaymentMethodRequest(
    string Name,
    string? Code = null,
    string? Description = null,
    bool IsActive = true,
    bool IsDefault = false
);
