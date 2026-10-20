namespace Khata.Application.Interfaces;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Domain.Enums;

/// <summary>
/// Platform administration surface: cross-tenant user and business
/// management, platform statistics, the audit log, feature flags and
/// support tickets. Every method assumes the caller already passed the
/// <c>admin.access</c> policy — these queries run WITHOUT the tenant
/// filter by design (see <see cref="Khata.Domain.Entities.AuditLog"/>).
/// </summary>
public interface IAdminService
{
    // --- Statistics ---

    Task<PlatformStatsDto> GetStatsAsync(CancellationToken cancellationToken = default);

    // --- Users ---

    Task<PagedResult<AdminUserDto>> GetUsersAsync(AdminUserQuery query, CancellationToken cancellationToken = default);
    Task<AdminUserDto> SetUserActiveAsync(long userId, bool isActive, string? reason, CancellationToken cancellationToken = default);

    // --- Businesses ---

    Task<PagedResult<AdminBusinessDto>> GetBusinessesAsync(string? search, bool? isActive, int page, int pageSize, CancellationToken cancellationToken = default);
    Task<AdminBusinessDto> SetBusinessActiveAsync(long businessId, bool isActive, string? reason, CancellationToken cancellationToken = default);

    // --- Audit log ---

    Task<PagedResult<AuditLogDto>> GetAuditLogsAsync(AuditLogQuery query, CancellationToken cancellationToken = default);

    // --- Feature flags ---

    Task<IReadOnlyList<FeatureFlagDto>> GetFeatureFlagsAsync(CancellationToken cancellationToken = default);
    Task<FeatureFlagDto> SetFeatureFlagAsync(string key, bool isEnabled, CancellationToken cancellationToken = default);

    // --- Support tickets ---

    Task<SupportTicketDto> CreateTicketAsync(string subject, string body, long? businessId, SupportTicketPriority priority, CancellationToken cancellationToken = default);
    Task<PagedResult<SupportTicketDto>> GetTicketsAsync(SupportTicketStatus? status, int page, int pageSize, CancellationToken cancellationToken = default);
    Task<SupportTicketDto> UpdateTicketStatusAsync(long ticketId, SupportTicketStatus status, string? resolution, CancellationToken cancellationToken = default);
}
