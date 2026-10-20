namespace Khata.Api.Controllers;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>Purchases of the active business. Creating a purchase posts stock,
/// khata and payment effects atomically; deleting one reverses them.</summary>
[ApiController]
[Route("api/purchases")]
[Authorize]
public class PurchasesController : ControllerBase
{
    private readonly IPurchaseService _purchases;

    public PurchasesController(IPurchaseService purchases)
    {
        _purchases = purchases;
    }

    /// <summary>Lists purchases. Search matches bill number and supplier name.</summary>
    [HttpGet]
    [Authorize(Policy = Permissions.PurchaseView)]
    [ProducesResponseType(typeof(PagedResult<PurchaseDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<PurchaseDto>>> GetPurchases(
        [FromQuery] long? supplierId,
        [FromQuery] PurchaseType? purchaseType,
        [FromQuery] PaymentStatus? paymentStatus,
        [FromQuery] DateOnly? dateFrom,
        [FromQuery] DateOnly? dateTo,
        [FromQuery] string? search,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var query = new PurchaseQuery(supplierId, purchaseType, paymentStatus, dateFrom, dateTo, search, page, pageSize);
        return Ok(await _purchases.GetPurchasesAsync(query));
    }

    /// <summary>Gets one purchase with its line items.</summary>
    [HttpGet("{id:long}")]
    [Authorize(Policy = Permissions.PurchaseView)]
    [ProducesResponseType(typeof(PurchaseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PurchaseDto>> GetPurchase(long id)
        => Ok(await _purchases.GetPurchaseAsync(id));

    /// <summary>
    /// Creates a purchase: allocates a bill number, increases stock, and records
    /// the credit portion on the supplier's khata — all in one transaction.
    /// </summary>
    [HttpPost]
    [Authorize(Policy = Permissions.PurchaseCreate)]
    [ProducesResponseType(typeof(PurchaseDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status422UnprocessableEntity)]
    public async Task<ActionResult<PurchaseDto>> Create([FromBody] CreatePurchaseRequest request)
    {
        var purchase = await _purchases.CreatePurchaseAsync(request);
        return CreatedAtAction(nameof(GetPurchase), new { id = purchase.Id }, purchase);
    }

    /// <summary>Reverses a purchase (stock removed, payable credited back) and soft-deletes it.</summary>
    [HttpDelete("{id:long}")]
    [Authorize(Policy = Permissions.PurchaseDelete)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(long id)
    {
        await _purchases.DeletePurchaseAsync(id);
        return NoContent();
    }
}
