namespace Khata.Infrastructure.Services;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Domain.Exceptions;
using Khata.Domain.Entities;
using Khata.Domain.Enums;
using Khata.Infrastructure.Data;
using Khata.Infrastructure.Identity;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

/// <summary>
/// Platform administration: cross-tenant user/business management, stats,
/// audit log, feature flags, support tickets.
///
/// EVERY query here runs IgnoreQueryFilters (or on platform-scoped tables
/// that carry no filter): the admin console deliberately sees all tenants.
/// The controller still gates each endpoint behind the admin.access policy,
/// so this breadth is authorized, not accidental.
/// </summary>
public class AdminService : IAdminService
{
    private readonly KhataDbContext _db;
    private readonly ICurrentUserService _currentUser;
    private readonly IHttpContextAccessor _httpContext;
    private readonly IDateTimeProvider _clock;

    public AdminService(
        KhataDbContext db,
        ICurrentUserService currentUser,
        IHttpContextAccessor httpContext,
        IDateTimeProvider clock)
    {
        _db = db;
        _currentUser = currentUser;
        _httpContext = httpContext;
        _clock = clock;
    }

    private long ActorUserId =>
        _currentUser.UserId ?? throw new UnauthorizedException();

    // ---------------------------------------------------------------
    // Statistics
    // ---------------------------------------------------------------

    public async Task<PlatformStatsDto> GetStatsAsync(CancellationToken cancellationToken = default)
    {
        var totalUsers = await _db.Users.IgnoreQueryFilters().CountAsync(cancellationToken);
        var activeUsers = await _db.Users.IgnoreQueryFilters()
            .CountAsync(u => u.IsActive, cancellationToken);

        var totalBusinesses = await _db.Businesses.IgnoreQueryFilters()
            .CountAsync(cancellationToken);
        var activeBusinesses = await _db.Businesses.IgnoreQueryFilters()
            .CountAsync(b => b.IsActive, cancellationToken);

        var sales = await _db.Sales.IgnoreQueryFilters().ToListAsync(cancellationToken);
        var payments = await _db.Payments.IgnoreQueryFilters().ToListAsync(cancellationToken);

        var openTickets = await _db.SupportTickets
            .CountAsync(t => t.Status == SupportTicketStatus.Open
                || t.Status == SupportTicketStatus.InProgress, cancellationToken);
        var totalTickets = await _db.SupportTickets.CountAsync(cancellationToken);

        return new PlatformStatsDto(
            totalUsers,
            activeUsers,
            totalBusinesses,
            activeBusinesses,
            sales.Count,
            sales.Sum(s => s.TotalAmount),
            payments.Count,
            payments.Sum(p => p.Amount),
            openTickets,
            totalTickets);
    }

    // ---------------------------------------------------------------
    // Users
    // ---------------------------------------------------------------

    public async Task<PagedResult<AdminUserDto>> GetUsersAsync(
        AdminUserQuery query, CancellationToken cancellationToken = default)
    {
        var users = _db.Users.IgnoreQueryFilters().AsQueryable();

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var term = query.Search.Trim();
            users = users.Where(u =>
                EF.Functions.Like(u.Email!, $"%{term}%") ||
                EF.Functions.Like(u.FullName, $"%{term}%"));
        }
        if (query.IsActive is { } active)
            users = users.Where(u => u.IsActive == active);

        var total = await users.CountAsync(cancellationToken);

        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var rows = await users
            .OrderByDescending(u => u.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(u => new
            {
                u.Id,
                u.Email,
                u.FullName,
                u.IsActive,
                u.Locale,
                u.CreatedAt,
                BusinessCount = _db.BusinessMembers.IgnoreQueryFilters()
                    .Count(bm => bm.UserId == u.Id && bm.DeletedAt == null && bm.IsActive),
            })
            .ToListAsync(cancellationToken);

        var data = rows.Select(r => new AdminUserDto(
            r.Id, r.Email ?? string.Empty, r.FullName, r.IsActive, r.Locale, r.CreatedAt,
            r.BusinessCount)).ToList();

        return PagedResult<AdminUserDto>.Create(data, page, pageSize, total);
    }

    public async Task<AdminUserDto> SetUserActiveAsync(
        long userId, bool isActive, string? reason, CancellationToken cancellationToken = default)
    {
        var user = await _db.Users.IgnoreQueryFilters()
            .FirstOrDefaultAsync(u => u.Id == userId, cancellationToken)
            ?? throw new NotFoundException("User", userId);

        user.IsActive = isActive;
        user.UpdatedAt = _clock.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);

