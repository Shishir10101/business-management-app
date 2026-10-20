namespace Khata.Application.Interfaces;

using Khata.Application.DTOs;

/// <summary>
/// Business (tenant) setup, membership management, and staff administration.
/// Every method is user-scoped: the caller's membership is verified inside.
/// </summary>
public interface IBusinessService
{
    /// <summary>All businesses the user is an active member of.</summary>
    Task<IReadOnlyList<BusinessDto>> GetMyBusinessesAsync(long userId,
        CancellationToken cancellationToken = default);

    /// <summary>Creates a business; the creator becomes its Owner and it becomes their active business.</summary>
    Task<BusinessDto> CreateBusinessAsync(long userId, CreateBusinessRequest request,
        CancellationToken cancellationToken = default);

    Task<BusinessDto> GetBusinessAsync(long userId, long businessId,
        CancellationToken cancellationToken = default);

    Task<BusinessDto> UpdateBusinessAsync(long userId, long businessId, UpdateBusinessRequest request,
        CancellationToken cancellationToken = default);

    /// <summary>Soft-deletes a business. Owner-only, enforced in the implementation.</summary>
    Task DeleteBusinessAsync(long userId, long businessId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<BusinessMemberDto>> GetMembersAsync(long userId, long businessId,
        CancellationToken cancellationToken = default);

    /// <summary>Invites an existing user to the business. Owner/Admin only.</summary>
    Task<BusinessMemberDto> InviteMemberAsync(long userId, long businessId, InviteMemberRequest request,
        CancellationToken cancellationToken = default);

    Task<BusinessMemberDto> UpdateMemberRoleAsync(long userId, long businessId, long memberId,
        UpdateMemberRoleRequest request, CancellationToken cancellationToken = default);

    Task RemoveMemberAsync(long userId, long businessId, long memberId,
        CancellationToken cancellationToken = default);

    // --- Bank accounts ---

    Task<IReadOnlyList<BankAccountDto>> GetBankAccountsAsync(long userId, long businessId,
        CancellationToken cancellationToken = default);

    Task<BankAccountDto> AddBankAccountAsync(long userId, long businessId,
        CreateBankAccountRequest request, CancellationToken cancellationToken = default);

    Task<BankAccountDto> UpdateBankAccountAsync(long userId, long businessId, long accountId,
        UpdateBankAccountRequest request, CancellationToken cancellationToken = default);

    Task RemoveBankAccountAsync(long userId, long businessId, long accountId,
        CancellationToken cancellationToken = default);
}
