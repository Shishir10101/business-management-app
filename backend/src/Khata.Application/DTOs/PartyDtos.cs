namespace Khata.Application.DTOs;

using Khata.Application.Common;
using Khata.Domain.Enums;

// --- Customers ---

/// <summary>
/// Creates a customer. OpeningBalance is paisa; positive = the customer owes
/// the business. A non-zero opening balance immediately creates the party's
/// ledger account and its first (opening) transaction.
/// </summary>
public record CreateCustomerRequest(
    string Name,
    string? PhoneNumber = null,
    string? Email = null,
    string? AddressLine = null,
    string? City = null,
    string? District = null,
    long OpeningBalance = 0,
    string? PanNumber = null,
    long? CreditLimit = null,
    string? Notes = null,
    bool IsActive = true
);

/// <summary>
/// Updates a customer. Changing OpeningBalance appends an "adjustment"
/// ledger transaction for the difference (the ledger is never rewritten).
/// </summary>
public record UpdateCustomerRequest(
    string Name,
    string? PhoneNumber = null,
    string? Email = null,
    string? AddressLine = null,
    string? City = null,
    string? District = null,
    long OpeningBalance = 0,
    string? PanNumber = null,
    long? CreditLimit = null,
    string? Notes = null,
    bool IsActive = true
);

/// <summary>Customer with the cached current khata balance (paisa).</summary>
public record CustomerDto(
    long Id,
    string Name,
    string? PhoneNumber,
    string? Email,
    string? AddressLine,
    string? City,
    string? District,
    long OpeningBalance,
    string? PanNumber,
    long? CreditLimit,
    string? Notes,
    bool IsActive,
    long CurrentBalance,
    DateTime CreatedAt,
    DateTime UpdatedAt
);

// --- Suppliers ---

/// <summary>Creates a supplier. OpeningBalance is paisa; positive = we owe the supplier.</summary>
public record CreateSupplierRequest(
    string Name,
    string? PhoneNumber = null,
    string? Email = null,
    string? AddressLine = null,
    string? City = null,
    string? District = null,
    long OpeningBalance = 0,
    string? PanNumber = null,
    string? Notes = null,
    bool IsActive = true
);

/// <summary>Updates a supplier. Opening balance changes append an adjustment transaction.</summary>
public record UpdateSupplierRequest(
    string Name,
    string? PhoneNumber = null,
    string? Email = null,
    string? AddressLine = null,
    string? City = null,
    string? District = null,
    long OpeningBalance = 0,
    string? PanNumber = null,
    string? Notes = null,
    bool IsActive = true
);

/// <summary>Supplier with the cached current khata balance (paisa).</summary>
public record SupplierDto(
    long Id,
    string Name,
    string? PhoneNumber,
    string? Email,
    string? AddressLine,
    string? City,
    string? District,
    long OpeningBalance,
    string? PanNumber,
    string? Notes,
    bool IsActive,
    long CurrentBalance,
    DateTime CreatedAt,
    DateTime UpdatedAt
);

// --- Ledger (khata) ---

/// <summary>
/// Running summary of a party ledger. ClosingBalance = Opening + debits −
/// credits for customers (receivable) and Opening + credits − debits for
/// suppliers (payable) — always in the party's natural direction.
/// </summary>
public record LedgerSummaryDto(
    long OpeningBalance,
    long TotalDebit,
    long TotalCredit,
    long ClosingBalance
);

/// <summary>One immutable ledger entry. Amount is positive; direction is the type.</summary>
public record LedgerTransactionDto(
    long Id,
    LedgerEntryType TransactionType,
    long Amount,
    long BalanceAfter,
    DateOnly TransactionDate,
    string? ReferenceType,
    long? ReferenceId,
    string? Description,
    DateTime CreatedAt
);

/// <summary>Party ledger: summary + paged transactions (newest first).</summary>
public record PartyLedgerDto(
    LedgerSummaryDto Summary,
    IReadOnlyList<LedgerTransactionDto> Data,
    PaginationInfo Pagination
);

// --- Queries ---

/// <summary>Party list query. Search matches name and phone.</summary>
public record PartyQuery(
    string? Search = null,
    bool? IsActive = null,
    int Page = 1,
    int PageSize = 20
);
