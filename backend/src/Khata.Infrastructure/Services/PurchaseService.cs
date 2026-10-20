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
/// Purchases: list/detail/create/delete. Mirror of <see cref="SaleService"/> —
/// stock goes up, the credit portion increases what we owe the supplier, and a
/// bill number is allocated atomically. Deleting a purchase reverses both.
/// </summary>
public class PurchaseService : IPurchaseService
{
    private readonly KhataDbContext _db;
    private readonly ICurrentUserService _currentUser;
    private readonly IDateTimeProvider _clock;

    public PurchaseService(KhataDbContext db, ICurrentUserService currentUser, IDateTimeProvider clock)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
    }

    private long BusinessId =>
        _currentUser.BusinessId ?? throw new UnauthorizedException();

    public async Task<PagedResult<PurchaseDto>> GetPurchasesAsync(PurchaseQuery query, CancellationToken cancellationToken = default)
    {
        var baseQuery = _db.Purchases.Where(p => p.DeletedAt == null && p.BusinessId == BusinessId);

        if (query.SupplierId is { } supplierId)
            baseQuery = baseQuery.Where(p => p.SupplierId == supplierId);
        if (query.PurchaseType is { } purchaseType)
            baseQuery = baseQuery.Where(p => p.PurchaseType == purchaseType);
        if (query.PaymentStatus is { } paymentStatus)
            baseQuery = baseQuery.Where(p => p.PaymentStatus == paymentStatus);
        if (query.DateFrom is { } from)
            baseQuery = baseQuery.Where(p => p.PurchaseDate >= from);
        if (query.DateTo is { } to)
            baseQuery = baseQuery.Where(p => p.PurchaseDate <= to);
        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            baseQuery = baseQuery.Where(p =>
                p.BillNumber.ToLower().Contains(search) ||
                (p.Supplier != null && p.Supplier.Name.ToLower().Contains(search)));
        }

        var total = await baseQuery.CountAsync(cancellationToken);

        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var rows = await baseQuery
            .OrderByDescending(p => p.PurchaseDate)
            .ThenByDescending(p => p.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(p => new
            {
                p.Id,
                p.BillNumber,
                p.SupplierId,
                SupplierName = p.Supplier == null ? null : p.Supplier.Name,
                p.PurchaseType,
                p.PaymentStatus,
                p.PurchaseDate,
                p.Subtotal,
                p.DiscountAmount,
                p.TaxAmount,
                p.TotalAmount,
                p.PaidAmount,
                p.DueAmount,
                p.Notes,
                p.CreatedAt,
                p.UpdatedAt,
            })
            .ToListAsync(cancellationToken);

        return PagedResult<PurchaseDto>.Create(
            rows.Select(x => new PurchaseDto(
                x.Id, x.BillNumber, x.SupplierId, x.SupplierName, x.PurchaseType,
                x.PaymentStatus, x.PurchaseDate, x.Subtotal, x.DiscountAmount, x.TaxAmount,
                x.TotalAmount, x.PaidAmount, x.DueAmount, x.Notes,
                [], x.CreatedAt, x.UpdatedAt)).ToList(),
            page, pageSize, total);
    }

    public async Task<PurchaseDto> GetPurchaseAsync(long purchaseId, CancellationToken cancellationToken = default)
    {
        var purchase = await _db.Purchases
            .Include(p => p.Supplier)
            .Include(p => p.Items)
            .FirstOrDefaultAsync(p => p.Id == purchaseId && p.DeletedAt == null
                && p.BusinessId == BusinessId, cancellationToken)
            ?? throw new NotFoundException("Purchase", purchaseId);

        return ToDto(purchase);
    }

    public async Task<PurchaseDto> CreatePurchaseAsync(CreatePurchaseRequest request, CancellationToken cancellationToken = default)
    {
        var purchaseDate = request.PurchaseDate ?? _clock.Today;

        var productMap = await LoadProductsAsync(
            request.Items.Select(i => i.ProductId), cancellationToken);

        long subtotal = 0, lineDiscountTotal = 0, taxTotal = 0;
        var items = new List<PurchaseItem>(request.Items.Count);

        foreach (var line in request.Items)
        {
            var product = productMap[line.ProductId];
            var unitPrice = line.UnitPrice ?? product.CostPrice;
            var taxBps = line.TaxRateBps ?? product.TaxRateBps;

            var gross = (long)Math.Round(unitPrice * line.Quantity, MidpointRounding.AwayFromZero);
            var lineDiscount = Math.Clamp(line.DiscountAmount, 0, gross);
            var net = gross - lineDiscount;
            var tax = (long)Math.Round(net * taxBps / 10000m, MidpointRounding.AwayFromZero);

            subtotal += gross;
            lineDiscountTotal += lineDiscount;
            taxTotal += tax;

            items.Add(new PurchaseItem
            {
                BusinessId = BusinessId,
                ProductId = product.Id,
                ProductName = product.Name,
                Quantity = line.Quantity,
                UnitPrice = unitPrice,
                DiscountAmount = lineDiscount,
                TaxRateBps = taxBps,
                TaxAmount = tax,
                LineTotal = net + tax,
            });
        }

        var discountTotal = lineDiscountTotal + request.DiscountAmount;
        var totalAmount = subtotal - discountTotal + taxTotal;
        if (totalAmount < 0)
            throw new BusinessRuleException("invalid_totals",
                "Discount cannot exceed the purchase subtotal.");

        var paid = request.PaidAmount;
        if (paid > totalAmount)
            throw new BusinessRuleException("overpayment",
                "Paid amount cannot exceed the purchase total.");
        ValidatePayment(request.PurchaseType, paid, totalAmount);

        var due = totalAmount - paid;
        var paymentStatus = paid <= 0
            ? PaymentStatus.Unpaid
            : paid >= totalAmount ? PaymentStatus.Paid : PaymentStatus.Partial;

        if (due > 0 && request.SupplierId is null)
            throw new BusinessRuleException("supplier_required",
                "A credit purchase requires a supplier.");

        Supplier? supplier = null;
        if (request.SupplierId is { } supplierId)
        {
            supplier = await _db.Suppliers
                .FirstOrDefaultAsync(s => s.Id == supplierId && s.DeletedAt == null
                    && s.BusinessId == BusinessId, cancellationToken)
                ?? throw new NotFoundException("Supplier", supplierId);
        }

        await using var transaction = await _db.Database.BeginTransactionAsync(cancellationToken);

        var billNumber = string.IsNullOrWhiteSpace(request.BillNumber)
            ? await DocumentNumberAllocator.AllocateAsync(_db, BusinessId, "purchase", "BILL", cancellationToken)
            : request.BillNumber.Trim();

        var purchase = new Purchase
        {
            BusinessId = BusinessId,
            BillNumber = billNumber,
            SupplierId = supplier?.Id,
            PurchaseType = request.PurchaseType,
            PaymentStatus = paymentStatus,
            PurchaseDate = purchaseDate,
            Subtotal = subtotal,
            DiscountAmount = discountTotal,
            TaxAmount = taxTotal,
            TotalAmount = totalAmount,
            PaidAmount = paid,
            DueAmount = due,
            Notes = request.Notes,
        };
        foreach (var item in items)
            purchase.Items.Add(item);
        _db.Purchases.Add(purchase);

        await _db.SaveChangesAsync(cancellationToken);

        // Stock in.
        foreach (var item in items)
        {
            var product = productMap[item.ProductId];
            EnsureStockRow(product);
            StockLedger.Apply(_db, BusinessId, product, product.Stock!, item.Quantity,
                StockMovementType.Purchase, "purchase", purchase.Id,
                $"Purchase {purchase.BillNumber}", purchaseDate);
        }

        // Ledger: the unpaid portion increases what we owe the supplier.
        if (due > 0 && supplier is not null)
        {
            var account = await GetOrCreateAccountAsync(PartyType.Supplier, supplier.Id, cancellationToken);
            LedgerWriter.Append(_db, BusinessId, account, due, "purchase", purchase.Id,
                $"Purchase {purchase.BillNumber}", purchaseDate);
        }

        await _db.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        return await GetPurchaseAsync(purchase.Id, cancellationToken);
    }

    public async Task DeletePurchaseAsync(long purchaseId, CancellationToken cancellationToken = default)
    {
        var purchase = await _db.Purchases
            .Include(p => p.Items)
            .FirstOrDefaultAsync(p => p.Id == purchaseId && p.DeletedAt == null
                && p.BusinessId == BusinessId, cancellationToken)
            ?? throw new NotFoundException("Purchase", purchaseId);

        await using var transaction = await _db.Database.BeginTransactionAsync(cancellationToken);

        var productMap = await LoadProductsAsync(
            purchase.Items.Select(i => i.ProductId), cancellationToken);

        // Reverse stock: the goods go back to the supplier.
        foreach (var item in purchase.Items)
        {
            if (!productMap.TryGetValue(item.ProductId, out var product)) continue;
            EnsureStockRow(product);
            StockLedger.Apply(_db, BusinessId, product, product.Stock!, -item.Quantity,
                StockMovementType.ReturnOut, "purchase_reversal", purchase.Id,
                $"Reversal of {purchase.BillNumber}", _clock.Today);
        }

        // Reverse the payable.
        if (purchase.DueAmount > 0 && purchase.SupplierId is { } supplierId)
        {
            var account = await GetOrCreateAccountAsync(PartyType.Supplier, supplierId, cancellationToken);
            LedgerWriter.Append(_db, BusinessId, account, -purchase.DueAmount, "purchase_reversal", purchase.Id,
                $"Reversal of {purchase.BillNumber}", _clock.Today);
        }

        purchase.DeletedAt = DateTime.UtcNow;
        _db.Entry(purchase).State = EntityState.Modified;

        await _db.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
    }

    // --- helpers ---

    private async Task<Dictionary<long, Product>> LoadProductsAsync(
        IEnumerable<long> productIds, CancellationToken cancellationToken)
    {
        var ids = productIds.Distinct().ToList();
        var products = await _db.Products
            .Include(p => p.Stock)
            .Where(p => ids.Contains(p.Id) && p.DeletedAt == null && p.BusinessId == BusinessId)
            .ToListAsync(cancellationToken);

        var map = products.ToDictionary(p => p.Id);
        foreach (var id in ids)
            if (!map.ContainsKey(id))
                throw new NotFoundException("Product", id);

        return map;
    }

    private void EnsureStockRow(Product product)
    {
        if (product.Stock is not null) return;
        product.Stock = new ProductStock
        {
            BusinessId = BusinessId,
            ProductId = product.Id,
            Quantity = 0,
            MinQuantity = 0,
        };
        _db.ProductStocks.Add(product.Stock);
    }

    private async Task<LedgerAccount> GetOrCreateAccountAsync(
        PartyType partyType, long partyId, CancellationToken cancellationToken)
    {
        var account = await _db.LedgerAccounts
            .FirstOrDefaultAsync(a => a.PartyType == partyType && a.PartyId == partyId, cancellationToken);

        if (account is null)
        {
            account = new LedgerAccount
            {
                BusinessId = BusinessId,
                PartyType = partyType,
                PartyId = partyId,
                OpeningBalance = 0,
                CurrentBalance = 0,
            };
            _db.LedgerAccounts.Add(account);
        }

        return account;
    }

    private static void ValidatePayment(PurchaseType type, long paid, long total)
    {
        switch (type)
        {
            case PurchaseType.Cash when paid != total:
                throw new BusinessRuleException("payment_mismatch",
                    "A cash purchase must be fully paid.");
            case PurchaseType.Credit when paid != 0:
                throw new BusinessRuleException("payment_mismatch",
                    "A credit purchase must have no payment recorded.");
            case PurchaseType.Partial when paid <= 0 || paid >= total:
                throw new BusinessRuleException("payment_mismatch",
                    "A partial purchase requires a payment greater than zero and less than the total.");
        }
    }

    private static PurchaseDto ToDto(Purchase p) => new(
        p.Id, p.BillNumber, p.SupplierId, p.Supplier?.Name, p.PurchaseType, p.PaymentStatus,
        p.PurchaseDate, p.Subtotal, p.DiscountAmount, p.TaxAmount, p.TotalAmount,
        p.PaidAmount, p.DueAmount, p.Notes,
        p.Items
            .OrderBy(i => i.Id)
            .Select(i => new PurchaseItemDto(
                i.Id, i.ProductId, i.ProductName, i.Quantity, i.UnitPrice,
                i.DiscountAmount, i.TaxRateBps, i.TaxAmount, i.LineTotal))
            .ToList(),
        p.CreatedAt, p.UpdatedAt);
}
