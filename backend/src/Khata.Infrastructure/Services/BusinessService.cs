namespace Khata.Infrastructure.Services;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Domain.Entities;
using Khata.Domain.Exceptions;
using Khata.Infrastructure.Data;
using Khata.Infrastructure.Identity;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

/// <summary>
/// Business setup, membership management, and staff administration.
/// </summary>
/// <remarks>
/// NOTE: <see cref="BusinessMember"/> implements <see cref="Khata.Domain.Common.IBusinessEntity"/>,
/// so the DbContext global query filter (active business of the current request) would hide
/// memberships of OTHER businesses. Membership queries therefore always use
/// <c>IgnoreQueryFilters()</c> plus an explicit user/business predicate — the service itself
/// is the authorization boundary.
/// </remarks>
public class BusinessService : IBusinessService
{
    private readonly KhataDbContext _db;
    private readonly UserManager<AppUser> _userManager;
    private readonly RoleManager<AppRole> _roleManager;
    private readonly IDateTimeProvider _clock;

    public BusinessService(
        KhataDbContext db,
        UserManager<AppUser> userManager,
        RoleManager<AppRole> roleManager,
        IDateTimeProvider clock)
    {
        _db = db;
        _userManager = userManager;
        _roleManager = roleManager;
        _clock = clock;
    }

    public async Task<IReadOnlyList<BusinessDto>> GetMyBusinessesAsync(long userId,
        CancellationToken cancellationToken = default)
    {
        var rows = await (
            from bm in _db.BusinessMembers.IgnoreQueryFilters()
            join b in _db.Businesses on bm.BusinessId equals b.Id
            join r in _db.Roles on bm.RoleId equals r.Id
            where bm.UserId == userId && bm.DeletedAt == null && b.DeletedAt == null
            orderby bm.Id
            select new { b, RoleName = r.Name }
        ).ToListAsync(cancellationToken);

        return rows.Select(x => ToDto(x.b, x.RoleName!)).ToList();
    }

    public async Task<BusinessDto> CreateBusinessAsync(long userId, CreateBusinessRequest request,
        CancellationToken cancellationToken = default)
    {
        var ownerRole = await _roleManager.FindByNameAsync(SystemRoles.Owner)
            ?? throw new BusinessRuleException("seed_missing",
                "System roles have not been seeded. Contact support.");

        var now = _clock.UtcNow;

        var business = new Business
        {
            Name = request.Name,
            Type = request.Type,
            PanNumber = request.PanNumber,
            PhoneNumber = request.PhoneNumber,
            Email = request.Email,
            AddressLine = request.AddressLine,
            City = request.City,
            District = request.District,
            Province = request.Province,
            WardNumber = request.WardNumber,
            Currency = NormalizeCurrency(request.Currency),
            IsActive = true,
            CreatedAt = now,
            UpdatedAt = now,
            CreatedBy = userId,
            UpdatedBy = userId,
        };
        _db.Businesses.Add(business);

        // Creator becomes Owner; the first business automatically becomes active.
        _db.BusinessMembers.Add(new BusinessMember
        {
            // Set the navigation (not BusinessId) so EF orders the INSERTs correctly
            // and propagates the generated Business.Id into the FK.
            Business = business,
            UserId = userId,
            RoleId = ownerRole.Id,
            IsActive = true,
            JoinedAt = now,
            CreatedAt = now,
            UpdatedAt = now,
            CreatedBy = userId,
            UpdatedBy = userId,
        });

        await _db.SaveChangesAsync(cancellationToken);

        // First business becomes the user's active selection.
        var user = await _userManager.FindByIdAsync(userId.ToString())
            ?? throw new NotFoundException("User", userId);
        user.ActiveBusinessId ??= business.Id;

        await _db.SaveChangesAsync(cancellationToken);

        // Seed the starter catalog (common units + a "General" category) and the
        // default payment methods so a new business is usable immediately.
        await SeedDefaultsAsync(business.Id, userId, now, cancellationToken);

        return ToDto(business, SystemRoles.Owner);
    }

