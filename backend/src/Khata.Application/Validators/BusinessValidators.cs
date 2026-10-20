namespace Khata.Application.Validators;

using FluentValidation;
using Khata.Application.Common;
using Khata.Application.DTOs;

public class CreateBusinessRequestValidator : AbstractValidator<CreateBusinessRequest>
{
    public CreateBusinessRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Business name is required.")
            .MaximumLength(200);

        RuleFor(x => x.Type).MaximumLength(50);
        RuleFor(x => x.PanNumber)
            .MaximumLength(50)
            .Matches(@"^\d{9}$")
            .When(x => !string.IsNullOrWhiteSpace(x.PanNumber))
            .WithMessage("PAN must be a 9-digit number.");

        RuleFor(x => x.PhoneNumber)
            .MaximumLength(20)
            .Matches(@"^\+?[\d\s-]{6,20}$")
            .When(x => !string.IsNullOrWhiteSpace(x.PhoneNumber))
            .WithMessage("Phone number format is invalid.");

        RuleFor(x => x.Email)
            .EmailAddress()
            .When(x => !string.IsNullOrWhiteSpace(x.Email))
            .WithMessage("A valid email address is required.")
            .MaximumLength(256);

        RuleFor(x => x.AddressLine).MaximumLength(500);
        RuleFor(x => x.City).MaximumLength(100);
        RuleFor(x => x.District).MaximumLength(100);

        // Province is the official 1-7 number; WardNumber is 1-35. Both are
        // nullable (a business may not have filled them in).
        RuleFor(x => x.Province)
            .InclusiveBetween(NepalAddress.MinProvince, NepalAddress.MaxProvince)
            .When(x => x.Province.HasValue)
            .WithMessage($"Province must be between {NepalAddress.MinProvince} and {NepalAddress.MaxProvince}.");

        RuleFor(x => x.WardNumber)
            .InclusiveBetween(1, NepalAddress.MaxWardNumber)
            .When(x => x.WardNumber.HasValue)
            .WithMessage($"Ward number must be between 1 and {NepalAddress.MaxWardNumber}.");

        // If a district was given, the province must agree with the official
        // district-to-province table. Catching this here keeps a bad pair out
        // rather than letting a report group Kathmandu under Karnali.
        RuleFor(x => x)
            .Must(x => !x.Province.HasValue
                       || string.IsNullOrWhiteSpace(x.District)
                       || NepalAddress.ProvinceForDistrict(x.District) is not int known
                       || known == x.Province.Value)
            .WithName("Province")
            .WithMessage("Province does not match the selected district.");

        RuleFor(x => x.Currency)
            .Must(c => string.IsNullOrEmpty(c) || (c.Length == 3 && c.All(char.IsLetter)))
            .WithMessage("Currency must be a 3-letter code (e.g. NPR).");
    }
}

public class UpdateBusinessRequestValidator : AbstractValidator<UpdateBusinessRequest>
{
    public UpdateBusinessRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Business name is required.")
            .MaximumLength(200);

        RuleFor(x => x.Type).MaximumLength(50);
        RuleFor(x => x.PanNumber)
            .MaximumLength(50)
            .Matches(@"^\d{9}$")
            .When(x => !string.IsNullOrWhiteSpace(x.PanNumber))
            .WithMessage("PAN must be a 9-digit number.");

        RuleFor(x => x.PhoneNumber)
            .MaximumLength(20)
            .Matches(@"^\+?[\d\s-]{6,20}$")
            .When(x => !string.IsNullOrWhiteSpace(x.PhoneNumber))
            .WithMessage("Phone number format is invalid.");

        RuleFor(x => x.Email)
            .EmailAddress()
            .When(x => !string.IsNullOrWhiteSpace(x.Email))
            .WithMessage("A valid email address is required.")
            .MaximumLength(256);

        RuleFor(x => x.AddressLine).MaximumLength(500);
        RuleFor(x => x.City).MaximumLength(100);
        RuleFor(x => x.District).MaximumLength(100);

        // Province is the official 1-7 number; WardNumber is 1-35. Both are
        // nullable (a business may not have filled them in).
        RuleFor(x => x.Province)
            .InclusiveBetween(NepalAddress.MinProvince, NepalAddress.MaxProvince)
            .When(x => x.Province.HasValue)
            .WithMessage($"Province must be between {NepalAddress.MinProvince} and {NepalAddress.MaxProvince}.");

        RuleFor(x => x.WardNumber)
            .InclusiveBetween(1, NepalAddress.MaxWardNumber)
            .When(x => x.WardNumber.HasValue)
            .WithMessage($"Ward number must be between 1 and {NepalAddress.MaxWardNumber}.");

        // If a district was given, the province must agree with the official
        // district-to-province table. Catching this here keeps a bad pair out
        // rather than letting a report group Kathmandu under Karnali.
        RuleFor(x => x)
            .Must(x => !x.Province.HasValue
                       || string.IsNullOrWhiteSpace(x.District)
                       || NepalAddress.ProvinceForDistrict(x.District) is not int known
                       || known == x.Province.Value)
            .WithName("Province")
            .WithMessage("Province does not match the selected district.");
        RuleFor(x => x.LogoUrl).MaximumLength(512);

        RuleFor(x => x.Currency)
            .Must(c => string.IsNullOrEmpty(c) || (c.Length == 3 && c.All(char.IsLetter)))
            .WithMessage("Currency must be a 3-letter code (e.g. NPR).");
    }
}

public class InviteMemberRequestValidator : AbstractValidator<InviteMemberRequest>
{
    public InviteMemberRequestValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required.")
            .EmailAddress().WithMessage("A valid email address is required.")
            .MaximumLength(256);

        RuleFor(x => x.Role)
            .Must(SystemRoles.Exists)
            .WithMessage($"Role must be one of: {string.Join(", ", SystemRoles.All)}.");
    }
}

public class UpdateMemberRoleRequestValidator : AbstractValidator<UpdateMemberRoleRequest>
{
    public UpdateMemberRoleRequestValidator()
    {
        RuleFor(x => x.Role)
            .Must(SystemRoles.Exists)
            .WithMessage($"Role must be one of: {string.Join(", ", SystemRoles.All)}.");
    }
}
