namespace Khata.Api.Controllers;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>Units of measure of the active business (tenant-scoped).</summary>
[ApiController]
[Route("api/units")]
[Authorize]
public class UnitsController : ControllerBase
{
    private readonly IProductService _productService;

    public UnitsController(IProductService productService)
    {
        _productService = productService;
    }

    /// <summary>Lists all units of the active business.</summary>
    [HttpGet]
    [Authorize(Policy = Permissions.ProductsView)]
    [ProducesResponseType(typeof(IReadOnlyList<UnitDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<UnitDto>>> GetUnits()
        => Ok(await _productService.GetUnitsAsync());

    /// <summary>Creates a unit. Name must be unique within the business (409).</summary>
    [HttpPost]
    [Authorize(Policy = Permissions.ProductsCreate)]
    [ProducesResponseType(typeof(UnitDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<ActionResult<UnitDto>> Create([FromBody] CreateUnitRequest request)
    {
        var unit = await _productService.CreateUnitAsync(request);
        return CreatedAtAction(nameof(GetUnits), new { }, unit);
    }

    /// <summary>Updates a unit.</summary>
    [HttpPut("{id:long}")]
    [Authorize(Policy = Permissions.ProductsEdit)]
    [ProducesResponseType(typeof(UnitDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<ActionResult<UnitDto>> Update(long id, [FromBody] UpdateUnitRequest request)
        => Ok(await _productService.UpdateUnitAsync(id, request));

    /// <summary>Soft-deletes a unit. Products keep working without a unit.</summary>
    [HttpDelete("{id:long}")]
    [Authorize(Policy = Permissions.ProductsEdit)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(long id)
    {
        await _productService.DeleteUnitAsync(id);
        return NoContent();
    }
}
