namespace Khata.Infrastructure.Services;

using Khata.Application.Interfaces;
using Khata.Domain.Entities;
using Khata.Domain.Exceptions;
using Khata.Infrastructure.Data;
using Khata.Infrastructure.Identity;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

public class AuthRepository : IAuthRepository
{
    private readonly UserManager<AppUser> _userManager;
    private readonly SignInManager<AppUser> _signInManager;
    private readonly KhataDbContext _db;

    public AuthRepository(
        UserManager<AppUser> userManager,
        SignInManager<AppUser> signInManager,
        KhataDbContext db)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _db = db;
    }

    public async Task<bool> EmailExistsAsync(string email, CancellationToken cancellationToken = default)
    {
        return await _userManager.FindByEmailAsync(email) is not null;
    }

    public async Task<long> CreateUserAsync(string email, string fullName, string passwordHash,
        string? phoneNumber, string locale, CancellationToken cancellationToken = default)
    {
        var user = new AppUser
        {
            UserName = email,
            Email = email,
            FullName = fullName,
            PhoneNumber = phoneNumber,
            Locale = locale,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
        };

        var result = await _userManager.CreateAsync(user, passwordHash);
        if (!result.Succeeded)
        {
            // Identity's password policy is a USER error, not a server fault:
            // surface it as a 400 with the policy messages so the register
            // screen can show "Passwords must have at least one digit" instead
            // of "An unexpected error occurred".
            var errors = result.Errors
                .GroupBy(e => FieldFor(e.Code))
                .ToDictionary(
                    g => g.Key,
                    g => g.Select(e => e.Description).ToArray());
            throw new ValidationException(errors);
        }

        return user.Id;
    }

    /// <summary>Maps an Identity error code onto the form field it belongs to.</summary>
    private static string FieldFor(string code)
    {
        if (code.StartsWith("Password", StringComparison.OrdinalIgnoreCase))
            return "password";
        if (code.Contains("Email", StringComparison.OrdinalIgnoreCase)
            || code == "DuplicateUserName")
            return "email";
        return "user";
    }

    public async Task<(long userId, string fullName, string email, string? passwordHash, bool isActive,
        long? activeBusinessId, string? locale)?>
        GetUserByEmailAsync(string email, CancellationToken cancellationToken = default)
    {
        var user = await _userManager.FindByEmailAsync(email);
        if (user is null) return null;

        return (user.Id, user.FullName, user.Email!, user.PasswordHash, user.IsActive,
            user.ActiveBusinessId, user.Locale);
    }

    public async Task<bool> VerifyPasswordAsync(string email, string password, CancellationToken cancellationToken = default)
    {
        var user = await _userManager.FindByEmailAsync(email);
        if (user is null || !user.IsActive) return false;

        var result = await _signInManager.CheckPasswordSignInAsync(user, password, lockoutOnFailure: true);
        return result.Succeeded;
    }

    public async Task UpdateUserLoginAsync(long userId, CancellationToken cancellationToken = default)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user is null) return;

        await _userManager.UpdateSecurityStampAsync(user);
    }

    public async Task<IReadOnlyList<(long businessId, string businessName, string roleName)>>
        GetUserBusinessesAsync(long userId, CancellationToken cancellationToken = default)
    {
        // IgnoreQueryFilters: this lists the user's memberships across ALL businesses,
        // which the tenant filter (active business of the current request) would hide.
        var results = await (
            from bm in _db.BusinessMembers.IgnoreQueryFilters()
            join b in _db.Businesses on bm.BusinessId equals b.Id
            join r in _db.Roles on bm.RoleId equals r.Id
            where bm.UserId == userId && bm.DeletedAt == null && b.DeletedAt == null
            select new { b.Id, b.Name, RoleName = r.Name }
        ).ToListAsync(cancellationToken);

        return results.Select(r => (r.Id, r.Name, r.RoleName!)).ToList();
    }

    public async Task<IReadOnlyList<string>> GetBusinessPermissionsAsync(long userId, long businessId,
        CancellationToken cancellationToken = default)
    {
        // IgnoreQueryFilters: called with the target business, not necessarily the
        // caller's currently active one.
        var perms = await (from bm in _db.BusinessMembers.IgnoreQueryFilters()
                           join rp in _db.RolePermissions on bm.RoleId equals rp.RoleId
                           where bm.UserId == userId && bm.BusinessId == businessId
                               && bm.DeletedAt == null && bm.IsActive
                           select rp.Permission.Code)
                          .Distinct()
                          .ToListAsync(cancellationToken);
        return perms;
    }

    public async Task<(string fullName, string? phoneNumber, string locale, string timezone, string? profileImageUrl)>
        GetUserProfileAsync(long userId, CancellationToken cancellationToken = default)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId, cancellationToken)
            ?? throw new InvalidOperationException("User not found.");

        return (user.FullName, user.PhoneNumber, user.Locale, user.Timezone, user.ProfileImageUrl);
    }

    public async Task UpdateUserProfileAsync(long userId, string fullName, string? phoneNumber,
        string locale, CancellationToken cancellationToken = default)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId, cancellationToken)
            ?? throw new InvalidOperationException("User not found.");

        user.FullName = fullName;
        user.PhoneNumber = phoneNumber;
        user.Locale = locale;
        user.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);
    }

    public async Task<bool> ChangePasswordAsync(long userId, string currentPassword, string newPassword,
        CancellationToken cancellationToken = default)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());
        if (user is null) return false;

        var result = await _userManager.ChangePasswordAsync(user, currentPassword, newPassword);
        return result.Succeeded;
    }

    public async Task SetActiveBusinessAsync(long userId, long businessId, CancellationToken cancellationToken = default)
    {
        // Validate the user actually holds an active membership in this business.
        var isMember = await _db.BusinessMembers.IgnoreQueryFilters()
            .AnyAsync(bm => bm.UserId == userId && bm.BusinessId == businessId
                && bm.DeletedAt == null && bm.IsActive, cancellationToken);

        if (!isMember)
            throw new Khata.Domain.Exceptions.NotFoundException("Business", businessId);

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);
        if (user is null) return;

        user.ActiveBusinessId = businessId;
        user.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);
    }
}
