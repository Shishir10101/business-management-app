namespace Khata.Infrastructure.Identity;

using Microsoft.AspNetCore.Identity;

/// <summary>
/// Application user extending ASP.NET Core Identity user with Nepal-specific fields.
/// </summary>
public class AppUser : IdentityUser<long>
{
    public string FullName { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public bool PhoneConfirmed { get; set; }
    public string Locale { get; set; } = "ne";
    public string Timezone { get; set; } = "Asia/Kathmandu";
    public string? ProfileImageUrl { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public long CreatedBy { get; set; }
    public long UpdatedBy { get; set; }

    /// <summary>
    /// The business the user is currently working in (drives the "bid" JWT claim).
    /// Null when the user has no business yet.
    /// </summary>
    public long? ActiveBusinessId { get; set; }

    // Navigation: user's business memberships
    public ICollection<Domain.Entities.BusinessMember> BusinessMemberships { get; set; } = [];
}

/// <summary>
/// Application role extending ASP.NET Core Identity role.
/// </summary>
public class AppRole : IdentityRole<long>
{
    public string? Description { get; set; }
    public bool IsSystem { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public long CreatedBy { get; set; }
    public long UpdatedBy { get; set; }

    public ICollection<RolePermission> RolePermissions { get; set; } = [];
}

/// <summary>
/// Permission entity: granular authorization codes like "sales.create".
/// </summary>
public class Permission
{
    public long Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Category { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public long CreatedBy { get; set; }
    public long UpdatedBy { get; set; }

    public ICollection<RolePermission> RolePermissions { get; set; } = [];
}

/// <summary>
/// Join entity between roles and permissions.
/// </summary>
public class RolePermission
{
    public long RoleId { get; set; }
    public AppRole Role { get; set; } = null!;

    public long PermissionId { get; set; }
    public Permission Permission { get; set; } = null!;
}
