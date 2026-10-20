namespace Khata.Application.DTOs;

using Khata.Domain.Enums;

// ==============================================================
// Notifications (in-app feed)
// ==============================================================

/// <summary>One notification row. <see cref="IsRead"/> is derived from ReadAt.</summary>
public record NotificationDto(
    long Id,
    string Title,
    string Body,
    NotificationCategory Category,
    string? ReferenceType,
    long? ReferenceId,
    bool IsRead,
    DateTime? ReadAt,
    DateTime CreatedAt
);

/// <summary>Filter for the notification feed.</summary>
public class NotificationQuery
{
    public bool UnreadOnly { get; set; }
    public NotificationCategory? Category { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 50;
}

public record UnreadCountDto(int Count);

// ==============================================================
// Devices (FCM registration tokens)
// ==============================================================

public record DeviceDto(
    long Id,
    string Token,
    DevicePlatform Platform,
    DateTime LastSeenAt,
    bool IsActive
);

public record RegisterDeviceRequest(
    string Token,
    DevicePlatform Platform
);

// ==============================================================
// Settings (per-user push preferences)
// ==============================================================

public record NotificationSettingsDto(
    bool PushEnabled,
    bool ReminderEnabled,
    bool LowStockEnabled,
    bool PaymentDueEnabled,
    bool BackupEnabled,
    bool SystemEnabled
);

public record UpdateNotificationSettingsRequest(
    bool PushEnabled,
    bool ReminderEnabled,
    bool LowStockEnabled,
    bool PaymentDueEnabled,
    bool BackupEnabled,
    bool SystemEnabled
);

// ==============================================================
// Reminders
// ==============================================================

public record ReminderDto(
    long Id,
    string Title,
    string? Notes,
    DateTime DueAt,
    ReminderStatus Status,
    ReminderRepeat Repeat,
    string? RelatedEntityType,
    long? RelatedEntityId,
    DateTime? CompletedAt,
    DateTime CreatedAt
);

/// <summary>Filter for the reminder list.</summary>
public class ReminderQuery
{
    public ReminderStatus? Status { get; set; }
    /// <summary>Only reminders due on or before this instant (default: now).</summary>
    public DateTime? DueBefore { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 50;
}

public record CreateReminderRequest(
    string Title,
    string? Notes,
    DateTime DueAt,
    ReminderRepeat Repeat,
    string? RelatedEntityType,
    long? RelatedEntityId
);

public record UpdateReminderRequest(
    string Title,
    string? Notes,
    DateTime DueAt,
    ReminderRepeat Repeat
);

// ==============================================================
// Backup (export / restore) — see BackupDtos.cs for the payload
// ==============================================================

/// <summary>Per-table insert/skip counts from a restore.</summary>
public record BackupRestoreResultDto(
    long BusinessId,
    int ProductsInserted,
    int ProductsSkipped,
    int CustomersInserted,
    int CustomersSkipped,
    int SuppliersInserted,
    int SuppliersSkipped,
    int SalesInserted,
    int SalesSkipped,
    int PurchasesInserted,
    int PurchasesSkipped,
    int ExpensesInserted,
    int ExpensesSkipped,
    int IncomesInserted,
    int IncomesSkipped,
    int PaymentsInserted,
    int PaymentsSkipped,
    int InvoicesInserted,
    int InvoicesSkipped,
    int QuotationsInserted,
    int QuotationsSkipped,
    int PaymentMethodsInserted = 0,
    int PaymentMethodsMatched = 0,
    int UnitsInserted = 0,
    int UnitsMatched = 0
);