        await WriteAuditAsync(
            isActive ? "user.activate" : "user.suspend",
            "User", userId,
            reason ?? (isActive ? "Activated by admin" : "Suspended by admin"),
            cancellationToken);

        var businessCount = await _db.BusinessMembers.IgnoreQueryFilters()
            .CountAsync(bm => bm.UserId == userId && bm.DeletedAt == null && bm.IsActive,
                cancellationToken);

        return new AdminUserDto(
            user.Id, user.Email ?? string.Empty, user.FullName, user.IsActive,
            user.Locale, user.CreatedAt, businessCount);
    }

    // ---------------------------------------------------------------
    // Businesses
    // ---------------------------------------------------------------

    public async Task<PagedResult<AdminBusinessDto>> GetBusinessesAsync(
        string? search, bool? isActive, int page, int pageSize,
        CancellationToken cancellationToken = default)
    {
        var businesses = _db.Businesses.IgnoreQueryFilters().AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim();
            businesses = businesses.Where(b => EF.Functions.Like(b.Name, $"%{term}%"));
        }
        if (isActive is { } active)
            businesses = businesses.Where(b => b.IsActive == active);

        var total = await businesses.CountAsync(cancellationToken);

        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var rows = await businesses
            .OrderByDescending(b => b.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(b => new
            {
                b.Id,
                b.Name,
                b.Type,
                b.Province,
                b.IsActive,
                b.CreatedAt,
                MemberCount = _db.BusinessMembers.IgnoreQueryFilters()
                    .Count(bm => bm.BusinessId == b.Id && bm.DeletedAt == null && bm.IsActive),
                SaleCount = _db.Sales.IgnoreQueryFilters()
                    .Count(s => s.BusinessId == b.Id && s.DeletedAt == null),
            })
            .ToListAsync(cancellationToken);

        var data = rows.Select(r => new AdminBusinessDto(
            r.Id, r.Name, r.Type, r.Province, r.IsActive, r.CreatedAt,
            r.MemberCount, r.SaleCount)).ToList();

        return PagedResult<AdminBusinessDto>.Create(data, page, pageSize, total);
    }

    public async Task<AdminBusinessDto> SetBusinessActiveAsync(
        long businessId, bool isActive, string? reason, CancellationToken cancellationToken = default)
    {
        var business = await _db.Businesses.IgnoreQueryFilters()
            .FirstOrDefaultAsync(b => b.Id == businessId, cancellationToken)
            ?? throw new NotFoundException("Business", businessId);

        business.IsActive = isActive;
        business.UpdatedAt = _clock.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);

        await WriteAuditAsync(
            isActive ? "business.activate" : "business.suspend",
            "Business", businessId,
            reason ?? (isActive ? "Activated by admin" : "Suspended by admin"),
            cancellationToken);

        var memberCount = await _db.BusinessMembers.IgnoreQueryFilters()
            .CountAsync(bm => bm.BusinessId == businessId && bm.DeletedAt == null && bm.IsActive,
                cancellationToken);
        var saleCount = await _db.Sales.IgnoreQueryFilters()
            .CountAsync(s => s.BusinessId == businessId && s.DeletedAt == null, cancellationToken);

        return new AdminBusinessDto(
            business.Id, business.Name, business.Type, business.Province,
            business.IsActive, business.CreatedAt, memberCount, saleCount);
    }

    // ---------------------------------------------------------------
    // Audit log
    // ---------------------------------------------------------------

    public async Task<PagedResult<AuditLogDto>> GetAuditLogsAsync(
        AuditLogQuery query, CancellationToken cancellationToken = default)
    {
        var logs = _db.AuditLogs.AsQueryable();

        if (query.ActorUserId is { } actor)
            logs = logs.Where(l => l.ActorUserId == actor);
        if (!string.IsNullOrWhiteSpace(query.Action))
        {
            var action = query.Action.Trim();
            logs = logs.Where(l => l.Action == action);
        }

        var total = await logs.CountAsync(cancellationToken);

        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var rows = await logs
            .OrderByDescending(l => l.OccurredAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        var data = rows.Select(l => new AuditLogDto(
            l.Id, l.ActorUserId, l.Action, l.EntityType, l.EntityId, l.Details,
            l.OccurredAt, l.IpAddress)).ToList();

        return PagedResult<AuditLogDto>.Create(data, page, pageSize, total);
    }

    /// <summary>Records an admin action. Never throws — auditing must not
    /// break the action it audits; a failed write is swallowed on purpose.</summary>
    private async Task WriteAuditAsync(
        string action, string? entityType, long? entityId, string? details,
        CancellationToken cancellationToken)
    {
        try
        {
            _db.AuditLogs.Add(new AuditLog
            {
                ActorUserId = ActorUserId,
                Action = action,
                EntityType = entityType,
                EntityId = entityId,
                Details = details,
                OccurredAt = _clock.UtcNow,
                IpAddress = _httpContext.HttpContext?.Connection.RemoteIpAddress?.ToString(),
            });
            await _db.SaveChangesAsync(cancellationToken);
        }
        catch
        {
            // Deliberate: an audit write failure must not fail the action.
        }
    }

    // ---------------------------------------------------------------
    // Feature flags
    // ---------------------------------------------------------------

    public async Task<IReadOnlyList<FeatureFlagDto>> GetFeatureFlagsAsync(
        CancellationToken cancellationToken = default)
    {
        var flags = await _db.FeatureFlags
            .OrderBy(f => f.Key)
            .ToListAsync(cancellationToken);

        return flags
            .Select(f => new FeatureFlagDto(f.Id, f.Key, f.IsEnabled, f.Description))
            .ToList();
    }

    public async Task<FeatureFlagDto> SetFeatureFlagAsync(
        string key, bool isEnabled, CancellationToken cancellationToken = default)
    {
        var flag = await _db.FeatureFlags.FirstOrDefaultAsync(f => f.Key == key, cancellationToken)
            ?? throw new NotFoundException("FeatureFlag", key);

        var previous = flag.IsEnabled;
        flag.IsEnabled = isEnabled;
        flag.UpdatedAt = _clock.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);

        await WriteAuditAsync(
            "feature_flag.update", "FeatureFlag", flag.Id,
            $"{key}: {previous} → {isEnabled}", cancellationToken);

        return new FeatureFlagDto(flag.Id, flag.Key, flag.IsEnabled, flag.Description);
    }

    // ---------------------------------------------------------------
    // Support tickets
    // ---------------------------------------------------------------

    public async Task<SupportTicketDto> CreateTicketAsync(
        string subject, string body, long? businessId,
        SupportTicketPriority priority, CancellationToken cancellationToken = default)
    {
        var ticket = new SupportTicket
        {
            Subject = subject.Trim(),
            Body = body.Trim(),
            Status = SupportTicketStatus.Open,
            Priority = priority,
            ReportedByUserId = ActorUserId,
            BusinessId = businessId,
        };

        _db.SupportTickets.Add(ticket);
        await _db.SaveChangesAsync(cancellationToken);

        await WriteAuditAsync("ticket.create", "SupportTicket", ticket.Id, subject, cancellationToken);

        return ToDto(ticket);
    }

    public async Task<PagedResult<SupportTicketDto>> GetTicketsAsync(
        SupportTicketStatus? status, int page, int pageSize,
        CancellationToken cancellationToken = default)
    {
        var tickets = _db.SupportTickets.Where(t => t.DeletedAt == null).AsQueryable();

        if (status is { } s)
            tickets = tickets.Where(t => t.Status == s);

        var total = await tickets.CountAsync(cancellationToken);

        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var rows = await tickets
            .OrderByDescending(t => t.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return PagedResult<SupportTicketDto>.Create(
            rows.Select(ToDto).ToList(), page, pageSize, total);
    }

    public async Task<SupportTicketDto> UpdateTicketStatusAsync(
        long ticketId, SupportTicketStatus status, string? resolution,
        CancellationToken cancellationToken = default)
    {
        var ticket = await _db.SupportTickets
            .FirstOrDefaultAsync(t => t.Id == ticketId && t.DeletedAt == null, cancellationToken)
            ?? throw new NotFoundException("SupportTicket", ticketId);

        var previous = ticket.Status;
        ticket.Status = status;
        ticket.Resolution = resolution?.Trim();
        if (status is SupportTicketStatus.Resolved or SupportTicketStatus.Closed)
            ticket.ResolvedAt = _clock.UtcNow;
        else
            ticket.ResolvedAt = null;

        ticket.UpdatedAt = _clock.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);

        await WriteAuditAsync(
            "ticket.status", "SupportTicket", ticketId,
            $"{previous} → {status}", cancellationToken);

        return ToDto(ticket);
    }

    private static SupportTicketDto ToDto(SupportTicket t) => new(
        t.Id, t.Subject, t.Body, t.Status, t.Priority,
        t.ReportedByUserId, t.BusinessId, t.AssignedToUserId,
        t.Resolution, t.ResolvedAt, t.CreatedAt);
}
