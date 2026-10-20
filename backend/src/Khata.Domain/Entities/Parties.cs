namespace Khata.Domain.Entities;

using Khata.Domain.Common;
using Khata.Domain.Enums;

/// <summary>
/// A customer (party that buys from the business). Opening balance in paisa;
/// positive = the customer owes the business (receivable).
/// </summary>
public class Customer : SoftDeletableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public string Name { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? Email { get; set; }
    public string? AddressLine { get; set; }
    public string? City { get; set; }
    public string? District { get; set; }

    /// <summary>Opening balance in paisa. Positive = customer owes us.</summary>
    public long OpeningBalance { get; set; }

    public string? PanNumber { get; set; }

    /// <summary>Max allowed credit in paisa (null = unlimited).</summary>
    public long? CreditLimit { get; set; }

    public string? Notes { get; set; }
    public bool IsActive { get; set; } = true;
}

/// <summary>
/// A supplier (party the business buys from). Opening balance in paisa;
/// positive = we owe the supplier (payable).
/// </summary>
public class Supplier : SoftDeletableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public string Name { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? Email { get; set; }
    public string? AddressLine { get; set; }
    public string? City { get; set; }
    public string? District { get; set; }

    /// <summary>Opening balance in paisa. Positive = we owe the supplier.</summary>
    public long OpeningBalance { get; set; }

    public string? PanNumber { get; set; }
    public string? Notes { get; set; }
    public bool IsActive { get; set; } = true;
}

/// <summary>
/// Running khata account for a customer or supplier. Party reference is
/// polymorphic (PartyType + PartyId) — one ledger mechanism serves both.
/// CurrentBalance is cached from the (immutable) transactions and updated
/// within the same transaction as each of them.
/// </summary>
public class LedgerAccount : AuditableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public PartyType PartyType { get; set; }
    public long PartyId { get; set; }

    /// <summary>Opening balance in paisa, in the party's natural direction.</summary>
    public long OpeningBalance { get; set; }

    /// <summary>
    /// Current balance in paisa, natural direction: customer → +receivable,
    /// supplier → +payable. Equals OpeningBalance + Σ(debit − credit) for
    /// customers and OpeningBalance + Σ(credit − debit) for suppliers.
    /// </summary>
    public long CurrentBalance { get; set; }

    public ICollection<LedgerTransaction> Transactions { get; set; } = [];
}

/// <summary>
/// Immutable record of every debit/credit movement on a ledger account.
/// Never updated or deleted — the DbContext enforces this for
/// <see cref="IImmutable"/> entities.
/// </summary>
/// <remarks>
/// <see cref="Amount"/> is always positive; direction comes from
/// <see cref="TransactionType"/>. For a customer, debit = they owe more
/// (sale), credit = they paid. For a supplier, debit = we paid, credit = we
/// owe more (purchase).
/// </remarks>
public class LedgerTransaction : ImmutableEntity, IBusinessEntity, IImmutable
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public long LedgerAccountId { get; set; }
    public LedgerAccount LedgerAccount { get; set; } = null!;

    public LedgerEntryType TransactionType { get; set; }

    /// <summary>Absolute amount in paisa.</summary>
    public long Amount { get; set; }

    /// <summary>Account balance (natural direction) after this transaction.</summary>
    public long BalanceAfter { get; set; }

    public DateOnly TransactionDate { get; set; }

    /// <summary>'sale' | 'purchase' | 'payment' | 'adjustment' | 'opening'.</summary>
    public string? ReferenceType { get; set; }
    public long? ReferenceId { get; set; }
    public string? Description { get; set; }
}
