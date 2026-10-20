namespace Khata.Application.DTOs;

public record RegisterRequest(
    string FullName,
    string Email,
    string Password,
    string? PhoneNumber,
    string Locale = "ne"
);

public record LoginRequest(
    string Email,
    string Password
);

public record RefreshRequest(
    string RefreshToken
);

public record AuthResponse(
    long UserId,
    string Email,
    string FullName,
    string AccessToken,
    string RefreshToken,
    int ExpiresIn,
    // Returned so the client can open in the language the account was saved
    // with, instead of defaulting to one on a guess.
    string Locale,
    IReadOnlyList<BusinessSummary>? Businesses
);

public record BusinessSummary(
    long Id,
    string Name,
    string Role
);

public record UserProfileDto(
    long Id,
    string Email,
    string FullName,
    string? PhoneNumber,
    string Locale,
    string Timezone,
    string? ProfileImageUrl
);

public record UpdateProfileRequest(
    string FullName,
    string? PhoneNumber,
    string Locale
);

public record ChangePasswordRequest(
    string CurrentPassword,
    string NewPassword
);
