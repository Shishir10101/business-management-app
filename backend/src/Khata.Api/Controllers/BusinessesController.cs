namespace Khata.Api.Controllers;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

/// <summary>
/// Business (tenant) setup, switching, and staff management.
/// </summary>
/// <remarks>
/// Endpoints marked with a permission policy require the caller's role in their
/// ACTIVE business to grant it; the BusinessService additionally verifies
/// membership and role within the target business on every call.
/// </remarks>
[ApiController]
[Route("api/businesses")]
[Authorize]
public class BusinessesController : ControllerBase
{
    private readonly IBusinessService _businessService;
    private readonly IAuthRepository _authRepo;
    private readonly ITokenService _tokenService;
    private readonly ICurrentUserService _currentUser;

    public BusinessesController(
        IBusinessService businessService,
        IAuthRepository authRepo,
        ITokenService tokenService,
        ICurrentUserService currentUser)
    {
        _businessService = businessService;
        _authRepo = authRepo;
        _tokenService = tokenService;
        _currentUser = currentUser;
    }

    /// <summary>Lists all businesses the current user belongs to.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<BusinessDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<BusinessDto>>> GetMyBusinesses()
    {
        var userId = RequireUserId();
        return Ok(await _businessService.GetMyBusinessesAsync(userId));
    }

