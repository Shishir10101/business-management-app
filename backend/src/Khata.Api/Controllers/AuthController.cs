namespace Khata.Api.Controllers;

using System.Security.Claims;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.IdentityModel.Tokens;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthRepository _authRepo;
    private readonly ITokenService _tokenService;

    public AuthController(IAuthRepository authRepo, ITokenService tokenService)
    {
        _authRepo = authRepo;
        _tokenService = tokenService;
    }

    [HttpPost("register")]
    [EnableRateLimiting("auth")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<AuthResponse>> Register([FromBody] RegisterRequest request)
    {
        if (await _authRepo.EmailExistsAsync(request.Email))
            return BadRequest(new ProblemDetails
            {
                Title = "Email already exists",
                Status = 400,
                Detail = $"The email '{request.Email}' is already registered."
            });

        // Password strength is enforced by Identity's policy (see
        // AddKhataInfrastructure) and surfaces through CreateUserAsync as a
        // ValidationException. Deliberately not duplicated here: a second copy
        // of the rule drifts, and then the error message contradicts the policy.

        // Create user (password is hashed internally by Identity UserManager)
        // We pass the plain password as the "passwordHash" param — the AuthRepository
        // uses UserManager.CreateAsync which handles hashing.
        var userId = await _authRepo.CreateUserAsync(
            request.Email, request.FullName, request.Password,
            request.PhoneNumber, request.Locale);

        // Generate tokens
        var (accessToken, refreshToken, expiresAt) = await _tokenService.GenerateAccessTokenAsync(
            userId, request.Email, request.FullName, null, [], [], default);

        var expiresIn = (int)(expiresAt - DateTime.UtcNow).TotalSeconds;

        return CreatedAtAction(nameof(Me), new { }, new AuthResponse(
            userId, request.Email, request.FullName,
            accessToken, refreshToken, expiresIn,
            string.IsNullOrWhiteSpace(request.Locale) ? "en" : request.Locale,
            null));
    }

    [HttpPost("login")]
    [EnableRateLimiting("auth")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest request)
    {
        var userData = await _authRepo.GetUserByEmailAsync(request.Email);
        if (userData is null || !userData.Value.isActive)
            return Unauthorized(new ProblemDetails
            {
                Title = "Invalid credentials",
                Status = 401,
                Detail = "Email or password is incorrect."
            });

        var valid = await _authRepo.VerifyPasswordAsync(request.Email, request.Password);
        if (!valid)
            return Unauthorized(new ProblemDetails
            {
                Title = "Invalid credentials",
                Status = 401,
                Detail = "Email or password is incorrect."
            });

        // Get user's businesses
        var businesses = await _authRepo.GetUserBusinessesAsync(userData.Value.userId);

        // Active business: the user's selected business, else their first membership
        var activeBusiness = businesses.Count > 0
            ? businesses[0]
            : ((long businessId, string businessName, string roleName)?)null;
        if (activeBusiness is null && userData.Value.activeBusinessId is { } activeId)
        {
            activeBusiness = businesses.FirstOrDefault(b => b.businessId == activeId);
        }

        var activeBusinessId = activeBusiness?.businessId;

        // Roles and permissions are scoped to the active business
        var roles = activeBusiness is null
            ? new List<string>()
            : new List<string> { activeBusiness.Value.roleName };
        var permissions = activeBusinessId.HasValue
            ? (await _authRepo.GetBusinessPermissionsAsync(userData.Value.userId, activeBusinessId.Value)).ToList()
            : new List<string>();

        // Platform roles (SuperAdmin → admin.access) ride along regardless
        // of business context — that is what lets the admin console work
        // for a user who belongs to no business.
        var platformPermissions = await _tokenService.GetPlatformPermissionsAsync(userData.Value.userId, default);
        foreach (var perm in platformPermissions.Where(p => !permissions.Contains(p)))
            permissions.Add(perm);

        var (accessToken, refreshToken, expiresAt) = await _tokenService.GenerateAccessTokenAsync(
            userData.Value.userId, userData.Value.email, userData.Value.fullName,
            activeBusinessId, roles, permissions, default);

        var expiresIn = (int)(expiresAt - DateTime.UtcNow).TotalSeconds;

        await _authRepo.UpdateUserLoginAsync(userData.Value.userId);

        var businessDtos = businesses
            .Select(b => new BusinessSummary(b.businessId, b.businessName, b.roleName))
            .ToList();

        return Ok(new AuthResponse(
            userData.Value.userId, userData.Value.email, userData.Value.fullName,
            accessToken, refreshToken, expiresIn,
            string.IsNullOrWhiteSpace(userData.Value.locale) ? "en" : userData.Value.locale,
            businessDtos));
    }

    [HttpPost("refresh")]
    [EnableRateLimiting("auth")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<AuthResponse>> Refresh([FromBody] RefreshRequest request)
    {
        try
        {
            var result = await _tokenService.RefreshTokenAsync(request.RefreshToken, default);

            var businesses = await _authRepo.GetUserBusinessesAsync(result.UserId, default);
            var businessDtos = businesses
                .Select(b => new BusinessSummary(b.businessId, b.businessName, b.roleName))
                .ToList();

            var expiresIn = (int)(result.ExpiresAt - DateTime.UtcNow).TotalSeconds;

            var refreshed = await _authRepo.GetUserByEmailAsync(result.Email, default);

            return Ok(new AuthResponse(
                result.UserId, result.Email, result.FullName,
                result.AccessToken, result.RefreshToken, expiresIn,
                refreshed?.locale is { Length: > 0 } locale ? locale : "en",
                businessDtos));
        }
        catch (SecurityTokenException)
        {
            return Unauthorized(new ProblemDetails
            {
                Title = "Invalid refresh token",
                Status = 401,
                Detail = "The refresh token is invalid or expired."
            });
        }
    }

    [HttpPost("logout")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Logout([FromBody] RefreshRequest? request)
    {
        if (request is not null && !string.IsNullOrEmpty(request.RefreshToken))
            await _tokenService.RevokeRefreshTokenAsync(request.RefreshToken, default);

        return NoContent();
    }

    [HttpGet("me")]
    [Authorize]
    [ProducesResponseType(typeof(UserProfileDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<UserProfileDto>> Me(
        [FromServices] ICurrentUserService currentUser)
    {
        if (!currentUser.IsAuthenticated || currentUser.UserId is null)
            return Unauthorized();

        var (fullName, phoneNumber, locale, timezone, profileImageUrl) =
            await _authRepo.GetUserProfileAsync(currentUser.UserId.Value, default);

        return Ok(new UserProfileDto(
            currentUser.UserId.Value,
            currentUser.Email ?? "",
            fullName,
            phoneNumber,
            locale,
            timezone,
            profileImageUrl));
    }

    [HttpPut("profile")]
    [Authorize]
    [ProducesResponseType(typeof(UserProfileDto), StatusCodes.Status200OK)]
    public async Task<ActionResult<UserProfileDto>> UpdateProfile(
        [FromBody] UpdateProfileRequest request,
        [FromServices] ICurrentUserService currentUser)
    {
        if (currentUser.UserId is null)
            return Unauthorized();

        await _authRepo.UpdateUserProfileAsync(
            currentUser.UserId.Value, request.FullName,
            request.PhoneNumber, request.Locale, default);

        var (fullName, phoneNumber, locale, timezone, profileImageUrl) =
            await _authRepo.GetUserProfileAsync(currentUser.UserId.Value, default);

        return Ok(new UserProfileDto(
            currentUser.UserId.Value,
            currentUser.Email ?? "",
            fullName,
            phoneNumber,
            locale,
            timezone,
            profileImageUrl));
    }

    [HttpPost("change-password")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ChangePassword(
        [FromBody] ChangePasswordRequest request,
        [FromServices] ICurrentUserService currentUser)
    {
        if (currentUser.UserId is null)
            return Unauthorized();

        var success = await _authRepo.ChangePasswordAsync(
            currentUser.UserId.Value, request.CurrentPassword, request.NewPassword, default);

        if (!success)
            return BadRequest(new ProblemDetails
            {
                Title = "Password change failed",
                Status = 400,
                Detail = "Current password is incorrect."
            });

        return NoContent();
    }
}
