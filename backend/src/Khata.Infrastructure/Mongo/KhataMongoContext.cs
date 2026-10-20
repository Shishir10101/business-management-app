namespace Khata.Infrastructure.Mongo;

using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MongoDB.Bson;
using MongoDB.Driver;

/// <summary>
/// Owns the Atlas connection and the four document collections that sit
/// alongside the relational ledger.
/// </summary>
/// <remarks>
/// <para>
/// Registered as a singleton because <see cref="MongoClient"/> is thread-safe and
/// expensive to build; the driver maintains its own connection pool. Do not
/// create a client per request — that is the classic Atlas connection-limit bug,
/// and the free M0 tier caps out at 500 connections.
/// </para>
/// <para>
/// <see cref="IsEnabled"/> is false when Atlas is not configured. Callers must
/// check it and fall back to their relational path rather than catching
/// exceptions, so the SQLite demo and the test suite never depend on credentials.
/// </para>
/// </remarks>
public sealed class KhataMongoContext : IDisposable
{
    private readonly MongoClient? _client;
    private readonly ILogger<KhataMongoContext> _logger;

    public KhataMongoContext(IOptions<MongoOptions> options, ILogger<KhataMongoContext> logger)
    {
        _logger = logger;
        var o = options.Value;

        if (!o.Enabled || string.IsNullOrWhiteSpace(o.ConnectionString))
        {
            _logger.LogInformation(
                "MongoDB Atlas is not configured (Mongo:Enabled={Enabled}); document collections are disabled.",
                o.Enabled);
            return;
        }

        try
        {
            var settings = MongoClientSettings.FromConnectionString(o.ConnectionString);
            settings.ApplicationName = "Khata.Api";
            settings.ServerSelectionTimeout = TimeSpan.FromSeconds(o.ServerSelectionTimeoutSeconds);

            _client = new MongoClient(settings);
            Database = _client.GetDatabase(o.Database);
        }
        catch (Exception ex)
        {
            // A malformed connection string must not take the API down: the
            // ledger still works, only the document features degrade.
            _logger.LogError(ex, "MongoDB Atlas connection string was rejected; document collections are disabled.");
        }
    }

    /// <summary>The configured database, or null when Atlas is off.</summary>
    public IMongoDatabase? Database { get; }

    /// <summary>True when a usable client and database exist.</summary>
    public bool IsEnabled => Database is not null;

    /// <summary>Append-only audit trail, read by the admin console.</summary>
    public IMongoCollection<AuditLogDocument> AuditLogs => Collection<AuditLogDocument>("audit_logs");

    /// <summary>Offline sync journal — idempotency keys live here.</summary>
    public IMongoCollection<SyncOperationDocument> SyncOperations =>
        Collection<SyncOperationDocument>("sync_operations");

    /// <summary>In-app notification feed, per user.</summary>
    public IMongoCollection<NotificationDocument> Notifications =>
        Collection<NotificationDocument>("notifications");

    /// <summary>Point-in-time business snapshots produced by the backup service.</summary>
    public IMongoCollection<BackupSnapshotDocument> BackupSnapshots =>
        Collection<BackupSnapshotDocument>("backup_snapshots");

    private IMongoCollection<T> Collection<T>(string name) =>
        Database is null
            ? throw new InvalidOperationException(
                $"MongoDB Atlas is not configured, so collection '{name}' is unavailable. " +
                "Check KhataMongoContext.IsEnabled before touching document collections.")
            : Database.GetCollection<T>(name);