    /// <summary>Creates a business; the creator becomes its Owner and it becomes active.</summary>
    [HttpPost]
    [ProducesResponseType(typeof(BusinessDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<BusinessDto>> Create([FromBody] CreateBusinessRequest request)
    {
        var userId = RequireUserId();
        var business = await _businessService.CreateBusinessAsync(userId, request);
        return CreatedAtAction(nameof(Get), new { id = business.Id }, business);
    }

    /// <summary>Gets a business the user is a member of. Non-members get 404.</summary>
    [HttpGet("{id:long}")]
    [ProducesResponseType(typeof(BusinessDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<BusinessDto>> Get(long id)
    {
        var userId = RequireUserId();
        return Ok(await _businessService.GetBusinessAsync(userId, id));
    }

    /// <summary>Updates a business profile. Owner/Admin only.</summary>
    [HttpPut("{id:long}")]
    [Authorize(Policy = Permissions.SettingsManage)]
    [ProducesResponseType(typeof(BusinessDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<BusinessDto>> Update(long id, [FromBody] UpdateBusinessRequest request)
    {
        var userId = RequireUserId();
        return Ok(await _businessService.UpdateBusinessAsync(userId, id, request));
    }

    /// <summary>Soft-deletes a business. Owner only.</summary>
    [HttpDelete("{id:long}")]
    [Authorize(Policy = Permissions.SettingsManage)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(long id)
    {
        var userId = RequireUserId();
        await _businessService.DeleteBusinessAsync(userId, id);
        return NoContent();
    }

    /// <summary>
    /// Switches the user's active business. Issues a fresh JWT whose "bid" claim
    /// and permission set now reflect the selected business.
    /// </summary>
    [HttpPost("{id:long}/switch")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status403Forbidden)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AuthResponse>> Switch(long id)
    {
        var userId = RequireUserId();

        // Validates membership and stores the new active business.
        await _authRepo.SetActiveBusinessAsync(userId, id);

        var businesses = await _authRepo.GetUserBusinessesAsync(userId);
        var active = businesses.FirstOrDefault(b => b.businessId == id);
        if (active == default)
            throw new Domain.Exceptions.NotFoundException("Business", id);

        var roles = active.roleName is null ? [] : new List<string> { active.roleName };
        var permissions = (await _authRepo.GetBusinessPermissionsAsync(userId, id)).ToList();

        var (accessToken, refreshToken, expiresAt) = await _tokenService.GenerateAccessTokenAsync(
            userId, _currentUser.Email ?? "", _currentUser.FullName ?? "",
            id, roles, permissions, default);

        var expiresIn = (int)(expiresAt - DateTime.UtcNow).TotalSeconds;
        var businessDtos = businesses
            .Select(b => new BusinessSummary(b.businessId, b.businessName, b.roleName))
            .ToList();

        // The switched-business token must carry the account's locale, like the
        // login response does, or the app drops back to a guess.
        var locale = (await _authRepo.GetUserByEmailAsync(
            _currentUser.Email ?? "", default))?.locale;

        return Ok(new AuthResponse(
            userId, _currentUser.Email ?? "", _currentUser.FullName ?? "",
            accessToken, refreshToken, expiresIn,
            string.IsNullOrWhiteSpace(locale) ? "en" : locale,
            businessDtos));
    }

    /// <summary>Lists the members (staff) of a business. Owner/Admin only.</summary>
    [HttpGet("{id:long}/members")]
    [Authorize(Policy = Permissions.SettingsManage)]
    [ProducesResponseType(typeof(IReadOnlyList<BusinessMemberDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IReadOnlyList<BusinessMemberDto>>> GetMembers(long id)
    {
        var userId = RequireUserId();
        return Ok(await _businessService.GetMembersAsync(userId, id));
    }

    /// <summary>Invites an existing user to the business. Owner/Admin only.</summary>
    [HttpPost("{id:long}/members")]
    [Authorize(Policy = Permissions.SettingsManage)]
    [ProducesResponseType(typeof(BusinessMemberDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<ActionResult<BusinessMemberDto>> Invite(long id, [FromBody] InviteMemberRequest request)
    {
        var userId = RequireUserId();
        var member = await _businessService.InviteMemberAsync(userId, id, request);
        return CreatedAtAction(nameof(GetMembers), new { id }, member);
    }

    /// <summary>Changes a member's role. Owner/Admin only. Cannot demote the last Owner.</summary>
    [HttpPut("{id:long}/members/{memberId:long}")]
    [Authorize(Policy = Permissions.SettingsManage)]
    [ProducesResponseType(typeof(BusinessMemberDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status422UnprocessableEntity)]
    public async Task<ActionResult<BusinessMemberDto>> UpdateMemberRole(
        long id, long memberId, [FromBody] UpdateMemberRoleRequest request)
    {
        var userId = RequireUserId();
        return Ok(await _businessService.UpdateMemberRoleAsync(userId, id, memberId, request));
    }

    /// <summary>Removes a member. Owner/Admin only. Cannot remove the last Owner.</summary>
    [HttpDelete("{id:long}/members/{memberId:long}")]
    [Authorize(Policy = Permissions.SettingsManage)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> RemoveMember(long id, long memberId)
    {
        var userId = RequireUserId();
        await _businessService.RemoveMemberAsync(userId, id, memberId);
        return NoContent();
    }

    // --- Bank accounts ---

    [HttpGet("{id:long}/bank-accounts")]
    [Authorize(Policy = Permissions.SettingsManage)]
    [ProducesResponseType(typeof(IReadOnlyList<BankAccountDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<BankAccountDto>>> GetBankAccounts(long id)
        => Ok(await _businessService.GetBankAccountsAsync(RequireUserId(), id));

    [HttpPost("{id:long}/bank-accounts")]
    [Authorize(Policy = Permissions.SettingsManage)]
    [ProducesResponseType(typeof(BankAccountDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<BankAccountDto>> AddBankAccount(
        long id, [FromBody] CreateBankAccountRequest request)
    {
        var account = await _businessService.AddBankAccountAsync(RequireUserId(), id, request);
        return CreatedAtAction(nameof(GetBankAccounts), new { id }, account);
    }

    [HttpPut("{id:long}/bank-accounts/{accountId:long}")]
    [Authorize(Policy = Permissions.SettingsManage)]
    [ProducesResponseType(typeof(BankAccountDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<ActionResult<BankAccountDto>> UpdateBankAccount(
        long id, long accountId, [FromBody] UpdateBankAccountRequest request)
        => Ok(await _businessService.UpdateBankAccountAsync(
            RequireUserId(), id, accountId, request));

    [HttpDelete("{id:long}/bank-accounts/{accountId:long}")]
    [Authorize(Policy = Permissions.SettingsManage)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RemoveBankAccount(long id, long accountId)
    {
        await _businessService.RemoveBankAccountAsync(RequireUserId(), id, accountId);
        return NoContent();
    }

    private long RequireUserId()
        => _currentUser.UserId ?? throw new Domain.Exceptions.UnauthorizedException();
}
