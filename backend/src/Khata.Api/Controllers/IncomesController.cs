namespace Khata.Api.Controllers;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>Non-sale income of the active business.</summary>
[ApiController]
[Route("api/incomes")]
[Authorize]
public class IncomesController : ControllerBase
{
    private readonly IIncomeService _incomes;

    public IncomesController(IIncomeService incomes)
    {
        _incomes = incomes;
    }

    /// <summary>Lists income entries. Search matches source, description and reference.</summary>
    [HttpGet]
    [Authorize(Policy = Permissions.IncomeView)]
    [ProducesResponseType(typeof(PagedResult<IncomeDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<IncomeDto>>> GetIncomes(
        [FromQuery] string? search,
        [FromQuery] string? source,
        [FromQuery] DateOnly? dateFrom,
        [FromQuery] DateOnly? dateTo,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var query = new IncomeQuery(search, source, dateFrom, dateTo, page, pageSize);
        return Ok(await _incomes.GetIncomesAsync(query));
    }

    [HttpGet("{id:long}")]
    [Authorize(Policy = Permissions.IncomeView)]
    [ProducesResponseType(typeof(IncomeDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IncomeDto>> GetIncome(long id)
        => Ok(await _incomes.GetIncomeAsync(id));

    [HttpPost]
    [Authorize(Policy = Permissions.IncomeCreate)]
    [ProducesResponseType(typeof(IncomeDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<IncomeDto>> Create([FromBody] CreateIncomeRequest request)
    {
        var income = await _incomes.CreateIncomeAsync(request);
        return CreatedAtAction(nameof(GetIncome), new { id = income.Id }, income);
    }

    [HttpPut("{id:long}")]
    [Authorize(Policy = Permissions.IncomeEdit)]
    [ProducesResponseType(typeof(IncomeDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IncomeDto>> Update(long id, [FromBody] UpdateIncomeRequest request)
        => Ok(await _incomes.UpdateIncomeAsync(id, request));

    [HttpDelete("{id:long}")]
    [Authorize(Policy = Permissions.IncomeEdit)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(long id)
    {
        await _incomes.DeleteIncomeAsync(id);
        return NoContent();
    }
}
