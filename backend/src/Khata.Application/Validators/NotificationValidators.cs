namespace Khata.Application.Validators;

using FluentValidation;
using Khata.Application.DTOs;

public class RegisterDeviceRequestValidator : AbstractValidator<RegisterDeviceRequest>
{
    public RegisterDeviceRequestValidator()
    {
        RuleFor(x => x.Token)
            .NotEmpty().WithMessage("Device token is required.")
            .MaximumLength(512);
        RuleFor(x => x.Platform).IsInEnum();
    }
}

/// <summary>
/// All booleans — nothing to validate beyond the shape, but registering the
/// validator keeps the request flowing through the shared pipeline.
/// </summary>
public class UpdateNotificationSettingsRequestValidator : AbstractValidator<UpdateNotificationSettingsRequest>
{
}

public class CreateReminderRequestValidator : AbstractValidator<CreateReminderRequest>
{
    public CreateReminderRequestValidator()
    {
        RuleFor(x => x.Title)
            .NotEmpty().WithMessage("Title is required.")
            .MaximumLength(200);
        RuleFor(x => x.Notes).MaximumLength(1000);
        RuleFor(x => x.DueAt).NotEmpty();
        RuleFor(x => x.Repeat).IsInEnum();
        RuleFor(x => x.RelatedEntityType).MaximumLength(30);
    }
}

public class UpdateReminderRequestValidator : AbstractValidator<UpdateReminderRequest>
{
    public UpdateReminderRequestValidator()
    {
        RuleFor(x => x.Title)
            .NotEmpty().WithMessage("Title is required.")
            .MaximumLength(200);
        RuleFor(x => x.Notes).MaximumLength(1000);
        RuleFor(x => x.DueAt).NotEmpty();
        RuleFor(x => x.Repeat).IsInEnum();
    }
}
