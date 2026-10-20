namespace Khata.Application.Validators;

using FluentValidation;
using Khata.Application.DTOs;

public class CreateSaleRequestValidator : AbstractValidator<CreateSaleRequest>
{
    public CreateSaleRequestValidator()
    {
        RuleFor(x => x.Items)
            .NotEmpty().WithMessage("At least one sale item is required.");

        RuleForEach(x => x.Items).ChildRules(item =>
        {
            item.RuleFor(i => i.ProductId).GreaterThan(0);
            item.RuleFor(i => i.Quantity)
                .GreaterThan(0).WithMessage("Quantity must be greater than zero.");
            item.RuleFor(i => i.UnitPrice)
                .GreaterThanOrEqualTo(0).When(i => i.UnitPrice.HasValue)
                .WithMessage("Unit price cannot be negative.");
            item.RuleFor(i => i.DiscountAmount)
                .GreaterThanOrEqualTo(0).WithMessage("Discount cannot be negative.");
            item.RuleFor(i => i.TaxRateBps)
                .InclusiveBetween(0, 10000).When(i => i.TaxRateBps.HasValue)
                .WithMessage("Tax rate must be between 0 and 10000 basis points.");
        });

        RuleFor(x => x.DiscountAmount)
            .GreaterThanOrEqualTo(0).WithMessage("Discount cannot be negative.");

        RuleFor(x => x.PaidAmount)
            .GreaterThanOrEqualTo(0).WithMessage("Paid amount cannot be negative.");

        RuleFor(x => x.Notes).MaximumLength(1000);
        RuleFor(x => x.InvoiceNumber).MaximumLength(30);
    }
}

public class CreatePurchaseRequestValidator : AbstractValidator<CreatePurchaseRequest>
{
    public CreatePurchaseRequestValidator()
    {
        RuleFor(x => x.Items)
            .NotEmpty().WithMessage("At least one purchase item is required.");

        RuleForEach(x => x.Items).ChildRules(item =>
        {
            item.RuleFor(i => i.ProductId).GreaterThan(0);
            item.RuleFor(i => i.Quantity)
                .GreaterThan(0).WithMessage("Quantity must be greater than zero.");
            item.RuleFor(i => i.UnitPrice)
                .GreaterThanOrEqualTo(0).When(i => i.UnitPrice.HasValue)
                .WithMessage("Unit price cannot be negative.");
            item.RuleFor(i => i.DiscountAmount)
                .GreaterThanOrEqualTo(0).WithMessage("Discount cannot be negative.");
            item.RuleFor(i => i.TaxRateBps)
                .InclusiveBetween(0, 10000).When(i => i.TaxRateBps.HasValue)
                .WithMessage("Tax rate must be between 0 and 10000 basis points.");
        });

        RuleFor(x => x.DiscountAmount)
            .GreaterThanOrEqualTo(0).WithMessage("Discount cannot be negative.");

        RuleFor(x => x.PaidAmount)
            .GreaterThanOrEqualTo(0).WithMessage("Paid amount cannot be negative.");

        RuleFor(x => x.Notes).MaximumLength(1000);
        RuleFor(x => x.BillNumber).MaximumLength(30);
    }
}

public class CreateExpenseRequestValidator : AbstractValidator<CreateExpenseRequest>
{
    public CreateExpenseRequestValidator()
    {
        RuleFor(x => x.Category)
            .NotEmpty().WithMessage("Expense category is required.")
            .MaximumLength(100);
        RuleFor(x => x.Amount)
            .GreaterThan(0).WithMessage("Amount must be greater than zero.");
        RuleFor(x => x.Description).MaximumLength(1000);
        RuleFor(x => x.PaymentMethod).MaximumLength(30);
        RuleFor(x => x.Reference).MaximumLength(100);
        RuleFor(x => x.Notes).MaximumLength(1000);
    }
}

public class UpdateExpenseRequestValidator : AbstractValidator<UpdateExpenseRequest>
{
    public UpdateExpenseRequestValidator()
    {
        RuleFor(x => x.Category)
            .NotEmpty().WithMessage("Expense category is required.")
            .MaximumLength(100);
        RuleFor(x => x.Amount)
            .GreaterThan(0).WithMessage("Amount must be greater than zero.");
        RuleFor(x => x.Description).MaximumLength(1000);
        RuleFor(x => x.PaymentMethod).MaximumLength(30);
        RuleFor(x => x.Reference).MaximumLength(100);
        RuleFor(x => x.Notes).MaximumLength(1000);
    }
}

public class CreateIncomeRequestValidator : AbstractValidator<CreateIncomeRequest>
{
    public CreateIncomeRequestValidator()
    {
        RuleFor(x => x.Source)
            .NotEmpty().WithMessage("Income source is required.")
            .MaximumLength(100);
        RuleFor(x => x.Amount)
            .GreaterThan(0).WithMessage("Amount must be greater than zero.");
        RuleFor(x => x.Description).MaximumLength(1000);
        RuleFor(x => x.PaymentMethod).MaximumLength(30);
        RuleFor(x => x.Reference).MaximumLength(100);
        RuleFor(x => x.Notes).MaximumLength(1000);
    }
}

public class UpdateIncomeRequestValidator : AbstractValidator<UpdateIncomeRequest>
{
    public UpdateIncomeRequestValidator()
    {
        RuleFor(x => x.Source)
            .NotEmpty().WithMessage("Income source is required.")
            .MaximumLength(100);
        RuleFor(x => x.Amount)
            .GreaterThan(0).WithMessage("Amount must be greater than zero.");
        RuleFor(x => x.Description).MaximumLength(1000);
        RuleFor(x => x.PaymentMethod).MaximumLength(30);
        RuleFor(x => x.Reference).MaximumLength(100);
        RuleFor(x => x.Notes).MaximumLength(1000);
    }
}
