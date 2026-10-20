namespace Khata.Domain.Entities;

using Khata.Domain.Common;
using Khata.Domain.Enums;

/// <summary>
/// Platform-level audit entry. Deliberately NOT <see cref="IBusinessEntity"/>:
/// the admin console reads across all tenants, so a business-scoped filter
/// would hide the very rows it exists to show. Append-only — rows are never
/// updated or deleted.
/// </summary>
public class AuditLog : AuditableEntity
{
    /// <summary>Who performed the action (platform user id).</summary>
    public long ActorUserId { get; set; }

    /// <summary>Action code, e.g. "user.suspend", "feature_flag.update".</summary>
    public string Action { get; set; } = string.Empty;

    /// <summary>Entity kind the action targeted, e.g. "User" / "Business".</summary>
    public string? EntityType { get; set; }

    /// <summary>Target entity id, when the action had one.</summary>
    public long? EntityId { get; set; }

    /// <summary>Human-readable detail (old → new value, reason, etc.).</summary>
    public string? Details { get; set; }

    /// <summary>UTC timestamp of the action.</summary>
    public DateTime OccurredAt { get; set; }

    /// <summary>Client IP the action came from, when known.</summary>
    public string? IpAddress { get; set; }
}

/// <summary>
/// A runtime feature switch. Platform-scoped (not per business): the admin
/// console flips a flag and every tenant sees the change. Flags are keyed by
/// a stable code so code can look one up without a database round-trip list.
/// </summary>
public class FeatureFlag : AuditableEntity
{
    /// <summary>Stable lookup code, e.g. "esewa_payments". Unique.</summary>
    public string Key { get; set; } = string.Empty;

    public bool IsEnabled { get; set; }

    public string? Description { get; set; }
}

/// <summary>
/// A support ticket filed from the app (or by the platform team). Platform-
/// scoped like the audit log: the admin console triages across all tenants.
/// Soft-deletable so closing a ticket never destroys the conversation.
/// </summary>
public class SupportTicket : SoftDeletableEntity
{
    public string Subject { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;

    public SupportTicketStatus Status { get; set; } = SupportTicketStatus.Open;
    public SupportTicketPriority Priority { get; set; } = SupportTicketPriority.Normal;

    /// <summary>Who filed it (platform user id).</summary>
    public long ReportedByUserId { get; set; }

    /// <summary>
    /// The business the ticket concerns, when it came from inside one.
    /// Null for platform-level tickets.
    /// </summary>
    public long? BusinessId { get; set; }

    /// <summary>Optional assignee (platform user id).</summary>
    public long? AssignedToUserId { get; set; }

    /// <summary>Resolution note, set when the ticket is Resolved or Closed.</summary>
    public string? Resolution { get; set; }

    public DateTime? ResolvedAt { get; set; }
}
