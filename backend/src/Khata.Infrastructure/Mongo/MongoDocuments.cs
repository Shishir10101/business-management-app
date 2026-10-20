namespace Khata.Infrastructure.Mongo;

using Khata.Domain.Enums;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

/// <summary>
/// Platform audit entry — the document-store twin of
/// <see cref="Khata.Domain.Entities.AuditLog"/>. Append-only, written for every
/// privileged action, read by the admin console.
/// </summary>
/// <remarks>
/// Why this lives in Atlas rather than beside the ledger: it is append-only,
/// has no foreign keys, is read in time ranges rather than joined, and grows
/// without bound. Those are the four properties that make a collection a better
/// fit than a table. The relational twin stays in place until this one is wired,
/// so nothing regresses if Atlas is switched off.
/// </remarks>
public sealed class AuditLogDocument
{
    [BsonId]
    public ObjectId Id { get; set; }

    /// <summary>Tenant the action affected. Zero for platform-wide actions.</summary>
    public long BusinessId { get; set; }

    /// <summary>Who performed the action.</summary>
    public long ActorUserId { get; set; }

    /// <summary>Action code, e.g. "user.suspend", "feature_flag.update".</summary>
    public string Action { get; set; } = string.Empty;

    public string? EntityType { get; set; }
    public long? EntityId { get; set; }

    /// <summary>Human-readable detail (old → new value, reason, etc.).</summary>
    public string? Details { get; set; }

    /// <summary>Structured before/after values, when the caller has them.</summary>
    public BsonDocument? Changes { get; set; }

    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }

    public DateTime OccurredAt { get; set; }
}

/// <summary>
/// One row of the offline sync journal — the server-side record of an operation
/// the mobile app queued while it had no network.
/// </summary>
/// <remarks>
/// <see cref="OperationId"/> is the client-generated idempotency key. The mobile
/// queue replays on reconnect, so the same operation can arrive several times;
/// a unique index on (BusinessId, OperationId) makes the replay a no-op instead
/// of a duplicate sale. That uniqueness constraint is the whole reason this
/// belongs in a store that can enforce it without a schema migration.
/// </remarks>
public sealed class SyncOperationDocument
{
    [BsonId]
    public ObjectId Id { get; set; }

    public long BusinessId { get; set; }
    public long UserId { get; set; }

    /// <summary>Client-generated idempotency key. Unique per business.</summary>
    public string OperationId { get; set; } = string.Empty;

    public string EntityType { get; set; } = string.Empty;

    /// <summary>"applied" | "duplicate" | "rejected" | "failed".</summary>
    public string Status { get; set; } = "applied";

    public string? Error { get; set; }

    /// <summary>Server-side id after the operation was applied.</summary>
    public long? EntityId { get; set; }

    /// <summary>Client's view of the row version, for conflict detection.</summary>
    public DateTime? Version { get; set; }

    /// <summary>The raw client payload, kept for replay and for support.</summary>
    public BsonDocument? Payload { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime? AppliedAt { get; set; }
}

/// <summary>
/// An in-app notification for one user of one business — the document-store twin
/// of <see cref="Khata.Domain.Entities.Notification"/>.
/// </summary>
public sealed class NotificationDocument
{
    [BsonId]
    public ObjectId Id { get; set; }

    public long BusinessId { get; set; }
    public long UserId { get; set; }

    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;

    [BsonRepresentation(BsonType.String)]
    public NotificationCategory Category { get; set; }

    public string? ReferenceType { get; set; }
    public long? ReferenceId { get; set; }

    /// <summary>Null while unread. Indexed — the unread count is the hot query.</summary>
    public DateTime? ReadAt { get; set; }

    public DateTime CreatedAt { get; set; }
}

/// <summary>
/// A point-in-time snapshot of one business, as produced by the backup service.
/// Stored as a document because it is already opaque JSON — keeping it in a
/// relational text column bought nothing but a 0.5 GB row limit conversation.
/// </summary>
public sealed class BackupSnapshotDocument
{
    [BsonId]
    public ObjectId Id { get; set; }

    public long BusinessId { get; set; }
    public long CreatedBy { get; set; }

    /// <summary>Stable key for the snapshot, e.g. "2026-10-20T06:46:00Z". Unique per business.</summary>
    public string BackupKey { get; set; } = string.Empty;

    public string Format { get; set; } = "khata-backup-v1";
    public long SizeBytes { get; set; }

    /// <summary>The snapshot itself. Stored as BSON so Atlas can query inside it.</summary>
    public BsonDocument Payload { get; set; } = new();

    public DateTime CreatedAt { get; set; }
}
