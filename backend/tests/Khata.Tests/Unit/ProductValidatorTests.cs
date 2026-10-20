using Khata.Application.DTOs;
using Khata.Application.Validators;

namespace Khata.Tests.Unit;

public class ProductValidatorsTests
{
    private readonly CreateProductRequestValidator _createProductValidator = new();
    private readonly UpdateProductRequestValidator _updateProductValidator = new();
    private readonly CreateUnitRequestValidator _createUnitValidator = new();
    private readonly CreateCategoryRequestValidator _createCategoryValidator = new();
    private readonly AdjustStockRequestValidator _adjustStockValidator = new();

    [Fact]
    public async Task CreateProduct_WithValidRequest_Passes()
    {
        var request = new CreateProductRequest(
            "Wai Wai Noodles", CostPrice: 1600, SellingPrice: 2000,
            WholesalePrice: 1900, TaxRateBps: 1300, OpeningQuantity: 10, MinQuantity: 5);

        var result = await _createProductValidator.ValidateAsync(request);

        Assert.True(result.IsValid);
    }

    [Theory]
    [InlineData("")]                                    // missing name
    [InlineData("Negative price", -1, 0, 0, 0)]         // negative cost
    [InlineData("Negative selling", 0, -5, 0, 0)]       // negative selling
    [InlineData("Tax too high", 0, 0, 10001)]        // >100%
    [InlineData("Negative opening", 0, 0, 0, 0, -1)]    // negative opening qty
    [InlineData("Negative min", 0, 0, 0, 0, -1)]     // negative min qty
    public async Task CreateProduct_WithInvalidField_Fails(
        string name, long costPrice = 0, long sellingPrice = 0,
        int taxRateBps = 0, decimal openingQuantity = 0, decimal minQuantity = 0)
    {
        var request = new CreateProductRequest(
            name, CostPrice: costPrice, SellingPrice: sellingPrice,
            TaxRateBps: taxRateBps, OpeningQuantity: openingQuantity, MinQuantity: minQuantity);

        var result = await _createProductValidator.ValidateAsync(request);

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task UpdateProduct_WithNegativeWholesalePrice_Fails()
    {
        var request = new UpdateProductRequest("Noodles", WholesalePrice: -100);

        var result = await _updateProductValidator.ValidateAsync(request);

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task CreateUnit_WithMissingShortName_Fails()
    {
        var result = await _createUnitValidator.ValidateAsync(new CreateUnitRequest("Piece", ""));

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task CreateCategory_WithValidRequest_Passes()
    {
        var result = await _createCategoryValidator.ValidateAsync(
            new CreateCategoryRequest("Beverages", "Drinks and water"));

        Assert.True(result.IsValid);
    }

    [Fact]
    public async Task AdjustStock_WithZeroQuantity_Fails()
    {
        var result = await _adjustStockValidator.ValidateAsync(new AdjustStockRequest(0));

        Assert.False(result.IsValid);
    }

    [Theory]
    [InlineData(5)]
    [InlineData(-3.5)]
    public async Task AdjustStock_WithSignedQuantity_Passes(decimal quantity)
    {
        var result = await _adjustStockValidator.ValidateAsync(new AdjustStockRequest(quantity, "stock count"));

        Assert.True(result.IsValid);
    }
}
