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
/// Payments: receipts from customers and disbursements to suppliers. Every
/// payment appends one immutable khata entry moving the party balance down by
/// the full amount; when a sale/purchase is linked, the applied portion also
/// updates that document. Excess becomes an advance (negative balance).
/// </summary>
public class PaymentService : IPaymentService
{
    private readonly KhataDbContext _db;
    private readonly ICurrentUserService _currentUser;
    private readonly IDateTimeProvider _clock;
    private readonly IPaymentProviderRegistry _providers;

    public PaymentService(
        KhataDbContext db,
        ICurrentUserService currentUser,
        IDateTimeProvider clock,
        IPaymentProviderRegistry providers)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
        _providers = providers;
    }

    private long BusinessId =>
        _currentUser.BusinessId ?? throw new UnauthorizedException();

    public async Task<PagedResult<PaymentDto>> GetPaymentsAsync(PaymentQuery query, CancellationToken cancellationToken = default)
    {
        var baseQuery = _db.Payments.Where(p => p.BusinessId == BusinessId);

        if (query.PartyType is { } partyType)
            baseQuery = baseQuery.Where(p => p.PartyType == partyType);
        if (query.PartyId is { } partyId)
            baseQuery = baseQuery.Where(p => p.PartyId == partyId);
        if (query.Direction is { } direction)
            baseQuery = baseQuery.Where(p => p.Direction == direction);
        if (query.DateFrom is { } from)
            baseQuery = baseQuery.Where(p => p.PaymentDate >= from);
        if (query.DateTo is { } to)
            baseQuery = baseQuery.Where(p => p.PaymentDate <= to);

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            // Party names live behind a polymorphic reference, so match them with
            // correlated EXISTS subqueries (translated server-side, keeping paging correct).
            var search = query.Search.Trim().ToLower();
            baseQuery = baseQuery.Where(p =>
                (p.Reference != null && p.Reference.ToLower().Contains(search)) ||
                _db.Customers.Any(c => c.Id == p.PartyId
                    && p.PartyType == PartyType.Customer
                    && c.Name.ToLower().Contains(search)) ||
                _db.Suppliers.Any(s => s.Id == p.PartyId
                    && p.PartyType == PartyType.Supplier
                    && s.Name.ToLower().Contains(search)));
        }

        var total = await baseQuery.CountAsync(cancellationToken);

        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var rows = await baseQuery
            .OrderByDescending(p => p.PaymentDate)
            .ThenByDescending(p => p.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(p => new
            {
                p.Id,
                p.PartyType,
                p.PartyId,
                p.Direction,
                p.Amount,
                p.PaymentDate,
                p.PaymentMethodId,
                p.MethodName,
                p.Reference,
                p.Notes,
                p.SaleId,
                SaleInvoiceNumber = p.Sale == null ? null : p.Sale.InvoiceNumber,
                p.PurchaseId,
                PurchaseBillNumber = p.Purchase == null ? null : p.Purchase.BillNumber,
                p.AppliedAmount,
                p.UnappliedAmount,
                p.CreatedAt,
            })
            .ToListAsync(cancellationToken);

        var names = await LoadPartyNamesAsync(
            rows.Select(r => (r.PartyType, r.PartyId)).ToList(), cancellationToken);

        var data = rows.Select(r => new PaymentDto(
            r.Id, r.PartyType, r.PartyId, names.GetValueOrDefault((r.PartyType, r.PartyId)) ?? string.Empty,
            r.Direction, r.Amount, r.PaymentDate, r.PaymentMethodId, r.MethodName, r.Reference,
            r.Notes, r.SaleId, r.SaleInvoiceNumber, r.PurchaseId, r.PurchaseBillNumber,
            r.AppliedAmount, r.UnappliedAmount, r.CreatedAt)).ToList();

        return PagedResult<PaymentDto>.Create(data, page, pageSize, total);
    }

    public async Task<PaymentDto> GetPaymentAsync(long paymentId, CancellationToken cancellationToken = default)
    {
        var payment = await _db.Payments
            .Include(p => p.Sale)
            .Include(p => p.Purchase)
            .FirstOrDefaultAsync(p => p.Id == paymentId && p.BusinessId == BusinessId, cancellationToken)
            ?? throw new NotFoundException("Payment", paymentId);

        var partyName = await LoadPartyNameAsync(payment.PartyType, payment.PartyId, cancellationToken);
        return ToDto(payment, partyName);
    }

    public async Task<PaymentDto> CreatePaymentAsync(CreatePaymentRequest request, CancellationToken cancellationToken = default)
    {
        var partyType = request.PartyType;
        var direction = request.Direction
            ?? (partyType == PartyType.Customer ? PaymentDirection.In : PaymentDirection.Out);

        if (partyType == PartyType.Customer && direction != PaymentDirection.In)
            throw new BusinessRuleException("direction_mismatch",
                "A customer payment must be a receipt (In).");
        if (partyType == PartyType.Supplier && direction != PaymentDirection.Out)
            throw new BusinessRuleException("direction_mismatch",
                "A supplier payment must be a disbursement (Out).");

        // The party must exist in this business.
        var partyName = await LoadPartyNameAsync(partyType, request.PartyId, cancellationToken);

        var method = await ResolveMethodAsync(request.PaymentMethodId, request.MethodCode, cancellationToken);
        var methodCode = method?.Code ?? request.MethodCode ?? "cash";
        var methodName = method?.Name ?? "Cash";

        // Hand the settlement to the provider for this method (cash/manual today).
        var provider = _providers.Resolve(methodCode);
        var result = await provider.ProcessAsync(
            new PaymentProviderRequest(BusinessId, direction, request.Amount, request.Reference),
            cancellationToken);
        if (!result.Success)
            throw new BusinessRuleException("payment_failed",
                result.ErrorMessage ?? "The payment could not be processed.");

        // Optional document linkage.
        Sale? sale = null;
        Purchase? purchase = null;
        long applied = 0;

        if (request.SaleId is { } saleId)
        {
            if (partyType != PartyType.Customer)
                throw new BusinessRuleException("invalid_link",
                    "A sale can only be settled by a customer payment.");
            sale = await _db.Sales
                .FirstOrDefaultAsync(s => s.Id == saleId && s.DeletedAt == null && s.BusinessId == BusinessId,
                    cancellationToken)
                ?? throw new NotFoundException("Sale", saleId);
            if (sale.CustomerId != request.PartyId)
                throw new BusinessRuleException("party_mismatch",
                    "The sale belongs to a different customer.");
            applied = Math.Min(request.Amount, sale.DueAmount);
        }
        else if (request.PurchaseId is { } purchaseId)
        {
            if (partyType != PartyType.Supplier)
                throw new BusinessRuleException("invalid_link",
                    "A purchase can only be settled by a supplier payment.");
            purchase = await _db.Purchases
                .FirstOrDefaultAsync(p => p.Id == purchaseId && p.DeletedAt == null && p.BusinessId == BusinessId,
                    cancellationToken)
                ?? throw new NotFoundException("Purchase", purchaseId);
            if (purchase.SupplierId != request.PartyId)
                throw new BusinessRuleException("party_mismatch",
                    "The purchase belongs to a different supplier.");
            applied = Math.Min(request.Amount, purchase.DueAmount);
        }

        var paymentDate = request.PaymentDate ?? _clock.Today;

        await using var transaction = await _db.Database.BeginTransactionAsync(cancellationToken);

        var payment = new Payment
        {
            BusinessId = BusinessId,
            PartyType = partyType,
            PartyId = request.PartyId,
            Direction = direction,
            Amount = request.Amount,
            PaymentDate = paymentDate,
            PaymentMethodId = method?.Id,
            MethodName = methodName,
            Reference = result.ProviderReference ?? request.Reference,
            Notes = request.Notes,
            SaleId = sale?.Id,
            PurchaseId = purchase?.Id,
            AppliedAmount = applied,
            UnappliedAmount = request.Amount - applied,
        };
        _db.Payments.Add(payment);

        // First save assigns Payment.Id so the ledger entry can reference it.
        await _db.SaveChangesAsync(cancellationToken);

        var account = await GetOrCreateAccountAsync(partyType, request.PartyId, cancellationToken);
        LedgerWriter.Append(_db, BusinessId, account, -request.Amount, "payment", payment.Id,
            $"Payment to {partyName}", paymentDate);

        if (sale is not null && applied > 0) ApplyToSale(sale, applied);
        if (purchase is not null && applied > 0) ApplyToPurchase(purchase, applied);

        await _db.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        return await GetPaymentAsync(payment.Id, cancellationToken);
    }

    public async Task<ReceivablePayableSummaryDto> GetSummaryAsync(CancellationToken cancellationToken = default)
    {
        var accounts = await _db.LedgerAccounts
            .Where(a => a.BusinessId == BusinessId)
            .Select(a => new { a.PartyType, a.CurrentBalance })
            .ToListAsync(cancellationToken);

        var customers = accounts.Where(a => a.PartyType == PartyType.Customer).ToList();
        var suppliers = accounts.Where(a => a.PartyType == PartyType.Supplier).ToList();

        return new ReceivablePayableSummaryDto(
            TotalReceivable: customers.Where(a => a.CurrentBalance > 0).Sum(a => a.CurrentBalance),
            TotalPayable: suppliers.Where(a => a.CurrentBalance > 0).Sum(a => a.CurrentBalance),
            CustomerAdvances: -customers.Where(a => a.CurrentBalance < 0).Sum(a => a.CurrentBalance),
            SupplierAdvances: -suppliers.Where(a => a.CurrentBalance < 0).Sum(a => a.CurrentBalance),
            ReceivableParties: customers.Count(a => a.CurrentBalance > 0),
            PayableParties: suppliers.Count(a => a.CurrentBalance > 0));
    }

    // --- helpers ---

    private async Task<PaymentMethod?> ResolveMethodAsync(
        long? methodId, string? methodCode, CancellationToken cancellationToken)
    {
        if (methodId is { } id)
        {
            return await _db.PaymentMethods
                .FirstOrDefaultAsync(m => m.Id == id && m.DeletedAt == null && m.BusinessId == BusinessId,
                    cancellationToken)
                ?? throw new NotFoundException("PaymentMethod", id);
        }

        if (!string.IsNullOrWhiteSpace(methodCode))
        {
            return await _db.PaymentMethods
                .FirstOrDefaultAsync(m => m.Code == methodCode && m.DeletedAt == null && m.BusinessId == BusinessId,
                    cancellationToken);
        }

        return await _db.PaymentMethods
            .FirstOrDefaultAsync(m => m.IsDefault && m.DeletedAt == null && m.BusinessId == BusinessId,
                cancellationToken);
    }

    private async Task<LedgerAccount> GetOrCreateAccountAsync(
        PartyType partyType, long partyId, CancellationToken cancellationToken)
    {
        var account = await _db.LedgerAccounts
            .FirstOrDefaultAsync(a => a.PartyType == partyType && a.PartyId == partyId, cancellationToken);

        if (account is null)
        {
            account = new LedgerAccount
            {
                BusinessId = BusinessId,
                PartyType = partyType,
                PartyId = partyId,
                OpeningBalance = 0,
                CurrentBalance = 0,
            };
            _db.LedgerAccounts.Add(account);
        }

        return account;
    }

    private async Task<string> LoadPartyNameAsync(
        PartyType partyType, long partyId, CancellationToken cancellationToken)
    {
        if (partyType == PartyType.Customer)
        {
            var name = await _db.Customers
                .Where(c => c.Id == partyId && c.DeletedAt == null)
                .Select(c => c.Name)
                .FirstOrDefaultAsync(cancellationToken);
            return name ?? throw new NotFoundException("Customer", partyId);
        }

        var supplierName = await _db.Suppliers
            .Where(s => s.Id == partyId && s.DeletedAt == null)
            .Select(s => s.Name)
            .FirstOrDefaultAsync(cancellationToken);
        return supplierName ?? throw new NotFoundException("Supplier", partyId);
    }

    private async Task<Dictionary<(PartyType, long), string>> LoadPartyNamesAsync(
        IReadOnlyList<(PartyType PartyType, long PartyId)> parties, CancellationToken cancellationToken)
    {
        var result = new Dictionary<(PartyType, long), string>();

        var customerIds = parties.Where(p => p.PartyType == PartyType.Customer)
            .Select(p => p.PartyId).Distinct().ToList();
        if (customerIds.Count > 0)
        {
            var names = await _db.Customers
                .Where(c => customerIds.Contains(c.Id))
                .Select(c => new { c.Id, c.Name })
                .ToListAsync(cancellationToken);
            foreach (var n in names)
                result[(PartyType.Customer, n.Id)] = n.Name;
        }

        var supplierIds = parties.Where(p => p.PartyType == PartyType.Supplier)
            .Select(p => p.PartyId).Distinct().ToList();
        if (supplierIds.Count > 0)
        {
            var names = await _db.Suppliers
                .Where(s => supplierIds.Contains(s.Id))
                .Select(s => new { s.Id, s.Name })
                .ToListAsync(cancellationToken);
            foreach (var n in names)
                result[(PartyType.Supplier, n.Id)] = n.Name;
        }

        return result;
    }

    private static void ApplyToSale(Sale sale, long applied)
    {
        sale.PaidAmount += applied;
        sale.DueAmount -= applied;
        sale.PaymentStatus = sale.PaidAmount <= 0
            ? PaymentStatus.Unpaid
            : sale.DueAmount <= 0 ? PaymentStatus.Paid : PaymentStatus.Partial;
    }

    private static void ApplyToPurchase(Purchase purchase, long applied)
    {
        purchase.PaidAmount += applied;
        purchase.DueAmount -= applied;
        purchase.PaymentStatus = purchase.PaidAmount <= 0
            ? PaymentStatus.Unpaid
            : purchase.DueAmount <= 0 ? PaymentStatus.Paid : PaymentStatus.Partial;
    }

    private static PaymentDto ToDto(Payment p, string partyName) => new(
        p.Id, p.PartyType, p.PartyId, partyName, p.Direction, p.Amount, p.PaymentDate,
        p.PaymentMethodId, p.MethodName, p.Reference, p.Notes,
        p.SaleId, p.Sale?.InvoiceNumber, p.PurchaseId, p.Purchase?.BillNumber,
        p.AppliedAmount, p.UnappliedAmount, p.CreatedAt);
}
