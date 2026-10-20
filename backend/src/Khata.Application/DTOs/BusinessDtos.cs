namespace Khata.Application.DTOs;

public record CreateBusinessRequest(
    string Name,
    string? Type = null,
    string? PanNumber = null,
    string? PhoneNumber = null,
    string? Email = null,
    string? AddressLine = null,
    string? City = null,
    string? District = null,
    int? Province = null,
    int? WardNumber = null,
    // Null means "use the business default" (NPR).
    string? Currency = null
);

/// <summary>Full update of a business profile (Name required, rest optional).</summary>
public record UpdateBusinessRequest(
    string Name,
    string? Type = null,
    string? PanNumber = null,
    string? PhoneNumber = null,
    string? Email = null,
    string? AddressLine = null,
    string? City = null,
    string? District = null,
    int? Province = null,
    int? WardNumber = null,
    string? LogoUrl = null,
    string? Currency = null,
    bool IsActive = true
);

public record BusinessDto(
    long Id,
    string Name,
    string? Type,
    string? PanNumber,
    string? PhoneNumber,
    string? Email,
    string? AddressLine,
    string? City,
    string? District,
    int? Province,
    int? WardNumber,
    string? LogoUrl,
    string Currency,
    bool IsActive,
    string Role
);

public record BusinessMemberDto(
    long Id,
    long UserId,
    string Email,
    string FullName,
    string Role,
    bool IsActive,
    DateTime? InvitedAt,
    DateTime? JoinedAt
);

public record InviteMemberRequest(
    string Email,
    string Role
);

public record UpdateMemberRoleRequest(
    string Role
);

// ==============================================================
// Bank accounts
// ==============================================================

public record BankAccountDto(
    long Id,
    string BankName,
    string AccountName,
    string AccountNumber,
    string? Branch,
    bool IsDefault,
    bool IsActive,
    // Payments recorded against this account.
    int PaymentCount,
    long TotalPaisa
);

public record CreateBankAccountRequest(
    string BankName,
    string AccountName,
    string AccountNumber,
    string? Branch = null,
    bool IsDefault = false
);

public record UpdateBankAccountRequest(
    string BankName,
    string AccountName,
    string AccountNumber,
    string? Branch = null,
    bool IsDefault = false,
    bool IsActive = true
);