    /// <summary>
    /// Seeds the default units (pcs, kg, g, L, box, dozen), a "General" category
    /// and the default payment methods for a brand-new business.
    /// </summary>
    private async Task SeedDefaultsAsync(long businessId, long userId, DateTime now, CancellationToken ct)
    {
        foreach (var (name, shortName) in ProductService.DefaultUnits)
        {
            _db.Units.Add(new Unit
            {
                BusinessId = businessId,
                Name = name,
                ShortName = shortName,
                IsActive = true,
                CreatedAt = now,
                UpdatedAt = now,
                CreatedBy = userId,
                UpdatedBy = userId,
            });
        }

        _db.ProductCategories.Add(new ProductCategory
        {
            BusinessId = businessId,
            Name = ProductService.DefaultCategoryName,
            IsActive = true,
            CreatedAt = now,
            UpdatedAt = now,
            CreatedBy = userId,
            UpdatedBy = userId,
        });

        foreach (var (name, code, isDefault) in PaymentMethodService.DefaultMethods)
        {
            _db.PaymentMethods.Add(new PaymentMethod
            {
                BusinessId = businessId,
                Name = name,
                Code = code,
                IsDefault = isDefault,
                IsActive = true,
                CreatedAt = now,
                UpdatedAt = now,
                CreatedBy = userId,
                UpdatedBy = userId,
            });
        }

        await _db.SaveChangesAsync(ct);
    }

    public async Task<BusinessDto> GetBusinessAsync(long userId, long businessId,
        CancellationToken cancellationToken = default)
    {
        var (business, roleName) = await LoadMembershipAsync(userId, businessId, cancellationToken);
        return ToDto(business, roleName);
    }

    public async Task<BusinessDto> UpdateBusinessAsync(long userId, long businessId, UpdateBusinessRequest request,
        CancellationToken cancellationToken = default)
    {
        var (business, roleName) = await LoadMembershipAsync(userId, businessId, cancellationToken);
        EnsureManagerRole(roleName);

        business.Name = request.Name;
        business.Type = request.Type;
        business.PanNumber = request.PanNumber;
        business.PhoneNumber = request.PhoneNumber;
        business.Email = request.Email;
        business.AddressLine = request.AddressLine;
        business.City = request.City;
        business.District = request.District;
        business.Province = request.Province;
        business.WardNumber = request.WardNumber;
        business.LogoUrl = request.LogoUrl;
        business.Currency = NormalizeCurrency(request.Currency);
        business.IsActive = request.IsActive;

        await _db.SaveChangesAsync(cancellationToken);

        return ToDto(business, roleName);
    }

