using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Domain.Enums;
using Khata.Tests.Testing;
using Xunit;

namespace Khata.Tests.Integration;

/// <summary>
/// Phase 10: reminders — CRUD, the due-processing engine (fire once,
/// reschedule recurrences, complete/dismiss), and tenant isolation.
/// </summary>
[Collection(ApiTestCollection.Name)]
public class ReminderEndpointsTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    private readonly KhataApiFactory _factory;

    public ReminderEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Create_ReturnsPendingReminder()
    {
        var client = await CreateOwnerClientAsync();

        var reminder = await CreateReminderAsync(client, "Call Ram", DateTime.UtcNow.AddDays(1));

        Assert.Equal(ReminderStatus.Pending, reminder.Status);
        Assert.Equal(ReminderRepeat.None, reminder.Repeat);
        Assert.Equal("Call Ram", reminder.Title);
        Assert.Null(reminder.CompletedAt);
    }

    [Fact]
    public async Task Create_WithoutTitle_Returns400()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync("/api/reminders", new
        {
            title = "",
            dueAt = DateTime.UtcNow,
            repeat = "None",
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task List_FiltersByStatus()
    {
        var client = await CreateOwnerClientAsync();
        var pending = await CreateReminderAsync(client, "Pending", DateTime.UtcNow.AddDays(1));
        var done = await CreateReminderAsync(client, "Done", DateTime.UtcNow.AddDays(2));
        await CompleteAsync(client, done.Id);

        var pendingOnly = await ListAsync(client, "Pending");
        var doneOnly = await ListAsync(client, "Done");

        Assert.Single(pendingOnly.Data);
        Assert.Equal(pending.Id, pendingOnly.Data[0].Id);
        Assert.Single(doneOnly.Data);
        Assert.Equal(done.Id, doneOnly.Data[0].Id);
    }

    [Fact]
    public async Task Update_ReschedulingACompletedReminder_ReopensIt()
    {
        var client = await CreateOwnerClientAsync();
        var reminder = await CreateReminderAsync(client, "Pay rent", DateTime.UtcNow.AddDays(1));
        await CompleteAsync(client, reminder.Id);

        var update = await client.PutAsJsonAsync($"/api/reminders/{reminder.Id}", new
        {
            title = "Pay rent (moved)",
            notes = "Moved to next week",
            dueAt = DateTime.UtcNow.AddDays(7),
            repeat = "Monthly",
        });
        update.EnsureSuccessStatusCode();
        var updated = await update.Content.ReadFromJsonAsync<ReminderDto>(JsonOptions);

        // A moved reminder must be able to fire again — otherwise "snooze"
        // silently does nothing.
        Assert.Equal(ReminderStatus.Pending, updated!.Status);
        Assert.Null(updated.CompletedAt);
        Assert.Equal(ReminderRepeat.Monthly, updated.Repeat);
        Assert.Equal("Pay rent (moved)", updated.Title);
    }

    [Fact]
    public async Task Complete_ThenDismiss_AreDistinctStates()
    {
        var client = await CreateOwnerClientAsync();
        var done = await CreateReminderAsync(client, "Complete me", DateTime.UtcNow.AddDays(1));
        var dismissed = await CreateReminderAsync(client, "Dismiss me", DateTime.UtcNow.AddDays(1));

        await CompleteAsync(client, done.Id);
        var dismissResponse = await client.PostAsync($"/api/reminders/{dismissed.Id}/dismiss", null);
        dismissResponse.EnsureSuccessStatusCode();

        var doneRow = (await ListAsync(client, "Done")).Data.Single();
        var dismissedRow = (await ListAsync(client, "Dismissed")).Data.Single();

        Assert.Equal(done.Id, doneRow.Id);
        Assert.Equal(dismissed.Id, dismissedRow.Id);
    }

    [Fact]
    public async Task Delete_RemovesItFromTheList()
    {
        var client = await CreateOwnerClientAsync();
        var reminder = await CreateReminderAsync(client, "Delete me", DateTime.UtcNow.AddDays(1));

        var response = await client.DeleteAsync($"/api/reminders/{reminder.Id}");
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        Assert.Empty((await ListAsync(client, null)).Data);
    }

    [Fact]
    public async Task ProcessDue_IgnoresFutureReminders()
    {
        var client = await CreateOwnerClientAsync();
        await CreateReminderAsync(client, "Tomorrow", DateTime.UtcNow.AddDays(1));

        var fired = await ProcessDueAsync(client);

        Assert.Equal(0, fired);
        Assert.Single((await ListAsync(client, "Pending")).Data);
        Assert.Empty((await FeedAsync(client)).Data);
    }

    [Fact]
    public async Task ProcessDue_FiresOneShotAndCompletesIt()
    {
        var client = await CreateOwnerClientAsync();
        var reminder = await CreateReminderAsync(client, "Overdue bill", DateTime.UtcNow.AddMinutes(-10));

        var fired = await ProcessDueAsync(client);

        Assert.Equal(1, fired);

        // One-shot → Done, with the notification in the feed.
        Assert.Empty((await ListAsync(client, "Pending")).Data);
        var done = (await ListAsync(client, "Done")).Data.Single();
        Assert.Equal(reminder.Id, done.Id);
        Assert.NotNull(done.CompletedAt);

        var notification = (await FeedAsync(client)).Data.Single();
        Assert.Equal("Overdue bill", notification.Title);
        Assert.Equal(NotificationCategory.Reminder, notification.Category);
        Assert.Equal(reminder.Id, notification.ReferenceId);
    }

    [Fact]
    public async Task ProcessDue_IsNotRepeatable_ForAOneShotReminder()
    {
        var client = await CreateOwnerClientAsync();
        await CreateReminderAsync(client, "Fire once", DateTime.UtcNow.AddMinutes(-10));

        var first = await ProcessDueAsync(client);
        var second = await ProcessDueAsync(client);

        Assert.Equal(1, first);
        Assert.Equal(0, second);           // already Done — no second fire
        Assert.Single((await FeedAsync(client)).Data);
    }

    [Fact]
    public async Task ProcessDue_AdvancesARepeatingReminder_InsteadOfCompletingIt()
    {
        var client = await CreateOwnerClientAsync();
        var reminder = await CreateReminderAsync(
            client, "Daily standup", DateTime.UtcNow.AddMinutes(-10), ReminderRepeat.Daily);

        var fired = await ProcessDueAsync(client);
        Assert.Equal(1, fired);

        // Still pending, and rescheduled to a FUTURE occurrence — an offline
        // client must not come back to a burst of missed reminders.
        var pending = (await ListAsync(client, "Pending")).Data.Single();
        Assert.Equal(reminder.Id, pending.Id);
        Assert.True(pending.DueAt > DateTime.UtcNow.AddHours(-1));
        Assert.Null(pending.CompletedAt);
        Assert.Single((await FeedAsync(client)).Data);
    }

    [Fact]
    public async Task ProcessDue_Weekly_CatchesUpToTheNextFutureOccurrence()
    {
        var client = await CreateOwnerClientAsync();
        // Three weeks overdue: the engine must jump straight to the future.
        var reminder = await CreateReminderAsync(
            client, "Weekly report", DateTime.UtcNow.AddDays(-21), ReminderRepeat.Weekly);

        await ProcessDueAsync(client);

        var pending = (await ListAsync(client, "Pending")).Data.Single();
        Assert.Equal(reminder.Id, pending.Id);
        Assert.True(pending.DueAt > DateTime.UtcNow);
    }

    [Fact]
    public async Task CrossBusiness_AccessReturns404()
    {
        var ownerA = await CreateOwnerClientAsync();
        var ownerB = await CreateOwnerClientAsync();

        var reminderA = await CreateReminderAsync(ownerA, "A's reminder", DateTime.UtcNow.AddDays(1));

        var get = await ownerB.GetAsync($"/api/reminders/{reminderA.Id}");
        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);

        var update = await ownerB.PutAsJsonAsync($"/api/reminders/{reminderA.Id}", new
        {
            title = "Hijacked",
            dueAt = DateTime.UtcNow,
            repeat = "None",
        });
        Assert.Equal(HttpStatusCode.NotFound, update.StatusCode);

        var delete = await ownerB.DeleteAsync($"/api/reminders/{reminderA.Id}");
        Assert.Equal(HttpStatusCode.NotFound, delete.StatusCode);

        // And A's list never saw B's activity.
        Assert.Single((await ListAsync(ownerA, null)).Data);
        Assert.Empty((await ListAsync(ownerB, null)).Data);
    }

    [Fact]
    public async Task ProcessDue_NotifiesTheOwner_WhenTheReminderHasNoAssignee()
    {
        // Reminders are assigned to their creator, but the engine must still
        // resolve a recipient for rows created without one.
        var client = await CreateOwnerClientAsync();
        await CreateReminderAsync(client, "Unassigned", DateTime.UtcNow.AddMinutes(-5));

        await ProcessDueAsync(client);

        Assert.Single((await FeedAsync(client)).Data);
    }

    [Fact]
    public async Task NaiveLocalDueAt_IsReadAsNepalTime_SoAnOverdueReminderFires()
    {
        // Regression guard. The client sends a bare wall-clock time (Nepal
        // local, as DateTime.now() produces) with no offset. Before the fix
        // this was stored verbatim and read as UTC, so a reminder that looked
        // two hours overdue on the phone landed 3h45m in the FUTURE and never
        // fired.
        var client = await CreateOwnerClientAsync();
        var nepalNow = DateTime.UtcNow.Add(LocalTime.NepalOffset);
        var naiveOverdue = DateTime.SpecifyKind(nepalNow.AddHours(-2), DateTimeKind.Unspecified);

        var create = await client.PostAsJsonAsync("/api/reminders", new
        {
            title = "Two hours late",
            dueAt = naiveOverdue,
            repeat = "None",
        });
        create.EnsureSuccessStatusCode();

        var fired = await ProcessDueAsync(client);

        Assert.Equal(1, fired);
        Assert.Single((await ListAsync(client, "Done")).Data);
    }

    [Fact]
    public async Task DueAt_RoundTripsInNepalLocalTime()
    {
        // What the user typed must read back unchanged, or the list shows the
        // wrong time and they do not trust the app.
        var client = await CreateOwnerClientAsync();
        var nepalWallClock = new DateTime(2026, 12, 1, 9, 30, 0, DateTimeKind.Unspecified);

        var reminder = await CreateReminderAsync(client, "Morning call", nepalWallClock);

        Assert.Equal(2026, reminder.DueAt.Year);
        Assert.Equal(12, reminder.DueAt.Month);
        Assert.Equal(1, reminder.DueAt.Day);
        Assert.Equal(9, reminder.DueAt.Hour);
        Assert.Equal(30, reminder.DueAt.Minute);
    }

    // ---------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------

    private static async Task<ReminderDto> CreateReminderAsync(
        HttpClient client, string title, DateTime dueAt, ReminderRepeat repeat = ReminderRepeat.None)
    {
        var response = await client.PostAsJsonAsync("/api/reminders", new
        {
            title,
            notes = (string?)null,
            dueAt,
            repeat = repeat.ToString(),
        });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<ReminderDto>(JsonOptions))!;
    }

    private static async Task<PagedResult<ReminderDto>> ListAsync(HttpClient client, string? status)
    {
        var url = status is null ? "/api/reminders" : $"/api/reminders?status={status}";
        return (await client.GetFromJsonAsync<PagedResult<ReminderDto>>(url, JsonOptions))!;
    }

    private static async Task CompleteAsync(HttpClient client, long id)
    {
        var response = await client.PostAsync($"/api/reminders/{id}/complete", null);
        response.EnsureSuccessStatusCode();
    }

    private static async Task<int> ProcessDueAsync(HttpClient client)
    {
        var response = await client.PostAsync("/api/reminders/process-due", null);
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadFromJsonAsync<FiredResult>(JsonOptions);
        return body!.Fired;
    }

    private static async Task<PagedResult<NotificationDto>> FeedAsync(HttpClient client)
        => (await client.GetFromJsonAsync<PagedResult<NotificationDto>>(
            "/api/notifications", JsonOptions))!;

    private sealed record FiredResult(int Fired);

    private async Task<HttpClient> CreateOwnerClientAsync()
    {
        var client = await AuthEndpointsTests.CreateAuthenticatedClientAsync(_factory);

        var create = await client.PostAsJsonAsync("/api/businesses", new
        {
            name = $"Shop {Guid.NewGuid():n}",
            currency = "NPR",
        });
        create.EnsureSuccessStatusCode();
        var business = await create.Content.ReadFromJsonAsync<BusinessDto>(JsonOptions);

        var switchResponse = await client.PostAsJsonAsync($"/api/businesses/{business!.Id}/switch", new { });
        switchResponse.EnsureSuccessStatusCode();
        var auth = await switchResponse.Content.ReadFromJsonAsync<AuthResponse>(JsonOptions);
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", auth!.AccessToken);

        return client;
    }
}
