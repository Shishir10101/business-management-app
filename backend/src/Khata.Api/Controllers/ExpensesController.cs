namespace Khata.Api.Controllers;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>Operating expenses of the active business.</summary>
[ApiController]
[Route("api/expenses")]
[Authorize]
public class ExpensesController : ControllerBase
{
    private readonly IExpenseService _expenses;

    public ExpensesController(IExpenseService expenses)
    {
        _expenses = expenses;
    }

    /// <summary>Lists expenses. Search matches category, description and reference.</summary>
    [HttpGet]
    [Authorize(Policy = Permissions.ExpensesView)]
    [ProducesResponseType(typeof(PagedResult<ExpenseDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<ExpenseDto>>> GetExpenses(
        [FromQuery] string? search,
        [FromQuery] string? category,
        [FromQuery] DateOnly? dateFrom,
        [FromQuery] DateOnly? dateTo,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var query = new ExpenseQuery(search, category, dateFrom, dateTo, page, pageSize);
        return Ok(await _expenses.GetExpensesAsync(query));
    }

    [HttpGet("{id:long}")]
    [Authorize(Policy = Permissions.ExpensesView)]
    [ProducesResponseType(typeof(ExpenseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ExpenseDto>> GetExpense(long id)
        => Ok(await _expenses.GetExpenseAsync(id));

    [HttpPost]
    [Authorize(Policy = Permissions.ExpensesCreate)]
    [ProducesResponseType(typeof(ExpenseDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<ExpenseDto>> Create([FromBody] CreateExpenseRequest request)
    {
        var expense = await _expenses.CreateExpenseAsync(request);
        return CreatedAtAction(nameof(GetExpense), new { id = expense.Id }, expense);
    }

    [HttpPut("{id:long}")]
    [Authorize(Policy = Permissions.ExpensesEdit)]
    [ProducesResponseType(typeof(ExpenseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ExpenseDto>> Update(long id, [FromBody] UpdateExpenseRequest request)
        => Ok(await _expenses.UpdateExpenseAsync(id, request));

    [HttpDelete("{id:long}")]
    [Authorize(Policy = Permissions.ExpensesEdit)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(long id)
    {
        await _expenses.DeleteExpenseAsync(id);
        return NoContent();
    }
}
