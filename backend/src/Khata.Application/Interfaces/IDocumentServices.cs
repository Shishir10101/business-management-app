namespace Khata.Application.Interfaces;

using Khata.Application.Common;
using Khata.Application.DTOs;

/// <summary>
/// Formal invoices. An invoice can be created standalone or generated from an
/// existing sale (copying its lines and reusing its invoice number). PDFs are
/// rendered on demand and cached in file storage.
/// </summary>
public interface IInvoiceService
{
    Task<PagedResult<InvoiceDto>> GetInvoicesAsync(InvoiceQuery query, CancellationToken cancellationToken = default);
    Task<InvoiceDto> GetInvoiceAsync(long invoiceId, CancellationToken cancellationToken = default);
    Task<InvoiceDto> CreateInvoiceAsync(CreateInvoiceRequest request, CancellationToken cancellationToken = default);
    Task<InvoiceDto> UpdateInvoiceAsync(long invoiceId, UpdateInvoiceRequest request, CancellationToken cancellationToken = default);
    Task DeleteInvoiceAsync(long invoiceId, CancellationToken cancellationToken = default);

    /// <summary>Renders the invoice PDF, caches it, and returns the bytes.</summary>
    Task<byte[]> GeneratePdfAsync(long invoiceId, CancellationToken cancellationToken = default);
}

/// <summary>
/// Quotations (offers). Never touch stock or the khata — converting one to a
/// sale runs the full sale workflow.
/// </summary>
public interface IQuotationService
{
    Task<PagedResult<QuotationDto>> GetQuotationsAsync(QuotationQuery query, CancellationToken cancellationToken = default);
    Task<QuotationDto> GetQuotationAsync(long quotationId, CancellationToken cancellationToken = default);
    Task<QuotationDto> CreateQuotationAsync(CreateQuotationRequest request, CancellationToken cancellationToken = default);
    Task<QuotationDto> UpdateQuotationAsync(long quotationId, UpdateQuotationRequest request, CancellationToken cancellationToken = default);
    Task DeleteQuotationAsync(long quotationId, CancellationToken cancellationToken = default);

    /// <summary>Converts an accepted quotation into a real sale and returns it.</summary>
    Task<SaleDto> ConvertToSaleAsync(long quotationId, ConvertQuotationRequest request, CancellationToken cancellationToken = default);

    /// <summary>Renders the quotation PDF, caches it, and returns the bytes.</summary>
    Task<byte[]> GeneratePdfAsync(long quotationId, CancellationToken cancellationToken = default);
}