    /// <summary>
    /// Creates the indexes the queries actually need. Idempotent — safe to call on
    /// every startup. Never throws: a failure here must not block the API.
    /// </summary>
    /// <remarks>
    /// Every index leads with BusinessId, mirroring the EF global query filter.
    /// Without that, a tenant-scoped read is a collection scan.
    /// </remarks>
    public async Task EnsureIndexesAsync(CancellationToken cancellationToken = default)
    {
        if (!IsEnabled)
        {
            return;
        }

        try
        {
            await AuditLogs.Indexes.CreateManyAsync(
                [
                    // Admin console: "what happened, newest first".
                    new CreateIndexModel<AuditLogDocument>(
                        Builders<AuditLogDocument>.IndexKeys
                            .Descending(x => x.OccurredAt),
                        new CreateIndexOptions { Name = "ix_audit_occurred" }),

                    // Admin console: "what did this actor do".
                    new CreateIndexModel<AuditLogDocument>(
                        Builders<AuditLogDocument>.IndexKeys
                            .Ascending(x => x.ActorUserId)
                            .Descending(x => x.OccurredAt),
                        new CreateIndexOptions { Name = "ix_audit_actor_occurred" }),

                    // Drill-down from an entity to its history.
                    new CreateIndexModel<AuditLogDocument>(
                        Builders<AuditLogDocument>.IndexKeys
                            .Ascending(x => x.BusinessId)
                            .Ascending(x => x.EntityType)
                            .Ascending(x => x.EntityId),
                        new CreateIndexOptions { Name = "ix_audit_business_entity" }),
                ],
                cancellationToken);

            await SyncOperations.Indexes.CreateManyAsync(
                [
                    // The idempotency guarantee: a replayed operation cannot insert twice.
                    new CreateIndexModel<SyncOperationDocument>(
                        Builders<SyncOperationDocument>.IndexKeys
                            .Ascending(x => x.BusinessId)
                            .Ascending(x => x.OperationId),
                        new CreateIndexOptions { Name = "ux_sync_business_operation", Unique = true }),

                    // "What came in since my last pull".
                    new CreateIndexModel<SyncOperationDocument>(
                        Builders<SyncOperationDocument>.IndexKeys
                            .Ascending(x => x.BusinessId)
                            .Descending(x => x.CreatedAt),
                        new CreateIndexOptions { Name = "ix_sync_business_created" }),
                ],
                cancellationToken);

            await Notifications.Indexes.CreateManyAsync(
                [
                    // The feed.
                    new CreateIndexModel<NotificationDocument>(
                        Builders<NotificationDocument>.IndexKeys
                            .Ascending(x => x.BusinessId)
                            .Ascending(x => x.UserId)
                            .Descending(x => x.CreatedAt),
                        new CreateIndexOptions { Name = "ix_notif_business_user_created" }),

                    // The unread badge — the single hottest query in the app.
                    new CreateIndexModel<NotificationDocument>(
                        Builders<NotificationDocument>.IndexKeys
                            .Ascending(x => x.BusinessId)
                            .Ascending(x => x.UserId)
                            .Ascending(x => x.ReadAt),
                        new CreateIndexOptions { Name = "ix_notif_business_user_unread" }),
                ],
                cancellationToken);

            await BackupSnapshots.Indexes.CreateManyAsync(
                [
                    new CreateIndexModel<BackupSnapshotDocument>(
                        Builders<BackupSnapshotDocument>.IndexKeys
                            .Ascending(x => x.BusinessId)
                            .Ascending(x => x.BackupKey),
                        new CreateIndexOptions { Name = "ux_backup_business_key", Unique = true }),

                    new CreateIndexModel<BackupSnapshotDocument>(
                        Builders<BackupSnapshotDocument>.IndexKeys
                            .Ascending(x => x.BusinessId)
                            .Descending(x => x.CreatedAt),
                        new CreateIndexOptions { Name = "ix_backup_business_created" }),
                ],
                cancellationToken);

            _logger.LogInformation("MongoDB Atlas indexes verified.");
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Could not create MongoDB Atlas indexes; the API will keep running.");
        }
    }

    /// <summary>
    /// Round-trips a ping. Used by /health so a wrong IP allowlist or a paused
    /// free-tier cluster is visible instead of silent.
    /// </summary>
    public async Task<bool> PingAsync(CancellationToken cancellationToken = default)
    {
        if (Database is null)
        {
            return false;
        }

        try
        {
            await Database.RunCommandAsync<BsonDocument>(
                new BsonDocument("ping", 1),
                cancellationToken: cancellationToken);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "MongoDB Atlas ping failed.");
            return false;
        }
    }

    public void Dispose() => _client?.Dispose();
}
