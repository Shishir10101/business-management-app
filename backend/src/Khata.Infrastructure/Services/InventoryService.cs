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
/// Inventory: stock levels, signed manual adjustments (which append immutable
/// stock movements) and movement history. Tenant-scoped by the active business
/// (JWT "bid") via the global query filter, plus explicit predicates.
/// </summary>
public class InventoryService : IInventoryService
{
    private readonly KhataDbContext _db;
    private readonly ICurrentUserService _currentUser;
    private readonly IDateTimeProvider _clock;

    public InventoryService(KhataDbContext db, ICurrentUserService currentUser, IDateTimeProvider clock)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
    }

    private long BusinessId =>
        _currentUser.BusinessId ?? throw new UnauthorizedException();

    public async Task<PagedResult<ProductDto>> GetInventoryAsync(InventoryQuery query, CancellationToken cancellationToken = default)
    {
        var products = _db.Products
            .Where(p => p.DeletedAt == null && p.BusinessId == BusinessId);

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            products = products.Where(p =>
                p.Name.ToLower().Contains(search) ||
                (p.Sku != null && p.Sku.ToLower().Contains(search)) ||
                (p.Barcode != null && p.Barcode.ToLower().Contains(search)));
        }

        if (query.LowStockOnly)
            products = products.Where(p => p.Stock != null
                && p.Stock.Quantity <= p.Stock.MinQuantity && p.Stock.MinQuantity > 0);

        var total = await products.CountAsync(cancellationToken);

        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var sorted = query.SortBy?.ToLower() switch
        {
            "quantity" => products.OrderBy(p => p.Stock == null ? 0m : p.Stock.Quantity),
            _ => products.OrderBy(p => p.Name),
        };

        var rows = await sorted
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

    public async Task<IReadOnlyList<ProductDto>> GetLowStockAsync(CancellationToken cancellationToken = default)
    {
        var rows = await (
            from p in _db.Products
            where p.DeletedAt == null && p.BusinessId == BusinessId
                && p.Stock != null
                && p.Stock.Quantity <= p.Stock.MinQuantity && p.Stock.MinQuantity > 0
            orderby (p.Stock == null ? 0m : p.Stock.Quantity)
            select new
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
            }
        ).ToListAsync(cancellationToken);

        return rows.Select(x => new ProductDto(
            x.Id, x.Name, x.CategoryId, x.CategoryName, x.UnitId, x.UnitShortName,
            x.Sku, x.Barcode, x.Description, x.CostPrice, x.SellingPrice, x.WholesalePrice,
            x.TaxRateBps, x.ImageUrl, x.IsActive, x.Quantity, x.MinQuantity,
            IsLowStock(x.Quantity, x.MinQuantity), x.CreatedAt, x.UpdatedAt)).ToList();
    }

    public async Task<AdjustStockResponse> AdjustStockAsync(long productId, AdjustStockRequest request, CancellationToken cancellationToken = default)
    {
        var product = await _db.Products
            .Include(p => p.Stock)
            .FirstOrDefaultAsync(p => p.Id == productId && p.DeletedAt == null
                && p.BusinessId == BusinessId, cancellationToken)
            ?? throw new NotFoundException("Product", productId);

        // Legacy products (created before stock rows) get one on first adjustment.
        if (product.Stock is null)
        {
            product.Stock = new ProductStock
            {
                BusinessId = BusinessId,
                ProductId = product.Id,
                Quantity = 0,
                MinQuantity = 0,
            };
            _db.ProductStocks.Add(product.Stock);
        }

        var before = product.Stock.Quantity;
        var after = before + request.Quantity;

        if (after < 0)
            throw new InsufficientStockException(product.Name, before, -request.Quantity);

        var movementType = request.Quantity > 0 ? StockMovementType.AdjustmentIn : StockMovementType.AdjustmentOut;
        var movement = new StockMovement
        {
            BusinessId = BusinessId,
            ProductId = product.Id,
            MovementType = movementType,
            Quantity = request.Quantity,
            BalanceAfter = after,
            ReferenceType = "adjustment",
            Notes = request.Notes,
            MovementDate = _clock.Today,
        };
        _db.StockMovements.Add(movement);

        product.Stock.Quantity = after;

        // One SaveChanges: the cached stock row and the immutable movement
        // commit together or not at all.
        await _db.SaveChangesAsync(cancellationToken);

        return new AdjustStockResponse(
            product.Id, product.Name, after, product.Stock.MinQuantity,
            new StockMovementDto(
                movement.Id, product.Id, product.Name, movement.MovementType,
                movement.Quantity, movement.BalanceAfter, movement.ReferenceType,
                movement.ReferenceId, movement.Notes, movement.MovementDate, movement.CreatedAt));
    }

    public async Task<PagedResult<StockMovementDto>> GetMovementsAsync(long productId, int page = 1, int pageSize = 20, CancellationToken cancellationToken = default)
    {
        // Product must exist (and belong to this business) — 404 otherwise.
        var product = await _db.Products
            .FirstOrDefaultAsync(p => p.Id == productId && p.BusinessId == BusinessId, cancellationToken)
            ?? throw new NotFoundException("Product", productId);

        var movements = _db.StockMovements
            .Where(m => m.ProductId == productId && m.BusinessId == BusinessId);

        var total = await movements.CountAsync(cancellationToken);

        var currentPage = Math.Max(1, page);
        var currentSize = Math.Clamp(pageSize, 1, 100);

        var rows = await movements
            .OrderByDescending(m => m.MovementDate)
            .ThenByDescending(m => m.Id)
            .Skip((currentPage - 1) * currentSize)
            .Take(currentSize)
            .Select(m => new StockMovementDto(
                m.Id, m.ProductId, product.Name, m.MovementType, m.Quantity, m.BalanceAfter,
                m.ReferenceType, m.ReferenceId, m.Notes, m.MovementDate, m.CreatedAt))
            .ToListAsync(cancellationToken);

        return PagedResult<StockMovementDto>.Create(rows, currentPage, currentSize, total);
    }

    private static bool IsLowStock(decimal quantity, decimal minQuantity)
        => minQuantity > 0 && quantity <= minQuantity;
}