    public async Task DeleteBusinessAsync(long userId, long businessId,
        CancellationToken cancellationToken = default)
    {
        var (business, roleName) = await LoadMembershipAsync(userId, businessId, cancellationToken);
        if (roleName != SystemRoles.Owner)
            throw new ForbiddenException("Only the business owner can delete the business.");

        // Soft delete (the DbContext converts this to a DeletedAt stamp).
        _db.Businesses.Remove(business);

        // Users whose active business was this one lose their selection.
        var affectedUsers = await _db.Users
            .Where(u => u.ActiveBusinessId == businessId)
            .ToListAsync(cancellationToken);
        foreach (var u in affectedUsers)
            u.ActiveBusinessId = null;

        await _db.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<BusinessMemberDto>> GetMembersAsync(long userId, long businessId,
        CancellationToken cancellationToken = default)
    {
        await LoadMembershipAsync(userId, businessId, cancellationToken); // membership check only

        var rows = await (
            from bm in _db.BusinessMembers.IgnoreQueryFilters()
            join u in _db.Users on bm.UserId equals u.Id
            join r in _db.Roles on bm.RoleId equals r.Id
            where bm.BusinessId == businessId && bm.DeletedAt == null
            orderby bm.Id
            select new { bm, u.Email, u.FullName, RoleName = r.Name }
        ).ToListAsync(cancellationToken);

        return rows.Select(x => ToMemberDto(x.bm, x.Email!, x.FullName, x.RoleName!)).ToList();
    }

    public async Task<BusinessMemberDto> InviteMemberAsync(long userId, long businessId, InviteMemberRequest request,
        CancellationToken cancellationToken = default)
    {
        var (_, roleName) = await LoadMembershipAsync(userId, businessId, cancellationToken);
        EnsureManagerRole(roleName);

        var role = await _roleManager.FindByNameAsync(request.Role)
            ?? throw new NotFoundException("Role", request.Role);

        var invitee = await _userManager.FindByEmailAsync(request.Email)
            ?? throw new NotFoundException("User", request.Email);

        var alreadyMember = await _db.BusinessMembers.IgnoreQueryFilters()
            .AnyAsync(bm => bm.BusinessId == businessId && bm.UserId == invitee.Id
                && bm.DeletedAt == null, cancellationToken);
        if (alreadyMember)
            throw new ConflictException(
                $"'{request.Email}' is already a member of this business.");

        var now = _clock.UtcNow;
        var member = new BusinessMember
        {
            BusinessId = businessId,
            UserId = invitee.Id,
            RoleId = role.Id,
            IsActive = true,
            InvitedAt = now,
            CreatedAt = now,
            UpdatedAt = now,
            CreatedBy = userId,
            UpdatedBy = userId,
        };
        _db.BusinessMembers.Add(member);

        await _db.SaveChangesAsync(cancellationToken);

        return ToMemberDto(member, invitee.Email!, invitee.FullName, role.Name!);
    }

    public async Task<BusinessMemberDto> UpdateMemberRoleAsync(long userId, long businessId, long memberId,
        UpdateMemberRoleRequest request, CancellationToken cancellationToken = default)
    {
        var (_, callerRole) = await LoadMembershipAsync(userId, businessId, cancellationToken);
        EnsureManagerRole(callerRole);

        var role = await _roleManager.FindByNameAsync(request.Role)
            ?? throw new NotFoundException("Role", request.Role);

        var member = await LoadMemberAsync(businessId, memberId, cancellationToken);

        // Guard: never demote the last Owner.
        if (member.RoleId != role.Id && await IsLastOwnerAsync(businessId, member.RoleId, cancellationToken))
            throw new BusinessRuleException("last_owner",
                "Cannot change the role of the only Owner. Assign another Owner first.");

        member.RoleId = role.Id;
        await _db.SaveChangesAsync(cancellationToken);

        var user = await _userManager.FindByIdAsync(member.UserId.ToString());
        return ToMemberDto(member, user?.Email ?? "", user?.FullName ?? "", role.Name!);
    }

    public async Task RemoveMemberAsync(long userId, long businessId, long memberId,
        CancellationToken cancellationToken = default)
    {
        var (_, callerRole) = await LoadMembershipAsync(userId, businessId, cancellationToken);
        EnsureManagerRole(callerRole);

        var member = await LoadMemberAsync(businessId, memberId, cancellationToken);

        // Guard: never remove the last Owner.
        if (await IsLastOwnerAsync(businessId, member.RoleId, cancellationToken))
            throw new BusinessRuleException("last_owner",
                "Cannot remove the only Owner. Assign another Owner first.");

        // Removed user loses their active-business selection if it was this business.
        if (member.UserId != userId)
        {
            var removedUser = await _userManager.FindByIdAsync(member.UserId.ToString());
            if (removedUser?.ActiveBusinessId == businessId)
                removedUser.ActiveBusinessId = null;
        }

        _db.BusinessMembers.Remove(member); // soft delete via DbContext override

        await _db.SaveChangesAsync(cancellationToken);
    }

    // --- helpers ---

    /// <summary>
    /// Loads the caller's membership in the business with the business and role names.
    /// Throws NotFound for non-members so business existence isn't leaked cross-tenant.
    /// </summary>
    // ---------------------------------------------------------------
    // Bank accounts
    // ---------------------------------------------------------------

    public async Task<IReadOnlyList<BankAccountDto>> GetBankAccountsAsync(
        long userId, long businessId, CancellationToken cancellationToken = default)
    {
        // Authorization: any member may read; mutating calls check the role.
        await LoadMembershipAsync(userId, businessId, cancellationToken);

        var accounts = await _db.BusinessBankAccounts
            .IgnoreQueryFilters()
            .Where(a => a.BusinessId == businessId && a.DeletedAt == null)
            .OrderByDescending(a => a.IsDefault)
            .ThenBy(a => a.BankName)
            .ToListAsync(cancellationToken);

        // Payments are append-only (ImmutableEntity) — there is no DeletedAt.
        var paymentTotals = await _db.Payments
            .IgnoreQueryFilters()
            .Where(p => p.BusinessId == businessId && p.BankAccountId != null)
            .GroupBy(p => p.BankAccountId!.Value)
            .Select(g => new { AccountId = g.Key, Count = g.Count(), Total = g.Sum(p => p.Amount) })
            .ToListAsync(cancellationToken);

        var byAccount = paymentTotals.ToDictionary(x => x.AccountId, x => x);

        return accounts.Select(a =>
        {
            var totals = byAccount.TryGetValue(a.Id, out var t) ? t : null;
            return new BankAccountDto(
                a.Id, a.BankName, a.AccountName, a.AccountNumber, a.Branch,
                a.IsDefault, a.IsActive, totals?.Count ?? 0, totals?.Total ?? 0);
        }).ToList();
    }

    public async Task<BankAccountDto> AddBankAccountAsync(
        long userId, long businessId, CreateBankAccountRequest request,
        CancellationToken cancellationToken = default)
    {
        var (_, callerRole) = await LoadMembershipAsync(userId, businessId, cancellationToken);
        EnsureManagerRole(callerRole);

        var accountNumber = request.AccountNumber?.Trim() ?? string.Empty;
        if (accountNumber.Length == 0)
            throw new ValidationException(new Dictionary<string, string[]>
            {
                [nameof(request.AccountNumber)] = ["Account number is required."],
            });

        // One default per business: setting a new one clears the old.
        if (request.IsDefault)
            await ClearDefaultAsync(businessId, cancellationToken);

        var account = new BusinessBankAccount
        {
            BusinessId = businessId,
            BankName = request.BankName.Trim(),
            AccountName = request.AccountName.Trim(),
            AccountNumber = accountNumber,
            Branch = string.IsNullOrWhiteSpace(request.Branch) ? null : request.Branch.Trim(),
            IsDefault = request.IsDefault,
            IsActive = true,
        };

        _db.BusinessBankAccounts.Add(account);
        await _db.SaveChangesAsync(cancellationToken);

        return new BankAccountDto(
            account.Id, account.BankName, account.AccountName, account.AccountNumber,
            account.Branch, account.IsDefault, account.IsActive, 0, 0);
    }

    public async Task<BankAccountDto> UpdateBankAccountAsync(
        long userId, long businessId, long accountId, UpdateBankAccountRequest request,
        CancellationToken cancellationToken = default)
    {
        var (_, callerRole) = await LoadMembershipAsync(userId, businessId, cancellationToken);
        EnsureManagerRole(callerRole);

        var account = await _db.BusinessBankAccounts
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(a => a.Id == accountId && a.BusinessId == businessId
                && a.DeletedAt == null, cancellationToken)
            ?? throw new NotFoundException("BankAccount", accountId);

        if (request.IsDefault && !account.IsDefault)
            await ClearDefaultAsync(businessId, cancellationToken);

        account.BankName = request.BankName.Trim();
        account.AccountName = request.AccountName.Trim();
        account.AccountNumber = (request.AccountNumber ?? string.Empty).Trim();
        account.Branch = string.IsNullOrWhiteSpace(request.Branch) ? null : request.Branch.Trim();
        account.IsDefault = request.IsDefault;
        account.IsActive = request.IsActive;
        account.UpdatedAt = _clock.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);

        var totals = await _db.Payments
            .IgnoreQueryFilters()
            .Where(p => p.BusinessId == businessId && p.BankAccountId == accountId)
            .GroupBy(p => p.BankAccountId)
            .Select(g => new { Count = g.Count(), Total = g.Sum(p => p.Amount) })
            .FirstOrDefaultAsync(cancellationToken);

        return new BankAccountDto(
            account.Id, account.BankName, account.AccountName, account.AccountNumber,
            account.Branch, account.IsDefault, account.IsActive,
            totals?.Count ?? 0, totals?.Total ?? 0);
    }

