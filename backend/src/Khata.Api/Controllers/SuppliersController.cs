namespace Khata.Api.Controllers;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>Suppliers of the active business and their digital khata ledgers.</summary>
[ApiController]
[Route("api/suppliers")]
[Authorize]
public class SuppliersController : ControllerBase
{
    private readonly IPartyService _partyService;

    public SuppliersController(IPartyService partyService)
    {
        _partyService = partyService;
    }

    /// <summary>Lists suppliers with current khata balances. Search matches name and phone.</summary>
    [HttpGet]
    [Authorize(Policy = Permissions.SuppliersView)]
    [ProducesResponseType(typeof(PagedResult<SupplierDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<SupplierDto>>> GetSuppliers(
        [FromQuery] string? search,
        [FromQuery] bool? isActive,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var query = new PartyQuery(search, isActive, page, pageSize);
        return Ok(await _partyService.GetSuppliersAsync(query));
    }

    /// <summary>Gets a supplier by id with its current balance.</summary>
    [HttpGet("{id:long}")]
    [Authorize(Policy = Permissions.SuppliersView)]
    [ProducesResponseType(typeof(SupplierDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SupplierDto>> GetSupplier(long id)
        => Ok(await _partyService.GetSupplierAsync(id));

    /// <summary>
    /// Creates a supplier. A non-zero opening balance immediately creates the
    /// ledger account and its opening transaction.
    /// </summary>
    [HttpPost]
    [Authorize(Policy = Permissions.SuppliersCreate)]
    [ProducesResponseType(typeof(SupplierDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<SupplierDto>> Create([FromBody] CreateSupplierRequest request)
    {
        var supplier = await _partyService.CreateSupplierAsync(request);
        return CreatedAtAction(nameof(GetSupplier), new { id = supplier.Id }, supplier);
    }

    /// <summary>
    /// Updates a supplier. Changing the opening balance appends an adjustment
    /// transaction to the ledger (history is never rewritten).
    /// </summary>
    [HttpPut("{id:long}")]
    [Authorize(Policy = Permissions.SuppliersEdit)]
    [ProducesResponseType(typeof(SupplierDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SupplierDto>> Update(long id, [FromBody] UpdateSupplierRequest request)
        => Ok(await _partyService.UpdateSupplierAsync(id, request));

    /// <summary>Soft-deletes a supplier. Ledger history is preserved.</summary>
    [HttpDelete("{id:long}")]
    [Authorize(Policy = Permissions.SuppliersEdit)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(long id)
    {
        await _partyService.DeleteSupplierAsync(id);
        return NoContent();
    }

    /// <summary>
    /// Supplier khata ledger: summary (opening, debit, credit, closing) plus
    /// paged immutable transactions, newest first.
    /// </summary>
    [HttpGet("{id:long}/ledger")]
    [Authorize(Policy = Permissions.SuppliersView)]
    [ProducesResponseType(typeof(PartyLedgerDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PartyLedgerDto>> GetLedger(
        long id,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
        => Ok(await _partyService.GetSupplierLedgerAsync(id, page, pageSize));
}
