namespace Khata.Domain.Entities;

using Khata.Domain.Common;
using Khata.Domain.Enums;

/// <summary>
/// How money was received or paid (Cash, Bank Transfer, eSewa, Khalti…).
/// Business-scoped and configurable; <see cref="Code"/> selects the
/// <c>IPaymentProvider</c> that processes payments made with it.
/// </summary>
public class PaymentMethod : SoftDeletableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public string Name { get; set; } = string.Empty;

    /// <summary>Provider code: 'cash' | 'bank' | 'esewa' | 'khalti' | 'cheque'.</summary>
    public string Code { get; set; } = "cash";

    public string? Description { get; set; }
    public bool IsActive { get; set; } = true;

    /// <summary>Pre-selected method in the payment form.</summary>
    public bool IsDefault { get; set; }
}

/// <summary>
/// An immutable record of money received from a customer or paid to a supplier.
/// Append-only (enforced by the DbContext) — a mistake is corrected by
/// recording the opposite payment, never by editing history.
/// </summary>
/// <remarks>
/// Every payment writes one khata ledger entry for its full amount: the
/// party's natural balance moves by −Amount (a customer Credit or a supplier
/// Debit). When a sale/purchase is referenced, the applied portion also
/// updates that document's Paid/Due and payment status; any excess stays on
/// the account as an advance (credit balance).
/// </remarks>
public class Payment : ImmutableEntity, IBusinessEntity, IImmutable
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public PartyType PartyType { get; set; }
    public long PartyId { get; set; }

    public PaymentDirection Direction { get; set; }

    /// <summary>Amount in paisa (always positive).</summary>
    public long Amount { get; set; }

    public DateOnly PaymentDate { get; set; }

    public long? PaymentMethodId { get; set; }
    public PaymentMethod? PaymentMethod { get; set; }

    /// <summary>Snapshot of the method name (survives method renames/deletes).</summary>
    public string? MethodName { get; set; }

    /// <summary>Receipt number / external transaction id.</summary>
    public string? Reference { get; set; }

    public string? Notes { get; set; }

    /// <summary>Sale this payment settles (customers only).</summary>
    public long? SaleId { get; set; }
    public Sale? Sale { get; set; }

    /// <summary>Purchase this payment settles (suppliers only).</summary>
    public long? PurchaseId { get; set; }
    public Purchase? Purchase { get; set; }

    /// <summary>Portion of <see cref="Amount"/> applied to the linked document.</summary>
    public long AppliedAmount { get; set; }

    /// <summary>Portion left as an advance/credit on the party's account.</summary>
    public long UnappliedAmount { get; set; }

    /// <summary>
    /// Bank account this payment went through, when it was a bank transfer.
    /// Null for cash and for payments recorded before accounts were tracked —
    /// the field is optional by design so existing rows stay valid.
    /// </summary>
    public long? BankAccountId { get; set; }
    public BusinessBankAccount? BankAccount { get; set; }
}
