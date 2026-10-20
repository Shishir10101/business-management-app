namespace Khata.Infrastructure.Services;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Domain.Entities;
using Khata.Domain.Exceptions;
using Khata.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

/// <summary>Operating expenses — simple CRUD scoped to the active business.</summary>
public class ExpenseService : IExpenseService
{
    private readonly KhataDbContext _db;
    private readonly ICurrentUserService _currentUser;
    private readonly IDateTimeProvider _clock;

    public ExpenseService(KhataDbContext db, ICurrentUserService currentUser, IDateTimeProvider clock)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
    }

    private long BusinessId =>
        _currentUser.BusinessId ?? throw new UnauthorizedException();

    public async Task<PagedResult<ExpenseDto>> GetExpensesAsync(ExpenseQuery query, CancellationToken cancellationToken = default)
    {
        var baseQuery = _db.Expenses.Where(e => e.DeletedAt == null && e.BusinessId == BusinessId);

        if (!string.IsNullOrWhiteSpace(query.Category))
            baseQuery = baseQuery.Where(e => e.Category == query.Category);
        if (query.DateFrom is { } from)
            baseQuery = baseQuery.Where(e => e.ExpenseDate >= from);
        if (query.DateTo is { } to)
            baseQuery = baseQuery.Where(e => e.ExpenseDate <= to);
        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            baseQuery = baseQuery.Where(e =>
                e.Category.ToLower().Contains(search) ||
                (e.Description != null && e.Description.ToLower().Contains(search)) ||
                (e.Reference != null && e.Reference.ToLower().Contains(search)));
        }

        var total = await baseQuery.CountAsync(cancellationToken);

        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var rows = await baseQuery
            .OrderByDescending(e => e.ExpenseDate)
            .ThenByDescending(e => e.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(e => new ExpenseDto(
                e.Id, e.Category, e.Amount, e.ExpenseDate, e.Description,
                e.PaymentMethod, e.Reference, e.Notes, e.CreatedAt, e.UpdatedAt))
            .ToListAsync(cancellationToken);

        return PagedResult<ExpenseDto>.Create(rows, page, pageSize, total);
    }

    public async Task<ExpenseDto> GetExpenseAsync(long expenseId, CancellationToken cancellationToken = default)
    {
        var expense = await LoadAsync(expenseId, cancellationToken);
        return ToDto(expense);
    }

    public async Task<ExpenseDto> CreateExpenseAsync(CreateExpenseRequest request, CancellationToken cancellationToken = default)
    {
        var expense = new Expense
        {
            BusinessId = BusinessId,
            Category = request.Category.Trim(),
            Amount = request.Amount,
            ExpenseDate = request.ExpenseDate ?? _clock.Today,
            Description = request.Description,
            PaymentMethod = request.PaymentMethod,
            Reference = request.Reference,
            Notes = request.Notes,
        };

        _db.Expenses.Add(expense);
        await _db.SaveChangesAsync(cancellationToken);

        return ToDto(expense);
    }

    public async Task<ExpenseDto> UpdateExpenseAsync(long expenseId, UpdateExpenseRequest request, CancellationToken cancellationToken = default)
    {
        var expense = await LoadAsync(expenseId, cancellationToken);

        expense.Category = request.Category.Trim();
        expense.Amount = request.Amount;
        expense.ExpenseDate = request.ExpenseDate ?? expense.ExpenseDate;
        expense.Description = request.Description;
        expense.PaymentMethod = request.PaymentMethod;
        expense.Reference = request.Reference;
        expense.Notes = request.Notes;

        await _db.SaveChangesAsync(cancellationToken);

        return ToDto(expense);
    }

    public async Task DeleteExpenseAsync(long expenseId, CancellationToken cancellationToken = default)
    {
        var expense = await LoadAsync(expenseId, cancellationToken);
        _db.Expenses.Remove(expense); // soft delete
        await _db.SaveChangesAsync(cancellationToken);
    }

    private async Task<Expense> LoadAsync(long expenseId, CancellationToken cancellationToken)
        => await _db.Expenses
            .FirstOrDefaultAsync(e => e.Id == expenseId && e.DeletedAt == null
                && e.BusinessId == BusinessId, cancellationToken)
            ?? throw new NotFoundException("Expense", expenseId);

    private static ExpenseDto ToDto(Expense e) => new(
        e.Id, e.Category, e.Amount, e.ExpenseDate, e.Description,
        e.PaymentMethod, e.Reference, e.Notes, e.CreatedAt, e.UpdatedAt);
}
