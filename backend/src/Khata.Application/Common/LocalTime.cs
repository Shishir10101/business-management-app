namespace Khata.Application.Common;

/// <summary>
/// Timestamp rules for reminder schedules.
/// </summary>
/// <remarks>
/// The API stores every timestamp in UTC. A client that sends a bare local
/// wall-clock time ("2026-10-15T15:41:00", no offset) is ambiguous: .NET
/// deserializes it as <see cref="DateTimeKind.Unspecified"/> and — with the
/// default JSON options — stores it verbatim. For a user in Nepal (UTC+05:45)
/// that silently schedules the reminder 5h45m in the future, so a reminder
/// that reads as "already overdue" on the phone never fires.
///
/// Rather than guess, the rule is explicit: a naive timestamp is interpreted
/// in the business's local zone (Asia/Kathmandu), which is what the client
/// meant when it built the value with <c>DateTime.now()</c>. An explicit
/// offset — "Z", "+05:45", anything — is always honoured as written, so
/// well-formed clients are unaffected.
/// </remarks>
public static class LocalTime
{
    /// <summary>Nepal Standard Time — UTC+05:45. Fixed offset; Nepal has no DST.</summary>
    public static readonly TimeSpan NepalOffset = TimeSpan.FromMinutes(5 * 60 + 45);

    /// <summary>
    /// Converts a client-supplied schedule to UTC. A value that already
    /// carries an offset is converted as-is; a naive value is read as Nepal
    /// local time.
    /// </summary>
    public static DateTime ToUtc(DateTime value) => value.Kind switch
    {
        DateTimeKind.Utc => value,
        DateTimeKind.Local => value.ToUniversalTime(),
        // Unspecified: the client sent a wall-clock time with no zone. Read it
        // as Nepal local — the audience's zone — and convert to UTC.
        _ => DateTime.SpecifyKind(value - NepalOffset, DateTimeKind.Utc),
    };

    /// <summary>
    /// Converts a stored UTC value back to the client's local zone for
    /// display. Rounds to whole seconds so serialization stays clean.
    /// </summary>
    public static DateTime FromUtc(DateTime value)
    {
        var utc = value.Kind == DateTimeKind.Utc ? value : ToUtc(value);
        var local = utc + NepalOffset;
        return new DateTime(
            local.Ticks - local.Ticks % TimeSpan.TicksPerSecond,
            DateTimeKind.Unspecified);
    }
}
