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
/// Phase 10: the notification feed, device registration, per-user push
/// settings, and the reminder engine (fire-once, reschedule, complete).
/// </summary>
[Collection(ApiTestCollection.Name)]
public class NotificationEndpointsTests
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    private readonly KhataApiFactory _factory;

    public NotificationEndpointsTests(KhataApiFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Feed_IsEmptyForANewBusiness()
    {
        var client = await CreateOwnerClientAsync();

        var feed = await GetFeedAsync(client);

        Assert.Empty(feed.Data);
        Assert.Equal(0, (await GetUnreadAsync(client)).Count);
    }

    [Fact]
    public async Task Device_Register_IsIdempotentPerToken()
    {
        var client = await CreateOwnerClientAsync();
        var token = $"tok-{Guid.NewGuid():n}";

        var first = await RegisterDeviceAsync(client, token, DevicePlatform.Android);
        var second = await RegisterDeviceAsync(client, token, DevicePlatform.Android);

        // Same token → same row refreshed, not a duplicate.
        Assert.Equal(first.Id, second.Id);

        var devices = await GetDevicesAsync(client);
        Assert.Single(devices);
        Assert.Equal(token, devices[0].Token);
    }

    [Fact]
    public async Task Device_Unregister_DeactivatesIt()
    {
        var client = await CreateOwnerClientAsync();
        var token = $"tok-{Guid.NewGuid():n}";
        await RegisterDeviceAsync(client, token, DevicePlatform.Android);

        var response = await client.DeleteAsync($"/api/notifications/devices?token={token}");
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        Assert.Empty(await GetDevicesAsync(client));
    }

    [Fact]
    public async Task Device_Register_WithoutToken_Returns400()
    {
        var client = await CreateOwnerClientAsync();

        var response = await client.PostAsJsonAsync("/api/notifications/devices",
            new { token = "", platform = "Android" });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Settings_DefaultToEverythingEnabled()
    {
        var client = await CreateOwnerClientAsync();

        var settings = await GetSettingsAsync(client);

        Assert.True(settings.PushEnabled);
        Assert.True(settings.ReminderEnabled);
        Assert.True(settings.LowStockEnabled);
        Assert.True(settings.PaymentDueEnabled);
        Assert.True(settings.BackupEnabled);
        Assert.True(settings.SystemEnabled);
    }

    [Fact]
    public async Task Settings_Update_Persists()
    {
        var client = await CreateOwnerClientAsync();

        var update = await client.PutAsJsonAsync("/api/notifications/settings", new
        {
            pushEnabled = true,
            reminderEnabled = false,
            lowStockEnabled = false,
            paymentDueEnabled = true,
            backupEnabled = false,
            systemEnabled = true,
        });
        update.EnsureSuccessStatusCode();

        var settings = await GetSettingsAsync(client);
        Assert.False(settings.ReminderEnabled);
        Assert.False(settings.LowStockEnabled);
        Assert.False(settings.BackupEnabled);
        Assert.True(settings.PaymentDueEnabled);
    }

    [Fact]
    public async Task Feed_OnlyShowsOwnNotifications()
    {
        // Two owners in two businesses; neither may see the other's feed.
        var ownerA = await CreateOwnerClientAsync();
        var ownerB = await CreateOwnerClientAsync();

        await FireReminderAsync(ownerA, "A's private reminder");

        var feedB = await GetFeedAsync(ownerB);
        Assert.Empty(feedB.Data);

        var feedA = await GetFeedAsync(ownerA);
        Assert.Single(feedA.Data);
    }

    [Fact]
    public async Task MarkRead_ClearsTheUnreadBadge()
    {
        var client = await CreateOwnerClientAsync();
        await FireReminderAsync(client, "Pay the rent");

        var feed = await GetFeedAsync(client);
        var notification = feed.Data.Single();
        Assert.False(notification.IsRead);
        Assert.Equal(1, (await GetUnreadAsync(client)).Count);

        var read = await client.PostAsync($"/api/notifications/{notification.Id}/read", null);
        read.EnsureSuccessStatusCode();

        Assert.Equal(0, (await GetUnreadAsync(client)).Count);

        var after = await GetFeedAsync(client);
        Assert.True(after.Data.Single().IsRead);
        Assert.NotNull(after.Data.Single().ReadAt);
    }

    [Fact]
    public async Task MarkAllRead_ClearsEverything()
    {
        var client = await CreateOwnerClientAsync();
        await FireReminderAsync(client, "First");
        await FireReminderAsync(client, "Second");
        Assert.Equal(2, (await GetUnreadAsync(client)).Count);

        var response = await client.PostAsync("/api/notifications/read-all", null);
        response.EnsureSuccessStatusCode();

        Assert.Equal(0, (await GetUnreadAsync(client)).Count);
    }

    [Fact]
    public async Task UnreadOnly_FilterExcludesReadRows()
    {
        var client = await CreateOwnerClientAsync();
        await FireReminderAsync(client, "Read me");
        await FireReminderAsync(client, "Leave me");

        var all = await GetFeedAsync(client);
        var toRead = all.Data.First();
        await client.PostAsync($"/api/notifications/{toRead.Id}/read", null);

        var unread = await GetFeedAsync(client, unreadOnly: true);
        Assert.Single(unread.Data);
        Assert.NotEqual(toRead.Id, unread.Data[0].Id);
    }

    [Fact]
    public async Task Delete_RemovesFromTheFeed()
    {
        var client = await CreateOwnerClientAsync();
        await FireReminderAsync(client, "Doomed notification");
        var notification = (await GetFeedAsync(client)).Data.Single();

        var response = await client.DeleteAsync($"/api/notifications/{notification.Id}");
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        Assert.Empty((await GetFeedAsync(client)).Data);
    }

    [Fact]
    public async Task MarkRead_ForAnotherBusinessesNotification_Returns404()
    {
        var ownerA = await CreateOwnerClientAsync();
        var ownerB = await CreateOwnerClientAsync();

        await FireReminderAsync(ownerA, "A only");
        var idA = (await GetFeedAsync(ownerA)).Data.Single().Id;

        var response = await ownerB.PostAsync($"/api/notifications/{idA}/read", null);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    // ---------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------

    private static async Task<PagedResult<NotificationDto>> GetFeedAsync(
        HttpClient client, bool unreadOnly = false)
    {
        var url = unreadOnly ? "/api/notifications?unreadOnly=true" : "/api/notifications";
        return (await client.GetFromJsonAsync<PagedResult<NotificationDto>>(url, JsonOptions))!;
    }

    private static async Task<UnreadCountDto> GetUnreadAsync(HttpClient client)
        => (await client.GetFromJsonAsync<UnreadCountDto>(
            "/api/notifications/unread-count", JsonOptions))!;

    private static async Task<IReadOnlyList<DeviceDto>> GetDevicesAsync(HttpClient client)
        => (await client.GetFromJsonAsync<IReadOnlyList<DeviceDto>>(
            "/api/notifications/devices", JsonOptions))!;

    private static async Task<NotificationSettingsDto> GetSettingsAsync(HttpClient client)
        => (await client.GetFromJsonAsync<NotificationSettingsDto>(
            "/api/notifications/settings", JsonOptions))!;

    private static async Task<DeviceDto> RegisterDeviceAsync(
        HttpClient client, string token, DevicePlatform platform)
    {
        var response = await client.PostAsJsonAsync("/api/notifications/devices",
            new { token, platform = platform.ToString() });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<DeviceDto>(JsonOptions))!;
    }

    /// <summary>Creates a past-due one-shot reminder and fires it.</summary>
    private static async Task FireReminderAsync(HttpClient client, string title)
    {
        var create = await client.PostAsJsonAsync("/api/reminders", new
        {
            title,
            notes = (string?)null,
            dueAt = DateTime.UtcNow.AddMinutes(-5),
            repeat = "None",
        });
        create.EnsureSuccessStatusCode();

        var process = await client.PostAsync("/api/reminders/process-due", null);
        process.EnsureSuccessStatusCode();
    }

    /// <summary>Registers a user, creates a business, switches to it (Owner JWT).</summary>
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
