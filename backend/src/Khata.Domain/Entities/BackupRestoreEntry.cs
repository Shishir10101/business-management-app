namespace Khata.Domain.Entities;

using Khata.Domain.Common;

/// <summary>
/// One row of a backup restore's id ledger: the id a payload row carried, the
/// id it was actually written under, and the payload it came from. It is the
/// restore's idempotency guard, in the same spirit as <see cref="SyncOperation"/>
/// for sync pushes.
/// </summary>
/// <remarks>
/// Ids cannot be compared directly once a restore had to re-home a row: primary
/// keys are global, so a payload id already owned by another business is
/// replaced by a free one. Without this ledger a second restore of the same
/// file would not recognise the rows it just wrote and would insert them again.
/// </remarks>
public class BackupRestoreEntry : AuditableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    /// <summary>
    /// Identifies the backup file this entry came from. Derived from the
    /// payload's source business and export timestamp, so restoring the same
    /// file twice is recognised while restoring a newer export is not blocked.
    /// </summary>
    public string BackupKey { get; set; } = string.Empty;

    /// <summary>Table name, e.g. "sale".</summary>
    public string EntityType { get; set; } = string.Empty;

    /// <summary>The id the row had in the source business.</summary>
    public long SourceId { get; set; }

    /// <summary>The id it was written under here (equal when it was free).</summary>
    public long TargetId { get; set; }
}
