namespace Khata.Api.Controllers;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>
/// Business data backup: export a full JSON snapshot of the active business,
/// and restore one into it. Restore merges — existing ids are skipped, never
/// overwritten.
/// </summary>
[ApiController]
[Route("api/backup")]
[Authorize]
public class BackupController : ControllerBase
{
    private readonly IBackupService _backup;

    public BackupController(IBackupService backup)
    {
        _backup = backup;
    }

    /// <summary>Full JSON snapshot of the active business, as a file download.</summary>
    [HttpGet("export")]
    [Authorize(Policy = Permissions.BackupView)]
    [ProducesResponseType(typeof(BackupExportDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<BackupExportDto>> Export()
    {
        var backup = await _backup.ExportAsync();
        var fileName = $"khata-backup-{backup.BusinessId}-{DateTime.UtcNow:yyyyMMdd-HHmmss}.json";
        return File(
            System.Text.Json.JsonSerializer.SerializeToUtf8Bytes(backup, JsonOptions),
            "application/json",
            fileName);
    }

    /// <summary>
    /// Restores a snapshot into the active business. Rows whose id already
    /// exists are skipped (merge semantics; money rows are immutable).
    /// </summary>
    [HttpPost("restore")]
    [Authorize(Policy = Permissions.BackupManage)]
    [ProducesResponseType(typeof(BackupRestoreResultDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<BackupRestoreResultDto>> Restore([FromBody] BackupExportDto backup)
        => Ok(await _backup.RestoreAsync(backup));

    private static readonly System.Text.Json.JsonSerializerOptions JsonOptions = new(NewtonsoftCompat)
    {
        Converters = { new System.Text.Json.Serialization.JsonStringEnumConverter() },
        WriteIndented = false,
    };

    private const System.Text.Json.JsonSerializerDefaults NewtonsoftCompat =
        System.Text.Json.JsonSerializerDefaults.Web;
}
