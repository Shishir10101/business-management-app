namespace Khata.Infrastructure.Data;

/// <summary>
/// Classifies a SQLite connection string as in-memory or file-backed.
/// </summary>
/// <remarks>
/// The distinction matters for connection lifetime: an in-memory database is
/// destroyed the moment its last connection closes, so it must be served by one
/// long-lived connection; a file-backed database persists on its own and can
/// safely use one connection per request.
/// <para>
/// Public because the decision is load-bearing — getting it wrong either
/// destroys a database or silently keeps the shared-connection bug — so it is
/// pinned by tests rather than trusted to review.
/// </para>
/// </remarks>
public static class SqliteConnectionStrings
{
    /// <summary>
    /// True for <c>DataSource=:memory:</c>, <c>DataSource=file::memory:?cache=shared</c>
    /// and any <c>Mode=Memory</c> variant.
    /// </summary>
    public static bool IsInMemory(string? connectionString)
    {
        if (string.IsNullOrWhiteSpace(connectionString))
            return false;

        foreach (var parameter in connectionString.Split(';', StringSplitOptions.RemoveEmptyEntries))
        {
            var pair = parameter.Split('=', 2);
            if (pair.Length != 2)
                continue;

            var key = pair[0].Trim();
            var value = pair[1].Trim().Trim('"');

            if (key.Equals("mode", StringComparison.OrdinalIgnoreCase))
            {
                if (value.Equals("memory", StringComparison.OrdinalIgnoreCase))
                    return true;
            }
            // Not `key is "datasource" or ...`: a constant pattern matches
            // ordinals, case-sensitively, so "DataSource" would silently miss.
            else if (key.Equals("datasource", StringComparison.OrdinalIgnoreCase)
                || key.Equals("data source", StringComparison.OrdinalIgnoreCase)
                || key.Equals("filename", StringComparison.OrdinalIgnoreCase))
            {
                if (IsMemoryDataSource(value))
                    return true;
            }
        }

        return false;
    }

    private static bool IsMemoryDataSource(string value) =>
        // ":memory:" and "file::memory:" are the documented forms; a plain
        // file path — including one simply named "memory" — is not.
        value.Equals(":memory:", StringComparison.OrdinalIgnoreCase)
        || value.StartsWith("file::memory:", StringComparison.OrdinalIgnoreCase);
}