    public async Task RemoveBankAccountAsync(
        long userId, long businessId, long accountId, CancellationToken cancellationToken = default)
    {
        var (_, callerRole) = await LoadMembershipAsync(userId, businessId, cancellationToken);
        EnsureManagerRole(callerRole);

        var account = await _db.BusinessBankAccounts
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(a => a.Id == accountId && a.BusinessId == businessId
                && a.DeletedAt == null, cancellationToken)
            ?? throw new NotFoundException("BankAccount", accountId);

        // An account with recorded payments is history, not clutter: retire it
        // rather than delete, so the payment rows keep a valid reference.
        var hasPayments = await _db.Payments
            .IgnoreQueryFilters()
            .AnyAsync(p => p.BusinessId == businessId && p.BankAccountId == accountId,
                cancellationToken);

        if (hasPayments)
        {
            account.IsActive = false;
            account.IsDefault = false;
            account.UpdatedAt = _clock.UtcNow;
        }
        else
        {
            // Soft delete (DeletedAt) — the DbContext converts Deleted to Modified.
            _db.BusinessBankAccounts.Remove(account);
        }

        await _db.SaveChangesAsync(cancellationToken);
    }

    /// <summary>At most one default account per business.</summary>
    private async Task ClearDefaultAsync(long businessId, CancellationToken cancellationToken)
    {
        var currentDefaults = await _db.BusinessBankAccounts
            .IgnoreQueryFilters()
            .Where(a => a.BusinessId == businessId && a.IsDefault && a.DeletedAt == null)
            .ToListAsync(cancellationToken);

        foreach (var a in currentDefaults)
            a.IsDefault = false;
    }

