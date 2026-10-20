namespace Khata.Application.Validators;

using FluentValidation;
using Khata.Application.DTOs;

public class CreatePaymentRequestValidator : AbstractValidator<CreatePaymentRequest>
{
    public CreatePaymentRequestValidator()
    {
        RuleFor(x => x.PartyId)
            .GreaterThan(0).WithMessage("A party is required.");

        RuleFor(x => x.Amount)
            .GreaterThan(0).WithMessage("Amount must be greater than zero.");

        RuleFor(x => x.Reference).MaximumLength(100);
        RuleFor(x => x.Notes).MaximumLength(1000);
        RuleFor(x => x.MethodCode).MaximumLength(30);
    }
}

public class CreatePaymentMethodRequestValidator : AbstractValidator<CreatePaymentMethodRequest>
{
    public CreatePaymentMethodRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Method name is required.")
            .MaximumLength(100);
        RuleFor(x => x.Code).MaximumLength(30);
        RuleFor(x => x.Description).MaximumLength(500);
    }
}

public class UpdatePaymentMethodRequestValidator : AbstractValidator<UpdatePaymentMethodRequest>
{
    public UpdatePaymentMethodRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Method name is required.")
            .MaximumLength(100);
        RuleFor(x => x.Code).MaximumLength(30);
        RuleFor(x => x.Description).MaximumLength(500);
    }
}
