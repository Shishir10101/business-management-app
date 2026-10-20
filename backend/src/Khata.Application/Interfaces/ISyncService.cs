namespace Khata.Application.Interfaces;

using Khata.Application.DTOs;

/// <summary>
/// Delta synchronisation for offline-first clients.
/// <para>
/// <b>Pull</b> returns everything changed since a cursor (the last
/// <c>serverTime</c> the client saw) so the client refreshes its local cache.
/// <para>
/// <b>Push</b> applies a batch of client-queued operations. Every operation
/// carries a client-generated <c>operationId</c> (idempotency: a retry returns
/// "duplicate" instead of applying twice) and, for updates, a
/// <c>baseUpdatedAt</c> (optimistic concurrency: a newer server row is a
/// "conflict", never silently overwritten).
/// </para>
/// </summary>
public interface ISyncService
{
    Task<SyncPullResultDto> PullAsync(DateTime? since, int limit, CancellationToken cancellationToken = default);

    Task<SyncPushResultDto> PushAsync(SyncPushRequestDto request, CancellationToken cancellationToken = default);

    Task<SyncStatusDto> GetStatusAsync(CancellationToken cancellationToken = default);
}
