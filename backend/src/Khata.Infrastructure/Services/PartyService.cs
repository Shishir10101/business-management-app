namespace Khata.Infrastructure.Services;

using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Domain.Entities;
using Khata.Domain.Enums;
using Khata.Domain.Exceptions;
using Khata.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

/// <summary>
/// Parties (customers, suppliers) and their digital khata ledgers.
/// </summary>
/// <remarks>
/// Ledger invariants:
/// <list type="bullet">
/// <item>Every party gets a <see cref="LedgerAccount"/> on creation; a non-zero
/// opening balance immediately writes the first (immutable) transaction.</item>
/// <item>Transactions are append-only — never edited or deleted (enforced by
/// the DbContext for <see cref="IImmutable"/>).</item>
/// <item>LedgerAccount.CurrentBalance is a cache derived from the transaction
/// sum, updated within the same transaction as each append.</item>
/// <item>Balances are paisa, in the party's natural direction: customer →
/// positive = receivable; supplier → positive = payable.</item>
/// </list>
/// </remarks>
public class PartyService : IPartyService
{
    private readonly KhataDbContext _db;
    private readonly ICurrentUserService _currentUser;
    private readonly IDateTimeProvider _clock;

    public PartyService(KhataDbContext db, ICurrentUserService currentUser, IDateTimeProvider clock)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
    }

    private long BusinessId =>
        _currentUser.BusinessId ?? throw new UnauthorizedException();

    // ==============================================================
    // Customers
    // ==============================================================

    public async Task<PagedResult<CustomerDto>> GetCustomersAsync(PartyQuery query, CancellationToken cancellationToken = default)
    {
        var baseQuery = _db.Customers
            .Where(c => c.DeletedAt == null && c.BusinessId == BusinessId);

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            baseQuery = baseQuery.Where(c =>
                c.Name.ToLower().Contains(search) ||
                (c.PhoneNumber != null && c.PhoneNumber.ToLower().Contains(search)));
        }

        if (query.IsActive is { } isActive)
            baseQuery = baseQuery.Where(c => c.IsActive == isActive);

        var total = await baseQuery.CountAsync(cancellationToken);

        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var customers = await baseQuery
            .OrderBy(c => c.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        var balances = await LoadBalancesAsync(
            customers.Select(c => c.Id), PartyType.Customer, cancellationToken);

        return PagedResult<CustomerDto>.Create(
            customers.Select(c => ToDto(c, balances.GetValueOrDefault(c.Id))).ToList(),
            page, pageSize, total);
    }

    public async Task<CustomerDto> GetCustomerAsync(long customerId, CancellationToken cancellationToken = default)
    {
        var customer = await LoadCustomerAsync(customerId, cancellationToken);
        var account = await LoadLedgerAccountAsync(PartyType.Customer, customerId, cancellationToken);
        return ToDto(customer, account?.CurrentBalance ?? 0);
    }

    public async Task<CustomerDto> CreateCustomerAsync(CreateCustomerRequest request, CancellationToken cancellationToken = default)
    {
        var customer = new Customer
        {
            BusinessId = BusinessId,
            Name = request.Name,
            PhoneNumber = request.PhoneNumber,
            Email = request.Email,
            AddressLine = request.AddressLine,
            City = request.City,
            District = request.District,
            OpeningBalance = request.OpeningBalance,
            PanNumber = request.PanNumber,
            CreditLimit = request.CreditLimit,
            Notes = request.Notes,
            IsActive = request.IsActive,
        };
        _db.Customers.Add(customer);

        // Save first: the ledger account needs the generated customer Id
        // (polymorphic PartyId — there is no navigation to propagate it).
        await _db.SaveChangesAsync(cancellationToken);

        var account = CreateLedgerAccount(PartyType.Customer, customer.Id, request.OpeningBalance);
        if (request.OpeningBalance != 0)
            AppendTransaction(account, request.OpeningBalance, "opening", "Opening balance");

        // Account + opening txn commit atomically; the customer row is already
        // durable (and the account-less state is handled gracefully on read).
        await _db.SaveChangesAsync(cancellationToken);

        return ToDto(customer, account.CurrentBalance);
    }

    public async Task<CustomerDto> UpdateCustomerAsync(long customerId, UpdateCustomerRequest request, CancellationToken cancellationToken = default)
    {
        var customer = await LoadCustomerAsync(customerId, cancellationToken);
        var account = await LoadLedgerAccountAsync(PartyType.Customer, customerId, cancellationToken);

        var previousOpening = customer.OpeningBalance;

        customer.Name = request.Name;
        customer.PhoneNumber = request.PhoneNumber;
        customer.Email = request.Email;
        customer.AddressLine = request.AddressLine;
        customer.City = request.City;
        customer.District = request.District;
        customer.PanNumber = request.PanNumber;
        customer.CreditLimit = request.CreditLimit;
        customer.Notes = request.Notes;
        customer.IsActive = request.IsActive;
        customer.OpeningBalance = request.OpeningBalance;

        AppendOpeningAdjustmentIfNeeded(account, previousOpening, request.OpeningBalance);

        await _db.SaveChangesAsync(cancellationToken);

        return ToDto(customer, account?.CurrentBalance ?? 0);
    }

    public async Task DeleteCustomerAsync(long customerId, CancellationToken cancellationToken = default)
    {
        var customer = await LoadCustomerAsync(customerId, cancellationToken);

        // Soft delete. The ledger account and its transaction history are kept —
        // the khata ledger is immutable and history must survive.
        _db.Customers.Remove(customer);
        await _db.SaveChangesAsync(cancellationToken);
    }

    public async Task<PartyLedgerDto> GetCustomerLedgerAsync(long customerId, int page = 1, int pageSize = 20, CancellationToken cancellationToken = default)
    {
        var customer = await LoadCustomerAsync(customerId, cancellationToken);
        var account = await LoadLedgerAccountAsync(PartyType.Customer, customerId, cancellationToken);

        return await BuildLedgerAsync(account, page, pageSize, cancellationToken);
    }

    // ==============================================================
    // Suppliers
    // ==============================================================

    public async Task<PagedResult<SupplierDto>> GetSuppliersAsync(PartyQuery query, CancellationToken cancellationToken = default)
    {
        var baseQuery = _db.Suppliers
            .Where(s => s.DeletedAt == null && s.BusinessId == BusinessId);

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            baseQuery = baseQuery.Where(s =>
                s.Name.ToLower().Contains(search) ||
                (s.PhoneNumber != null && s.PhoneNumber.ToLower().Contains(search)));
        }

        if (query.IsActive is { } isActive)
            baseQuery = baseQuery.Where(s => s.IsActive == isActive);

        var total = await baseQuery.CountAsync(cancellationToken);

        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var suppliers = await baseQuery
            .OrderBy(s => s.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        var balances = await LoadBalancesAsync(
            suppliers.Select(s => s.Id), PartyType.Supplier, cancellationToken);

        return PagedResult<SupplierDto>.Create(
            suppliers.Select(s => ToDto(s, balances.GetValueOrDefault(s.Id))).ToList(),
            page, pageSize, total);
    }

    public async Task<SupplierDto> GetSupplierAsync(long supplierId, CancellationToken cancellationToken = default)
    {
        var supplier = await LoadSupplierAsync(supplierId, cancellationToken);
        var account = await LoadLedgerAccountAsync(PartyType.Supplier, supplierId, cancellationToken);
        return ToDto(supplier, account?.CurrentBalance ?? 0);
    }

    public async Task<SupplierDto> CreateSupplierAsync(CreateSupplierRequest request, CancellationToken cancellationToken = default)
    {
        var supplier = new Supplier
        {
            BusinessId = BusinessId,
            Name = request.Name,
            PhoneNumber = request.PhoneNumber,
            Email = request.Email,
            AddressLine = request.AddressLine,
            City = request.City,
            District = request.District,
            OpeningBalance = request.OpeningBalance,
            PanNumber = request.PanNumber,
            Notes = request.Notes,
            IsActive = request.IsActive,
        };
        _db.Suppliers.Add(supplier);

        // Save first: the ledger account needs the generated supplier Id.
        await _db.SaveChangesAsync(cancellationToken);

        var account = CreateLedgerAccount(PartyType.Supplier, supplier.Id, request.OpeningBalance);
        if (request.OpeningBalance != 0)
            AppendTransaction(account, request.OpeningBalance, "opening", "Opening balance");

        await _db.SaveChangesAsync(cancellationToken);

        return ToDto(supplier, account.CurrentBalance);
    }

    public async Task<SupplierDto> UpdateSupplierAsync(long supplierId, UpdateSupplierRequest request, CancellationToken cancellationToken = default)
    {
        var supplier = await LoadSupplierAsync(supplierId, cancellationToken);
        var account = await LoadLedgerAccountAsync(PartyType.Supplier, supplierId, cancellationToken);

        var previousOpening = supplier.OpeningBalance;

        supplier.Name = request.Name;
        supplier.PhoneNumber = request.PhoneNumber;
        supplier.Email = request.Email;
        supplier.AddressLine = request.AddressLine;
        supplier.City = request.City;
        supplier.District = request.District;
        supplier.PanNumber = request.PanNumber;
        supplier.Notes = request.Notes;
        supplier.IsActive = request.IsActive;
        supplier.OpeningBalance = request.OpeningBalance;

        AppendOpeningAdjustmentIfNeeded(account, previousOpening, request.OpeningBalance);

        await _db.SaveChangesAsync(cancellationToken);

        return ToDto(supplier, account?.CurrentBalance ?? 0);
    }

    public async Task DeleteSupplierAsync(long supplierId, CancellationToken cancellationToken = default)
    {
        var supplier = await LoadSupplierAsync(supplierId, cancellationToken);

        // Soft delete; ledger history preserved.
        _db.Suppliers.Remove(supplier);
        await _db.SaveChangesAsync(cancellationToken);
    }

    public async Task<PartyLedgerDto> GetSupplierLedgerAsync(long supplierId, int page = 1, int pageSize = 20, CancellationToken cancellationToken = default)
    {
        var supplier = await LoadSupplierAsync(supplierId, cancellationToken);
        var account = await LoadLedgerAccountAsync(PartyType.Supplier, supplierId, cancellationToken);

        return await BuildLedgerAsync(account, page, pageSize, cancellationToken);
    }

    // ==============================================================
    // Shared ledger helpers
    // ==============================================================

    private LedgerAccount CreateLedgerAccount(PartyType partyType, long partyId, long openingBalance)
    {
        var account = new LedgerAccount
        {
            BusinessId = BusinessId,
            PartyType = partyType,
            PartyId = partyId,
            OpeningBalance = openingBalance,
            CurrentBalance = openingBalance,
        };
        _db.LedgerAccounts.Add(account);
        return account;
    }

    /// <summary>
    /// Appends an immutable ledger transaction for a signed natural-direction
    /// delta. Sign convention: a delta that increases what the party owes is
    /// Debit for customers (they owe more) and Credit for suppliers (we owe
    /// more). <see cref="LedgerAccount.CurrentBalance"/> must already reflect
    /// the delta — <see cref="LedgerTransaction.BalanceAfter"/> records it.
    /// </summary>
    private void AppendTransaction(
        LedgerAccount account, long signedDelta, string referenceType, string description)
    {
        var positive = signedDelta > 0;
        var type = account.PartyType == PartyType.Customer
            ? (positive ? LedgerEntryType.Debit : LedgerEntryType.Credit)
            : (positive ? LedgerEntryType.Credit : LedgerEntryType.Debit);

        _db.LedgerTransactions.Add(new LedgerTransaction
        {
            BusinessId = BusinessId,
            // Navigation (not the scalar FK): the account is still unsaved, so
            // its Id is 0 — EF propagates the generated Id from the navigation.
            LedgerAccount = account,
            TransactionType = type,
            Amount = Math.Abs(signedDelta),
            BalanceAfter = account.CurrentBalance,
            ReferenceType = referenceType,
            Description = description,
            TransactionDate = _clock.Today,
        });
    }

    /// <summary>
    /// When an update changes the opening balance, the difference is appended
    /// as an "adjustment" transaction and the cached balance moves with it —
    /// the original opening transaction and the account's opening are never
    /// touched. The delta is measured against the party's previous opening
    /// (the last value the user set), not the original one.
    /// </summary>
    private void AppendOpeningAdjustmentIfNeeded(LedgerAccount? account, long oldOpening, long newOpening)
    {
        if (account is null || newOpening == oldOpening) return;

        var delta = newOpening - oldOpening;
        account.CurrentBalance += delta;

        AppendTransaction(account, delta, "adjustment", "Opening balance adjustment");
    }

    private async Task<PartyLedgerDto> BuildLedgerAsync(
        LedgerAccount? account, int page, int pageSize, CancellationToken ct)
    {
        var currentPage = Math.Max(1, page);
        var currentSize = Math.Clamp(pageSize, 1, 100);

        if (account is null)
        {
            // Legacy party without an account: everything zero, no transactions.
            return new PartyLedgerDto(
                new LedgerSummaryDto(0, 0, 0, 0),
                [],
                NewPagination(currentPage, currentSize, 0));
        }

        var totalDebit = await _db.LedgerTransactions
            .Where(t => t.LedgerAccountId == account.Id && t.TransactionType == LedgerEntryType.Debit)
            .SumAsync(t => (long?)t.Amount, ct) ?? 0;
        var totalCredit = await _db.LedgerTransactions
            .Where(t => t.LedgerAccountId == account.Id && t.TransactionType == LedgerEntryType.Credit)
            .SumAsync(t => (long?)t.Amount, ct) ?? 0;

        var summary = new LedgerSummaryDto(
            account.OpeningBalance, totalDebit, totalCredit, account.CurrentBalance);

        var baseQuery = _db.LedgerTransactions.Where(t => t.LedgerAccountId == account.Id);
        var total = await baseQuery.CountAsync(ct);

        var transactions = await baseQuery
            .OrderByDescending(t => t.TransactionDate)
            .ThenByDescending(t => t.Id)
            .Skip((currentPage - 1) * currentSize)
            .Take(currentSize)
            .Select(t => new LedgerTransactionDto(
                t.Id, t.TransactionType, t.Amount, t.BalanceAfter, t.TransactionDate,
                t.ReferenceType, t.ReferenceId, t.Description, t.CreatedAt))
            .ToListAsync(ct);

        return new PartyLedgerDto(summary, transactions, NewPagination(currentPage, currentSize, total));
    }

    private static PaginationInfo NewPagination(int page, int pageSize, int total)
    {
        var totalPages = (int)Math.Ceiling((double)total / pageSize);
        return new PaginationInfo
        {
            Page = page,
            PageSize = pageSize,
            TotalItems = total,
            TotalPages = totalPages,
            HasNext = page < totalPages,
            HasPrev = page > 1,
        };
    }

    private async Task<Dictionary<long, long>> LoadBalancesAsync(
        IEnumerable<long> partyIds, PartyType partyType, CancellationToken ct)
    {
        var ids = partyIds.ToList();
        if (ids.Count == 0) return [];

        return await _db.LedgerAccounts
            .Where(a => a.PartyType == partyType && ids.Contains(a.PartyId))
            .ToDictionaryAsync(a => a.PartyId, a => a.CurrentBalance, ct);
    }

    private async Task<Customer> LoadCustomerAsync(long customerId, CancellationToken ct)
    {
        var customer = await _db.Customers
            .FirstOrDefaultAsync(c => c.Id == customerId && c.DeletedAt == null, ct);

        return customer ?? throw new NotFoundException("Customer", customerId);
    }

    private async Task<Supplier> LoadSupplierAsync(long supplierId, CancellationToken ct)
    {
        var supplier = await _db.Suppliers
            .FirstOrDefaultAsync(s => s.Id == supplierId && s.DeletedAt == null, ct);

        return supplier ?? throw new NotFoundException("Supplier", supplierId);
    }

    private Task<LedgerAccount?> LoadLedgerAccountAsync(PartyType partyType, long partyId, CancellationToken ct)
        => _db.LedgerAccounts.FirstOrDefaultAsync(
            a => a.PartyType == partyType && a.PartyId == partyId, ct);

    private static CustomerDto ToDto(Customer c, long currentBalance) => new(
        c.Id, c.Name, c.PhoneNumber, c.Email, c.AddressLine, c.City, c.District,
        c.OpeningBalance, c.PanNumber, c.CreditLimit, c.Notes, c.IsActive,
        currentBalance, c.CreatedAt, c.UpdatedAt);

    private static SupplierDto ToDto(Supplier s, long currentBalance) => new(
        s.Id, s.Name, s.PhoneNumber, s.Email, s.AddressLine, s.City, s.District,
        s.OpeningBalance, s.PanNumber, s.Notes, s.IsActive,
        currentBalance, s.CreatedAt, s.UpdatedAt);
}
