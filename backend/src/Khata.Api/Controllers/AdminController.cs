namespace Khata.Api.Controllers;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>
/// Platform administration. Every endpoint requires the <c>admin.access</c>
/// permission, which only the platform SuperAdmin role carries — no business
/// role maps to it, so tenant users get 403 even when authenticated.
///
/// These queries are deliberately cross-tenant: the admin console exists to
/// see every user and business on the platform.
/// </summary>
[ApiController]
[Route("api/admin")]
[Authorize(Policy = Permissions.AdminAccess)]
public class AdminController : ControllerBase
{
    private readonly IAdminService _admin;

    public AdminController(IAdminService admin)
    {
        _admin = admin;
    }

    // --- Statistics ---

    [HttpGet("statistics")]
    [ProducesResponseType(typeof(PlatformStatsDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<PlatformStatsDto>> GetStatistics()
        => Ok(await _admin.GetStatsAsync());

    // --- Users ---

    [HttpGet("users")]
    [ProducesResponseType(typeof(PagedResult<AdminUserDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<AdminUserDto>>> GetUsers(
        [FromQuery] AdminUserQuery query)
        => Ok(await _admin.GetUsersAsync(query));

    [HttpPost("users/{id:long}/suspend")]
    [ProducesResponseType(typeof(AdminUserDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AdminUserDto>> SuspendUser(
        long id, [FromBody] AdminUserStateRequest? request)
        => Ok(await _admin.SetUserActiveAsync(id, false, request?.Reason));

    [HttpPost("users/{id:long}/activate")]
    [ProducesResponseType(typeof(AdminUserDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AdminUserDto>> ActivateUser(
        long id, [FromBody] AdminUserStateRequest? request)
        => Ok(await _admin.SetUserActiveAsync(id, true, request?.Reason));

    // --- Businesses ---

    [HttpGet("businesses")]
    [ProducesResponseType(typeof(PagedResult<AdminBusinessDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<AdminBusinessDto>>> GetBusinesses(
        [FromQuery] string? search,
        [FromQuery] bool? isActive,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
        => Ok(await _admin.GetBusinessesAsync(search, isActive, page, pageSize));

    [HttpPost("businesses/{id:long}/suspend")]
    [ProducesResponseType(typeof(AdminBusinessDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AdminBusinessDto>> SuspendBusiness(
        long id, [FromBody] AdminBusinessStateRequest? request)
        => Ok(await _admin.SetBusinessActiveAsync(id, false, request?.Reason));

    [HttpPost("businesses/{id:long}/activate")]
    [ProducesResponseType(typeof(AdminBusinessDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AdminBusinessDto>> ActivateBusiness(
        long id, [FromBody] AdminBusinessStateRequest? request)
        => Ok(await _admin.SetBusinessActiveAsync(id, true, request?.Reason));

    // --- Audit log ---

    [HttpGet("audit-logs")]
    [ProducesResponseType(typeof(PagedResult<AuditLogDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<AuditLogDto>>> GetAuditLogs(
        [FromQuery] AuditLogQuery query)
        => Ok(await _admin.GetAuditLogsAsync(query));

    // --- Feature flags ---

    [HttpGet("feature-flags")]
    [ProducesResponseType(typeof(IReadOnlyList<FeatureFlagDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<FeatureFlagDto>>> GetFeatureFlags()
        => Ok(await _admin.GetFeatureFlagsAsync());

    [HttpPut("feature-flags/{key}")]
    [ProducesResponseType(typeof(FeatureFlagDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<FeatureFlagDto>> SetFeatureFlag(
        string key, [FromBody] UpdateFeatureFlagRequest request)
        => Ok(await _admin.SetFeatureFlagAsync(key, request.IsEnabled));

    // --- Support tickets ---

    [HttpPost("support-tickets")]
    [ProducesResponseType(typeof(SupportTicketDto), StatusCodes.Status201Created)]
    public async Task<ActionResult<SupportTicketDto>> CreateTicket(
        [FromBody] CreateSupportTicketRequest request)
    {
        var ticket = await _admin.CreateTicketAsync(
            request.Subject, request.Body, request.BusinessId, request.Priority);
        return CreatedAtAction(nameof(GetTicket), new { id = ticket.Id }, ticket);
    }

    [HttpGet("support-tickets")]
    [ProducesResponseType(typeof(PagedResult<SupportTicketDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<SupportTicketDto>>> GetTickets(
        [FromQuery] SupportTicketStatus? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
        => Ok(await _admin.GetTicketsAsync(status, page, pageSize));

    [HttpGet("support-tickets/{id:long}")]
    [ProducesResponseType(typeof(SupportTicketDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SupportTicketDto>> GetTicket(long id)
    {
        var page = await _admin.GetTicketsAsync(null, 1, 1000);
        var ticket = page.Data.FirstOrDefault(t => t.Id == id);
        return ticket is null ? NotFound() : Ok(ticket);
    }

    [HttpPut("support-tickets/{id:long}/status")]
    [ProducesResponseType(typeof(SupportTicketDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SupportTicketDto>> UpdateTicketStatus(
        long id, [FromBody] UpdateSupportTicketStatusRequest request)
        => Ok(await _admin.UpdateTicketStatusAsync(id, request.Status, request.Resolution));
}
