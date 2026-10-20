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
/// Sales: list/detail/create/delete. Creating a sale is one transaction —
/// invoice number allocation, stock decrement (append-only movements), and the
/// credit portion on the customer's khata ledger. Deleting a sale soft-deletes
/// it and appends the reversing stock and ledger entries.
/// </summary>
public class SaleService : ISaleService
{
    private readonly KhataDbContext _db;
    private readonly ICurrentUserService _currentUser;
    private readonly IDateTimeProvider _clock;

    public SaleService(KhataDbContext db, ICurrentUserService currentUser, IDateTimeProvider clock)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
    }

    private long BusinessId =>
        _currentUser.BusinessId ?? throw new UnauthorizedException();

    public async Task<PagedResult<SaleDto>> GetSalesAsync(SaleQuery query, CancellationToken cancellationToken = default)
    {
        var baseQuery = _db.Sales.Where(s => s.DeletedAt == null && s.BusinessId == BusinessId);

        if (query.CustomerId is { } customerId)
            baseQuery = baseQuery.Where(s => s.CustomerId == customerId);
        if (query.SaleType is { } saleType)
            baseQuery = baseQuery.Where(s => s.SaleType == saleType);
        if (query.PaymentStatus is { } paymentStatus)
            baseQuery = baseQuery.Where(s => s.PaymentStatus == paymentStatus);
        if (query.DateFrom is { } from)
            baseQuery = baseQuery.Where(s => s.SaleDate >= from);
        if (query.DateTo is { } to)
            baseQuery = baseQuery.Where(s => s.SaleDate <= to);
        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            baseQuery = baseQuery.Where(s =>
                s.InvoiceNumber.ToLower().Contains(search) ||
                (s.Customer != null && s.Customer.Name.ToLower().Contains(search)));
        }

        var total = await baseQuery.CountAsync(cancellationToken);

        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var rows = await baseQuery
            .OrderByDescending(s => s.SaleDate)
            .ThenByDescending(s => s.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(s => new
            {
                s.Id,
                s.InvoiceNumber,
                s.CustomerId,
                CustomerName = s.Customer == null ? null : s.Customer.Name,
                s.SaleType,
                s.PaymentStatus,
                s.SaleDate,
                s.Subtotal,
                s.DiscountAmount,
                s.TaxAmount,
                s.TotalAmount,
                s.PaidAmount,
                s.DueAmount,
                s.Notes,
                s.CreatedAt,
                s.UpdatedAt,
            })
            .ToListAsync(cancellationToken);

        return PagedResult<SaleDto>.Create(
            rows.Select(x => new SaleDto(
                x.Id, x.InvoiceNumber, x.CustomerId, x.CustomerName, x.SaleType,
                x.PaymentStatus, x.SaleDate, x.Subtotal, x.DiscountAmount, x.TaxAmount,
                x.TotalAmount, x.PaidAmount, x.DueAmount, x.Notes,
                [], x.CreatedAt, x.UpdatedAt)).ToList(),
            page, pageSize, total);
    }

    public async Task<SaleDto> GetSaleAsync(long saleId, CancellationToken cancellationToken = default)
    {
        var sale = await _db.Sales
            .Include(s => s.Customer)
            .Include(s => s.Items)
            .FirstOrDefaultAsync(s => s.Id == saleId && s.DeletedAt == null && s.BusinessId == BusinessId,
                cancellationToken)
            ?? throw new NotFoundException("Sale", saleId);

        return ToDto(sale);
    }

    public async Task<SaleDto> CreateSaleAsync(CreateSaleRequest request, CancellationToken cancellationToken = default)
    {
        var saleDate = request.SaleDate ?? _clock.Today;

        var productMap = await LoadProductsAsync(
            request.Items.Select(i => i.ProductId), cancellationToken);

        // --- money math (integer paisa; quantity is the only decimal) ---
        long subtotal = 0, lineDiscountTotal = 0, taxTotal = 0;
        var items = new List<SaleItem>(request.Items.Count);

        foreach (var line in request.Items)
        {
            var product = productMap[line.ProductId];
            var unitPrice = line.UnitPrice ?? product.SellingPrice;
            var taxBps = line.TaxRateBps ?? product.TaxRateBps;

            var gross = (long)Math.Round(unitPrice * line.Quantity, MidpointRounding.AwayFromZero);
            var lineDiscount = Math.Clamp(line.DiscountAmount, 0, gross);
            var net = gross - lineDiscount;
            var tax = (long)Math.Round(net * taxBps / 10000m, MidpointRounding.AwayFromZero);

            subtotal += gross;
            lineDiscountTotal += lineDiscount;
            taxTotal += tax;

            items.Add(new SaleItem
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
                "Discount cannot exceed the sale subtotal.");

        var paid = request.PaidAmount;
        if (paid > totalAmount)
            throw new BusinessRuleException("overpayment",
                "Paid amount cannot exceed the sale total.");
        ValidatePayment(request.SaleType, paid, totalAmount);

        var due = totalAmount - paid;
        var paymentStatus = paid <= 0
            ? PaymentStatus.Unpaid
            : paid >= totalAmount ? PaymentStatus.Paid : PaymentStatus.Partial;

        if (due > 0 && request.CustomerId is null)
            throw new BusinessRuleException("customer_required",
                "A credit sale requires a customer.");

        Customer? customer = null;
        if (request.CustomerId is { } customerId)
        {
            customer = await _db.Customers
                .FirstOrDefaultAsync(c => c.Id == customerId && c.DeletedAt == null
                    && c.BusinessId == BusinessId, cancellationToken)
                ?? throw new NotFoundException("Customer", customerId);
        }

        await using var transaction = await _db.Database.BeginTransactionAsync(cancellationToken);

        var invoiceNumber = string.IsNullOrWhiteSpace(request.InvoiceNumber)
            ? await DocumentNumberAllocator.AllocateAsync(_db, BusinessId, "sale", "INV", cancellationToken)
            : request.InvoiceNumber.Trim();

        var sale = new Sale
        {
            BusinessId = BusinessId,
            InvoiceNumber = invoiceNumber,
            CustomerId = customer?.Id,
            SaleType = request.SaleType,
            PaymentStatus = paymentStatus,
            SaleDate = saleDate,
            Subtotal = subtotal,
            DiscountAmount = discountTotal,
            TaxAmount = taxTotal,
            TotalAmount = totalAmount,
            PaidAmount = paid,
            DueAmount = due,
            Notes = request.Notes,
        };
        foreach (var item in items)
            sale.Items.Add(item);
        _db.Sales.Add(sale);

        // First save assigns Sale.Id so movements/ledger can reference it.
        await _db.SaveChangesAsync(cancellationToken);

        // Stock out — append-only movements, guarded against negative stock.
        foreach (var item in items)
        {
            var product = productMap[item.ProductId];
            EnsureStockRow(product);
            StockLedger.Apply(_db, BusinessId, product, product.Stock!, -item.Quantity,
                StockMovementType.Sale, "sale", sale.Id,
                $"Sale {sale.InvoiceNumber}", saleDate);
        }

        // Ledger: the unpaid portion increases what the customer owes us.
        if (due > 0 && customer is not null)
        {
            var account = await GetOrCreateAccountAsync(PartyType.Customer, customer.Id, cancellationToken);
            LedgerWriter.Append(_db, BusinessId, account, due, "sale", sale.Id,
                $"Sale {sale.InvoiceNumber}", saleDate);
        }

        await _db.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        return await GetSaleAsync(sale.Id, cancellationToken);
    }

    public async Task DeleteSaleAsync(long saleId, CancellationToken cancellationToken = default)
    {
        var sale = await _db.Sales
            .Include(s => s.Items)
            .FirstOrDefaultAsync(s => s.Id == saleId && s.DeletedAt == null && s.BusinessId == BusinessId,
                cancellationToken)
            ?? throw new NotFoundException("Sale", saleId);

        await using var transaction = await _db.Database.BeginTransactionAsync(cancellationToken);

        // Reverse stock: the goods come back.
        var productMap = await LoadProductsAsync(
            sale.Items.Select(i => i.ProductId), cancellationToken);

        foreach (var item in sale.Items)
        {
            if (!productMap.TryGetValue(item.ProductId, out var product)) continue;
            EnsureStockRow(product);
            StockLedger.Apply(_db, BusinessId, product, product.Stock!, item.Quantity,
                StockMovementType.ReturnIn, "sale_reversal", sale.Id,
                $"Reversal of {sale.InvoiceNumber}", _clock.Today);
        }

        // Reverse the receivable that was recorded for this sale.
        if (sale.DueAmount > 0 && sale.CustomerId is { } customerId)
        {
            var account = await GetOrCreateAccountAsync(PartyType.Customer, customerId, cancellationToken);
            LedgerWriter.Append(_db, BusinessId, account, -sale.DueAmount, "sale_reversal", sale.Id,
                $"Reversal of {sale.InvoiceNumber}", _clock.Today);
        }

        // Soft delete: the row and its items are kept for audit; the reversal
        // movements/ledger entries above are the auditable record of the undo.
        sale.DeletedAt = DateTime.UtcNow;
        _db.Entry(sale).State = EntityState.Modified;

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

    private static void ValidatePayment(SaleType type, long paid, long total)
    {
        switch (type)
        {
            case SaleType.Cash when paid != total:
                throw new BusinessRuleException("payment_mismatch",
                    "A cash sale must be fully paid.");
            case SaleType.Credit when paid != 0:
                throw new BusinessRuleException("payment_mismatch",
                    "A credit sale must have no payment recorded.");
            case SaleType.Partial when paid <= 0 || paid >= total:
                throw new BusinessRuleException("payment_mismatch",
                    "A partial sale requires a payment greater than zero and less than the total.");
        }
    }

    private static SaleDto ToDto(Sale s) => new(
        s.Id, s.InvoiceNumber, s.CustomerId, s.Customer?.Name, s.SaleType, s.PaymentStatus,
        s.SaleDate, s.Subtotal, s.DiscountAmount, s.TaxAmount, s.TotalAmount,
        s.PaidAmount, s.DueAmount, s.Notes,
        s.Items
            .OrderBy(i => i.Id)
            .Select(i => new SaleItemDto(
                i.Id, i.ProductId, i.ProductName, i.Quantity, i.UnitPrice,
                i.DiscountAmount, i.TaxRateBps, i.TaxAmount, i.LineTotal))
            .ToList(),
        s.CreatedAt, s.UpdatedAt);
}
