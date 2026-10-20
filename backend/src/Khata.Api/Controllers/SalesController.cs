namespace Khata.Api.Controllers;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>Sales of the active business. Creating a sale posts stock, khata and
/// payment effects atomically; deleting one reverses them.</summary>
[ApiController]
[Route("api/sales")]
[Authorize]
public class SalesController : ControllerBase
{
    private readonly ISaleService _sales;

    public SalesController(ISaleService sales)
    {
        _sales = sales;
    }

    /// <summary>Lists sales. Search matches invoice number and customer name.</summary>
    [HttpGet]
    [Authorize(Policy = Permissions.SalesView)]
    [ProducesResponseType(typeof(PagedResult<SaleDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<SaleDto>>> GetSales(
        [FromQuery] long? customerId,
        [FromQuery] SaleType? saleType,
        [FromQuery] PaymentStatus? paymentStatus,
        [FromQuery] DateOnly? dateFrom,
        [FromQuery] DateOnly? dateTo,
        [FromQuery] string? search,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var query = new SaleQuery(customerId, saleType, paymentStatus, dateFrom, dateTo, search, page, pageSize);
        return Ok(await _sales.GetSalesAsync(query));
    }

    /// <summary>Gets one sale with its line items.</summary>
    [HttpGet("{id:long}")]
    [Authorize(Policy = Permissions.SalesView)]
    [ProducesResponseType(typeof(SaleDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<SaleDto>> GetSale(long id)
        => Ok(await _sales.GetSaleAsync(id));

    /// <summary>
    /// Creates a sale: allocates an invoice number, decrements stock, and records
    /// the credit portion on the customer's khata — all in one transaction.
    /// </summary>
    [HttpPost]
    [Authorize(Policy = Permissions.SalesCreate)]
    [ProducesResponseType(typeof(SaleDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status422UnprocessableEntity)]
    public async Task<ActionResult<SaleDto>> Create([FromBody] CreateSaleRequest request)
    {
        var sale = await _sales.CreateSaleAsync(request);
        return CreatedAtAction(nameof(GetSale), new { id = sale.Id }, sale);
    }

    /// <summary>Reverses a sale (stock restored, ledger credited back) and soft-deletes it.</summary>
    [HttpDelete("{id:long}")]
    [Authorize(Policy = Permissions.SalesDelete)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(long id)
    {
        await _sales.DeleteSaleAsync(id);
        return NoContent();
    }
}
