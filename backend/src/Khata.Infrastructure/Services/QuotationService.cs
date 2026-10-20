namespace Khata.Infrastructure.Services;

using Khata.Application.Common;
using Khata.Application.Documents;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Domain.Entities;
using Khata.Domain.Enums;
using Khata.Domain.Exceptions;
using Khata.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

/// <summary>
/// Quotations: list/detail/create/update/delete, PDF rendering, and conversion
/// into a real sale. A quotation itself never moves stock or the khata.
/// </summary>
public class QuotationService : IQuotationService
{
    private readonly KhataDbContext _db;
    private readonly ICurrentUserService _currentUser;
    private readonly IDateTimeProvider _clock;
    private readonly IDocumentPdfGenerator _pdf;
    private readonly IFileStorage _storage;
    private readonly ISaleService _sales;

    public QuotationService(
        KhataDbContext db,
        ICurrentUserService currentUser,
        IDateTimeProvider clock,
        IDocumentPdfGenerator pdf,
        IFileStorage storage,
        ISaleService sales)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
        _pdf = pdf;
        _storage = storage;
        _sales = sales;
    }

    private long BusinessId =>
        _currentUser.BusinessId ?? throw new UnauthorizedException();

    public async Task<PagedResult<QuotationDto>> GetQuotationsAsync(
        QuotationQuery query, CancellationToken cancellationToken = default)
    {
        var baseQuery = _db.Quotations.Where(q => q.DeletedAt == null && q.BusinessId == BusinessId);

        if (query.CustomerId is { } customerId)
            baseQuery = baseQuery.Where(q => q.CustomerId == customerId);
        if (query.Status is { } status)
            baseQuery = baseQuery.Where(q => q.Status == status);
        if (query.DateFrom is { } from)
            baseQuery = baseQuery.Where(q => q.IssueDate >= from);
        if (query.DateTo is { } to)
            baseQuery = baseQuery.Where(q => q.IssueDate <= to);
        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            baseQuery = baseQuery.Where(q =>
                q.QuoteNumber.ToLower().Contains(search) ||
                (q.Customer != null && q.Customer.Name.ToLower().Contains(search)));
        }

        var total = await baseQuery.CountAsync(cancellationToken);

        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var rows = await baseQuery
            .OrderByDescending(q => q.IssueDate)
            .ThenByDescending(q => q.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(q => new
            {
                q.Id,
                q.QuoteNumber,
                q.CustomerId,
                CustomerName = q.Customer == null ? null : q.Customer.Name,
                q.Status,
                q.IssueDate,
                q.ValidUntil,
                q.Subtotal,
                q.DiscountAmount,
                q.TaxAmount,
                q.TotalAmount,
                q.Notes,
                q.Terms,
                q.ConvertedSaleId,
                q.PdfPath,
                q.PdfGeneratedAt,
                q.CreatedAt,
                q.UpdatedAt,
            })
            .ToListAsync(cancellationToken);

        return PagedResult<QuotationDto>.Create(
            rows.Select(x => new QuotationDto(
                x.Id, x.QuoteNumber, x.CustomerId, x.CustomerName, x.Status, x.IssueDate, x.ValidUntil,
                x.Subtotal, x.DiscountAmount, x.TaxAmount, x.TotalAmount, x.Notes, x.Terms,
                x.ConvertedSaleId, x.PdfPath != null, x.PdfGeneratedAt, [], x.CreatedAt, x.UpdatedAt)).ToList(),
            page, pageSize, total);
    }

    public async Task<QuotationDto> GetQuotationAsync(long quotationId, CancellationToken cancellationToken = default)
    {
        var quotation = await LoadQuotationAsync(quotationId, cancellationToken);
        return ToDto(quotation);
    }

    public async Task<QuotationDto> CreateQuotationAsync(
        CreateQuotationRequest request, CancellationToken cancellationToken = default)
    {
        var computed = await DocumentMath.ComputeAsync(_db, BusinessId, request.Items ?? [], cancellationToken);
        var discountTotal = computed.LineDiscount + request.DiscountAmount;
        var total = computed.Subtotal - discountTotal + computed.Tax;
        if (total < 0)
            throw new BusinessRuleException("invalid_totals", "Discount cannot exceed the subtotal.");

        Customer? customer = null;
        if (request.CustomerId is { } customerId)
            customer = await LoadCustomerAsync(customerId, cancellationToken);

        var quoteNumber = await DocumentNumberAllocator.AllocateAsync(_db, BusinessId, "quotation", "QT", cancellationToken);

        var quotation = new Quotation
        {
            BusinessId = BusinessId,
            QuoteNumber = quoteNumber,
            CustomerId = customer?.Id,
            Status = request.Status ?? QuotationStatus.Draft,
            IssueDate = request.IssueDate ?? _clock.Today,
            ValidUntil = request.ValidUntil,
            Subtotal = computed.Subtotal,
            DiscountAmount = discountTotal,
            TaxAmount = computed.Tax,
            TotalAmount = total,
            Notes = request.Notes,
            Terms = request.Terms,
        };

        foreach (var line in computed.Lines)
            quotation.Items.Add(ToItem(line));

        _db.Quotations.Add(quotation);
        await _db.SaveChangesAsync(cancellationToken);

        return await GetQuotationAsync(quotation.Id, cancellationToken);
    }

    public async Task<QuotationDto> UpdateQuotationAsync(
        long quotationId, UpdateQuotationRequest request, CancellationToken cancellationToken = default)
    {
        var quotation = await LoadQuotationAsync(quotationId, cancellationToken);

        if (quotation.ConvertedSaleId is not null)
            throw new BusinessRuleException("already_converted",
                "A converted quotation can no longer be edited.");

        var computed = await DocumentMath.ComputeAsync(_db, BusinessId, request.Items ?? [], cancellationToken);
        var discountTotal = computed.LineDiscount + request.DiscountAmount;
        var total = computed.Subtotal - discountTotal + computed.Tax;
        if (total < 0)
            throw new BusinessRuleException("invalid_totals", "Discount cannot exceed the subtotal.");

        Customer? customer = null;
        if (request.CustomerId is { } customerId)
            customer = await LoadCustomerAsync(customerId, cancellationToken);

        quotation.CustomerId = customer?.Id;
        quotation.IssueDate = request.IssueDate ?? quotation.IssueDate;
        quotation.ValidUntil = request.ValidUntil;
        quotation.Status = request.Status ?? quotation.Status;
        quotation.Subtotal = computed.Subtotal;
        quotation.DiscountAmount = discountTotal;
        quotation.TaxAmount = computed.Tax;
        quotation.TotalAmount = total;
        quotation.Notes = request.Notes;
        quotation.Terms = request.Terms;

        quotation.PdfPath = null;
        quotation.PdfGeneratedAt = null;

        _db.QuotationItems.RemoveRange(quotation.Items);
        quotation.Items.Clear();
        foreach (var line in computed.Lines)
            quotation.Items.Add(ToItem(line));

        await _db.SaveChangesAsync(cancellationToken);

        return await GetQuotationAsync(quotation.Id, cancellationToken);
    }

    public async Task DeleteQuotationAsync(long quotationId, CancellationToken cancellationToken = default)
    {
        var quotation = await LoadQuotationAsync(quotationId, cancellationToken);
        _db.Quotations.Remove(quotation); // soft delete
        await _db.SaveChangesAsync(cancellationToken);
    }

    public async Task<SaleDto> ConvertToSaleAsync(
        long quotationId, ConvertQuotationRequest request, CancellationToken cancellationToken = default)
    {
        var quotation = await LoadQuotationAsync(quotationId, cancellationToken);

        if (quotation.ConvertedSaleId is not null)
            throw new BusinessRuleException("already_converted",
                "This quotation has already been converted to a sale.");
        if (quotation.Status is QuotationStatus.Rejected or QuotationStatus.Expired)
            throw new BusinessRuleException("invalid_status",
                "A rejected or expired quotation cannot be converted.");

        // A sale needs real catalog products.
        if (quotation.Items.Any(i => i.ProductId is null))
            throw new BusinessRuleException("free_text_lines",
                "Every quotation line must reference a product before it can be converted.");

        if (quotation.CustomerId is null && request.SaleType != SaleType.Cash)
            throw new BusinessRuleException("customer_required",
                "A credit sale requires the quotation to have a customer.");

        // The quotation's DiscountAmount is line + header; the sale request takes
        // the header part separately.
        var lineDiscounts = quotation.Items.Sum(i => i.DiscountAmount);
        var headerDiscount = quotation.DiscountAmount - lineDiscounts;

        var saleRequest = new CreateSaleRequest(
            CustomerId: quotation.CustomerId,
            SaleType: request.SaleType,
            Items: quotation.Items
                .OrderBy(i => i.Id)
                .Select(i => new SaleItemRequest(
                    i.ProductId!.Value, i.Quantity, i.UnitPrice, i.DiscountAmount, i.TaxRateBps))
                .ToList(),
            SaleDate: request.SaleDate,
            DiscountAmount: headerDiscount,
            PaidAmount: request.PaidAmount,
            Notes: request.Notes ?? $"Converted from quotation {quotation.QuoteNumber}");

        var sale = await _sales.CreateSaleAsync(saleRequest, cancellationToken);

        quotation.ConvertedSaleId = sale.Id;
        quotation.Status = QuotationStatus.Accepted;
        await _db.SaveChangesAsync(cancellationToken);

        return sale;
    }

    public async Task<byte[]> GeneratePdfAsync(long quotationId, CancellationToken cancellationToken = default)
    {
        var quotation = await LoadQuotationAsync(quotationId, cancellationToken);
        var business = await LoadBusinessAsync(cancellationToken);

        var model = new QuotationPdfModel(
            Business: InvoiceService.ToLetterhead(business),
            QuoteNumber: quotation.QuoteNumber,
            Status: quotation.Status.ToString(),
            IssueDate: quotation.IssueDate,
            ValidUntil: quotation.ValidUntil,
            Customer: quotation.Customer is null
                ? null
                : new DocumentParty(quotation.Customer.Name, quotation.Customer.PhoneNumber,
                    quotation.Customer.AddressLine, quotation.Customer.PanNumber),
            Lines: quotation.Items
                .OrderBy(i => i.Id)
                .Select(i => new DocumentLine(i.Description, i.Quantity, i.UnitPrice,
                    i.DiscountAmount, i.TaxRateBps, i.TaxAmount, i.LineTotal))
                .ToList(),
            Subtotal: quotation.Subtotal,
            DiscountAmount: quotation.DiscountAmount,
            TaxAmount: quotation.TaxAmount,
            TotalAmount: quotation.TotalAmount,
            Notes: quotation.Notes,
            Terms: quotation.Terms,
            Currency: business.Currency);

        var bytes = _pdf.GenerateQuotation(model);

        var key = $"quotations/{BusinessId}/{quotation.QuoteNumber}.pdf";
        await _storage.SaveAsync(key, bytes, "application/pdf", cancellationToken);
        quotation.PdfPath = key;
        quotation.PdfGeneratedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);

        return bytes;
    }

    // --- helpers ---

    private QuotationItem ToItem(ComputedLine line) => new()
    {
        BusinessId = BusinessId,
        ProductId = line.ProductId,
        Description = line.Description,
        Quantity = line.Quantity,
        UnitPrice = line.UnitPrice,
        DiscountAmount = line.DiscountAmount,
        TaxRateBps = line.TaxRateBps,
        TaxAmount = line.TaxAmount,
        LineTotal = line.LineTotal,
    };

    private async Task<Quotation> LoadQuotationAsync(long quotationId, CancellationToken cancellationToken)
        => await _db.Quotations
            .Include(q => q.Customer)
            .Include(q => q.Items)
            .FirstOrDefaultAsync(q => q.Id == quotationId && q.DeletedAt == null && q.BusinessId == BusinessId,
                cancellationToken)
            ?? throw new NotFoundException("Quotation", quotationId);

    private async Task<Customer> LoadCustomerAsync(long customerId, CancellationToken cancellationToken)
        => await _db.Customers
            .FirstOrDefaultAsync(c => c.Id == customerId && c.DeletedAt == null && c.BusinessId == BusinessId,
                cancellationToken)
            ?? throw new NotFoundException("Customer", customerId);

    private async Task<Business> LoadBusinessAsync(CancellationToken cancellationToken)
        => await _db.Businesses
            .FirstOrDefaultAsync(b => b.Id == BusinessId, cancellationToken)
            ?? throw new NotFoundException("Business", BusinessId);

    private static QuotationDto ToDto(Quotation q) => new(
        q.Id, q.QuoteNumber, q.CustomerId, q.Customer?.Name, q.Status, q.IssueDate, q.ValidUntil,
        q.Subtotal, q.DiscountAmount, q.TaxAmount, q.TotalAmount, q.Notes, q.Terms,
        q.ConvertedSaleId, q.PdfPath != null, q.PdfGeneratedAt,
        q.Items.OrderBy(x => x.Id)
            .Select(x => InvoiceService.ToLineDto(x.Id, x.ProductId, x.Description, x.Quantity,
                x.UnitPrice, x.DiscountAmount, x.TaxRateBps, x.TaxAmount, x.LineTotal))
            .ToList(),
        q.CreatedAt, q.UpdatedAt);
}
