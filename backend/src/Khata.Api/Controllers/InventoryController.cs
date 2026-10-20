namespace Khata.Api.Controllers;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>
/// Inventory: stock levels, low-stock alerts, signed adjustments and the
/// immutable movement history. All scoped to the active business.
/// </summary>
[ApiController]
[Route("api/inventory")]
[Authorize]
public class InventoryController : ControllerBase
{
    private readonly IInventoryService _inventoryService;

    public InventoryController(IInventoryService inventoryService)
    {
        _inventoryService = inventoryService;
    }

    /// <summary>
    /// Stock list (products + current quantity). lowStockOnly=true restricts to
    /// products at/below their minimum; sortBy=quantity orders by stock level.
    /// </summary>
    [HttpGet]
    [Authorize(Policy = Permissions.InventoryView)]
    [ProducesResponseType(typeof(PagedResult<ProductDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<ProductDto>>> GetInventory(
        [FromQuery] string? search,
        [FromQuery] bool lowStockOnly = false,
        [FromQuery] string? sortBy = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var query = new InventoryQuery(search, lowStockOnly, sortBy, page, pageSize);
        return Ok(await _inventoryService.GetInventoryAsync(query));
    }

    /// <summary>Products at or below their minimum quantity (low-stock alerts).</summary>
    [HttpGet("low-stock")]
    [Authorize(Policy = Permissions.InventoryView)]
    [ProducesResponseType(typeof(IReadOnlyList<ProductDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<ProductDto>>> GetLowStock()
        => Ok(await _inventoryService.GetLowStockAsync());

    /// <summary>
    /// Applies a signed stock adjustment (positive = in, negative = out).
    /// Appends an immutable movement; rejects negative stock with 422.
    /// </summary>
    [HttpPost("{productId:long}/adjust")]
    [Authorize(Policy = Permissions.InventoryAdjust)]
    [ProducesResponseType(typeof(AdjustStockResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status422UnprocessableEntity)]
    public async Task<ActionResult<AdjustStockResponse>> Adjust(long productId, [FromBody] AdjustStockRequest request)
        => Ok(await _inventoryService.AdjustStockAsync(productId, request));

    /// <summary>Append-only stock movement history for a product, newest first.</summary>
    [HttpGet("{productId:long}/movements")]
    [Authorize(Policy = Permissions.InventoryView)]
    [ProducesResponseType(typeof(PagedResult<StockMovementDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PagedResult<StockMovementDto>>> GetMovements(
        long productId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
        => Ok(await _inventoryService.GetMovementsAsync(productId, page, pageSize));
}
