namespace Khata.Application.Interfaces;

using Khata.Application.Common;
using Khata.Application.DTOs;

/// <summary>
/// Payments: money received from customers and paid to suppliers. Recording a
/// payment writes one khata ledger entry for the full amount and, when a
/// sale/purchase is linked, updates that document's paid/due and status.
/// Payments are append-only — a mistake is corrected by recording the
/// opposite payment.
/// </summary>
public interface IPaymentService
{
    Task<PagedResult<PaymentDto>> GetPaymentsAsync(PaymentQuery query, CancellationToken cancellationToken = default);
    Task<PaymentDto> GetPaymentAsync(long paymentId, CancellationToken cancellationToken = default);
    Task<PaymentDto> CreatePaymentAsync(CreatePaymentRequest request, CancellationToken cancellationToken = default);

    /// <summary>Receivable/payable position across all parties of the active business.</summary>
    Task<ReceivablePayableSummaryDto> GetSummaryAsync(CancellationToken cancellationToken = default);
}

/// <summary>Payment method configuration (Cash, Bank, eSewa, Khalti…).</summary>
public interface IPaymentMethodService
{
    Task<IReadOnlyList<PaymentMethodDto>> GetMethodsAsync(bool? isActive = null, CancellationToken cancellationToken = default);
    Task<PaymentMethodDto> GetMethodAsync(long methodId, CancellationToken cancellationToken = default);
    Task<PaymentMethodDto> CreateMethodAsync(CreatePaymentMethodRequest request, CancellationToken cancellationToken = default);
    Task<PaymentMethodDto> UpdateMethodAsync(long methodId, UpdatePaymentMethodRequest request, CancellationToken cancellationToken = default);
    Task DeleteMethodAsync(long methodId, CancellationToken cancellationToken = default);
}
