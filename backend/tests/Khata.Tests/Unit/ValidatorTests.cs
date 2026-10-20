using Khata.Application.DTOs;
using Khata.Application.Validators;

namespace Khata.Tests.Unit;

public class AuthValidatorsTests
{
    private readonly RegisterRequestValidator _registerValidator = new();
    private readonly LoginRequestValidator _loginValidator = new();
    private readonly ChangePasswordRequestValidator _changePasswordValidator = new();

    [Fact]
    public async Task Register_WithValidRequest_Passes()
    {
        var request = new RegisterRequest("Ram Bahadur", "ram@test.local", "Passw0rd123", "9800000000");

        var result = await _registerValidator.ValidateAsync(request);

        Assert.True(result.IsValid);
    }

    [Theory]
    [InlineData("", "ram@test.local", "Passw0rd123")]                 // missing name
    [InlineData("Ram", "not-an-email", "Passw0rd123")]                 // bad email
    [InlineData("Ram", "ram@test.local", "short")]                     // short password
    [InlineData("Ram", "ram@test.local", "Passw0rd123", "12")]         // bad phone
    public async Task Register_WithInvalidField_Fails(string name, string email, string password, string? phone = null)
    {
        var request = new RegisterRequest(name, email, password, phone);

        var result = await _registerValidator.ValidateAsync(request);

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task Login_WithMissingEmail_Fails()
    {
        var result = await _loginValidator.ValidateAsync(new LoginRequest("", "Passw0rd123"));

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task ChangePassword_WithSamePassword_Fails()
    {
        var request = new ChangePasswordRequest("Passw0rd123", "Passw0rd123");

        var result = await _changePasswordValidator.ValidateAsync(request);

        Assert.False(result.IsValid);
    }
}

public class BusinessValidatorsTests
{
    private readonly CreateBusinessRequestValidator _createValidator = new();
    private readonly InviteMemberRequestValidator _inviteValidator = new();
    private readonly UpdateMemberRoleRequestValidator _updateRoleValidator = new();

    [Fact]
    public async Task CreateBusiness_WithValidRequest_Passes()
    {
        var request = new CreateBusinessRequest(
            "Ram Kirana Pasal", "Retail", "123456789", "9800000000", null,
            "Main Road", "Kathmandu", "Kathmandu", 3, 5);

        var result = await _createValidator.ValidateAsync(request);

        Assert.True(result.IsValid);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(8)]
    [InlineData(-1)]
    public async Task CreateBusiness_WithProvinceOutOfRange_Fails(int province)
    {
        var request = new CreateBusinessRequest(
            "Ram Kirana", Province: province);

        var result = await _createValidator.ValidateAsync(request);

        Assert.Contains(result.Errors, e => e.PropertyName == "Province");
    }

    [Theory]
    [InlineData(0)]
    [InlineData(36)]
    [InlineData(-3)]
    public async Task CreateBusiness_WithWardNumberOutOfRange_Fails(int ward)
    {
        var request = new CreateBusinessRequest("Ram Kirana", WardNumber: ward);

        var result = await _createValidator.ValidateAsync(request);

        Assert.Contains(result.Errors, e => e.PropertyName == "WardNumber");
    }

    [Fact]
    public async Task CreateBusiness_WithDistrictProvinceMismatch_Fails()
    {
        // Kathmandu is in Bagmati (3); saying Karnali (6) is the mistake the
        // district-consistency rule exists to catch. Free-text province let
        // this through and produced a province report with Kathmandu in the
        // wrong bucket.
        var request = new CreateBusinessRequest(
            "Ram Kirana", District: "Kathmandu", Province: 6);

        var result = await _createValidator.ValidateAsync(request);

        Assert.Contains(result.Errors, e => e.PropertyName == "Province");
    }

    [Fact]
    public async Task CreateBusiness_WithUnknownDistrictButAnyProvince_Passes()
    {
        // A district outside the table (new district, typo, or a foreign
        // address) must not block a valid province number.
        var request = new CreateBusinessRequest(
            "Ram Kirana", District: "Rukum East", Province: 5);

        var result = await _createValidator.ValidateAsync(request);

        Assert.True(result.IsValid);
    }

    [Fact]
    public async Task CreateBusiness_WithNoAddress_Passes()
    {
        // A business that skips the whole address block is legal; the rules
        // only apply when a value is actually supplied.
        var request = new CreateBusinessRequest("Ram Kirana");

        var result = await _createValidator.ValidateAsync(request);

        Assert.True(result.IsValid);
    }

    [Fact]
    public async Task CreateBusiness_WithInvalidPan_Fails()
    {
        var request = new CreateBusinessRequest("Ram Kirana", null, "12345", null, null, null, null, null, null, null);

        var result = await _createValidator.ValidateAsync(request);

        Assert.Contains(result.Errors, e => e.PropertyName == nameof(CreateBusinessRequest.PanNumber));
    }

    [Fact]
    public async Task CreateBusiness_WithEmptyName_Fails()
    {
        var result = await _createValidator.ValidateAsync(new CreateBusinessRequest(""));

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task InviteMember_WithUnknownRole_Fails()
    {
        var result = await _inviteValidator.ValidateAsync(new InviteMemberRequest("ram@test.local", "SuperUser"));

        Assert.False(result.IsValid);
    }

    [Fact]
    public async Task InviteMember_WithSystemRole_Passes()
    {
        var result = await _inviteValidator.ValidateAsync(new InviteMemberRequest("ram@test.local", "Manager"));

        Assert.True(result.IsValid);
    }

    [Fact]
    public async Task UpdateMemberRole_WithInvalidRole_Fails()
    {
        var result = await _updateRoleValidator.ValidateAsync(new UpdateMemberRoleRequest("Nope"));

        Assert.False(result.IsValid);
    }
}
