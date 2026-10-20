namespace Khata.Application.Interfaces;

using Khata.Domain.Enums;

/// <summary>A request to settle money through a payment method.</summary>
public record PaymentProviderRequest(
    long BusinessId,
    PaymentDirection Direction,
    long Amount,
    string? Reference
);

/// <summary>The outcome of a payment attempt.</summary>
public record PaymentProviderResult(bool Success, string? ProviderReference, string? ErrorMessage)
{
    public static PaymentProviderResult Ok(string? reference = null) => new(true, reference, null);

    public static PaymentProviderResult Failed(string error) => new(false, null, error);
}

/// <summary>
/// Abstraction over a way of moving money. Cash settles immediately; card and
/// wallet providers (eSewa, Khalti, Fonepay…) will plug in here later without
/// the payment service changing.
/// </summary>
public interface IPaymentProvider
{
    /// <summary>Method code this provider handles, e.g. "cash".</summary>
    string Code { get; }

    Task<PaymentProviderResult> ProcessAsync(
        PaymentProviderRequest request, CancellationToken cancellationToken = default);
}

/// <summary>
/// Resolves the provider for a payment method code. Methods without a real
/// integration resolve to the manual (offline) provider.
/// </summary>
public interface IPaymentProviderRegistry
{
    IPaymentProvider Resolve(string? code);
}
