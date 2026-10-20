namespace Khata.Api.Controllers;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>Customers of the active business and their digital khata ledgers.</summary>
[ApiController]
[Route("api/customers")]
[Authorize]
public class CustomersController : ControllerBase
{
    private readonly IPartyService _partyService;

    public CustomersController(IPartyService partyService)
    {
        _partyService = partyService;
    }

    /// <summary>Lists customers with current khata balances. Search matches name and phone.</summary>
    [HttpGet]
    [Authorize(Policy = Permissions.CustomersView)]
    [ProducesResponseType(typeof(PagedResult<CustomerDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<CustomerDto>>> GetCustomers(
        [FromQuery] string? search,
        [FromQuery] bool? isActive,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var query = new PartyQuery(search, isActive, page, pageSize);
        return Ok(await _partyService.GetCustomersAsync(query));
    }

    /// <summary>Gets a customer by id with its current balance.</summary>
    [HttpGet("{id:long}")]
    [Authorize(Policy = Permissions.CustomersView)]
    [ProducesResponseType(typeof(CustomerDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CustomerDto>> GetCustomer(long id)
        => Ok(await _partyService.GetCustomerAsync(id));

    /// <summary>
    /// Creates a customer. A non-zero opening balance immediately creates the
    /// ledger account and its opening transaction.
    /// </summary>
    [HttpPost]
    [Authorize(Policy = Permissions.CustomersCreate)]
    [ProducesResponseType(typeof(CustomerDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<CustomerDto>> Create([FromBody] CreateCustomerRequest request)
    {
        var customer = await _partyService.CreateCustomerAsync(request);
        return CreatedAtAction(nameof(GetCustomer), new { id = customer.Id }, customer);
    }

    /// <summary>
    /// Updates a customer. Changing the opening balance appends an adjustment
    /// transaction to the ledger (history is never rewritten).
    /// </summary>
    [HttpPut("{id:long}")]
    [Authorize(Policy = Permissions.CustomersEdit)]
    [ProducesResponseType(typeof(CustomerDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CustomerDto>> Update(long id, [FromBody] UpdateCustomerRequest request)
        => Ok(await _partyService.UpdateCustomerAsync(id, request));

    /// <summary>Soft-deletes a customer. Ledger history is preserved.</summary>
    [HttpDelete("{id:long}")]
    [Authorize(Policy = Permissions.CustomersEdit)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(long id)
    {
        await _partyService.DeleteCustomerAsync(id);
        return NoContent();
    }

    /// <summary>
    /// Customer khata ledger: summary (opening, debit, credit, closing) plus
    /// paged immutable transactions, newest first.
    /// </summary>
    [HttpGet("{id:long}/ledger")]
    [Authorize(Policy = Permissions.CustomersView)]
    [ProducesResponseType(typeof(PartyLedgerDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PartyLedgerDto>> GetLedger(
        long id,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
        => Ok(await _partyService.GetCustomerLedgerAsync(id, page, pageSize));
}
