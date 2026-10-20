namespace Khata.Application.Validators;

using FluentValidation;
using Khata.Application.DTOs;

public class CreateInvoiceRequestValidator : AbstractValidator<CreateInvoiceRequest>
{
    public CreateInvoiceRequestValidator()
    {
        // Lines are only required when the invoice is not generated from a sale.
        RuleFor(x => x.Items)
            .NotEmpty().WithMessage("At least one line item is required.")
            .When(x => x.SaleId == null);

        When(x => x.Items != null, () =>
        {
            RuleForEach(x => x.Items).ChildRules(line =>
            {
                line.RuleFor(l => l.Description)
                    .NotEmpty().WithMessage("A description is required.")
                    .When(l => l.ProductId == null);
                line.RuleFor(l => l.Description).MaximumLength(300);
                line.RuleFor(l => l.Quantity)
                    .GreaterThan(0).WithMessage("Quantity must be greater than zero.");
                line.RuleFor(l => l.UnitPrice)
                    .GreaterThanOrEqualTo(0).WithMessage("Unit price cannot be negative.");
                line.RuleFor(l => l.DiscountAmount)
                    .GreaterThanOrEqualTo(0).WithMessage("Discount cannot be negative.");
                line.RuleFor(l => l.TaxRateBps)
                    .InclusiveBetween(0, 10000).When(l => l.TaxRateBps.HasValue)
                    .WithMessage("Tax rate must be between 0 and 10000 basis points.");
            });
        });

        RuleFor(x => x.DiscountAmount).GreaterThanOrEqualTo(0);
        RuleFor(x => x.Notes).MaximumLength(2000);
        RuleFor(x => x.Terms).MaximumLength(2000);
    }
}

public class UpdateInvoiceRequestValidator : AbstractValidator<UpdateInvoiceRequest>
{
    public UpdateInvoiceRequestValidator()
    {
        RuleFor(x => x.Items)
            .NotEmpty().WithMessage("At least one line item is required.");

        When(x => x.Items != null, () =>
        {
            RuleForEach(x => x.Items).ChildRules(line =>
            {
                line.RuleFor(l => l.Description)
                    .NotEmpty().WithMessage("A description is required.")
                    .When(l => l.ProductId == null);
                line.RuleFor(l => l.Description).MaximumLength(300);
                line.RuleFor(l => l.Quantity)
                    .GreaterThan(0).WithMessage("Quantity must be greater than zero.");
                line.RuleFor(l => l.UnitPrice)
                    .GreaterThanOrEqualTo(0).WithMessage("Unit price cannot be negative.");
                line.RuleFor(l => l.DiscountAmount)
                    .GreaterThanOrEqualTo(0).WithMessage("Discount cannot be negative.");
                line.RuleFor(l => l.TaxRateBps)
                    .InclusiveBetween(0, 10000).When(l => l.TaxRateBps.HasValue)
                    .WithMessage("Tax rate must be between 0 and 10000 basis points.");
            });
        });

        RuleFor(x => x.DiscountAmount).GreaterThanOrEqualTo(0);
        RuleFor(x => x.Notes).MaximumLength(2000);
        RuleFor(x => x.Terms).MaximumLength(2000);
    }
}

public class CreateQuotationRequestValidator : AbstractValidator<CreateQuotationRequest>
{
    public CreateQuotationRequestValidator()
    {
        RuleFor(x => x.Items)
            .NotEmpty().WithMessage("At least one line item is required.");

        When(x => x.Items != null, () =>
        {
            RuleForEach(x => x.Items).ChildRules(line =>
            {
                line.RuleFor(l => l.Description)
                    .NotEmpty().WithMessage("A description is required.")
                    .When(l => l.ProductId == null);
                line.RuleFor(l => l.Description).MaximumLength(300);
                line.RuleFor(l => l.Quantity)
                    .GreaterThan(0).WithMessage("Quantity must be greater than zero.");
                line.RuleFor(l => l.UnitPrice)
                    .GreaterThanOrEqualTo(0).WithMessage("Unit price cannot be negative.");
                line.RuleFor(l => l.DiscountAmount)
                    .GreaterThanOrEqualTo(0).WithMessage("Discount cannot be negative.");
                line.RuleFor(l => l.TaxRateBps)
                    .InclusiveBetween(0, 10000).When(l => l.TaxRateBps.HasValue)
                    .WithMessage("Tax rate must be between 0 and 10000 basis points.");
            });
        });

        RuleFor(x => x.DiscountAmount).GreaterThanOrEqualTo(0);
        RuleFor(x => x.Notes).MaximumLength(2000);
        RuleFor(x => x.Terms).MaximumLength(2000);
    }
}

public class UpdateQuotationRequestValidator : AbstractValidator<UpdateQuotationRequest>
{
    public UpdateQuotationRequestValidator()
    {
        RuleFor(x => x.Items)
            .NotEmpty().WithMessage("At least one line item is required.");

        When(x => x.Items != null, () =>
        {
            RuleForEach(x => x.Items).ChildRules(line =>
            {
                line.RuleFor(l => l.Description)
                    .NotEmpty().WithMessage("A description is required.")
                    .When(l => l.ProductId == null);
                line.RuleFor(l => l.Description).MaximumLength(300);
                line.RuleFor(l => l.Quantity)
                    .GreaterThan(0).WithMessage("Quantity must be greater than zero.");
                line.RuleFor(l => l.UnitPrice)
                    .GreaterThanOrEqualTo(0).WithMessage("Unit price cannot be negative.");
                line.RuleFor(l => l.DiscountAmount)
                    .GreaterThanOrEqualTo(0).WithMessage("Discount cannot be negative.");
                line.RuleFor(l => l.TaxRateBps)
                    .InclusiveBetween(0, 10000).When(l => l.TaxRateBps.HasValue)
                    .WithMessage("Tax rate must be between 0 and 10000 basis points.");
            });
        });

        RuleFor(x => x.DiscountAmount).GreaterThanOrEqualTo(0);
        RuleFor(x => x.Notes).MaximumLength(2000);
        RuleFor(x => x.Terms).MaximumLength(2000);
    }
}

public class ConvertQuotationRequestValidator : AbstractValidator<ConvertQuotationRequest>
{
    public ConvertQuotationRequestValidator()
    {
        RuleFor(x => x.PaidAmount)
            .GreaterThanOrEqualTo(0).WithMessage("Paid amount cannot be negative.");
        RuleFor(x => x.Notes).MaximumLength(1000);
    }
}
