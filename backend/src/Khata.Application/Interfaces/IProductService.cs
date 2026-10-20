namespace Khata.Application.Interfaces;

using Khata.Application.Common;
using Khata.Application.DTOs;

/// <summary>
/// Product catalog: categories, units of measure, and products.
/// All operations are scoped to the caller's ACTIVE business (JWT "bid" claim
/// via the EF Core global query filter) — no cross-business access is possible.
/// </summary>
public interface IProductService
{
    // Categories
    Task<IReadOnlyList<CategoryDto>> GetCategoriesAsync(CancellationToken cancellationToken = default);
    Task<CategoryDto> GetCategoryAsync(long categoryId, CancellationToken cancellationToken = default);
    Task<CategoryDto> CreateCategoryAsync(CreateCategoryRequest request, CancellationToken cancellationToken = default);
    Task<CategoryDto> UpdateCategoryAsync(long categoryId, UpdateCategoryRequest request, CancellationToken cancellationToken = default);
    Task DeleteCategoryAsync(long categoryId, CancellationToken cancellationToken = default);

    // Units
    Task<IReadOnlyList<UnitDto>> GetUnitsAsync(CancellationToken cancellationToken = default);
    Task<UnitDto> CreateUnitAsync(CreateUnitRequest request, CancellationToken cancellationToken = default);
    Task<UnitDto> UpdateUnitAsync(long unitId, UpdateUnitRequest request, CancellationToken cancellationToken = default);
    Task DeleteUnitAsync(long unitId, CancellationToken cancellationToken = default);

    // Products
    Task<PagedResult<ProductDto>> GetProductsAsync(ProductQuery query, CancellationToken cancellationToken = default);
    Task<ProductDto> GetProductAsync(long productId, CancellationToken cancellationToken = default);
    Task<ProductDto> CreateProductAsync(CreateProductRequest request, CancellationToken cancellationToken = default);
    Task<ProductDto> UpdateProductAsync(long productId, UpdateProductRequest request, CancellationToken cancellationToken = default);
    Task DeleteProductAsync(long productId, CancellationToken cancellationToken = default);
}
