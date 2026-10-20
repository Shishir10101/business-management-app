namespace Khata.Infrastructure.Services;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Domain.Entities;
using Khata.Domain.Enums;
using Khata.Domain.Exceptions;
using Khata.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

/// <summary>
/// In-app notification feed, device registrations and per-user push settings.
/// Every notification is stored in the feed; push delivery is best-effort and
/// gated by the recipient's settings through <see cref="INotificationDispatcher"/>.
/// </summary>
public class NotificationService : INotificationService
{
    private readonly KhataDbContext _db;
    private readonly ICurrentUserService _currentUser;
    private readonly IDateTimeProvider _clock;
    private readonly INotificationDispatcher _dispatcher;

    public NotificationService(
        KhataDbContext db,
        ICurrentUserService currentUser,
        IDateTimeProvider clock,
        INotificationDispatcher dispatcher)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
        _dispatcher = dispatcher;
    }

    private long BusinessId =>
        _currentUser.BusinessId ?? throw new UnauthorizedException();

    private long UserId =>
        _currentUser.UserId ?? throw new UnauthorizedException();

    public async Task<PagedResult<NotificationDto>> GetNotificationsAsync(
        NotificationQuery query, CancellationToken cancellationToken = default)
    {
        var baseQuery = _db.Notifications
            .Where(n => n.BusinessId == BusinessId && n.UserId == UserId && n.DeletedAt == null);

        if (query.UnreadOnly)
            baseQuery = baseQuery.Where(n => n.ReadAt == null);
        if (query.Category is { } category)
            baseQuery = baseQuery.Where(n => n.Category == category);

        var total = await baseQuery.CountAsync(cancellationToken);

        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var rows = await baseQuery
            .OrderByDescending(n => n.CreatedAt)
            .ThenByDescending(n => n.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(n => new NotificationDto(
                n.Id, n.Title, n.Body, n.Category, n.ReferenceType, n.ReferenceId,
                n.ReadAt != null, n.ReadAt, n.CreatedAt))
            .ToListAsync(cancellationToken);

        // Timestamps are stored in UTC; convert to Nepal local for display.
        var localised = rows.Select(n => n with
        {
            CreatedAt = LocalTime.FromUtc(n.CreatedAt),
            ReadAt = n.ReadAt is { } read ? LocalTime.FromUtc(read) : null,
        }).ToList();

        return PagedResult<NotificationDto>.Create(localised, page, pageSize, total);
    }

    public async Task<UnreadCountDto> GetUnreadCountAsync(CancellationToken cancellationToken = default)
    {
        var count = await _db.Notifications
            .CountAsync(n => n.BusinessId == BusinessId && n.UserId == UserId
                && n.DeletedAt == null && n.ReadAt == null, cancellationToken);
        return new UnreadCountDto(count);
    }

    public async Task<NotificationDto> MarkReadAsync(long notificationId, CancellationToken cancellationToken = default)
    {
        var notification = await LoadAsync(notificationId, cancellationToken);
        if (notification.ReadAt == null)
            notification.ReadAt = _clock.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);
        return ToDto(notification);
    }

    public async Task<int> MarkAllReadAsync(CancellationToken cancellationToken = default)
    {
        var unread = await _db.Notifications
            .Where(n => n.BusinessId == BusinessId && n.UserId == UserId
                && n.DeletedAt == null && n.ReadAt == null)
            .ToListAsync(cancellationToken);

        var now = _clock.UtcNow;
        foreach (var n in unread)
            n.ReadAt = now;

        await _db.SaveChangesAsync(cancellationToken);
        return unread.Count;
    }

    public async Task DeleteAsync(long notificationId, CancellationToken cancellationToken = default)
    {
        var notification = await LoadAsync(notificationId, cancellationToken);
        _db.Notifications.Remove(notification); // soft delete
        await _db.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<DeviceDto>> GetDevicesAsync(CancellationToken cancellationToken = default)
    {
        return await _db.DeviceRegistrations
            .Where(d => d.BusinessId == BusinessId && d.UserId == UserId && d.IsActive)
            .OrderByDescending(d => d.LastSeenAt)
            .Select(d => new DeviceDto(d.Id, d.Token, d.Platform, d.LastSeenAt, d.IsActive))
            .ToListAsync(cancellationToken);
    }

    public async Task<DeviceDto> RegisterDeviceAsync(
        RegisterDeviceRequest request, CancellationToken cancellationToken = default)
    {
        var now = _clock.UtcNow;

        // The token is globally unique: one physical device maps to one row.
        // Re-registering refreshes the row (the user may have logged out and
        // back in, or switched business) instead of creating a duplicate.
        var existing = await _db.DeviceRegistrations
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(d => d.Token == request.Token, cancellationToken);

        if (existing is not null)
        {
            existing.BusinessId = BusinessId;
            existing.UserId = UserId;
            existing.Platform = request.Platform;
            existing.LastSeenAt = now;
            existing.IsActive = true;
            await _db.SaveChangesAsync(cancellationToken);
            return new DeviceDto(existing.Id, existing.Token, existing.Platform, now, true);
        }

        var device = new DeviceRegistration
        {
            BusinessId = BusinessId,
            UserId = UserId,
            Token = request.Token.Trim(),
            Platform = request.Platform,
            LastSeenAt = now,
            IsActive = true,
        };

        _db.DeviceRegistrations.Add(device);
        await _db.SaveChangesAsync(cancellationToken);

        return new DeviceDto(device.Id, device.Token, device.Platform, now, true);
    }

    public async Task UnregisterDeviceAsync(string token, CancellationToken cancellationToken = default)
    {
        var device = await _db.DeviceRegistrations
            .FirstOrDefaultAsync(d => d.BusinessId == BusinessId && d.UserId == UserId
                && d.Token == token, cancellationToken)
            ?? throw new NotFoundException("Device", token);

        device.IsActive = false;
        await _db.SaveChangesAsync(cancellationToken);
    }

    public async Task<NotificationSettingsDto> GetSettingsAsync(CancellationToken cancellationToken = default)
    {
        var settings = await GetOrCreateSettingsAsync(BusinessId, UserId, cancellationToken);
        return ToDto(settings);
    }

    public async Task<NotificationSettingsDto> UpdateSettingsAsync(
        UpdateNotificationSettingsRequest request, CancellationToken cancellationToken = default)
    {
        var settings = await GetOrCreateSettingsAsync(BusinessId, UserId, cancellationToken);

        settings.PushEnabled = request.PushEnabled;
        settings.ReminderEnabled = request.ReminderEnabled;
        settings.LowStockEnabled = request.LowStockEnabled;
        settings.PaymentDueEnabled = request.PaymentDueEnabled;
        settings.BackupEnabled = request.BackupEnabled;
        settings.SystemEnabled = request.SystemEnabled;

        await _db.SaveChangesAsync(cancellationToken);
        return ToDto(settings);
    }

    public async Task<NotificationDto> CreateAndDispatchAsync(
        long businessId,
        long userId,
        NotificationCategory category,
        string title,
        string body,
        string? referenceType = null,
        long? referenceId = null,
        CancellationToken cancellationToken = default)
    {
        // The in-app row is unconditional: the feed is the source of truth and
        // a muted user still sees the notification next time they open the app.
        var notification = new Notification
        {
            BusinessId = businessId,
            UserId = userId,
            Category = category,
            Title = title.Trim(),
            Body = body.Trim(),
            ReferenceType = referenceType,
            ReferenceId = referenceId,
        };

        _db.Notifications.Add(notification);
        await _db.SaveChangesAsync(cancellationToken);

        // Push is best-effort: a failure must never break the caller (the
        // reminder engine runs in the background and cannot afford to throw).
        try
        {
            var settings = await GetOrCreateSettingsAsync(businessId, userId, cancellationToken);
            if (settings is { PushEnabled: true } && settings.IsCategoryEnabled(category))
            {
                await _dispatcher.DispatchAsync(
                    new NotificationMessage(businessId, userId, category, notification.Title,
                        notification.Body, referenceType, referenceId),
                    cancellationToken);
            }
        }
        catch
        {
            // Swallowed by design — see the comment above.
        }

        return ToDto(notification);
    }

    private async Task<Notification> LoadAsync(long notificationId, CancellationToken cancellationToken)
        => await _db.Notifications
            .FirstOrDefaultAsync(n => n.Id == notificationId && n.DeletedAt == null
                && n.BusinessId == BusinessId && n.UserId == UserId, cancellationToken)
            ?? throw new NotFoundException("Notification", notificationId);

    /// <summary>
    /// Loads the user's settings, creating the default row on first use
    /// (everything enabled). Keeps the read path free of null handling.
    /// Queries bypass the tenant filter so the background engine (no request
    /// context → FilterBusinessId 0) can resolve settings for any business.
    /// </summary>
    private async Task<NotificationSettings> GetOrCreateSettingsAsync(
        long businessId, long userId, CancellationToken cancellationToken)
    {
        var settings = await _db.NotificationSettings
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.BusinessId == businessId,
                cancellationToken);
        if (settings is not null)
            return settings;

        settings = new NotificationSettings
        {
            UserId = userId,
            BusinessId = businessId,
            PushEnabled = true,
        };

        _db.NotificationSettings.Add(settings);
        await _db.SaveChangesAsync(cancellationToken);
        return settings;
    }

    private async Task<NotificationSettings?> LoadSettingsForAsync(long userId, CancellationToken cancellationToken)
        => await _db.NotificationSettings
            .FirstOrDefaultAsync(s => s.UserId == userId && s.BusinessId == BusinessId,
                cancellationToken);

    private static NotificationDto ToDto(Notification n) => new(
        n.Id, n.Title, n.Body, n.Category, n.ReferenceType, n.ReferenceId,
        n.ReadAt != null,
        n.ReadAt is { } read ? LocalTime.FromUtc(read) : null,
        LocalTime.FromUtc(n.CreatedAt));

    private static NotificationSettingsDto ToDto(NotificationSettings s) => new(
        s.PushEnabled, s.ReminderEnabled, s.LowStockEnabled, s.PaymentDueEnabled,
        s.BackupEnabled, s.SystemEnabled);
}
