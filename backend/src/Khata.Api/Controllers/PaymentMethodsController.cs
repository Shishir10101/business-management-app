namespace Khata.Api.Controllers;

using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Application.Common;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>Payment method configuration (Cash, Bank Transfer, eSewa, Khalti…).</summary>
[ApiController]
[Route("api/payment-methods")]
[Authorize]
public class PaymentMethodsController : ControllerBase
{
    private readonly IPaymentMethodService _methods;

    public PaymentMethodsController(IPaymentMethodService methods)
    {
        _methods = methods;
    }

    [HttpGet]
    [Authorize(Policy = Permissions.PaymentMethodsView)]
    [ProducesResponseType(typeof(IReadOnlyList<PaymentMethodDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<PaymentMethodDto>>> GetMethods([FromQuery] bool? isActive)
        => Ok(await _methods.GetMethodsAsync(isActive));

    [HttpGet("{id:long}")]
    [Authorize(Policy = Permissions.PaymentMethodsView)]
    [ProducesResponseType(typeof(PaymentMethodDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PaymentMethodDto>> GetMethod(long id)
        => Ok(await _methods.GetMethodAsync(id));

    [HttpPost]
    [Authorize(Policy = Permissions.PaymentMethodsManage)]
    [ProducesResponseType(typeof(PaymentMethodDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<ActionResult<PaymentMethodDto>> Create([FromBody] CreatePaymentMethodRequest request)
    {
        var method = await _methods.CreateMethodAsync(request);
        return CreatedAtAction(nameof(GetMethod), new { id = method.Id }, method);
    }

    [HttpPut("{id:long}")]
    [Authorize(Policy = Permissions.PaymentMethodsManage)]
    [ProducesResponseType(typeof(PaymentMethodDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<ActionResult<PaymentMethodDto>> Update(long id, [FromBody] UpdatePaymentMethodRequest request)
        => Ok(await _methods.UpdateMethodAsync(id, request));

    [HttpDelete("{id:long}")]
    [Authorize(Policy = Permissions.PaymentMethodsManage)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> Delete(long id)
    {
        await _methods.DeleteMethodAsync(id);
        return NoContent();
    }
}
