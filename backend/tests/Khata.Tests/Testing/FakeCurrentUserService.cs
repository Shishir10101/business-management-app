using Khata.Application.Interfaces;

namespace Khata.Tests.Testing;

/// <summary>
/// Minimal ICurrentUserService double for unit tests that construct a DbContext directly.
/// </summary>
public class FakeCurrentUserService : ICurrentUserService
{
    public long? UserId { get; set; }
    public long? BusinessId { get; set; }
    public string? Email { get; set; }
    public string? FullName { get; set; }
    public IReadOnlyList<string> Roles { get; set; } = [];
    public IReadOnlyList<string> Permissions { get; set; } = [];
    public bool IsAuthenticated { get; set; }
}
