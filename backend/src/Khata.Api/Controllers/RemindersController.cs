namespace Khata.Api.Controllers;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>
/// Dated to-dos for the business, plus the engine endpoint that fires
/// everything that has come due.
/// </summary>
[ApiController]
[Route("api/reminders")]
[Authorize]
public class RemindersController : ControllerBase
{
    private readonly IReminderService _reminders;

    public RemindersController(IReminderService reminders)
    {
        _reminders = reminders;
    }

    [HttpGet]
    [Authorize(Policy = Permissions.RemindersView)]
    [ProducesResponseType(typeof(PagedResult<ReminderDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<ReminderDto>>> GetAll([FromQuery] ReminderQuery query)
        => Ok(await _reminders.GetRemindersAsync(query));

    [HttpGet("{id:long}")]
    [Authorize(Policy = Permissions.RemindersView)]
    [ProducesResponseType(typeof(ReminderDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ReminderDto>> Get(long id)
        => Ok(await _reminders.GetReminderAsync(id));

    [HttpPost]
    [Authorize(Policy = Permissions.RemindersManage)]
    [ProducesResponseType(typeof(ReminderDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<ReminderDto>> Create([FromBody] CreateReminderRequest request)
    {
        var reminder = await _reminders.CreateReminderAsync(request);
        return CreatedAtAction(nameof(Get), new { id = reminder.Id }, reminder);
    }

    [HttpPut("{id:long}")]
    [Authorize(Policy = Permissions.RemindersManage)]
    [ProducesResponseType(typeof(ReminderDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ReminderDto>> Update(long id, [FromBody] UpdateReminderRequest request)
        => Ok(await _reminders.UpdateReminderAsync(id, request));

    [HttpPost("{id:long}/complete")]
    [Authorize(Policy = Permissions.RemindersManage)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Complete(long id)
    {
        await _reminders.CompleteReminderAsync(id);
        return NoContent();
    }

    [HttpPost("{id:long}/dismiss")]
    [Authorize(Policy = Permissions.RemindersManage)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Dismiss(long id)
    {
        await _reminders.DismissReminderAsync(id);
        return NoContent();
    }

    [HttpDelete("{id:long}")]
    [Authorize(Policy = Permissions.RemindersManage)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Delete(long id)
    {
        await _reminders.DeleteReminderAsync(id);
        return NoContent();
    }

    /// <summary>
    /// Fires every due reminder (notification + best-effort push). Exposed so
    /// the mobile client can flush due reminders on app start, and so a
    /// deployment without background jobs still delivers them.
    /// </summary>
    [HttpPost("process-due")]
    [Authorize(Policy = Permissions.RemindersManage)]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> ProcessDue()
    {
        var fired = await _reminders.ProcessDueRemindersAsync();
        return Ok(new { fired });
    }
}
