namespace Khata.Domain.Enums;

public enum SaleType
{
    Cash = 1,
    Credit = 2,
    Partial = 3
}

public enum PaymentStatus
{
    Paid = 1,
    Partial = 2,
    Unpaid = 3
}

public enum PurchaseType
{
    Cash = 1,
    Credit = 2,
    Partial = 3
}

public enum StockMovementType
{
    Opening = 1,
    Purchase = 2,
    Sale = 3,
    ReturnIn = 4,
    ReturnOut = 5,
    AdjustmentIn = 6,
    AdjustmentOut = 7
}

public enum LedgerEntryType
{
    Debit = 1,
    Credit = 2
}

public enum PartyType
{
    Customer = 1,
    Supplier = 2
}

/// <summary>
/// Money direction for a payment. In = received from a customer (settles a
/// receivable); Out = paid to a supplier (settles a payable).
/// </summary>
public enum PaymentDirection
{
    In = 1,
    Out = 2
}

public enum InvoiceStatus
{
    Draft = 1,
    Sent = 2,
    Paid = 3,
    Partial = 4,
    Overdue = 5
}

public enum QuotationStatus
{
    Draft = 1,
    Sent = 2,
    Accepted = 3,
    Rejected = 4,
    Expired = 5
}

public enum SyncOperationType
{
    Create = 1,
    Update = 2,
    Delete = 3
}

public enum SyncStatus
{
    Pending = 1,
    Syncing = 2,
    Synced = 3,
    Failed = 4,
    Conflict = 5
}

/// <summary>
/// What a notification is about. Doubles as the per-user settings switch:
/// each category can be muted for push delivery independently.
/// </summary>
public enum NotificationCategory
{
    Reminder = 1,
    LowStock = 2,
    PaymentDue = 3,
    Backup = 4,
    System = 5
}

public enum ReminderStatus
{
    Pending = 1,
    Done = 2,
    Dismissed = 3
}

/// <summary>Recurrence of a reminder. None = one-shot (fires once, then Done).</summary>
public enum ReminderRepeat
{
    None = 1,
    Daily = 2,
    Weekly = 3,
    Monthly = 4,
    Yearly = 5
}

public enum DevicePlatform
{
    Android = 1,
    Ios = 2,
    Web = 3
}

/// <summary>Lifecycle of a support ticket. Open → InProgress → Resolved → Closed.</summary>
public enum SupportTicketStatus
{
    Open = 1,
    InProgress = 2,
    Resolved = 3,
    Closed = 4
}

/// <summary>Urgency of a support ticket.</summary>
public enum SupportTicketPriority
{
    Low = 1,
    Normal = 2,
    High = 3,
    Urgent = 4
}
