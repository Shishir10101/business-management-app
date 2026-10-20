namespace Khata.Infrastructure.Services;

using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Domain.Entities;
using Khata.Domain.Exceptions;
using Khata.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

/// <summary>
/// Payment method configuration for the active business (Cash, Bank Transfer,
/// eSewa, Khalti, Cheque…). Exactly one method may be the default.
/// </summary>
public class PaymentMethodService : IPaymentMethodService
{
    /// <summary>Methods seeded for a brand-new business.</summary>
    public static readonly (string Name, string Code, bool IsDefault)[] DefaultMethods =
    [
        ("Cash", "cash", true),
        ("Bank Transfer", "bank", false),
        ("eSewa", "esewa", false),
        ("Khalti", "khalti", false),
        ("Cheque", "cheque", false),
    ];

    private readonly KhataDbContext _db;
    private readonly ICurrentUserService _currentUser;

    public PaymentMethodService(KhataDbContext db, ICurrentUserService currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    private long BusinessId =>
        _currentUser.BusinessId ?? throw new UnauthorizedException();

    public async Task<IReadOnlyList<PaymentMethodDto>> GetMethodsAsync(
        bool? isActive = null, CancellationToken cancellationToken = default)
    {
        var query = _db.PaymentMethods.Where(m => m.DeletedAt == null && m.BusinessId == BusinessId);

        if (isActive is { } active)
            query = query.Where(m => m.IsActive == active);

        return await query
            .OrderByDescending(m => m.IsDefault)
            .ThenBy(m => m.Name)
            .Select(m => new PaymentMethodDto(m.Id, m.Name, m.Code, m.Description, m.IsActive, m.IsDefault))
            .ToListAsync(cancellationToken);
    }

    public async Task<PaymentMethodDto> GetMethodAsync(long methodId, CancellationToken cancellationToken = default)
        => ToDto(await LoadAsync(methodId, cancellationToken));

    public async Task<PaymentMethodDto> CreateMethodAsync(
        CreatePaymentMethodRequest request, CancellationToken cancellationToken = default)
    {
        var name = request.Name.Trim();
        await EnsureNameAvailableAsync(name, null, cancellationToken);

        var method = new PaymentMethod
        {
            BusinessId = BusinessId,
            Name = name,
            Code = string.IsNullOrWhiteSpace(request.Code) ? "manual" : request.Code.Trim().ToLowerInvariant(),
            Description = request.Description,
            IsActive = true,
            IsDefault = request.IsDefault,
        };

        if (method.IsDefault)
            await ClearOtherDefaultsAsync(null, cancellationToken);

        _db.PaymentMethods.Add(method);
        await _db.SaveChangesAsync(cancellationToken);

        return ToDto(method);
    }

    public async Task<PaymentMethodDto> UpdateMethodAsync(
        long methodId, UpdatePaymentMethodRequest request, CancellationToken cancellationToken = default)
    {
        var method = await LoadAsync(methodId, cancellationToken);
        var name = request.Name.Trim();
        await EnsureNameAvailableAsync(name, methodId, cancellationToken);

        method.Name = name;
        if (!string.IsNullOrWhiteSpace(request.Code))
            method.Code = request.Code.Trim().ToLowerInvariant();
        method.Description = request.Description;
        method.IsActive = request.IsActive;

        if (request.IsDefault && !method.IsDefault)
            await ClearOtherDefaultsAsync(methodId, cancellationToken);

        method.IsDefault = request.IsDefault;

        await _db.SaveChangesAsync(cancellationToken);
        return ToDto(method);
    }

    public async Task DeleteMethodAsync(long methodId, CancellationToken cancellationToken = default)
    {
        var method = await LoadAsync(methodId, cancellationToken);

        var remaining = await _db.PaymentMethods
            .CountAsync(m => m.DeletedAt == null && m.BusinessId == BusinessId && m.Id != methodId,
                cancellationToken);
        if (remaining == 0)
            throw new BusinessRuleException("last_method",
                "At least one payment method must remain.");

        _db.PaymentMethods.Remove(method); // soft delete
        await _db.SaveChangesAsync(cancellationToken);
    }

    private async Task<PaymentMethod> LoadAsync(long methodId, CancellationToken cancellationToken)
        => await _db.PaymentMethods
            .FirstOrDefaultAsync(m => m.Id == methodId && m.DeletedAt == null && m.BusinessId == BusinessId,
                cancellationToken)
            ?? throw new NotFoundException("PaymentMethod", methodId);

    private async Task EnsureNameAvailableAsync(string name, long? exceptId, CancellationToken cancellationToken)
    {
        var exists = await _db.PaymentMethods.AnyAsync(m =>
            m.DeletedAt == null && m.BusinessId == BusinessId && m.Name == name
            && (exceptId == null || m.Id != exceptId), cancellationToken);

        if (exists)
            throw new ConflictException($"A payment method named '{name}' already exists.");
    }

    private async Task ClearOtherDefaultsAsync(long? exceptId, CancellationToken cancellationToken)
    {
        var others = await _db.PaymentMethods
            .Where(m => m.DeletedAt == null && m.BusinessId == BusinessId && m.IsDefault
                && (exceptId == null || m.Id != exceptId))
            .ToListAsync(cancellationToken);

        foreach (var other in others)
            other.IsDefault = false;
    }

    private static PaymentMethodDto ToDto(PaymentMethod m) => new(
        m.Id, m.Name, m.Code, m.Description, m.IsActive, m.IsDefault);
}
