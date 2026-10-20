namespace Khata.Api.Controllers;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>Product categories of the active business (tenant-scoped).</summary>
[ApiController]
[Route("api/categories")]
[Authorize]
public class CategoriesController : ControllerBase
{
    private readonly IProductService _productService;

    public CategoriesController(IProductService productService)
    {
        _productService = productService;
    }

    /// <summary>Lists all categories of the active business.</summary>
    [HttpGet]
    [Authorize(Policy = Permissions.ProductsView)]
    [ProducesResponseType(typeof(IReadOnlyList<CategoryDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<CategoryDto>>> GetCategories()
        => Ok(await _productService.GetCategoriesAsync());

    /// <summary>Gets a category by id.</summary>
    [HttpGet("{id:long}")]
    [Authorize(Policy = Permissions.ProductsView)]
    [ProducesResponseType(typeof(CategoryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CategoryDto>> GetCategory(long id)
        => Ok(await _productService.GetCategoryAsync(id));

    /// <summary>Creates a category.</summary>
    [HttpPost]
    [Authorize(Policy = Permissions.ProductsCreate)]
    [ProducesResponseType(typeof(CategoryDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CategoryDto>> Create([FromBody] CreateCategoryRequest request)
    {
        var category = await _productService.CreateCategoryAsync(request);
        return CreatedAtAction(nameof(GetCategory), new { id = category.Id }, category);
    }

    /// <summary>Updates a category.</summary>
    [HttpPut("{id:long}")]
    [Authorize(Policy = Permissions.ProductsEdit)]
    [ProducesResponseType(typeof(CategoryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status422UnprocessableEntity)]
    public async Task<ActionResult<CategoryDto>> Update(long id, [FromBody] UpdateCategoryRequest request)
        => Ok(await _productService.UpdateCategoryAsync(id, request));

    /// <summary>Soft-deletes a category. Fails with 422 if it still has sub-categories.</summary>
    [HttpDelete("{id:long}")]
    [Authorize(Policy = Permissions.ProductsEdit)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> Delete(long id)
    {
        await _productService.DeleteCategoryAsync(id);
        return NoContent();
    }
}
