namespace Khata.Api.Controllers;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>Money received from customers and paid to suppliers, plus the
/// business's receivable/payable position.</summary>
[ApiController]
[Route("api/payments")]
[Authorize]
public class PaymentsController : ControllerBase
{
    private readonly IPaymentService _payments;

    public PaymentsController(IPaymentService payments)
    {
        _payments = payments;
    }

    /// <summary>Lists payments. Search matches party name and reference.</summary>
    [HttpGet]
    [Authorize(Policy = Permissions.PaymentsView)]
    [ProducesResponseType(typeof(PagedResult<PaymentDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<PaymentDto>>> GetPayments(
        [FromQuery] PartyType? partyType,
        [FromQuery] long? partyId,
        [FromQuery] PaymentDirection? direction,
        [FromQuery] DateOnly? dateFrom,
        [FromQuery] DateOnly? dateTo,
        [FromQuery] string? search,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var query = new PaymentQuery(partyType, partyId, direction, dateFrom, dateTo, search, page, pageSize);
        return Ok(await _payments.GetPaymentsAsync(query));
    }

    /// <summary>Total receivable, total payable and advances across all parties.</summary>
    [HttpGet("summary")]
    [Authorize(Policy = Permissions.PaymentsView)]
    [ProducesResponseType(typeof(ReceivablePayableSummaryDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<ReceivablePayableSummaryDto>> GetSummary()
        => Ok(await _payments.GetSummaryAsync());

    [HttpGet("{id:long}")]
    [Authorize(Policy = Permissions.PaymentsView)]
    [ProducesResponseType(typeof(PaymentDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PaymentDto>> GetPayment(long id)
        => Ok(await _payments.GetPaymentAsync(id));

    /// <summary>
    /// Records a payment. Writes one khata ledger entry for the full amount and,
    /// when a sale/purchase is linked, applies the payment to that document.
    /// Overpayment is allowed and stays on the account as an advance.
    /// </summary>
    [HttpPost]
    [Authorize(Policy = Permissions.PaymentsCreate)]
    [ProducesResponseType(typeof(PaymentDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status422UnprocessableEntity)]
    public async Task<ActionResult<PaymentDto>> Create([FromBody] CreatePaymentRequest request)
    {
        var payment = await _payments.CreatePaymentAsync(request);
        return CreatedAtAction(nameof(GetPayment), new { id = payment.Id }, payment);
    }
}
