namespace Khata.Infrastructure.Services;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Domain.Entities;
using Khata.Domain.Exceptions;
using Khata.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

/// <summary>Non-sale income — simple CRUD scoped to the active business.</summary>
public class IncomeService : IIncomeService
{
    private readonly KhataDbContext _db;
    private readonly ICurrentUserService _currentUser;
    private readonly IDateTimeProvider _clock;

    public IncomeService(KhataDbContext db, ICurrentUserService currentUser, IDateTimeProvider clock)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
    }

    private long BusinessId =>
        _currentUser.BusinessId ?? throw new UnauthorizedException();

    public async Task<PagedResult<IncomeDto>> GetIncomesAsync(IncomeQuery query, CancellationToken cancellationToken = default)
    {
        var baseQuery = _db.Incomes.Where(i => i.DeletedAt == null && i.BusinessId == BusinessId);

        if (!string.IsNullOrWhiteSpace(query.Source))
            baseQuery = baseQuery.Where(i => i.Source == query.Source);
        if (query.DateFrom is { } from)
            baseQuery = baseQuery.Where(i => i.IncomeDate >= from);
        if (query.DateTo is { } to)
            baseQuery = baseQuery.Where(i => i.IncomeDate <= to);
        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            baseQuery = baseQuery.Where(i =>
                i.Source.ToLower().Contains(search) ||
                (i.Description != null && i.Description.ToLower().Contains(search)) ||
                (i.Reference != null && i.Reference.ToLower().Contains(search)));
        }

        var total = await baseQuery.CountAsync(cancellationToken);

        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var rows = await baseQuery
            .OrderByDescending(i => i.IncomeDate)
            .ThenByDescending(i => i.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(i => new IncomeDto(
                i.Id, i.Source, i.Amount, i.IncomeDate, i.Description,
                i.PaymentMethod, i.Reference, i.Notes, i.CreatedAt, i.UpdatedAt))
            .ToListAsync(cancellationToken);

        return PagedResult<IncomeDto>.Create(rows, page, pageSize, total);
    }

    public async Task<IncomeDto> GetIncomeAsync(long incomeId, CancellationToken cancellationToken = default)
    {
        var income = await LoadAsync(incomeId, cancellationToken);
        return ToDto(income);
    }

    public async Task<IncomeDto> CreateIncomeAsync(CreateIncomeRequest request, CancellationToken cancellationToken = default)
    {
        var income = new Income
        {
            BusinessId = BusinessId,
            Source = request.Source.Trim(),
            Amount = request.Amount,
            IncomeDate = request.IncomeDate ?? _clock.Today,
            Description = request.Description,
            PaymentMethod = request.PaymentMethod,
            Reference = request.Reference,
            Notes = request.Notes,
        };

        _db.Incomes.Add(income);
        await _db.SaveChangesAsync(cancellationToken);

        return ToDto(income);
    }

    public async Task<IncomeDto> UpdateIncomeAsync(long incomeId, UpdateIncomeRequest request, CancellationToken cancellationToken = default)
    {
        var income = await LoadAsync(incomeId, cancellationToken);

        income.Source = request.Source.Trim();
        income.Amount = request.Amount;
        income.IncomeDate = request.IncomeDate ?? income.IncomeDate;
        income.Description = request.Description;
        income.PaymentMethod = request.PaymentMethod;
        income.Reference = request.Reference;
        income.Notes = request.Notes;

        await _db.SaveChangesAsync(cancellationToken);

        return ToDto(income);
    }

    public async Task DeleteIncomeAsync(long incomeId, CancellationToken cancellationToken = default)
    {
        var income = await LoadAsync(incomeId, cancellationToken);
        _db.Incomes.Remove(income); // soft delete
        await _db.SaveChangesAsync(cancellationToken);
    }

    private async Task<Income> LoadAsync(long incomeId, CancellationToken cancellationToken)
        => await _db.Incomes
            .FirstOrDefaultAsync(i => i.Id == incomeId && i.DeletedAt == null
                && i.BusinessId == BusinessId, cancellationToken)
            ?? throw new NotFoundException("Income", incomeId);

    private static IncomeDto ToDto(Income i) => new(
        i.Id, i.Source, i.Amount, i.IncomeDate, i.Description,
        i.PaymentMethod, i.Reference, i.Notes, i.CreatedAt, i.UpdatedAt);
}
