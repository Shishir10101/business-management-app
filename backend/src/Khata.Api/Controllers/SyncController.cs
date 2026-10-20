namespace Khata.Api.Controllers;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>
/// Delta synchronisation for offline-first clients: pull the cache, push queued
/// writes, and inspect sync status.
/// </summary>
[ApiController]
[Route("api/sync")]
[Authorize]
public class SyncController : ControllerBase
{
    private readonly ISyncService _sync;

    public SyncController(ISyncService sync)
    {
        _sync = sync;
    }

    /// <summary>
    /// Everything changed since <c>since</c> (a previous response's
    /// <c>serverTime</c>). Omit it for a full first sync. Returns at most
    /// <c>limit</c> changes (default 500, max 1000).
    /// </summary>
    [HttpGet("pull")]
    [Authorize(Policy = Permissions.SyncUse)]
    [ProducesResponseType(typeof(SyncPullResultDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<SyncPullResultDto>> Pull(
        [FromQuery] DateTime? since,
        [FromQuery] int limit = 500)
        => Ok(await _sync.PullAsync(since, limit));

    /// <summary>
    /// Applies a batch of client-queued operations. Each operation carries a
    /// client-generated <c>operationId</c> (idempotency) and, for updates, a
    /// <c>baseUpdatedAt</c> (optimistic concurrency).
    /// </summary>
    [HttpPost("push")]
    [Authorize(Policy = Permissions.SyncUse)]
    [ProducesResponseType(typeof(SyncPushResultDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<SyncPushResultDto>> Push([FromBody] SyncPushRequestDto request)
        => Ok(await _sync.PushAsync(request));

    /// <summary>Server time (the sync cursor) and operation ledger counts.</summary>
    [HttpGet("status")]
    [Authorize(Policy = Permissions.SyncView)]
    [ProducesResponseType(typeof(SyncStatusDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<SyncStatusDto>> GetStatus()
        => Ok(await _sync.GetStatusAsync());
}
