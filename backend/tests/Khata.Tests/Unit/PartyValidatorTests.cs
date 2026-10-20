using Khata.Application.DTOs;
using Khata.Application.Validators;

namespace Khata.Tests.Unit;

public class PartyValidatorsTests
{
    private readonly CreateCustomerRequestValidator _createCustomerValidator = new();
    private readonly UpdateCustomerRequestValidator _updateCustomerValidator = new();
    private readonly CreateSupplierRequestValidator _createSupplierValidator = new();

    [Fact]
    public async Task CreateCustomer_WithValidRequest_Passes()
    {
        var request = new CreateCustomerRequest(
            "Hari Bahadur", "9800000000", "hari@test.local",
            "Baneshwor", "Kathmandu", "Kathmandu",
            OpeningBalance: 50000, PanNumber: "123456789", CreditLimit: 500000);

        var result = await _createCustomerValidator.ValidateAsync(request);

        Assert.True(result.IsValid);
    }

    [Fact]
    public async Task CreateCustomer_WithEmptyName_Fails()
    {
        var result = await _createCustomerValidator
            .ValidateAsync(new CreateCustomerRequest(""));

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task CreateCustomer_WithBadPhone_Fails()
    {
        var result = await _createCustomerValidator
            .ValidateAsync(new CreateCustomerRequest("Hari", "12"));

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task CreateCustomer_WithNegativeCreditLimit_Fails()
    {
        var result = await _createCustomerValidator
            .ValidateAsync(new CreateCustomerRequest("Hari", CreditLimit: -1));

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task CreateCustomer_WithBadPan_Fails()
    {
        var result = await _createCustomerValidator
            .ValidateAsync(new CreateCustomerRequest("Hari", PanNumber: "123"));

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task UpdateCustomer_WithBadEmail_Fails()
    {
        var result = await _updateCustomerValidator
            .ValidateAsync(new UpdateCustomerRequest("Hari", Email: "not-an-email"));

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task CreateSupplier_WithValidRequest_Passes()
    {
        var request = new CreateSupplierRequest(
            "Bhatbhateni Wholesale", "9800000001", OpeningBalance: 250000);

        var result = await _createSupplierValidator.ValidateAsync(request);

        Assert.True(result.IsValid);
    }

    [Fact]
    public async Task CreateSupplier_WithEmptyName_Fails()
    {
        var result = await _createSupplierValidator
            .ValidateAsync(new CreateSupplierRequest(""));

        Assert.False(result.IsValid);
    }
}
