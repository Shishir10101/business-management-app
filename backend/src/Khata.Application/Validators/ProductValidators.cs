namespace Khata.Application.Validators;

using FluentValidation;
using Khata.Application.DTOs;

public class CreateCategoryRequestValidator : AbstractValidator<CreateCategoryRequest>
{
    public CreateCategoryRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Category name is required.")
            .MaximumLength(200);

        RuleFor(x => x.Description).MaximumLength(1000);
    }
}

public class UpdateCategoryRequestValidator : AbstractValidator<UpdateCategoryRequest>
{
    public UpdateCategoryRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Category name is required.")
            .MaximumLength(200);

        RuleFor(x => x.Description).MaximumLength(1000);
    }
}

public class CreateUnitRequestValidator : AbstractValidator<CreateUnitRequest>
{
    public CreateUnitRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Unit name is required.")
            .MaximumLength(50);

        RuleFor(x => x.ShortName)
            .NotEmpty().WithMessage("Short name is required.")
            .MaximumLength(10);
    }
}

public class UpdateUnitRequestValidator : AbstractValidator<UpdateUnitRequest>
{
    public UpdateUnitRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Unit name is required.")
            .MaximumLength(50);

        RuleFor(x => x.ShortName)
            .NotEmpty().WithMessage("Short name is required.")
            .MaximumLength(10);
    }
}

public class CreateProductRequestValidator : AbstractValidator<CreateProductRequest>
{
    public CreateProductRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Product name is required.")
            .MaximumLength(200);

        RuleFor(x => x.Sku).MaximumLength(100);
        RuleFor(x => x.Barcode).MaximumLength(100);
        RuleFor(x => x.Description).MaximumLength(2000);
        RuleFor(x => x.ImageUrl).MaximumLength(512);

        // Prices are paisa; must never be negative. Tax rate is basis points.
        RuleFor(x => x.CostPrice).GreaterThanOrEqualTo(0);
        RuleFor(x => x.SellingPrice).GreaterThanOrEqualTo(0);
        RuleFor(x => x.WholesalePrice)
            .GreaterThanOrEqualTo(0)
            .When(x => x.WholesalePrice.HasValue);
        RuleFor(x => x.TaxRateBps)
            .InclusiveBetween(0, 10000)
            .WithMessage("Tax rate must be between 0% and 100% (basis points).");

        RuleFor(x => x.OpeningQuantity)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Opening quantity cannot be negative.");
        RuleFor(x => x.MinQuantity)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Minimum quantity cannot be negative.");
    }
}

public class UpdateProductRequestValidator : AbstractValidator<UpdateProductRequest>
{
    public UpdateProductRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Product name is required.")
            .MaximumLength(200);

        RuleFor(x => x.Sku).MaximumLength(100);
        RuleFor(x => x.Barcode).MaximumLength(100);
        RuleFor(x => x.Description).MaximumLength(2000);
        RuleFor(x => x.ImageUrl).MaximumLength(512);

        RuleFor(x => x.CostPrice).GreaterThanOrEqualTo(0);
        RuleFor(x => x.SellingPrice).GreaterThanOrEqualTo(0);
        RuleFor(x => x.WholesalePrice)
            .GreaterThanOrEqualTo(0)
            .When(x => x.WholesalePrice.HasValue);
        RuleFor(x => x.TaxRateBps)
            .InclusiveBetween(0, 10000)
            .WithMessage("Tax rate must be between 0% and 100% (basis points).");
        RuleFor(x => x.MinQuantity)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Minimum quantity cannot be negative.");
    }
}

public class AdjustStockRequestValidator : AbstractValidator<AdjustStockRequest>
{
    public AdjustStockRequestValidator()
    {
        RuleFor(x => x.Quantity)
            .NotEqual(0).WithMessage("Adjustment quantity cannot be zero.")
            .Must(q => Math.Abs(q) <= 10_000_000)
            .WithMessage("Adjustment quantity is out of range.");

        RuleFor(x => x.Notes).MaximumLength(1000);
    }
}
