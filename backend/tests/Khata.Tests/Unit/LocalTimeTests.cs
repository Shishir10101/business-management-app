using Khata.Application.Common;
using Xunit;

namespace Khata.Tests.Unit;

/// <summary>
/// Reminder schedule time-zone handling.
/// </summary>
/// <remarks>
/// Regression guard for a bug found live: the API stores UTC, but a client
/// that sends a bare wall-clock time (no offset) had it stored verbatim, which
/// for a Nepal user (UTC+05:45) schedules the reminder 5h45m in the future —
/// a reminder that looks overdue on the phone silently never fires.
/// </remarks>
public class LocalTimeTests
{
    [Fact]
    public void ToUtc_NaiveTimestamp_IsReadAsNepalLocal()
    {
        // 15:00 Wall-clock in Kathmandu == 09:15 UTC.
        var naive = new DateTime(2026, 10, 15, 15, 0, 0, DateTimeKind.Unspecified);

        var utc = LocalTime.ToUtc(naive);

        Assert.Equal(DateTimeKind.Utc, utc.Kind);
        Assert.Equal(new DateTime(2026, 10, 15, 9, 15, 0), utc);
    }

    [Fact]
    public void ToUtc_ExplicitUtc_IsUnchanged()
    {
        var utcIn = new DateTime(2026, 10, 15, 9, 15, 0, DateTimeKind.Utc);

        Assert.Equal(utcIn, LocalTime.ToUtc(utcIn));
    }

    [Fact]
    public void ToUtc_RoundTripsWithFromUtc()
    {
        var naive = new DateTime(2026, 10, 15, 23, 45, 0, DateTimeKind.Unspecified);

        var back = LocalTime.FromUtc(LocalTime.ToUtc(naive));

        Assert.Equal(naive, back);
    }

    [Fact]
    public void FromUtc_ConvertsToNepalWallClock()
    {
        var utc = new DateTime(2026, 10, 15, 9, 15, 30, DateTimeKind.Utc);

        var local = LocalTime.FromUtc(utc);

        Assert.Equal(DateTimeKind.Unspecified, local.Kind);
        // Whole seconds — the 30s survives, sub-second noise does not matter.
        Assert.Equal(new DateTime(2026, 10, 15, 15, 0, 30), local);
    }

    [Fact]
    public void NepalOffset_IsFiveFortyFive()
    {
        Assert.Equal(TimeSpan.FromMinutes(345), LocalTime.NepalOffset);
    }

    [Fact]
    public void AnOverdueNepalWallClockTime_IsInThePastInUtc()
    {
        // The concrete bug: "two hours ago, local time" must actually be in
        // the past after conversion, or the engine will never fire it.
        var twoHoursAgoLocal = DateTime.UtcNow
            .Add(LocalTime.NepalOffset)
            .AddHours(-2);

        var utc = LocalTime.ToUtc(DateTime.SpecifyKind(twoHoursAgoLocal, DateTimeKind.Unspecified));

        Assert.True(utc < DateTime.UtcNow,
            $"Expected {utc:O} to be in the past relative to {DateTime.UtcNow:O}.");
    }
}
