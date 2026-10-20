using Khata.Application.DTOs;
using Khata.Application.Validators;
using Khata.Domain.Enums;

namespace Khata.Tests.Unit;

/// <summary>Validation rules for payments and payment methods.</summary>
public class PaymentValidatorTests
{
    private readonly CreatePaymentRequestValidator _paymentValidator = new();
    private readonly CreatePaymentMethodRequestValidator _createMethodValidator = new();
    private readonly UpdatePaymentMethodRequestValidator _updateMethodValidator = new();

    [Fact]
    public async Task CreatePayment_WithValidRequest_Passes()
    {
        var request = new CreatePaymentRequest(PartyType.Customer, PartyId: 1, Amount: 50000);

        Assert.True((await _paymentValidator.ValidateAsync(request)).IsValid);
    }

    [Fact]
    public async Task CreatePayment_WithZeroAmount_Fails()
    {
        var request = new CreatePaymentRequest(PartyType.Customer, PartyId: 1, Amount: 0);

        Assert.False((await _paymentValidator.ValidateAsync(request)).IsValid);
    }

    [Fact]
    public async Task CreatePayment_WithNegativeAmount_Fails()
    {
        var request = new CreatePaymentRequest(PartyType.Supplier, PartyId: 1, Amount: -100);

        Assert.False((await _paymentValidator.ValidateAsync(request)).IsValid);
    }

    [Fact]
    public async Task CreatePayment_WithoutParty_Fails()
    {
        var request = new CreatePaymentRequest(PartyType.Customer, PartyId: 0, Amount: 1000);

        Assert.False((await _paymentValidator.ValidateAsync(request)).IsValid);
    }

    [Fact]
    public async Task CreatePaymentMethod_WithValidRequest_Passes()
    {
        var request = new CreatePaymentMethodRequest("Fonepay", "fonepay", "QR payments");

        Assert.True((await _createMethodValidator.ValidateAsync(request)).IsValid);
    }

    [Fact]
    public async Task CreatePaymentMethod_WithEmptyName_Fails()
    {
        var request = new CreatePaymentMethodRequest("");

        Assert.False((await _createMethodValidator.ValidateAsync(request)).IsValid);
    }

    [Fact]
    public async Task UpdatePaymentMethod_WithEmptyName_Fails()
    {
        var request = new UpdatePaymentMethodRequest("");

        Assert.False((await _updateMethodValidator.ValidateAsync(request)).IsValid);
    }
}
