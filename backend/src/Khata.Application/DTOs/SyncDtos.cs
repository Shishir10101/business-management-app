namespace Khata.Application.DTOs;

// ==============================================================
// Pull (server → client)
// ==============================================================

/// <summary>One changed row in a pull response.</summary>
public record SyncChangeDto(
    string EntityType,
    long EntityId,
    string ChangeType,
    DateTime ChangedAt,
    object? Payload
);

/// <summary>
/// Everything that changed in the active business since <see cref="Since"/>.
/// Only soft-deletable/updatable rows can be delta-pulled; `ChangeType` is
/// "upsert" for live rows and "deleted" for soft-deleted ones.
/// </summary>
public record SyncPullResultDto(
    DateTime ServerTime,
    DateTime? Since,
    IReadOnlyList<SyncChangeDto> Changes,
    bool HasMore
);

// ==============================================================
// Push (client → server)
// ==============================================================

/// <summary>
/// One queued client operation. <see cref="BaseUpdatedAt"/> enables optimistic
/// concurrency: the server rejects the update as a conflict when the row has
/// changed since the client last saw it.
/// </summary>
public record SyncOperationDto(
    string OperationId,
    string EntityType,
    string Operation,
    long EntityId,
    DateTime? BaseUpdatedAt,
    object? Payload
);

public record SyncPushRequestDto(IReadOnlyList<SyncOperationDto> Operations);

/// <summary>
/// Per-operation outcome. `applied` = done, `duplicate` = the operation id was
/// already processed (safe to retry), `conflict` = the server row is newer than
/// <c>BaseUpdatedAt</c>, `rejected` = validation or a business rule failed.
/// </summary>
public record SyncOperationResultDto(
    string OperationId,
    string Status,
    long? EntityId,
    DateTime? Version,
    string? Error
);

public record SyncPushResultDto(
    DateTime ServerTime,
    int Applied,
    int Conflicts,
    int Rejected,
    IReadOnlyList<SyncOperationResultDto> Results
);

public record SyncStatusDto(
    DateTime ServerTime,
    int StoredOperations,
    int PendingConflicts
);
