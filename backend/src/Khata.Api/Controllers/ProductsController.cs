namespace Khata.Api.Controllers;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>Product catalog of the active business (tenant-scoped).</summary>
/// <remarks>
/// Prices are integer paisa (रु 199.00 = 19900); taxRateBps is basis points
/// (1300 = 13%). Stock quantity is only changed through
/// <c>POST /api/inventory/{productId}/adjust</c>, never through product edit.
/// </remarks>
[ApiController]
[Route("api/products")]
[Authorize]
public class ProductsController : ControllerBase
{
    private readonly IProductService _productService;

    public ProductsController(IProductService productService)
    {
        _productService = productService;
    }

    /// <summary>
    /// Lists products with their current stock. Search matches name, SKU and
    /// barcode (case-insensitive). Supports category and active filters + paging.
    /// </summary>
    [HttpGet]
    [Authorize(Policy = Permissions.ProductsView)]
    [ProducesResponseType(typeof(PagedResult<ProductDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<ProductDto>>> GetProducts(
        [FromQuery] string? search,
        [FromQuery] long? categoryId,
        [FromQuery] bool? isActive,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var query = new ProductQuery(search, categoryId, isActive, page, pageSize);
        return Ok(await _productService.GetProductsAsync(query));
    }

    /// <summary>Gets a product by id.</summary>
    [HttpGet("{id:long}")]
    [Authorize(Policy = Permissions.ProductsView)]
    [ProducesResponseType(typeof(ProductDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ProductDto>> GetProduct(long id)
        => Ok(await _productService.GetProductAsync(id));

    /// <summary>
    /// Creates a product. An opening quantity &gt; 0 records the first
    /// "opening" stock movement in the same transaction.
    /// </summary>
    [HttpPost]
    [Authorize(Policy = Permissions.ProductsCreate)]
    [ProducesResponseType(typeof(ProductDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<ActionResult<ProductDto>> Create([FromBody] CreateProductRequest request)
    {
        var product = await _productService.CreateProductAsync(request);
        return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, product);
    }

    /// <summary>Updates a product (stock quantity is NOT editable here).</summary>
    [HttpPut("{id:long}")]
    [Authorize(Policy = Permissions.ProductsEdit)]
    [ProducesResponseType(typeof(ProductDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<ActionResult<ProductDto>> Update(long id, [FromBody] UpdateProductRequest request)
        => Ok(await _productService.UpdateProductAsync(id, request));

    /// <summary>
    /// Soft-deletes a product. Stock movements are kept — the movement ledger
    /// is immutable and history must survive.
    /// </summary>
    [HttpDelete("{id:long}")]
    [Authorize(Policy = Permissions.ProductsEdit)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(long id)
    {
        await _productService.DeleteProductAsync(id);
        return NoContent();
    }
}
