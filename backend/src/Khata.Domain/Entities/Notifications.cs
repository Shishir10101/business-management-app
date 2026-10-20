namespace Khata.Domain.Entities;

using Khata.Domain.Common;
using Khata.Domain.Enums;

/// <summary>
/// An in-app notification for one user of a business. The in-app feed is the
/// primary channel — it is always written. Push delivery (FCM) is best-effort
/// and gated by the recipient's <see cref="NotificationSettings"/>.
/// </summary>
public class Notification : SoftDeletableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    /// <summary>Recipient. Notifications are personal, not business-wide.</summary>
    public long UserId { get; set; }

    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public NotificationCategory Category { get; set; }

    /// <summary>Optional link target, e.g. "product" / "reminder" / "sale".</summary>
    public string? ReferenceType { get; set; }
    public long? ReferenceId { get; set; }

    /// <summary>Null while unread.</summary>
    public DateTime? ReadAt { get; set; }
}

/// <summary>
/// A registered push token (FCM). One user may have several devices; the token
/// itself is unique so re-registering the same device refreshes it instead of
/// duplicating it.
/// </summary>
public class DeviceRegistration : AuditableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public long UserId { get; set; }

    /// <summary>FCM registration token. Globally unique.</summary>
    public string Token { get; set; } = string.Empty;

    public DevicePlatform Platform { get; set; }

    public DateTime LastSeenAt { get; set; }
    public bool IsActive { get; set; } = true;
}

/// <summary>
/// Per-user notification preferences (one row per user per business). The
/// in-app feed always records every notification; these switches gate push
/// delivery per category.
/// </summary>
public class NotificationSettings : AuditableEntity, IBusinessEntity
{
    /// <summary>Recipient these settings belong to.</summary>
    public long UserId { get; set; }

    /// <summary>Business context (settings follow the active business).</summary>
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    /// <summary>Master switch: false mutes every push, whatever the categories say.</summary>
    public bool PushEnabled { get; set; } = true;

    public bool ReminderEnabled { get; set; } = true;
    public bool LowStockEnabled { get; set; } = true;
    public bool PaymentDueEnabled { get; set; } = true;
    public bool BackupEnabled { get; set; } = true;
    public bool SystemEnabled { get; set; } = true;

    public bool IsCategoryEnabled(NotificationCategory category) => category switch
    {
        NotificationCategory.Reminder => ReminderEnabled,
        NotificationCategory.LowStock => LowStockEnabled,
        NotificationCategory.PaymentDue => PaymentDueEnabled,
        NotificationCategory.Backup => BackupEnabled,
        NotificationCategory.System => SystemEnabled,
        _ => false,
    };
}

/// <summary>
/// A dated to-do for the business: "call Ram about the pending bill", "pay
/// rent", etc. A due reminder raises a <see cref="Notification"/> and a push;
/// recurring reminders reschedule themselves instead of completing.
/// </summary>
public class Reminder : SoftDeletableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public string Title { get; set; } = string.Empty;
    public string? Notes { get; set; }

    /// <summary>When it should fire (UTC).</summary>
    public DateTime DueAt { get; set; }

    public ReminderStatus Status { get; set; } = ReminderStatus.Pending;
    public ReminderRepeat Repeat { get; set; } = ReminderRepeat.None;

    /// <summary>Optional context, e.g. "customer" + customer id for a payment call.</summary>
    public string? RelatedEntityType { get; set; }
    public long? RelatedEntityId { get; set; }

    /// <summary>Who the reminder is for (null = whoever processes it).</summary>
    public long? UserId { get; set; }

    public DateTime? CompletedAt { get; set; }
}
