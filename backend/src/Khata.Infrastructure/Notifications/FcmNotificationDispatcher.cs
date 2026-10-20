namespace Khata.Infrastructure.Notifications;

using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Khata.Application.Interfaces;
using Khata.Domain.Enums;
using Khata.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

/// <summary>
/// Firebase Cloud Messaging (HTTP v1) push delivery.
/// </summary>
/// <remarks>
/// Credentials have to come from the user's own Firebase project — this repo
/// ships none. When <c>Notifications:Firebase:ProjectId</c> or
/// <c>Notifications:Firebase:AccessToken</c> is missing the dispatcher is a
/// no-op that reports <see cref="NotificationDispatchStatus.Disabled"/>: the
/// in-app feed still records everything, so the feature degrades cleanly
/// instead of failing. Drop real service-account credentials in and pushes
/// start flowing without any other code change.
///
/// The access token is read from configuration rather than minted from a
/// service-account key: key signing needs the Google auth libraries, which
/// are not referenced here. A production deployment can either supply a
/// long-lived token via configuration or replace this class with one that
/// mints OAuth2 tokens from the service-account JSON.
/// </remarks>
public class FcmNotificationDispatcher : INotificationDispatcher
{
    private const string FcmEndpoint = "https://fcm.googleapis.com/v1/projects/{0}/messages:send";

    private readonly KhataDbContext _db;
    private readonly IConfiguration _config;
    private readonly IHttpClientFactory _httpFactory;
    private readonly ILogger<FcmNotificationDispatcher> _logger;

    public FcmNotificationDispatcher(
        KhataDbContext db,
        IConfiguration config,
        IHttpClientFactory httpFactory,
        ILogger<FcmNotificationDispatcher> logger)
    {
        _db = db;
        _config = config;
        _httpFactory = httpFactory;
        _logger = logger;
    }

    public async Task<NotificationDispatchResult> DispatchAsync(
        NotificationMessage message, CancellationToken cancellationToken = default)
    {
        var projectId = _config["Notifications:Firebase:ProjectId"];
        var accessToken = _config["Notifications:Firebase:AccessToken"];

        if (string.IsNullOrWhiteSpace(projectId) || string.IsNullOrWhiteSpace(accessToken))
        {
            _logger.LogDebug(
                "FCM push skipped for business {BusinessId}: Firebase credentials not configured.",
                message.BusinessId);
            return new NotificationDispatchResult(
                NotificationDispatchStatus.Disabled, 0, "Firebase credentials not configured.");
        }

        // The engine runs without a request context (tenant filter id 0), so
        // device lookup must bypass the global filter and scope explicitly.
        var tokens = await _db.DeviceRegistrations
            .IgnoreQueryFilters()
            .Where(d => d.BusinessId == message.BusinessId && d.UserId == message.UserId && d.IsActive)
            .Select(d => d.Token)
            .ToListAsync(cancellationToken);

        if (tokens.Count == 0)
            return new NotificationDispatchResult(NotificationDispatchStatus.NoDevices, 0);

        var client = _httpFactory.CreateClient("fcm");
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

        var url = string.Format(FcmEndpoint, projectId);
        var sent = 0;
        string? lastError = null;

        foreach (var token in tokens)
        {
            var payload = BuildPayload(token, message);

            try
            {
                var response = await client.PostAsJsonAsync(url, payload, cancellationToken);
                if (response.IsSuccessStatusCode)
                {
                    sent++;
                    continue;
                }

                var body = await response.Content.ReadAsStringAsync(cancellationToken);
                lastError = $"{(int)response.StatusCode} {body}";

                // 404 / UNREGISTERED means the token is stale — deactivate it
                // so it is not retried on every future notification.
                if (response.StatusCode == System.Net.HttpStatusCode.NotFound
                    || body.Contains("UNREGISTERED", StringComparison.OrdinalIgnoreCase))
                {
                    await DeactivateTokenAsync(token, cancellationToken);
                }
            }
            catch (Exception ex)
            {
                lastError = ex.Message;
                _logger.LogWarning(ex, "FCM push failed for one device.");
            }
        }

        return sent switch
        {
            > 0 => new NotificationDispatchResult(NotificationDispatchStatus.Sent, sent),
            _ => new NotificationDispatchResult(NotificationDispatchStatus.Failed, 0, lastError),
        };
    }

    private async Task DeactivateTokenAsync(string token, CancellationToken cancellationToken)
    {
        var device = await _db.DeviceRegistrations
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(d => d.Token == token, cancellationToken);

        if (device is null) return;

        device.IsActive = false;
        await _db.SaveChangesAsync(cancellationToken);
    }

    private static object BuildPayload(string token, NotificationMessage message) => new
    {
        message = new
        {
            token,
            notification = new
            {
                title = message.Title,
                body = message.Body,
            },
            data = new Dictionary<string, string>
            {
                ["category"] = message.Category.ToString(),
                ["referenceType"] = message.ReferenceType ?? string.Empty,
                ["referenceId"] = message.ReferenceId?.ToString() ?? string.Empty,
            },
            android = new { priority = "high" },
        },
    };
}
