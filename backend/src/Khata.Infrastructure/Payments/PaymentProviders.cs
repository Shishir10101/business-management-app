namespace Khata.Infrastructure.Payments;

using Khata.Application.Interfaces;

/// <summary>
/// Settles cash immediately — no external call. The user-supplied reference
/// (if any) is echoed back as the provider reference.
/// </summary>
public class CashPaymentProvider : IPaymentProvider
{
    public string Code => "cash";

    public Task<PaymentProviderResult> ProcessAsync(
        PaymentProviderRequest request, CancellationToken cancellationToken = default)
        => Task.FromResult(PaymentProviderResult.Ok(request.Reference));
}

/// <summary>
/// Fallback for methods with no integration yet (bank transfer, cheque, and
/// the wallet providers until they are wired up). Settlement is assumed to
/// happen outside the app, so it always succeeds.
/// </summary>
public class ManualPaymentProvider : IPaymentProvider
{
    public string Code => "manual";

    public Task<PaymentProviderResult> ProcessAsync(
        PaymentProviderRequest request, CancellationToken cancellationToken = default)
        => Task.FromResult(PaymentProviderResult.Ok(request.Reference));
}

/// <summary>
/// Resolves a provider by method code (case-insensitive), falling back to the
/// manual provider for codes without a dedicated implementation.
/// </summary>
public class PaymentProviderRegistry : IPaymentProviderRegistry
{
    private readonly Dictionary<string, IPaymentProvider> _providers;
    private readonly IPaymentProvider _fallback;

    public PaymentProviderRegistry(IEnumerable<IPaymentProvider> providers)
    {
        var list = providers.ToList();
        _providers = list.ToDictionary(p => p.Code, StringComparer.OrdinalIgnoreCase);
        _fallback = list.FirstOrDefault(p => p.Code == "manual")
            ?? list.FirstOrDefault()
            ?? throw new InvalidOperationException("No payment providers registered.");
    }

    public IPaymentProvider Resolve(string? code)
        => code is not null && _providers.TryGetValue(code, out var provider)
            ? provider
            : _fallback;
}
