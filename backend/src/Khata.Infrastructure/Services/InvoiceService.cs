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
/// Invoices: list/detail/create/update/delete plus on-demand PDF rendering.
/// An invoice may be created standalone (allocating the next INV number from the
/// business's shared invoice series) or generated from a sale (copying its lines
/// and reusing its number, so the printed document matches the sale).
/// </summary>
public class InvoiceService : IInvoiceService
{
    private readonly KhataDbContext _db;
    private readonly ICurrentUserService _currentUser;
    private readonly IDateTimeProvider _clock;
    private readonly IDocumentPdfGenerator _pdf;
    private readonly IFileStorage _storage;

    public InvoiceService(
        KhataDbContext db,
        ICurrentUserService currentUser,
        IDateTimeProvider clock,
        IDocumentPdfGenerator pdf,
        IFileStorage storage)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
        _pdf = pdf;
        _storage = storage;
    }

    private long BusinessId =>
        _currentUser.BusinessId ?? throw new UnauthorizedException();

    public async Task<PagedResult<InvoiceDto>> GetInvoicesAsync(
        InvoiceQuery query, CancellationToken cancellationToken = default)
    {
        var baseQuery = _db.Invoices.Where(i => i.DeletedAt == null && i.BusinessId == BusinessId);

        if (query.CustomerId is { } customerId)
            baseQuery = baseQuery.Where(i => i.CustomerId == customerId);
        if (query.Status is { } status)
            baseQuery = baseQuery.Where(i => i.Status == status);
        if (query.DateFrom is { } from)
            baseQuery = baseQuery.Where(i => i.IssueDate >= from);
        if (query.DateTo is { } to)
            baseQuery = baseQuery.Where(i => i.IssueDate <= to);
        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            baseQuery = baseQuery.Where(i =>
                i.InvoiceNumber.ToLower().Contains(search) ||
                (i.Customer != null && i.Customer.Name.ToLower().Contains(search)));
        }

        var total = await baseQuery.CountAsync(cancellationToken);

        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var rows = await baseQuery
            .OrderByDescending(i => i.IssueDate)
            .ThenByDescending(i => i.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(i => new
            {
                i.Id,
                i.InvoiceNumber,
                i.CustomerId,
                CustomerName = i.Customer == null ? null : i.Customer.Name,
                i.SaleId,
                SaleInvoiceNumber = i.Sale == null ? null : i.Sale.InvoiceNumber,
                i.Status,
                i.IssueDate,
                i.DueDate,
                i.Subtotal,
                i.DiscountAmount,
                i.TaxAmount,
                i.TotalAmount,
                i.Notes,
                i.Terms,
                i.PdfPath,
                i.PdfGeneratedAt,
                i.CreatedAt,
                i.UpdatedAt,
            })
            .ToListAsync(cancellationToken);

        return PagedResult<InvoiceDto>.Create(
            rows.Select(x => new InvoiceDto(
                x.Id, x.InvoiceNumber, x.CustomerId, x.CustomerName, x.SaleId, x.SaleInvoiceNumber,
                x.Status, x.IssueDate, x.DueDate, x.Subtotal, x.DiscountAmount, x.TaxAmount,
                x.TotalAmount, x.Notes, x.Terms, x.PdfPath != null, x.PdfGeneratedAt,
                [], x.CreatedAt, x.UpdatedAt)).ToList(),
            page, pageSize, total);
    }

    public async Task<InvoiceDto> GetInvoiceAsync(long invoiceId, CancellationToken cancellationToken = default)
    {
        var invoice = await LoadInvoiceAsync(invoiceId, cancellationToken);
        return ToDto(invoice);
    }

    public async Task<InvoiceDto> CreateInvoiceAsync(
        CreateInvoiceRequest request, CancellationToken cancellationToken = default)
    {
        var issueDate = request.IssueDate ?? _clock.Today;

        string invoiceNumber;
        List<ComputedLine> lines;
        long subtotal, lineDiscount, tax, headerDiscount;
        Customer? customer;

        if (request.SaleId is { } saleId)
        {
            var sale = await _db.Sales
                .Include(s => s.Items)
                .FirstOrDefaultAsync(s => s.Id == saleId && s.DeletedAt == null && s.BusinessId == BusinessId,
                    cancellationToken)
                ?? throw new NotFoundException("Sale", saleId);

            // Reuse the sale's number so the printed invoice matches the sale.
            invoiceNumber = sale.InvoiceNumber;
            if (await _db.Invoices.AnyAsync(i => i.DeletedAt == null && i.BusinessId == BusinessId
                    && i.InvoiceNumber == invoiceNumber, cancellationToken))
                throw new ConflictException($"An invoice for {invoiceNumber} already exists.");

            lines = sale.Items
                .OrderBy(i => i.Id)
                .Select(i => new ComputedLine(i.ProductId, i.ProductName, i.Quantity, i.UnitPrice,
                    i.DiscountAmount, i.TaxRateBps, i.TaxAmount, i.LineTotal))
                .ToList();

            subtotal = sale.Subtotal;
            // The sale's DiscountAmount already includes its header discount.
            lineDiscount = sale.DiscountAmount;
            tax = sale.TaxAmount;
            headerDiscount = 0;

            customer = sale.CustomerId is { } customerId
                ? await LoadCustomerAsync(customerId, cancellationToken)
                : null;
        }
        else
        {
            var computed = await DocumentMath.ComputeAsync(_db, BusinessId, request.Items ?? [], cancellationToken);
            lines = computed.Lines;
            subtotal = computed.Subtotal;
            lineDiscount = computed.LineDiscount;
            tax = computed.Tax;
            headerDiscount = request.DiscountAmount;

            invoiceNumber = await DocumentNumberAllocator.AllocateAsync(_db, BusinessId, "sale", "INV", cancellationToken);

            customer = request.CustomerId is { } cid
                ? await LoadCustomerAsync(cid, cancellationToken)
                : null;
        }

        var discountTotal = lineDiscount + headerDiscount;
        var total = subtotal - discountTotal + tax;
        if (total < 0)
            throw new BusinessRuleException("invalid_totals", "Discount cannot exceed the subtotal.");

        var invoice = new Invoice
        {
            BusinessId = BusinessId,
            InvoiceNumber = invoiceNumber,
            CustomerId = customer?.Id,
            SaleId = request.SaleId,
            Status = request.Status ?? InvoiceStatus.Draft,
            IssueDate = issueDate,
            DueDate = request.DueDate,
            Subtotal = subtotal,
            DiscountAmount = discountTotal,
            TaxAmount = tax,
            TotalAmount = total,
            Notes = request.Notes,
            Terms = request.Terms,
        };

        foreach (var line in lines)
            invoice.Items.Add(ToItem(BusinessId, line));

        _db.Invoices.Add(invoice);
        await _db.SaveChangesAsync(cancellationToken);

        return await GetInvoiceAsync(invoice.Id, cancellationToken);
    }

    public async Task<InvoiceDto> UpdateInvoiceAsync(
        long invoiceId, UpdateInvoiceRequest request, CancellationToken cancellationToken = default)
    {
        var invoice = await LoadInvoiceAsync(invoiceId, cancellationToken);

        if (invoice.Status != InvoiceStatus.Draft)
            throw new BusinessRuleException("not_editable",
                "Only draft invoices can be edited.");

        var computed = await DocumentMath.ComputeAsync(_db, BusinessId, request.Items ?? [], cancellationToken);
        var discountTotal = computed.LineDiscount + request.DiscountAmount;
        var total = computed.Subtotal - discountTotal + computed.Tax;
        if (total < 0)
            throw new BusinessRuleException("invalid_totals", "Discount cannot exceed the subtotal.");

        Customer? customer = null;
        if (request.CustomerId is { } customerId)
            customer = await LoadCustomerAsync(customerId, cancellationToken);

        invoice.CustomerId = customer?.Id;
        invoice.IssueDate = request.IssueDate ?? invoice.IssueDate;
        invoice.DueDate = request.DueDate;
        invoice.Status = request.Status ?? invoice.Status;
        invoice.Subtotal = computed.Subtotal;
        invoice.DiscountAmount = discountTotal;
        invoice.TaxAmount = computed.Tax;
        invoice.TotalAmount = total;
        invoice.Notes = request.Notes;
        invoice.Terms = request.Terms;

        // The rendered PDF is now stale.
        invoice.PdfPath = null;
        invoice.PdfGeneratedAt = null;

        _db.InvoiceItems.RemoveRange(invoice.Items);
        invoice.Items.Clear();
        foreach (var line in computed.Lines)
            invoice.Items.Add(ToItem(BusinessId, line));

        await _db.SaveChangesAsync(cancellationToken);

        return await GetInvoiceAsync(invoice.Id, cancellationToken);
    }

    public async Task DeleteInvoiceAsync(long invoiceId, CancellationToken cancellationToken = default)
    {
        var invoice = await LoadInvoiceAsync(invoiceId, cancellationToken);
        _db.Invoices.Remove(invoice); // soft delete
        await _db.SaveChangesAsync(cancellationToken);
    }

    public async Task<byte[]> GeneratePdfAsync(long invoiceId, CancellationToken cancellationToken = default)
    {
        var invoice = await LoadInvoiceAsync(invoiceId, cancellationToken);
        var business = await LoadBusinessAsync(cancellationToken);

        var model = new InvoicePdfModel(
            Business: ToLetterhead(business),
            InvoiceNumber: invoice.InvoiceNumber,
            Status: invoice.Status.ToString(),
            IssueDate: invoice.IssueDate,
            DueDate: invoice.DueDate,
            Customer: invoice.Customer is null
                ? null
                : new DocumentParty(invoice.Customer.Name, invoice.Customer.PhoneNumber,
                    invoice.Customer.AddressLine, invoice.Customer.PanNumber),
            Lines: invoice.Items
                .OrderBy(i => i.Id)
                .Select(i => new DocumentLine(i.Description, i.Quantity, i.UnitPrice,
                    i.DiscountAmount, i.TaxRateBps, i.TaxAmount, i.LineTotal))
                .ToList(),
            Subtotal: invoice.Subtotal,
            DiscountAmount: invoice.DiscountAmount,
            TaxAmount: invoice.TaxAmount,
            TotalAmount: invoice.TotalAmount,
            Notes: invoice.Notes,
            Terms: invoice.Terms,
            Currency: business.Currency);

        var bytes = _pdf.GenerateInvoice(model);

        var key = $"invoices/{BusinessId}/{invoice.InvoiceNumber}.pdf";
        await _storage.SaveAsync(key, bytes, "application/pdf", cancellationToken);
        invoice.PdfPath = key;
        invoice.PdfGeneratedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);

        return bytes;
    }

    // --- helpers ---

    internal static BusinessLetterhead ToLetterhead(Business business) => new(
        business.Name, business.AddressLine, business.City, business.District,
        business.PhoneNumber, business.Email, business.PanNumber);

    internal static InvoiceItem ToItem(long businessId, ComputedLine line) => new()
    {
        BusinessId = businessId,
        ProductId = line.ProductId,
        Description = line.Description,
        Quantity = line.Quantity,
        UnitPrice = line.UnitPrice,
        DiscountAmount = line.DiscountAmount,
        TaxRateBps = line.TaxRateBps,
        TaxAmount = line.TaxAmount,
        LineTotal = line.LineTotal,
    };

    internal static DocumentLineDto ToLineDto(long id, long? productId, string description, decimal quantity,
        long unitPrice, long discountAmount, int taxRateBps, long taxAmount, long lineTotal)
        => new(id, productId, description, quantity, unitPrice, discountAmount, taxRateBps, taxAmount, lineTotal);

    private async Task<Invoice> LoadInvoiceAsync(long invoiceId, CancellationToken cancellationToken)
        => await _db.Invoices
            .Include(i => i.Customer)
            .Include(i => i.Sale)
            .Include(i => i.Items)
            .FirstOrDefaultAsync(i => i.Id == invoiceId && i.DeletedAt == null && i.BusinessId == BusinessId,
                cancellationToken)
            ?? throw new NotFoundException("Invoice", invoiceId);

    private async Task<Customer> LoadCustomerAsync(long customerId, CancellationToken cancellationToken)
        => await _db.Customers
            .FirstOrDefaultAsync(c => c.Id == customerId && c.DeletedAt == null && c.BusinessId == BusinessId,
                cancellationToken)
            ?? throw new NotFoundException("Customer", customerId);

    private async Task<Business> LoadBusinessAsync(CancellationToken cancellationToken)
        => await _db.Businesses
            .FirstOrDefaultAsync(b => b.Id == BusinessId, cancellationToken)
            ?? throw new NotFoundException("Business", BusinessId);

    private static InvoiceDto ToDto(Invoice i) => new(
        i.Id, i.InvoiceNumber, i.CustomerId, i.Customer?.Name, i.SaleId, i.Sale?.InvoiceNumber,
        i.Status, i.IssueDate, i.DueDate, i.Subtotal, i.DiscountAmount, i.TaxAmount, i.TotalAmount,
        i.Notes, i.Terms, i.PdfPath != null, i.PdfGeneratedAt,
        i.Items.OrderBy(x => x.Id)
            .Select(x => ToLineDto(x.Id, x.ProductId, x.Description, x.Quantity, x.UnitPrice,
                x.DiscountAmount, x.TaxRateBps, x.TaxAmount, x.LineTotal))
            .ToList(),
        i.CreatedAt, i.UpdatedAt);
}