    private async Task<(Business business, string roleName)> LoadMembershipAsync(
        long userId, long businessId, CancellationToken ct)
    {
        var row = await (
            from bm in _db.BusinessMembers.IgnoreQueryFilters()
            join b in _db.Businesses on bm.BusinessId equals b.Id
            join r in _db.Roles on bm.RoleId equals r.Id
            where bm.UserId == userId && bm.BusinessId == businessId
                && bm.DeletedAt == null && bm.IsActive && b.DeletedAt == null
            select new { b, RoleName = r.Name }
        ).FirstOrDefaultAsync(ct);

        if (row is null)
            throw new NotFoundException("Business", businessId);

        return (row.b, row.RoleName!);
    }

    private async Task<BusinessMember> LoadMemberAsync(long businessId, long memberId, CancellationToken ct)
    {
        var member = await _db.BusinessMembers.IgnoreQueryFilters()
            .FirstOrDefaultAsync(bm => bm.Id == memberId && bm.BusinessId == businessId
                && bm.DeletedAt == null, ct);

        return member ?? throw new NotFoundException("BusinessMember", memberId);
    }

    private async Task<bool> IsLastOwnerAsync(long businessId, long roleId, CancellationToken ct)
    {
        var ownerRole = await _roleManager.FindByNameAsync(SystemRoles.Owner);
        if (ownerRole is null || roleId != ownerRole.Id) return false;

        var ownerCount = await _db.BusinessMembers.IgnoreQueryFilters()
            .CountAsync(bm => bm.BusinessId == businessId && bm.RoleId == ownerRole.Id
                && bm.DeletedAt == null, ct);

        return ownerCount <= 1;
    }

    private static void EnsureManagerRole(string roleName)
    {
        if (roleName is not (SystemRoles.Owner or SystemRoles.Admin))
            throw new ForbiddenException("Only Owners and Admins can perform this action.");
    }

    private static string NormalizeCurrency(string? currency)
        => string.IsNullOrWhiteSpace(currency) ? "NPR" : currency.ToUpperInvariant();

    private static BusinessDto ToDto(Business b, string roleName) => new(        b.Id, b.Name, b.Type, b.PanNumber, b.PhoneNumber, b.Email, b.AddressLine,
        b.City, b.District, b.Province, b.WardNumber, b.LogoUrl, b.Currency, b.IsActive, roleName);

    private static BusinessMemberDto ToMemberDto(BusinessMember m, string email, string fullName, string roleName)
        => new(m.Id, m.UserId, email, fullName, roleName, m.IsActive, m.InvitedAt, m.JoinedAt);
}
