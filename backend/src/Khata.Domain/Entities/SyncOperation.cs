namespace Khata.Domain.Entities;

using Khata.Domain.Common;

/// <summary>
/// Audit row for one client operation processed by <c>/api/sync/push</c>, keyed
/// by the client-generated <see cref="OperationId"/>. It is the idempotency
/// guard: a retried push finds the row and reports "duplicate" instead of
/// applying the operation twice.
/// </summary>
public class SyncOperation : AuditableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    /// <summary>Client-generated idempotency key (a UUID).</summary>
    public string OperationId { get; set; } = string.Empty;

    public string EntityType { get; set; } = string.Empty;

    /// <summary>"applied" | "conflict" | "rejected".</summary>
    public string Status { get; set; } = "applied";

    public string? Error { get; set; }
    public long? EntityId { get; set; }

    /// <summary>The server's UpdatedAt after applying, for the next pull's `since`.</summary>
    public DateTime? Version { get; set; }
}
