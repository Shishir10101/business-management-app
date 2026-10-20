namespace Khata.Domain.Entities;

using Khata.Domain.Common;

public class Business : SoftDeletableEntity
{

    public string Name { get; set; } = string.Empty;
    public string? Type { get; set; }
    public string? PanNumber { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Email { get; set; }
    public string? AddressLine { get; set; }
    public string? City { get; set; }
    public string? District { get; set; }

    /// <summary>
    /// Official province number 1–7 (1 = Koshi in the east, 7 = Sudurpashchim
    /// in the west). Nullable because a business may not have filled it in;
    /// range rules live in <c>NepalAddress</c>. Was free text before
    /// 2026-10-15, which made province reporting impossible.
    /// </summary>
    public int? Province { get; set; }

    /// <summary>Ward number within the municipality, 1–35.</summary>
    public int? WardNumber { get; set; }
    public string? LogoUrl { get; set; }
    public string Currency { get; set; } = "NPR";
    public DateOnly? FiscalYearStart { get; set; }
    public bool IsActive { get; set; } = true;

    public ICollection<BusinessMember> Members { get; set; } = [];
    public ICollection<BusinessBankAccount> BankAccounts { get; set; } = [];
}

public class BusinessMember : SoftDeletableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public long UserId { get; set; }

    public long RoleId { get; set; }

    public bool IsActive { get; set; } = true;
    public DateTime? InvitedAt { get; set; }
    public DateTime? JoinedAt { get; set; }
}

public class BusinessBankAccount : SoftDeletableEntity, IBusinessEntity
{
    public long BusinessId { get; set; }
    public Business Business { get; set; } = null!;

    public string BankName { get; set; } = string.Empty;
    public string AccountName { get; set; } = string.Empty;
    public string AccountNumber { get; set; } = string.Empty;
    public string? Branch { get; set; }
    public bool IsDefault { get; set; }
    public bool IsActive { get; set; } = true;
}
