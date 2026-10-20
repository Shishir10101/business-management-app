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
/// Dated to-dos for the business. Firing a reminder writes an in-app
/// notification (and best-effort push) for the assignee, then either
/// completes it (one-shot) or advances it to the next occurrence.
/// </summary>
public class ReminderService : IReminderService
{
    private readonly KhataDbContext _db;
    private readonly ICurrentUserService _currentUser;
    private readonly IDateTimeProvider _clock;
    private readonly INotificationService _notifications;

    public ReminderService(
        KhataDbContext db,
        ICurrentUserService currentUser,
        IDateTimeProvider clock,
        INotificationService notifications)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
        _notifications = notifications;
    }

    private long BusinessId =>
        _currentUser.BusinessId ?? throw new UnauthorizedException();

    public async Task<PagedResult<ReminderDto>> GetRemindersAsync(
        ReminderQuery query, CancellationToken cancellationToken = default)
    {
        var baseQuery = _db.Reminders
            .Where(r => r.BusinessId == BusinessId && r.DeletedAt == null);

        if (query.Status is { } status)
            baseQuery = baseQuery.Where(r => r.Status == status);
        if (query.DueBefore is { } dueBefore)
            baseQuery = baseQuery.Where(r => r.DueAt <= dueBefore);

        var total = await baseQuery.CountAsync(cancellationToken);

        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var rows = await baseQuery
            .OrderBy(r => r.DueAt)
            .ThenBy(r => r.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(r => ToDto(r))
            .ToListAsync(cancellationToken);

        return PagedResult<ReminderDto>.Create(rows, page, pageSize, total);
    }

    public async Task<ReminderDto> GetReminderAsync(long reminderId, CancellationToken cancellationToken = default)
    {
        var reminder = await LoadAsync(reminderId, cancellationToken);
        return ToDto(reminder);
    }

    public async Task<ReminderDto> CreateReminderAsync(
        CreateReminderRequest request, CancellationToken cancellationToken = default)
    {
        var reminder = new Reminder
        {
            BusinessId = BusinessId,
            Title = request.Title.Trim(),
            Notes = request.Notes,
            // Normalised to UTC at the boundary: a client that sends a bare
            // local wall-clock time (no offset) is read as Nepal local, so a
            // reminder that looks overdue on the phone actually fires.
            DueAt = LocalTime.ToUtc(request.DueAt),
            Repeat = request.Repeat,
            RelatedEntityType = request.RelatedEntityType,
            RelatedEntityId = request.RelatedEntityId,
            UserId = _currentUser.UserId,
            Status = ReminderStatus.Pending,
        };

        _db.Reminders.Add(reminder);
        await _db.SaveChangesAsync(cancellationToken);

        return ToDto(reminder);
    }

    public async Task<ReminderDto> UpdateReminderAsync(
        long reminderId, UpdateReminderRequest request, CancellationToken cancellationToken = default)
    {
        var reminder = await LoadAsync(reminderId, cancellationToken);

        reminder.Title = request.Title.Trim();
        reminder.Notes = request.Notes;
        reminder.DueAt = LocalTime.ToUtc(request.DueAt);
        reminder.Repeat = request.Repeat;

        // Rescheduling a completed reminder makes it pending again — otherwise
        // "move it to tomorrow" on a done item would silently never fire.
        if (reminder.Status != ReminderStatus.Pending)
        {
            reminder.Status = ReminderStatus.Pending;
            reminder.CompletedAt = null;
        }

        await _db.SaveChangesAsync(cancellationToken);
        return ToDto(reminder);
    }

    public async Task CompleteReminderAsync(long reminderId, CancellationToken cancellationToken = default)
    {
        var reminder = await LoadAsync(reminderId, cancellationToken);
        reminder.Status = ReminderStatus.Done;
        reminder.CompletedAt = _clock.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);
    }

    public async Task DismissReminderAsync(long reminderId, CancellationToken cancellationToken = default)
    {
        var reminder = await LoadAsync(reminderId, cancellationToken);
        reminder.Status = ReminderStatus.Dismissed;
        reminder.CompletedAt = _clock.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);
    }

    public async Task DeleteReminderAsync(long reminderId, CancellationToken cancellationToken = default)
    {
        var reminder = await LoadAsync(reminderId, cancellationToken);
        _db.Reminders.Remove(reminder); // soft delete
        await _db.SaveChangesAsync(cancellationToken);
    }

    public async Task<int> ProcessDueRemindersAsync(CancellationToken cancellationToken = default)
    {
        var now = _clock.UtcNow;

        // Business-agnostic: the engine runs in the background without an
        // HttpContext, so the tenant filter would hide every row. The due
        // window and the status guard make this safe to run repeatedly.
        var due = await _db.Reminders
            .IgnoreQueryFilters()
            .Where(r => r.Status == ReminderStatus.Pending && r.DeletedAt == null && r.DueAt <= now)
            .OrderBy(r => r.DueAt)
            .Take(200) // bounded batch per tick; the next tick continues
            .ToListAsync(cancellationToken);

        var fired = 0;
        foreach (var reminder in due)
        {
            var recipientId = reminder.UserId ?? await ResolveOwnerUserIdAsync(reminder.BusinessId, cancellationToken);

            await _notifications.CreateAndDispatchAsync(
                reminder.BusinessId,
                recipientId,
                NotificationCategory.Reminder,
                reminder.Title,
                reminder.Notes ?? "Reminder is due.",
                referenceType: "reminder",
                referenceId: reminder.Id,
                cancellationToken: cancellationToken);

            if (reminder.Repeat == ReminderRepeat.None)
            {
                reminder.Status = ReminderStatus.Done;
                reminder.CompletedAt = now;
            }
            else
            {
                reminder.DueAt = NextOccurrence(reminder.DueAt, reminder.Repeat, now);
            }

            fired++;
        }

        await _db.SaveChangesAsync(cancellationToken);
        return fired;
    }

    /// <summary>
    /// Advances a recurring past-due reminder to its next future occurrence.
    /// If it fell far behind (app offline for days), it jumps to the first
    /// occurrence after <paramref name="now"/> instead of firing in a burst.
    /// </summary>
    private static DateTime NextOccurrence(DateTime dueAt, ReminderRepeat repeat, DateTime now)
    {
        var next = dueAt;
        var guard = 0;
        do
        {
            next = repeat switch
            {
                ReminderRepeat.Daily => next.AddDays(1),
                ReminderRepeat.Weekly => next.AddDays(7),
                ReminderRepeat.Monthly => next.AddMonths(1),
                ReminderRepeat.Yearly => next.AddYears(1),
                _ => next,
            };
        }
        while (next <= now && ++guard < 1000);

        return next;
    }

    private async Task<long> ResolveOwnerUserIdAsync(long businessId, CancellationToken cancellationToken)
    {
        var owner = await _db.BusinessMembers
            .IgnoreQueryFilters()
            .Where(m => m.BusinessId == businessId && m.IsActive)
            .Join(_db.Roles, m => m.RoleId, r => r.Id, (m, r) => new { m.UserId, r.Name })
            .Where(x => x.Name == "Owner")
            .Select(x => (long?)x.UserId)
            .FirstOrDefaultAsync(cancellationToken);

        return owner ?? throw new InvalidOperationException(
            $"Business {businessId} has no Owner to receive the reminder notification.");
    }

    private async Task<Reminder> LoadAsync(long reminderId, CancellationToken cancellationToken)
        => await _db.Reminders
            .FirstOrDefaultAsync(r => r.Id == reminderId && r.DeletedAt == null
                && r.BusinessId == BusinessId, cancellationToken)
            ?? throw new NotFoundException("Reminder", reminderId);

    private static ReminderDto ToDto(Reminder r) => new(
        r.Id, r.Title, r.Notes,
        // Stored UTC → Nepal local for the client, so the due time reads the
        // same as the wall-clock value the user picked.
        LocalTime.FromUtc(r.DueAt),
        r.Status, r.Repeat, r.RelatedEntityType, r.RelatedEntityId,
        r.CompletedAt is { } completed ? LocalTime.FromUtc(completed) : null,
        LocalTime.FromUtc(r.CreatedAt));
}
