namespace Khata.Application.Validators;

using FluentValidation;
using Khata.Application.DTOs;

public class RegisterRequestValidator : AbstractValidator<RegisterRequest>
{
    public RegisterRequestValidator()
    {
        RuleFor(x => x.FullName)
            .NotEmpty().WithMessage("Full name is required.")
            .MaximumLength(200);

        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required.")
            .EmailAddress().WithMessage("A valid email address is required.")
            .MaximumLength(256);

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required.")
            // Mirrors Identity's policy (RequiredLength = 10). A lower bound here
            // let 8- and 9-character passwords through validation and then fail
            // in Identity, so the user saw the generic policy error instead of
            // the form-level one.
            .MinimumLength(10).WithMessage("Password must be at least 10 characters.")
            .MaximumLength(128);

        RuleFor(x => x.PhoneNumber)
            .MaximumLength(20)
            .Matches(@"^\+?[\d\s-]{6,20}$")
            .When(x => !string.IsNullOrWhiteSpace(x.PhoneNumber))
            .WithMessage("Phone number format is invalid.");

        RuleFor(x => x.Locale)
            .Must(l => l is "ne" or "en" or "hi")
            .WithMessage("Locale must be 'ne', 'en' or 'hi'.");
    }
}

public class LoginRequestValidator : AbstractValidator<LoginRequest>
{
    public LoginRequestValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required.")
            .EmailAddress().WithMessage("A valid email address is required.");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required.");
    }
}

public class ChangePasswordRequestValidator : AbstractValidator<ChangePasswordRequest>
{
    public ChangePasswordRequestValidator()
    {
        RuleFor(x => x.CurrentPassword)
            .NotEmpty().WithMessage("Current password is required.");

        RuleFor(x => x.NewPassword)
            .NotEmpty().WithMessage("New password is required.")
            // Same lower bound as registration and Identity's policy.
            .MinimumLength(10).WithMessage("Password must be at least 10 characters.")
            .MaximumLength(128)
            .NotEqual(x => x.CurrentPassword)
            .WithMessage("New password must differ from the current password.");
    }
}

public class UpdateProfileRequestValidator : AbstractValidator<UpdateProfileRequest>
{
    public UpdateProfileRequestValidator()
    {
        RuleFor(x => x.FullName)
            .NotEmpty().WithMessage("Full name is required.")
            .MaximumLength(200);

        RuleFor(x => x.PhoneNumber)
            .MaximumLength(20)
            .Matches(@"^\+?[\d\s-]{6,20}$")
            .When(x => !string.IsNullOrWhiteSpace(x.PhoneNumber))
            .WithMessage("Phone number format is invalid.");

        RuleFor(x => x.Locale)
            .Must(l => l is "ne" or "en" or "hi")
            .WithMessage("Locale must be 'ne', 'en' or 'hi'.");
    }
}
