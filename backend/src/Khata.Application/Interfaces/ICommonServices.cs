namespace Khata.Application.Interfaces;

/// <summary>
/// Provides information about the current authenticated user and active business context.
/// Resolved from JWT claims in the API layer.
/// </summary>
public interface ICurrentUserService
{
    long? UserId { get; }
    long? BusinessId { get; }
    string? Email { get; }
    string? FullName { get; }
    IReadOnlyList<string> Roles { get; }
    IReadOnlyList<string> Permissions { get; }
    bool IsAuthenticated { get; }
}

/// <summary>
/// Unit of Work pattern: wraps DbContext.SaveChanges in a transaction boundary.
/// </summary>
public interface IUnitOfWork : IDisposable
{
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
    Task BeginTransactionAsync(CancellationToken cancellationToken = default);
    Task CommitTransactionAsync(CancellationToken cancellationToken = default);
    Task RollbackTransactionAsync(CancellationToken cancellationToken = default);
}

/// <summary>
/// Abstraction over DateTime for testability.
/// </summary>
public interface IDateTimeProvider
{
    DateTime UtcNow { get; }
    DateOnly Today { get; }
}
