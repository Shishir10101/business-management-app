namespace Khata.Api.Controllers;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>
/// The in-app notification feed, device registration, and per-user push
/// preferences. Notifications are personal: a user only ever sees their own.
/// </summary>
[ApiController]
[Route("api/notifications")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _notifications;

    public NotificationsController(INotificationService notifications)
    {
        _notifications = notifications;
    }

    /// <summary>The current user's notifications, newest first.</summary>
    [HttpGet]
    [Authorize(Policy = Permissions.NotificationsView)]
    [ProducesResponseType(typeof(PagedResult<NotificationDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<NotificationDto>>> GetAll(
        [FromQuery] NotificationQuery query)
        => Ok(await _notifications.GetNotificationsAsync(query));

    /// <summary>Unread badge count.</summary>
    [HttpGet("unread-count")]
    [Authorize(Policy = Permissions.NotificationsView)]
    [ProducesResponseType(typeof(UnreadCountDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<UnreadCountDto>> GetUnreadCount()
        => Ok(await _notifications.GetUnreadCountAsync());

    [HttpPost("{id:long}/read")]
    [Authorize(Policy = Permissions.NotificationsManage)]
    [ProducesResponseType(typeof(NotificationDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<NotificationDto>> MarkRead(long id)
        => Ok(await _notifications.MarkReadAsync(id));

    [HttpPost("read-all")]
    [Authorize(Policy = Permissions.NotificationsManage)]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> MarkAllRead()
    {
        var count = await _notifications.MarkAllReadAsync();
        return Ok(new { markedRead = count });
    }

    [HttpDelete("{id:long}")]
    [Authorize(Policy = Permissions.NotificationsManage)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Delete(long id)
    {
        await _notifications.DeleteAsync(id);
        return NoContent();
    }

    // --- Devices ---

    [HttpGet("devices")]
    [Authorize(Policy = Permissions.NotificationsView)]
    [ProducesResponseType(typeof(IReadOnlyList<DeviceDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<DeviceDto>>> GetDevices()
        => Ok(await _notifications.GetDevicesAsync());

    /// <summary>
    /// Registers (or refreshes) this device's FCM token. Idempotent per token.
    /// </summary>
    [HttpPost("devices")]
    [Authorize(Policy = Permissions.NotificationsManage)]
    [ProducesResponseType(typeof(DeviceDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<DeviceDto>> RegisterDevice([FromBody] RegisterDeviceRequest request)
    {
        var device = await _notifications.RegisterDeviceAsync(request);
        return CreatedAtAction(nameof(GetDevices), device);
    }

    [HttpDelete("devices")]
    [Authorize(Policy = Permissions.NotificationsManage)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> UnregisterDevice([FromQuery] string token)
    {
        await _notifications.UnregisterDeviceAsync(token);
        return NoContent();
    }

    // --- Settings ---

    [HttpGet("settings")]
    [Authorize(Policy = Permissions.NotificationsView)]
    [ProducesResponseType(typeof(NotificationSettingsDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<NotificationSettingsDto>> GetSettings()
        => Ok(await _notifications.GetSettingsAsync());

    [HttpPut("settings")]
    [Authorize(Policy = Permissions.NotificationsManage)]
    [ProducesResponseType(typeof(NotificationSettingsDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<NotificationSettingsDto>> UpdateSettings(
        [FromBody] UpdateNotificationSettingsRequest request)
        => Ok(await _notifications.UpdateSettingsAsync(request));
}
