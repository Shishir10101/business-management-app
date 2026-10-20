namespace Khata.Domain.Common;

/// <summary>
/// Base class for all entities with audit tracking.
/// </summary>
public abstract class AuditableEntity
{
    public long Id { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public long CreatedBy { get; set; }
    public long UpdatedBy { get; set; }
}

/// <summary>
/// Base class for entities that support soft deletion.
/// </summary>
public abstract class SoftDeletableEntity : AuditableEntity, ISoftDeletable
{
    public DateTime? DeletedAt { get; set; }
}

/// <summary>
/// Base class for immutable entities (append-only ledgers): audit columns on
/// creation only — no UpdatedAt, no soft delete. The DbContext rejects any
/// update or delete of an <see cref="IImmutable"/> entity.
/// </summary>
public abstract class ImmutableEntity
{
    public long Id { get; set; }
    public DateTime CreatedAt { get; set; }
    public long CreatedBy { get; set; }
}

/// <summary>
/// Marker interface for entities scoped to a Business (tenant).
/// EF Core applies a global query filter on BusinessId for these entities.
/// </summary>
public interface IBusinessEntity
{
    long BusinessId { get; set; }
}

/// <summary>
/// Marker interface for entities that support soft deletion.
/// </summary>
public interface ISoftDeletable
{
    DateTime? DeletedAt { get; set; }
}

/// <summary>
/// Marker interface for immutable entities (no updates, no deletes).
/// Used by ledger transactions and stock movements.
/// </summary>
public interface IImmutable
{
}
