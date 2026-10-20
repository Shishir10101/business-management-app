namespace Khata.Application.Interfaces;

using Khata.Application.Common;
using Khata.Application.DTOs;

/// <summary>
/// Sales. Creating a sale is a single atomic operation: it allocates an invoice
/// number, decrements stock (append-only movements), and records the credit
/// portion on the customer's khata ledger. Deleting a sale soft-deletes it and
/// appends the reversing entries — history is never rewritten.
/// </summary>
public interface ISaleService
{
    Task<PagedResult<SaleDto>> GetSalesAsync(SaleQuery query, CancellationToken cancellationToken = default);
    Task<SaleDto> GetSaleAsync(long saleId, CancellationToken cancellationToken = default);
    Task<SaleDto> CreateSaleAsync(CreateSaleRequest request, CancellationToken cancellationToken = default);
    Task DeleteSaleAsync(long saleId, CancellationToken cancellationToken = default);
}

/// <summary>Purchases (mirror of <see cref="ISaleService"/>: stock in, supplier payable).</summary>
public interface IPurchaseService
{
    Task<PagedResult<PurchaseDto>> GetPurchasesAsync(PurchaseQuery query, CancellationToken cancellationToken = default);
    Task<PurchaseDto> GetPurchaseAsync(long purchaseId, CancellationToken cancellationToken = default);
    Task<PurchaseDto> CreatePurchaseAsync(CreatePurchaseRequest request, CancellationToken cancellationToken = default);
    Task DeletePurchaseAsync(long purchaseId, CancellationToken cancellationToken = default);
}

/// <summary>Operating expenses (simple CRUD).</summary>
public interface IExpenseService
{
    Task<PagedResult<ExpenseDto>> GetExpensesAsync(ExpenseQuery query, CancellationToken cancellationToken = default);
    Task<ExpenseDto> GetExpenseAsync(long expenseId, CancellationToken cancellationToken = default);
    Task<ExpenseDto> CreateExpenseAsync(CreateExpenseRequest request, CancellationToken cancellationToken = default);
    Task<ExpenseDto> UpdateExpenseAsync(long expenseId, UpdateExpenseRequest request, CancellationToken cancellationToken = default);
    Task DeleteExpenseAsync(long expenseId, CancellationToken cancellationToken = default);
}

/// <summary>Non-sale income (simple CRUD).</summary>
public interface IIncomeService
{
    Task<PagedResult<IncomeDto>> GetIncomesAsync(IncomeQuery query, CancellationToken cancellationToken = default);
    Task<IncomeDto> GetIncomeAsync(long incomeId, CancellationToken cancellationToken = default);
    Task<IncomeDto> CreateIncomeAsync(CreateIncomeRequest request, CancellationToken cancellationToken = default);
    Task<IncomeDto> UpdateIncomeAsync(long incomeId, UpdateIncomeRequest request, CancellationToken cancellationToken = default);
    Task DeleteIncomeAsync(long incomeId, CancellationToken cancellationToken = default);
}
