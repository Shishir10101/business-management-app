using Khata.Application.DTOs;
using Khata.Application.Validators;
using Khata.Domain.Enums;

namespace Khata.Tests.Unit;

/// <summary>Validation rules for sales, purchases, expenses and income.</summary>
public class TransactionValidatorTests
{
    private readonly CreateSaleRequestValidator _saleValidator = new();
    private readonly CreatePurchaseRequestValidator _purchaseValidator = new();
    private readonly CreateExpenseRequestValidator _expenseValidator = new();
    private readonly CreateIncomeRequestValidator _incomeValidator = new();

    [Fact]
    public async Task CreateSale_WithValidRequest_Passes()
    {
        var request = new CreateSaleRequest(
            CustomerId: 1,
            SaleType: SaleType.Cash,
            Items: [new SaleItemRequest(1, 2, 1000)],
            PaidAmount: 2000);

        Assert.True((await _saleValidator.ValidateAsync(request)).IsValid);
    }

    [Fact]
    public async Task CreateSale_WithNoItems_Fails()
    {
        var request = new CreateSaleRequest(null, SaleType.Cash, []);

        Assert.False((await _saleValidator.ValidateAsync(request)).IsValid);
    }

    [Fact]
    public async Task CreateSale_WithNonPositiveQuantity_Fails()
    {
        var request = new CreateSaleRequest(
            null, SaleType.Cash, [new SaleItemRequest(1, 0, 1000)], PaidAmount: 0);

        Assert.False((await _saleValidator.ValidateAsync(request)).IsValid);
    }

    [Fact]
    public async Task CreateSale_WithNegativeUnitPrice_Fails()
    {
        var request = new CreateSaleRequest(
            null, SaleType.Cash, [new SaleItemRequest(1, 1, -5)], PaidAmount: 0);

        Assert.False((await _saleValidator.ValidateAsync(request)).IsValid);
    }

    [Fact]
    public async Task CreateSale_WithOutOfRangeTaxRate_Fails()
    {
        var request = new CreateSaleRequest(
            null, SaleType.Cash, [new SaleItemRequest(1, 1, 1000, TaxRateBps: 20000)], PaidAmount: 1000);

        Assert.False((await _saleValidator.ValidateAsync(request)).IsValid);
    }

    [Fact]
    public async Task CreateSale_WithNegativeDiscount_Fails()
    {
        var request = new CreateSaleRequest(
            null, SaleType.Cash, [new SaleItemRequest(1, 1, 1000)], DiscountAmount: -1, PaidAmount: 1000);

        Assert.False((await _saleValidator.ValidateAsync(request)).IsValid);
    }

    [Fact]
    public async Task CreatePurchase_WithNoItems_Fails()
    {
        var request = new CreatePurchaseRequest(null, PurchaseType.Cash, []);

        Assert.False((await _purchaseValidator.ValidateAsync(request)).IsValid);
    }

    [Fact]
    public async Task CreatePurchase_WithValidRequest_Passes()
    {
        var request = new CreatePurchaseRequest(
            SupplierId: 1,
            PurchaseType: PurchaseType.Credit,
            Items: [new PurchaseItemRequest(1, 5, 2000)]);

        Assert.True((await _purchaseValidator.ValidateAsync(request)).IsValid);
    }

    [Fact]
    public async Task CreateExpense_WithValidRequest_Passes()
    {
        var request = new CreateExpenseRequest("Rent", 250000, Description: "Shop rent");

        Assert.True((await _expenseValidator.ValidateAsync(request)).IsValid);
    }

    [Fact]
    public async Task CreateExpense_WithZeroAmount_Fails()
    {
        var request = new CreateExpenseRequest("Rent", 0);

        Assert.False((await _expenseValidator.ValidateAsync(request)).IsValid);
    }

    [Fact]
    public async Task CreateExpense_WithEmptyCategory_Fails()
    {
        var request = new CreateExpenseRequest("", 100);

        Assert.False((await _expenseValidator.ValidateAsync(request)).IsValid);
    }

    [Fact]
    public async Task CreateIncome_WithZeroAmount_Fails()
    {
        var request = new CreateIncomeRequest("Interest", 0);

        Assert.False((await _incomeValidator.ValidateAsync(request)).IsValid);
    }

    [Fact]
    public async Task CreateIncome_WithEmptySource_Fails()
    {
        var request = new CreateIncomeRequest("", 500);

        Assert.False((await _incomeValidator.ValidateAsync(request)).IsValid);
    }
}
