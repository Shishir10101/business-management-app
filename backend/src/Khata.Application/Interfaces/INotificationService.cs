namespace Khata.Application.Interfaces;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Domain.Enums;

/// <summary>
/// In-app notification feed + device registrations + per-user push settings.
/// The in-app feed is the source of truth: every notification is stored even
/// when no push token exists or push is muted.
/// </summary>
public interface INotificationService
{
    Task<PagedResult<NotificationDto>> GetNotificationsAsync(NotificationQuery query, CancellationToken cancellationToken = default);
    Task<UnreadCountDto> GetUnreadCountAsync(CancellationToken cancellationToken = default);
    Task<NotificationDto> MarkReadAsync(long notificationId, CancellationToken cancellationToken = default);
    Task<int> MarkAllReadAsync(CancellationToken cancellationToken = default);
    Task DeleteAsync(long notificationId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<DeviceDto>> GetDevicesAsync(CancellationToken cancellationToken = default);
    Task<DeviceDto> RegisterDeviceAsync(RegisterDeviceRequest request, CancellationToken cancellationToken = default);
    Task UnregisterDeviceAsync(string token, CancellationToken cancellationToken = default);

    Task<NotificationSettingsDto> GetSettingsAsync(CancellationToken cancellationToken = default);
    Task<NotificationSettingsDto> UpdateSettingsAsync(UpdateNotificationSettingsRequest request, CancellationToken cancellationToken = default);

    /// <summary>
    /// Stores a notification for one user of one business and best-effort
    /// pushes it to that user's active devices (subject to their settings).
    /// Used by the reminder engine and the low-stock scan; the in-app row is
    /// written either way. <paramref name="businessId"/> is explicit because
    /// the engine runs in the background with no request context.
    /// </summary>
    Task<NotificationDto> CreateAndDispatchAsync(
        long businessId,
        long userId,
        NotificationCategory category,
        string title,
        string body,
        string? referenceType = null,
        long? referenceId = null,
        CancellationToken cancellationToken = default);
}

/// <summary>
/// Dated to-dos for the business. Due reminders raise a notification and a
/// push; recurring reminders reschedule themselves instead of completing.
/// </summary>
public interface IReminderService
{
    Task<PagedResult<ReminderDto>> GetRemindersAsync(ReminderQuery query, CancellationToken cancellationToken = default);
    Task<ReminderDto> GetReminderAsync(long reminderId, CancellationToken cancellationToken = default);
    Task<ReminderDto> CreateReminderAsync(CreateReminderRequest request, CancellationToken cancellationToken = default);
    Task<ReminderDto> UpdateReminderAsync(long reminderId, UpdateReminderRequest request, CancellationToken cancellationToken = default);
    Task CompleteReminderAsync(long reminderId, CancellationToken cancellationToken = default);
    Task DismissReminderAsync(long reminderId, CancellationToken cancellationToken = default);
    Task DeleteReminderAsync(long reminderId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Engine entry point: fires every due pending reminder (notification +
    /// push, then reschedule or complete). Returns the number fired.
    /// Idempotent — a reminder is only fired by the transition from pending.
    /// </summary>
    Task<int> ProcessDueRemindersAsync(CancellationToken cancellationToken = default);
}

/// <summary>
/// Business data backup. Export is a full JSON snapshot; restore inserts any
/// missing rows with their original ids (merge semantics — an existing id is
/// skipped, never overwritten, so money rows stay immutable).
/// </summary>
public interface IBackupService
{
    Task<BackupExportDto> ExportAsync(CancellationToken cancellationToken = default);
    Task<BackupRestoreResultDto> RestoreAsync(BackupExportDto backup, CancellationToken cancellationToken = default);
}

/// <summary>One push message destined for a user's devices.</summary>
public record NotificationMessage(
    long BusinessId,
    long UserId,
    NotificationCategory Category,
    string Title,
    string Body,
    string? ReferenceType,
    long? ReferenceId
);

/// <summary>
/// Outcome of a push dispatch. Disabled = no credentials configured (the
/// default in this repo); Sent = at least one device accepted it.
/// </summary>
public enum NotificationDispatchStatus
{
    Sent = 1,
    NoDevices = 2,
    Muted = 3,
    Failed = 4,
    Disabled = 5,
}

public record NotificationDispatchResult(
    NotificationDispatchStatus Status,
    int DeviceCount,
    string? Error = null
);

/// <summary>
/// Push delivery abstraction. The FCM implementation is in Infrastructure
/// and is disabled until server credentials are configured; everything else
/// in the system works without it.
/// </summary>
public interface INotificationDispatcher
{
    Task<NotificationDispatchResult> DispatchAsync(NotificationMessage message, CancellationToken cancellationToken = default);
}
