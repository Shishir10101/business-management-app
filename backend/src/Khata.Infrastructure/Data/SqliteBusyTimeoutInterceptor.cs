namespace Khata.Infrastructure.Data;

using System.Data.Common;
using Microsoft.EntityFrameworkCore.Diagnostics;

/// <summary>
/// SQLite installs no busy handler by default, so any lock conflict surfaces as
/// an immediate <c>SQLITE_BUSY</c> — "database is locked" — the moment another
/// connection holds it, instead of a short wait. This sets
/// <c>PRAGMA busy_timeout</c> as each connection opens so competing writers
/// queue behind each other and readers wait out a WAL checkpoint.
/// </summary>
/// <remarks>
/// Only needed for file-backed SQLite. In-memory databases are served by one
/// shared connection, so they never contend with themselves.
/// </remarks>
internal sealed class SqliteBusyTimeoutInterceptor : DbConnectionInterceptor
{
    /// <summary>
    /// Long enough to ride out a WAL checkpoint (a few hundred ms), short
    /// enough that a genuinely stuck transaction still fails the request
    /// rather than hanging the thread pool.
    /// </summary>
    internal const int BusyTimeoutSeconds = 30;

    private static string Pragma => $"PRAGMA busy_timeout = {BusyTimeoutSeconds * 1000};";

    public override void ConnectionOpened(
        DbConnection connection,
        ConnectionEndEventData eventData)
    {
        Apply(connection);

        base.ConnectionOpened(connection, eventData);
    }

    public override async Task ConnectionOpenedAsync(
        DbConnection connection,
        ConnectionEndEventData eventData,
        CancellationToken cancellationToken = default)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = Pragma;
        await command.ExecuteNonQueryAsync(cancellationToken).ConfigureAwait(false);

        await base.ConnectionOpenedAsync(connection, eventData, cancellationToken)
            .ConfigureAwait(false);
    }

    private static void Apply(DbConnection connection)
    {
        using var command = connection.CreateCommand();
        command.CommandText = Pragma;
        command.ExecuteNonQuery();
    }
}
