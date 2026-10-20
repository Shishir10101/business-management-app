namespace Khata.Api.Controllers;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>Quotations (offers) and their conversion into sales.</summary>
[ApiController]
[Route("api/quotations")]
[Authorize]
public class QuotationsController : ControllerBase
{
    private readonly IQuotationService _quotations;

    public QuotationsController(IQuotationService quotations)
    {
        _quotations = quotations;
    }

    /// <summary>Lists quotations. Search matches quote number and customer name.</summary>
    [HttpGet]
    [Authorize(Policy = Permissions.QuotationsView)]
    [ProducesResponseType(typeof(PagedResult<QuotationDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<QuotationDto>>> GetQuotations(
        [FromQuery] long? customerId,
        [FromQuery] QuotationStatus? status,
        [FromQuery] DateOnly? dateFrom,
        [FromQuery] DateOnly? dateTo,
        [FromQuery] string? search,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var query = new QuotationQuery(customerId, status, dateFrom, dateTo, search, page, pageSize);
        return Ok(await _quotations.GetQuotationsAsync(query));
    }

    /// <summary>Gets one quotation with its line items.</summary>
    [HttpGet("{id:long}")]
    [Authorize(Policy = Permissions.QuotationsView)]
    [ProducesResponseType(typeof(QuotationDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<QuotationDto>> GetQuotation(long id)
        => Ok(await _quotations.GetQuotationAsync(id));

    /// <summary>Renders (and caches) the quotation PDF.</summary>
    [HttpGet("{id:long}/pdf")]
    [Authorize(Policy = Permissions.QuotationsView)]
    [Produces("application/pdf")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPdf(long id)
    {
        var quotation = await _quotations.GetQuotationAsync(id);
        var bytes = await _quotations.GeneratePdfAsync(id);
        return File(bytes, "application/pdf", $"{quotation.QuoteNumber}.pdf");
    }

    [HttpPost]
    [Authorize(Policy = Permissions.QuotationsCreate)]
    [ProducesResponseType(typeof(QuotationDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<QuotationDto>> Create([FromBody] CreateQuotationRequest request)
    {
        var quotation = await _quotations.CreateQuotationAsync(request);
        return CreatedAtAction(nameof(GetQuotation), new { id = quotation.Id }, quotation);
    }

    [HttpPut("{id:long}")]
    [Authorize(Policy = Permissions.QuotationsEdit)]
    [ProducesResponseType(typeof(QuotationDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status422UnprocessableEntity)]
    public async Task<ActionResult<QuotationDto>> Update(long id, [FromBody] UpdateQuotationRequest request)
        => Ok(await _quotations.UpdateQuotationAsync(id, request));

    [HttpDelete("{id:long}")]
    [Authorize(Policy = Permissions.QuotationsEdit)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(long id)
    {
        await _quotations.DeleteQuotationAsync(id);
        return NoContent();
    }

    /// <summary>
    /// Converts an accepted quotation into a real sale (stock + khata + invoice
    /// number). Requires both quotations.edit and sales.create.
    /// </summary>
    [HttpPost("{id:long}/convert")]
    [Authorize(Policy = Permissions.QuotationsEdit)]
    [Authorize(Policy = Permissions.SalesCreate)]
    [ProducesResponseType(typeof(SaleDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status422UnprocessableEntity)]
    public async Task<ActionResult<SaleDto>> Convert(long id, [FromBody] ConvertQuotationRequest request)
    {
        var sale = await _quotations.ConvertToSaleAsync(id, request);
        return CreatedAtAction("GetSale", "Sales", new { id = sale.Id }, sale);
    }
}
