namespace Khata.Application.Common;

/// <summary>
/// System role names seeded at startup. Used by the role-permission seeder,
/// request validators, and authorization policies.
/// </summary>
public static class SystemRoles
{
    public const string Owner = "Owner";
    public const string Admin = "Admin";
    public const string Manager = "Manager";
    public const string Accountant = "Accountant";
    public const string SalesStaff = "SalesStaff";
    public const string InventoryStaff = "InventoryStaff";
    public const string Viewer = "Viewer";

    /// <summary>
    /// Platform administrator. NOT a business role: a SuperAdmin acts across
    /// all tenants from the admin console and carries the <c>admin.access</c>
    /// permission regardless of any business membership. Membership is
    /// granted directly through ASP.NET Identity (UserManager), not through
    /// BusinessMember rows.
    /// </summary>
    public const string SuperAdmin = "SuperAdmin";

    public static readonly IReadOnlyList<string> All =
        [Owner, Admin, Manager, Accountant, SalesStaff, InventoryStaff, Viewer, SuperAdmin];

    public static bool Exists(string roleName) => All.Contains(roleName);
}
