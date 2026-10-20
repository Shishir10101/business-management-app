namespace Khata.Infrastructure.Services;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Domain.Entities;
using Khata.Domain.Enums;
using Khata.Domain.Exceptions;
using Khata.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

/// <summary>
/// Product catalog: categories, units, products. Every query is tenant-scoped
/// by the DbContext global query filter (active business from the JWT); the
/// service additionally validates references (category/unit/SKU) within the
/// same business boundary.
/// </summary>
public class ProductService : IProductService
{
    /// <summary>Units seeded for a brand-new business so the catalog is usable immediately.</summary>
    public static readonly (string Name, string ShortName)[] DefaultUnits =
    [
        ("Piece", "pc"),
        ("Kilogram", "kg"),
        ("Gram", "g"),
        ("Litre", "L"),
        ("Box", "box"),
        ("Dozen", "dz"),
    ];

    public const string DefaultCategoryName = "General";

    private readonly KhataDbContext _db;
    private readonly ICurrentUserService _currentUser;
    private readonly IDateTimeProvider _clock;

    public ProductService(KhataDbContext db, ICurrentUserService currentUser, IDateTimeProvider clock)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
    }

    /// <summary>
    /// The caller's active business (JWT "bid" claim). Inserts carry this
    /// explicitly; queries are additionally tenant-scoped as defense in depth.
    /// </summary>
    private long BusinessId =>
        _currentUser.BusinessId ?? throw new UnauthorizedException();

    // --- Categories ---

    public async Task<IReadOnlyList<CategoryDto>> GetCategoriesAsync(CancellationToken cancellationToken = default)
    {
        var rows = await (
            from c in _db.ProductCategories
            where c.DeletedAt == null
            orderby c.Name
            select new
            {
                c.Id,
                c.Name,
                c.Description,
                c.ParentId,
                c.IsActive,
                ParentName = c.Parent == null ? null : c.Parent.Name,
                ProductCount = c.Products.Count(p => p.DeletedAt == null),
            }
        ).ToListAsync(cancellationToken);

        return rows.Select(x => new CategoryDto(
            x.Id, x.Name, x.Description, x.ParentId,
            x.ParentName, x.IsActive, x.ProductCount)).ToList();
    }

    public async Task<CategoryDto> GetCategoryAsync(long categoryId, CancellationToken cancellationToken = default)
    {
        var category = await LoadCategoryAsync(categoryId, cancellationToken);

        return new CategoryDto(
            category.Id, category.Name, category.Description, category.ParentId,
            category.Parent?.Name, category.IsActive,
            await CountProductsAsync(categoryId, cancellationToken));
    }

    public async Task<CategoryDto> CreateCategoryAsync(CreateCategoryRequest request, CancellationToken cancellationToken = default)
    {
        if (request.ParentId is { } parentId && !await CategoryExistsAsync(parentId, cancellationToken))
            throw new NotFoundException("ProductCategory", parentId);

        var category = new ProductCategory
        {
            BusinessId = BusinessId,
            Name = request.Name,
            Description = request.Description,
            ParentId = request.ParentId,
            IsActive = true,
        };
        _db.ProductCategories.Add(category);
        await _db.SaveChangesAsync(cancellationToken);

        return new CategoryDto(category.Id, category.Name, category.Description, category.ParentId,
            null, true, 0);
    }

    public async Task<CategoryDto> UpdateCategoryAsync(long categoryId, UpdateCategoryRequest request, CancellationToken cancellationToken = default)
    {
        var category = await LoadCategoryAsync(categoryId, cancellationToken);

        if (request.ParentId == categoryId)
            throw new BusinessRuleException("category_self_parent",
                "A category cannot be its own parent.");

        if (request.ParentId is { } parentId && !await CategoryExistsAsync(parentId, cancellationToken))
            throw new NotFoundException("ProductCategory", parentId);

        category.Name = request.Name;
        category.Description = request.Description;
        category.ParentId = request.ParentId;
        category.IsActive = request.IsActive;

        await _db.SaveChangesAsync(cancellationToken);

        var parentName = category.ParentId is null
            ? null
            : await _db.ProductCategories
                .Where(c => c.Id == category.ParentId)
                .Select(c => c.Name)
                .FirstOrDefaultAsync(cancellationToken);

        return new CategoryDto(category.Id, category.Name, category.Description, category.ParentId,
            parentName, category.IsActive, await CountProductsAsync(categoryId, cancellationToken));
    }

    public async Task DeleteCategoryAsync(long categoryId, CancellationToken cancellationToken = default)
    {
        var category = await LoadCategoryAsync(categoryId, cancellationToken);

        var hasChildren = await _db.ProductCategories
            .AnyAsync(c => c.ParentId == categoryId && c.DeletedAt == null, cancellationToken);
        if (hasChildren)
            throw new BusinessRuleException("category_has_children",
                "This category has sub-categories. Move or delete them first.");

        // Detach products from the category before soft-deleting it, so no live
        // product dangles at a deleted category.
        await DetachProductsAsync(p => p.CategoryId == categoryId, p => p.CategoryId = null, cancellationToken);

        _db.ProductCategories.Remove(category); // soft delete via DbContext
        await _db.SaveChangesAsync(cancellationToken);
    }

    // --- Units ---

    public async Task<IReadOnlyList<UnitDto>> GetUnitsAsync(CancellationToken cancellationToken = default)
    {
        var rows = await (
            from u in _db.Units
            where u.DeletedAt == null
            orderby u.Name
            select new
            {
                u.Id,
                u.Name,
                u.ShortName,
                u.IsActive,
                ProductCount = u.Products.Count(p => p.DeletedAt == null),
            }
        ).ToListAsync(cancellationToken);

        return rows.Select(x => new UnitDto(x.Id, x.Name, x.ShortName, x.IsActive, x.ProductCount)).ToList();
    }

    public async Task<UnitDto> CreateUnitAsync(CreateUnitRequest request, CancellationToken cancellationToken = default)
    {
        await EnsureUnitNameFreeAsync(request.Name, null, cancellationToken);

        var unit = new Unit
        {
            BusinessId = BusinessId,
            Name = request.Name,
            ShortName = request.ShortName,
            IsActive = true,
        };
        _db.Units.Add(unit);
        await _db.SaveChangesAsync(cancellationToken);

        return new UnitDto(unit.Id, unit.Name, unit.ShortName, true, 0);
    }

    public async Task<UnitDto> UpdateUnitAsync(long unitId, UpdateUnitRequest request, CancellationToken cancellationToken = default)
    {
        var unit = await LoadUnitAsync(unitId, cancellationToken);
        await EnsureUnitNameFreeAsync(request.Name, unitId, cancellationToken);

        unit.Name = request.Name;
        unit.ShortName = request.ShortName;
        unit.IsActive = request.IsActive;

        await _db.SaveChangesAsync(cancellationToken);

        return new UnitDto(unit.Id, unit.Name, unit.ShortName, unit.IsActive,
            await _db.Products.CountAsync(p => p.UnitId == unitId && p.DeletedAt == null, cancellationToken));
    }

    public async Task DeleteUnitAsync(long unitId, CancellationToken cancellationToken = default)
    {
        var unit = await LoadUnitAsync(unitId, cancellationToken);

        // Products keep working without a unit (UnitId becomes null).
        await DetachProductsAsync(p => p.UnitId == unitId, p => p.UnitId = null, cancellationToken);

        _db.Units.Remove(unit); // soft delete via DbContext
        await _db.SaveChangesAsync(cancellationToken);
    }

    // --- Products ---

    public async Task<PagedResult<ProductDto>> GetProductsAsync(ProductQuery query, CancellationToken cancellationToken = default)
    {
        var products = ApplyProductFilters(_db.Products.AsQueryable(), query);

        var total = await products.CountAsync(cancellationToken);

        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var rows = await products
            .OrderBy(p => p.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(p => new
            {
                p.Id,
                p.Name,
                p.CategoryId,
                CategoryName = p.Category == null ? null : p.Category.Name,
                p.UnitId,
                UnitShortName = p.Unit == null ? null : p.Unit.ShortName,
                p.Sku,
                p.Barcode,
                p.Description,
                p.CostPrice,
                p.SellingPrice,
                p.WholesalePrice,
                p.TaxRateBps,
                p.ImageUrl,
                p.IsActive,
                Quantity = p.Stock == null ? 0m : p.Stock.Quantity,
                MinQuantity = p.Stock == null ? 0m : p.Stock.MinQuantity,
                p.CreatedAt,
                p.UpdatedAt,
            })
            .ToListAsync(cancellationToken);

        return PagedResult<ProductDto>.Create(
            rows.Select(x => new ProductDto(
                x.Id, x.Name, x.CategoryId, x.CategoryName, x.UnitId, x.UnitShortName,
                x.Sku, x.Barcode, x.Description, x.CostPrice, x.SellingPrice, x.WholesalePrice,
                x.TaxRateBps, x.ImageUrl, x.IsActive, x.Quantity, x.MinQuantity,
                IsLowStock(x.Quantity, x.MinQuantity), x.CreatedAt, x.UpdatedAt)).ToList(),
            page, pageSize, total);
    }

    public async Task<ProductDto> GetProductAsync(long productId, CancellationToken cancellationToken = default)
    {
        var product = await LoadProductAsync(productId, cancellationToken);
        return ToDto(product);
    }

    public async Task<ProductDto> CreateProductAsync(CreateProductRequest request, CancellationToken cancellationToken = default)
    {
        if (request.CategoryId is { } categoryId && !await CategoryExistsAsync(categoryId, cancellationToken))
            throw new NotFoundException("ProductCategory", categoryId);
        if (request.UnitId is { } unitId && !await UnitExistsAsync(unitId, cancellationToken))
            throw new NotFoundException("Unit", unitId);
        await EnsureCodeFreeAsync(request.Sku, request.Barcode, null, cancellationToken);

        var product = new Product
        {
            BusinessId = BusinessId,
            Name = request.Name,
            CategoryId = request.CategoryId,
            UnitId = request.UnitId,
            Sku = string.IsNullOrWhiteSpace(request.Sku) ? null : request.Sku.Trim(),
            Barcode = string.IsNullOrWhiteSpace(request.Barcode) ? null : request.Barcode.Trim(),
            Description = request.Description,
            CostPrice = request.CostPrice,
            SellingPrice = request.SellingPrice,
            WholesalePrice = request.WholesalePrice,
            TaxRateBps = request.TaxRateBps,
            ImageUrl = request.ImageUrl,
            IsActive = request.IsActive,
        };
        _db.Products.Add(product);

        // Stock row is created with the product; an opening quantity (if any)
        // records the first movement of the product's ledger.
        var opening = request.OpeningQuantity;
        var stock = new ProductStock
        {
            BusinessId = BusinessId,
            Product = product,
            Quantity = opening,
            MinQuantity = request.MinQuantity,
        };
        _db.ProductStocks.Add(stock);

        if (opening > 0)
        {
            _db.StockMovements.Add(new StockMovement
            {
                BusinessId = BusinessId,
                Product = product,
                MovementType = StockMovementType.Opening,
                Quantity = opening,
                BalanceAfter = opening,
                Notes = "Opening stock",
                MovementDate = _clock.Today,
            });
        }

        // One SaveChanges: product + stock + opening movement commit atomically.
        await _db.SaveChangesAsync(cancellationToken);

        product.Stock = stock;
        return ToDto(product);
    }

    public async Task<ProductDto> UpdateProductAsync(long productId, UpdateProductRequest request, CancellationToken cancellationToken = default)
    {
        var product = await LoadProductAsync(productId, cancellationToken);

        if (request.CategoryId is { } categoryId && !await CategoryExistsAsync(categoryId, cancellationToken))
            throw new NotFoundException("ProductCategory", categoryId);
        if (request.UnitId is { } unitId && !await UnitExistsAsync(unitId, cancellationToken))
            throw new NotFoundException("Unit", unitId);
        await EnsureCodeFreeAsync(request.Sku, request.Barcode, productId, cancellationToken);

        product.Name = request.Name;
        product.CategoryId = request.CategoryId;
        product.UnitId = request.UnitId;
        product.Sku = string.IsNullOrWhiteSpace(request.Sku) ? null : request.Sku.Trim();
        product.Barcode = string.IsNullOrWhiteSpace(request.Barcode) ? null : request.Barcode.Trim();
        product.Description = request.Description;
        product.CostPrice = request.CostPrice;
        product.SellingPrice = request.SellingPrice;
        product.WholesalePrice = request.WholesalePrice;
        product.TaxRateBps = request.TaxRateBps;
        product.ImageUrl = request.ImageUrl;
        product.IsActive = request.IsActive;

        // Quantity itself never changes here — only via stock adjustments.
        if (product.Stock is null)
        {
            product.Stock = new ProductStock
            {
                BusinessId = BusinessId,
                ProductId = product.Id,
                Quantity = 0,
            };
            _db.ProductStocks.Add(product.Stock);
        }
        product.Stock.MinQuantity = request.MinQuantity;

        await _db.SaveChangesAsync(cancellationToken);

        return ToDto(product);
    }

    public async Task DeleteProductAsync(long productId, CancellationToken cancellationToken = default)
    {
        var product = await LoadProductAsync(productId, cancellationToken);

        // Soft delete. Stock movements and the stock row are kept: the movement
        // ledger is immutable and historical movements must survive.
        _db.Products.Remove(product);
        await _db.SaveChangesAsync(cancellationToken);
    }

    // --- helpers ---

    private static IQueryable<Product> ApplyProductFilters(IQueryable<Product> query, ProductQuery filter)
    {
        query = query.Where(p => p.DeletedAt == null);

        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var search = filter.Search.Trim().ToLower();
            query = query.Where(p =>
                p.Name.ToLower().Contains(search) ||
                (p.Sku != null && p.Sku.ToLower().Contains(search)) ||
                (p.Barcode != null && p.Barcode.ToLower().Contains(search)));
        }

        if (filter.CategoryId is { } categoryId)
            query = query.Where(p => p.CategoryId == categoryId);

        if (filter.IsActive is { } isActive)
            query = query.Where(p => p.IsActive == isActive);

        return query;
    }

    private static bool IsLowStock(decimal quantity, decimal minQuantity)
        => minQuantity > 0 && quantity <= minQuantity;

    private async Task<Product> LoadProductAsync(long productId, CancellationToken ct)
    {
        var product = await _db.Products
            .Include(p => p.Category)
            .Include(p => p.Unit)
            .Include(p => p.Stock)
            .FirstOrDefaultAsync(p => p.Id == productId && p.DeletedAt == null, ct);

        return product ?? throw new NotFoundException("Product", productId);
    }

    private async Task<ProductCategory> LoadCategoryAsync(long categoryId, CancellationToken ct)
    {
        var category = await _db.ProductCategories
            .Include(c => c.Parent)
            .FirstOrDefaultAsync(c => c.Id == categoryId && c.DeletedAt == null, ct);

        return category ?? throw new NotFoundException("ProductCategory", categoryId);
    }

    private async Task<Unit> LoadUnitAsync(long unitId, CancellationToken ct)
    {
        var unit = await _db.Units
            .FirstOrDefaultAsync(u => u.Id == unitId && u.DeletedAt == null, ct);

        return unit ?? throw new NotFoundException("Unit", unitId);
    }

    private Task<bool> CategoryExistsAsync(long categoryId, CancellationToken ct)
        => _db.ProductCategories.AnyAsync(c => c.Id == categoryId && c.DeletedAt == null, ct);

    private Task<bool> UnitExistsAsync(long unitId, CancellationToken ct)
        => _db.Units.AnyAsync(u => u.Id == unitId && u.DeletedAt == null, ct);

    private Task<int> CountProductsAsync(long categoryId, CancellationToken ct)
        => _db.Products.CountAsync(p => p.CategoryId == categoryId && p.DeletedAt == null, ct);

    /// <summary>SKU and barcode are unique per business when present (case-insensitive).</summary>
    private async Task EnsureCodeFreeAsync(string? sku, string? barcode, long? currentProductId, CancellationToken ct)
    {
        var normalizedSku = string.IsNullOrWhiteSpace(sku) ? null : sku.Trim().ToLower();
        var normalizedBarcode = string.IsNullOrWhiteSpace(barcode) ? null : barcode.Trim().ToLower();

        if (normalizedSku is not null && await _db.Products.AnyAsync(
                p => p.Sku != null && p.Sku.ToLower() == normalizedSku
                    && p.DeletedAt == null && p.Id != currentProductId, ct))
            throw new ConflictException($"SKU '{sku!.Trim()}' is already used by another product.");

        if (normalizedBarcode is not null && await _db.Products.AnyAsync(
                p => p.Barcode != null && p.Barcode.ToLower() == normalizedBarcode
                    && p.DeletedAt == null && p.Id != currentProductId, ct))
            throw new ConflictException($"Barcode '{barcode!.Trim()}' is already used by another product.");
    }

    private async Task EnsureUnitNameFreeAsync(string name, long? currentUnitId, CancellationToken ct)
    {
        var normalized = name.Trim().ToLower();
        if (await _db.Units.AnyAsync(
                u => u.Name.ToLower() == normalized && u.DeletedAt == null && u.Id != currentUnitId, ct))
            throw new ConflictException($"Unit '{name}' already exists.");
    }

    /// <summary>
    /// Clears a reference on products matching <paramref name="predicate"/> before the
    /// referenced entity is soft-deleted. Soft-deleted products are included too —
    /// no dangling references, even from history.
    /// </summary>
    private async Task DetachProductsAsync(
        System.Linq.Expressions.Expression<Func<Product, bool>> predicate,
        Action<Product> clearReference,
        CancellationToken ct)
    {
        var affected = await _db.Products.Where(predicate).ToListAsync(ct);
        foreach (var product in affected)
            clearReference(product);
    }

    private static ProductDto ToDto(Product p) => new(
        p.Id, p.Name, p.CategoryId, p.Category?.Name, p.UnitId, p.Unit?.ShortName,
        p.Sku, p.Barcode, p.Description, p.CostPrice, p.SellingPrice, p.WholesalePrice,
        p.TaxRateBps, p.ImageUrl, p.IsActive,
        p.Stock?.Quantity ?? 0, p.Stock?.MinQuantity ?? 0,
        IsLowStock(p.Stock?.Quantity ?? 0, p.Stock?.MinQuantity ?? 0),
        p.CreatedAt, p.UpdatedAt);
}
