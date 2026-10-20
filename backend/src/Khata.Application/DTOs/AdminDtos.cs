namespace Khata.Application.DTOs;

using Khata.Domain.Enums;

// ==============================================================
// Platform statistics
// ==============================================================

/// <summary>Cross-tenant totals for the admin dashboard.</summary>
public record PlatformStatsDto(
    int TotalUsers,
    int ActiveUsers,
    int TotalBusinesses,
    int ActiveBusinesses,
    int TotalSales,
    long TotalSalesPaisa,
    int TotalPayments,
    long TotalPaymentsPaisa,
    int OpenTickets,
    int TotalTickets
);

// ==============================================================
// Users (cross-tenant)
// ==============================================================

/// <summary>One platform user as the admin console sees it.</summary>
public record AdminUserDto(
    long Id,
    string Email,
    string FullName,
    bool IsActive,
    string Locale,
    DateTime CreatedAt,
    int BusinessCount
);

/// <summary>Search/filter for the admin user list.</summary>
public class AdminUserQuery
{
    public string? Search { get; set; }
    public bool? IsActive { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

/// <summary>Why a user is being suspended/activated — recorded in the audit log.</summary>
public record AdminUserStateRequest(string? Reason);

// ==============================================================
// Businesses (cross-tenant)
// ==============================================================

/// <summary>One business as the admin console sees it.
/// <see cref="Province"/> is the official province number 1–7 (null when unset).</summary>
public record AdminBusinessDto(
    long Id,
    string Name,
    string? Type,
    int? Province,
    bool IsActive,
    DateTime CreatedAt,
    int MemberCount,
    int SaleCount
);

public record AdminBusinessStateRequest(string? Reason);

// ==============================================================
// Audit log
// ==============================================================

public record AuditLogDto(
    long Id,
    long ActorUserId,
    string Action,
    string? EntityType,
    long? EntityId,
    string? Details,
    DateTime OccurredAt,
    string? IpAddress
);

public class AuditLogQuery
{
    public long? ActorUserId { get; set; }
    public string? Action { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 50;
}

// ==============================================================
// Feature flags
// ==============================================================

public record FeatureFlagDto(
    long Id,
    string Key,
    bool IsEnabled,
    string? Description
);

public record UpdateFeatureFlagRequest(bool IsEnabled);

// ==============================================================
// Support tickets
// ==============================================================

public record SupportTicketDto(
    long Id,
    string Subject,
    string Body,
    SupportTicketStatus Status,
    SupportTicketPriority Priority,
    long ReportedByUserId,
    long? BusinessId,
    long? AssignedToUserId,
    string? Resolution,
    DateTime? ResolvedAt,
    DateTime CreatedAt
);

public record CreateSupportTicketRequest(
    string Subject,
    string Body,
    long? BusinessId,
    SupportTicketPriority Priority = SupportTicketPriority.Normal
);

public record UpdateSupportTicketStatusRequest(
    SupportTicketStatus Status,
    string? Resolution
);
