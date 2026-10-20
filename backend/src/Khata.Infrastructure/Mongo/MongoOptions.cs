namespace Khata.Infrastructure.Mongo;

/// <summary>
/// MongoDB Atlas settings, bound from the "Mongo" configuration section.
/// </summary>
/// <remarks>
/// Deliberately OFF by default. The ledger itself stays on EF Core (SQLite for
/// the local demo, PostgreSQL when a real connection string is supplied) because
/// it is relational to the bone: 26 foreign keys, 201 DTO projections and 21
/// GroupBy reports, none of which the MongoDB EF Core provider supports. Atlas
/// carries the document-shaped data instead — the append-only audit trail, the
/// offline sync journal, the notification feed and backup snapshots.
/// </remarks>
public sealed class MongoOptions
{
    public const string SectionName = "Mongo";

    /// <summary>
    /// Master switch. When false — or when <see cref="ConnectionString"/> is
    /// empty — <see cref="KhataMongoContext.IsEnabled"/> is false and every
    /// Mongo-backed feature reports itself as unavailable instead of failing.
    /// This is what keeps the 350-test suite and the SQLite demo running with
    /// no Atlas credentials at all.
    /// </summary>
    public bool Enabled { get; set; }

    /// <summary>
    /// <c>mongodb+srv://user:password@cluster.mongodb.net/?retryWrites=true&amp;w=majority</c>
    /// from Atlas → Connect → Drivers → .NET. Never commit this; put it in
    /// <c>appsettings.Development.json</c> (gitignored) or user-secrets.
    /// </summary>
    public string? ConnectionString { get; set; }

    /// <summary>Database holding the document collections. Defaults to "khata".</summary>
    public string Database { get; set; } = "khata";

    /// <summary>
    /// How long the driver waits to find a reachable server before giving up.
    /// Short, so a wrong IP allowlist shows up as a fast 503 on /health instead
    /// of a 30-second hang on the first request.
    /// </summary>
    public int ServerSelectionTimeoutSeconds { get; set; } = 5;
}
