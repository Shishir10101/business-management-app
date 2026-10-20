namespace Khata.Api.Controllers;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>Formal invoices, including on-demand PDF rendering.</summary>
[ApiController]
[Route("api/invoices")]
[Authorize]
public class InvoicesController : ControllerBase
{
    private readonly IInvoiceService _invoices;

    public InvoicesController(IInvoiceService invoices)
    {
        _invoices = invoices;
    }

    /// <summary>Lists invoices. Search matches invoice number and customer name.</summary>
    [HttpGet]
    [Authorize(Policy = Permissions.InvoicesView)]
    [ProducesResponseType(typeof(PagedResult<InvoiceDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<InvoiceDto>>> GetInvoices(
        [FromQuery] long? customerId,
        [FromQuery] InvoiceStatus? status,
        [FromQuery] DateOnly? dateFrom,
        [FromQuery] DateOnly? dateTo,
        [FromQuery] string? search,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var query = new InvoiceQuery(customerId, status, dateFrom, dateTo, search, page, pageSize);
        return Ok(await _invoices.GetInvoicesAsync(query));
    }

    /// <summary>Gets one invoice with its line items.</summary>
    [HttpGet("{id:long}")]
    [Authorize(Policy = Permissions.InvoicesView)]
    [ProducesResponseType(typeof(InvoiceDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<InvoiceDto>> GetInvoice(long id)
        => Ok(await _invoices.GetInvoiceAsync(id));

    /// <summary>Renders (and caches) the invoice PDF.</summary>
    [HttpGet("{id:long}/pdf")]
    [Authorize(Policy = Permissions.InvoicesView)]
    [Produces("application/pdf")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPdf(long id)
    {
        var invoice = await _invoices.GetInvoiceAsync(id);
        var bytes = await _invoices.GeneratePdfAsync(id);
        return File(bytes, "application/pdf", $"{invoice.InvoiceNumber}.pdf");
    }

    /// <summary>
    /// Creates an invoice — standalone (with items) or from an existing sale
    /// (pass <c>saleId</c> to copy its lines and reuse its number).
    /// </summary>
    [HttpPost]
    [Authorize(Policy = Permissions.InvoicesCreate)]
    [ProducesResponseType(typeof(InvoiceDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<ActionResult<InvoiceDto>> Create([FromBody] CreateInvoiceRequest request)
    {
        var invoice = await _invoices.CreateInvoiceAsync(request);
        return CreatedAtAction(nameof(GetInvoice), new { id = invoice.Id }, invoice);
    }

    /// <summary>Updates a draft invoice (issued invoices are immutable).</summary>
    [HttpPut("{id:long}")]
    [Authorize(Policy = Permissions.InvoicesEdit)]
    [ProducesResponseType(typeof(InvoiceDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status422UnprocessableEntity)]
    public async Task<ActionResult<InvoiceDto>> Update(long id, [FromBody] UpdateInvoiceRequest request)
        => Ok(await _invoices.UpdateInvoiceAsync(id, request));

    /// <summary>Soft-deletes an invoice.</summary>
    [HttpDelete("{id:long}")]
    [Authorize(Policy = Permissions.InvoicesEdit)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(long id)
    {
        await _invoices.DeleteInvoiceAsync(id);
        return NoContent();
    }
}
