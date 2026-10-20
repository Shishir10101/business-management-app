namespace Khata.Infrastructure.Services;

using System.Text.Json;
using System.Text.Json.Serialization;
using FluentValidation;
using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Domain.Common;
using Khata.Domain.Entities;
using Khata.Domain.Exceptions;
using Khata.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

/// <summary>
/// Delta sync server: pull for the local cache, push for queued client writes.
/// Every write is routed to the existing service so validation, document
/// numbering, stock and ledger rules apply identically online and offline.
/// </summary>
public class SyncService : ISyncService
{
    private const int MaxPullLimit = 1000;
    private const int MaxPushBatch = 200;

    /// <summary>
    /// The sync cursor. SQLite stores whole-second precision, so a naive cursor
    /// (even rounded down to the second) can miss a row changed earlier in that
    /// same second. The cursor is therefore pulled back one full second: the
    /// next pull may re-report a few rows (harmless — applying an upsert twice is
    /// idempotent) but it can never skip a change.
    /// </summary>
    private DateTime ServerCursor()
    {
        var now = _clock.UtcNow;
        var whole = new DateTime(now.Ticks - now.Ticks % TimeSpan.TicksPerSecond, DateTimeKind.Utc);
        return whole.AddSeconds(-1);
    }

    /// <summary>Same rounding applied to an incoming cursor.</summary>
    private static DateTime NormalizeCursor(DateTime? since)
    {
        if (since is not { } value)
            return DateTime.MinValue;

        var utc = value.Kind == DateTimeKind.Utc ? value : value.ToUniversalTime();
        return new DateTime(utc.Ticks - utc.Ticks % TimeSpan.TicksPerSecond, DateTimeKind.Utc);
    }

    /// <summary>Payload JSON comes from any client, so match members case-insensitively.</summary>
    private static readonly JsonSerializerOptions PayloadOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        // The API speaks enums as strings (see Program.cs) — payloads must too.
        Converters = { new JsonStringEnumConverter() },
    };

    private readonly KhataDbContext _db;
    private readonly ICurrentUserService _currentUser;
    private readonly IDateTimeProvider _clock;
    private readonly IServiceProvider _services;
    private readonly IPartyService _parties;
    private readonly IProductService _products;
    private readonly IExpenseService _expenses;
    private readonly IIncomeService _incomes;
    private readonly ISaleService _sales;

    public SyncService(
        KhataDbContext db,
        ICurrentUserService currentUser,
        IDateTimeProvider clock,
        IServiceProvider services,
        IPartyService parties,
        IProductService products,
        IExpenseService expenses,
        IIncomeService incomes,
        ISaleService sales)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
        _services = services;
        _parties = parties;
        _products = products;
        _expenses = expenses;
        _incomes = incomes;
        _sales = sales;
    }

    private long BusinessId =>
        _currentUser.BusinessId ?? throw new UnauthorizedException();

    // ==============================================================
    // Pull
    // ==============================================================

    public async Task<SyncPullResultDto> PullAsync(
        DateTime? since, int limit, CancellationToken cancellationToken = default)
    {
        var take = Math.Clamp(limit <= 0 ? 500 : limit, 1, MaxPullLimit);
        var from = NormalizeCursor(since);
        var serverTime = ServerCursor();

        var changes = new List<SyncChangeDto>();

        // --- reference data ---
        var units = await _db.Units
            .Where(u => u.BusinessId == BusinessId && u.UpdatedAt >= from)
            .OrderBy(u => u.Id)
            .Select(u => new
            {
                u.Id, u.UpdatedAt, u.DeletedAt,
                Payload = new { u.Id, u.Name, u.ShortName, u.IsActive },
            })
            .Take(take).ToListAsync(cancellationToken);
        Append(changes, "unit", units, r => r.Id, r => r.UpdatedAt, r => r.DeletedAt, r => r.Payload);

        var categories = await _db.ProductCategories
            .Where(c => c.BusinessId == BusinessId && c.UpdatedAt >= from)
            .OrderBy(c => c.Id)
            .Select(c => new
            {
                c.Id, c.UpdatedAt, c.DeletedAt,
                Payload = new { c.Id, c.Name, c.Description, c.IsActive },
            })
            .Take(take).ToListAsync(cancellationToken);
        Append(changes, "category", categories, r => r.Id, r => r.UpdatedAt, r => r.DeletedAt, r => r.Payload);

        // --- master data ---
        var products = await _db.Products
            .Where(p => p.BusinessId == BusinessId && p.UpdatedAt >= from)
            .OrderBy(p => p.Id)
            .Select(p => new
            {
                p.Id, p.UpdatedAt, p.DeletedAt,
                Payload = new
                {
                    p.Id, p.CategoryId, p.UnitId, p.Name, p.Sku,
                    p.CostPrice, p.SellingPrice, p.TaxRateBps,
                    p.Description, p.IsActive,
                },
            })
            .Take(take).ToListAsync(cancellationToken);
        Append(changes, "product", products, r => r.Id, r => r.UpdatedAt, r => r.DeletedAt, r => r.Payload);

        // Stock rows are never soft-deleted, so the delete marker is a constant.
        var stocks = await _db.ProductStocks
            .Where(s => s.BusinessId == BusinessId && s.UpdatedAt >= from)
            .OrderBy(s => s.Id)
            .Select(s => new
            {
                s.Id, s.UpdatedAt,
                DeletedAt = (DateTime?)null,
                Payload = new { s.Id, s.ProductId, s.Quantity, s.MinQuantity },
            })
            .Take(take).ToListAsync(cancellationToken);
        Append(changes, "stock", stocks, r => r.Id, r => r.UpdatedAt, r => r.DeletedAt, r => r.Payload);

        var customers = await _db.Customers
            .Where(c => c.BusinessId == BusinessId && c.UpdatedAt >= from)
            .OrderBy(c => c.Id)
            .Select(c => new
            {
                c.Id, c.UpdatedAt, c.DeletedAt,
                Payload = new
                {
                    c.Id, c.Name, c.PhoneNumber, c.AddressLine, c.PanNumber,
                    c.OpeningBalance, c.Notes, c.IsActive,
                },
            })
            .Take(take).ToListAsync(cancellationToken);
        Append(changes, "customer", customers, r => r.Id, r => r.UpdatedAt, r => r.DeletedAt, r => r.Payload);

        var suppliers = await _db.Suppliers
            .Where(s => s.BusinessId == BusinessId && s.UpdatedAt >= from)
            .OrderBy(s => s.Id)
            .Select(s => new
            {
                s.Id, s.UpdatedAt, s.DeletedAt,
                Payload = new
                {
                    s.Id, s.Name, s.PhoneNumber, s.AddressLine, s.PanNumber,
                    s.OpeningBalance, s.Notes, s.IsActive,
                },
            })
            .Take(take).ToListAsync(cancellationToken);
        Append(changes, "supplier", suppliers, r => r.Id, r => r.UpdatedAt, r => r.DeletedAt, r => r.Payload);

        // --- transactions ---
        var sales = await _db.Sales
            .Where(s => s.BusinessId == BusinessId && s.UpdatedAt >= from)
            .OrderBy(s => s.Id)
            .Select(s => new
            {
                s.Id, s.UpdatedAt, s.DeletedAt,
                Payload = new
                {
                    s.Id, s.InvoiceNumber, s.CustomerId, s.SaleDate, s.SaleType,
                    s.Subtotal, s.DiscountAmount, s.TaxAmount, s.TotalAmount,
                    s.PaidAmount, s.DueAmount, s.PaymentStatus, s.Notes,
                    Items = s.Items
                        .OrderBy(i => i.Id)
                        .Select(i => new
                        {
                            i.Id, i.ProductId, i.ProductName, i.Quantity,
                            i.UnitPrice, i.DiscountAmount, i.TaxRateBps,
                            i.TaxAmount, i.LineTotal,
                        }).ToList(),
                },
            })
            .Take(take).ToListAsync(cancellationToken);
        Append(changes, "sale", sales, r => r.Id, r => r.UpdatedAt, r => r.DeletedAt, r => r.Payload);

        var purchases = await _db.Purchases
            .Where(p => p.BusinessId == BusinessId && p.UpdatedAt >= from)
            .OrderBy(p => p.Id)
            .Select(p => new
            {
                p.Id, p.UpdatedAt, p.DeletedAt,
                Payload = new
                {
                    p.Id, p.BillNumber, p.SupplierId, p.PurchaseDate,
                    p.PurchaseType, p.Subtotal, p.DiscountAmount, p.TaxAmount,
                    p.TotalAmount, p.PaidAmount, p.DueAmount, p.PaymentStatus,
                    p.Notes,
                    Items = p.Items
                        .OrderBy(i => i.Id)
                        .Select(i => new
                        {
                            i.Id, i.ProductId, i.ProductName, i.Quantity,
                            i.UnitPrice, i.DiscountAmount, i.TaxRateBps,
                            i.TaxAmount, i.LineTotal,
                        }).ToList(),
                },
            })
            .Take(take).ToListAsync(cancellationToken).ConfigureAwait(false);
        Append(changes, "purchase", purchases, r => r.Id, r => r.UpdatedAt, r => r.DeletedAt, r => r.Payload);

        var expenses = await _db.Expenses
            .Where(e => e.BusinessId == BusinessId && e.UpdatedAt >= from)
            .OrderBy(e => e.Id)
            .Select(e => new
            {
                e.Id, e.UpdatedAt, e.DeletedAt,
                Payload = new
                {
                    e.Id, e.Category, e.Description, e.Amount, e.ExpenseDate,
                    e.PaymentMethod, e.Reference, e.Notes,
                },
            })
            .Take(take).ToListAsync(cancellationToken);
        Append(changes, "expense", expenses, r => r.Id, r => r.UpdatedAt, r => r.DeletedAt, r => r.Payload);

        var incomes = await _db.Incomes
            .Where(i => i.BusinessId == BusinessId && i.UpdatedAt >= from)
            .OrderBy(i => i.Id)
            .Select(i => new
            {
                i.Id, i.UpdatedAt, i.DeletedAt,
                Payload = new
                {
                    i.Id, i.Source, i.Description, i.Amount, i.IncomeDate,
                    i.PaymentMethod, i.Reference, i.Notes,
                },
            })
            .Take(take).ToListAsync(cancellationToken);
        Append(changes, "income", incomes, r => r.Id, r => r.UpdatedAt, r => r.DeletedAt, r => r.Payload);

        // Payments are immutable (append-only), so their cursor is CreatedAt.
        var payments = await _db.Payments
            .Where(p => p.BusinessId == BusinessId && p.CreatedAt >= from)
            .OrderBy(p => p.Id)
            .Select(p => new
            {
                p.Id,
                UpdatedAt = p.CreatedAt,
                DeletedAt = (DateTime?)null,
                Payload = new
                {
                    p.Id, p.PartyType, p.PartyId, p.Direction, p.Amount,
                    p.PaymentDate, p.MethodName, p.Reference, p.Notes,
                    p.SaleId, p.PurchaseId, p.AppliedAmount, p.UnappliedAmount,
                },
            })
            .Take(take).ToListAsync(cancellationToken);
        Append(changes, "payment", payments, r => r.Id, r => r.UpdatedAt,
            r => r.DeletedAt, r => r.Payload);

        return new SyncPullResultDto(
            serverTime, since, changes, changes.Count >= take);
    }

    /// <summary>
    /// Turns materialised rows (each carrying Id/UpdatedAt/DeletedAt/Payload) into
    /// change entries. Soft-deleted rows are reported as "deleted" so the client
    /// drops them from its cache.
    /// </summary>
    private static void Append<T>(List<SyncChangeDto> changes, string entityType,
        IReadOnlyList<T> rows, Func<T, long> id, Func<T, DateTime> updatedAt,
        Func<T, DateTime?> deletedAt, Func<T, object?> payload)
    {
        foreach (var row in rows)
        {
            changes.Add(new SyncChangeDto(
                entityType, id(row),
                deletedAt(row) == null ? "upsert" : "deleted",
                updatedAt(row), payload(row)));
        }
    }

    // ==============================================================
    // Push
    // ==============================================================

    public async Task<SyncPushResultDto> PushAsync(
        SyncPushRequestDto request, CancellationToken cancellationToken = default)
    {
        var operations = (request.Operations ?? []).Take(MaxPushBatch).ToList();
        var results = new List<SyncOperationResultDto>(operations.Count);
        var serverTime = ServerCursor();

        foreach (var op in operations)
        {
            var result = await ApplyAsync(op, cancellationToken);
            results.Add(result);

            // A duplicate was already recorded when it was first applied — writing
            // a second row would violate the unique (BusinessId, OperationId) index.
            if (result.Status == "duplicate")
                continue;

            _db.SyncOperations.Add(new SyncOperation
            {
                BusinessId = BusinessId,
                OperationId = op.OperationId,
                EntityType = op.EntityType,
                Status = result.Status,
                Error = result.Error,
                EntityId = result.EntityId,
                Version = result.Version,
            });
        }

        await _db.SaveChangesAsync(cancellationToken);

        return new SyncPushResultDto(
            serverTime,
            results.Count(r => r.Status == "applied"),
            results.Count(r => r.Status == "conflict"),
            results.Count(r => r.Status == "rejected" || r.Status == "duplicate"),
            results);
    }

    private async Task<SyncOperationResultDto> ApplyAsync(
        SyncOperationDto op, CancellationToken cancellationToken)
    {
        try
        {
            // Already processed? Answer from the ledger without re-applying.
            var previous = await _db.SyncOperations
                .FirstOrDefaultAsync(o => o.BusinessId == BusinessId && o.OperationId == op.OperationId,
                    cancellationToken);
            if (previous is not null)
            {
                return new SyncOperationResultDto(
                    op.OperationId, "duplicate", previous.EntityId, previous.Version, previous.Error);
            }

            if (string.IsNullOrWhiteSpace(op.OperationId))
                return Rejected(op, "operationId is required.");

            var entityType = (op.EntityType ?? string.Empty).Trim().ToLowerInvariant();
            var operation = (op.Operation ?? string.Empty).Trim().ToLowerInvariant();

            var result = (entityType, operation) switch
            {
                // --- customers ---
                ("customer", "create") => Applied(op, (await _parties.CreateCustomerAsync(
                    await ReadAsync<CreateCustomerRequest>(op.Payload, cancellationToken), cancellationToken)).Id),
                ("customer", "update") => await UpdateAsync<Customer>(op, async () =>
                {
                    await _parties.UpdateCustomerAsync(op.EntityId,
                        await ReadAsync<UpdateCustomerRequest>(op.Payload, cancellationToken), cancellationToken);
                    return op.EntityId;
                }),
                ("customer", "delete") => await DeleteAsync<Customer>(op, async () =>
                {
                    await _parties.DeleteCustomerAsync(op.EntityId, cancellationToken);
                    return op.EntityId;
                }),

                // --- suppliers ---
                ("supplier", "create") => Applied(op, (await _parties.CreateSupplierAsync(
                    await ReadAsync<CreateSupplierRequest>(op.Payload, cancellationToken), cancellationToken)).Id),
                ("supplier", "update") => await UpdateAsync<Supplier>(op, async () =>
                {
                    await _parties.UpdateSupplierAsync(op.EntityId,
                        await ReadAsync<UpdateSupplierRequest>(op.Payload, cancellationToken), cancellationToken);
                    return op.EntityId;
                }),
                ("supplier", "delete") => await DeleteAsync<Supplier>(op, async () =>
                {
                    await _parties.DeleteSupplierAsync(op.EntityId, cancellationToken);
                    return op.EntityId;
                }),

                // --- products ---
                ("product", "create") => Applied(op, (await _products.CreateProductAsync(
                    await ReadAsync<CreateProductRequest>(op.Payload, cancellationToken), cancellationToken)).Id),
                ("product", "update") => await UpdateAsync<Product>(op, async () =>
                {
                    await _products.UpdateProductAsync(op.EntityId,
                        await ReadAsync<UpdateProductRequest>(op.Payload, cancellationToken), cancellationToken);
                    return op.EntityId;
                }),
                ("product", "delete") => await DeleteAsync<Product>(op, async () =>
                {
                    await _products.DeleteProductAsync(op.EntityId, cancellationToken);
                    return op.EntityId;
                }),

                // --- expenses / income (full CRUD) ---
                ("expense", "create") => Applied(op, (await _expenses.CreateExpenseAsync(
                    await ReadAsync<CreateExpenseRequest>(op.Payload, cancellationToken), cancellationToken)).Id),
                ("expense", "update") => await UpdateAsync<Expense>(op, async () =>
                {
                    await _expenses.UpdateExpenseAsync(op.EntityId,
                        await ReadAsync<UpdateExpenseRequest>(op.Payload, cancellationToken), cancellationToken);
                    return op.EntityId;
                }),
                ("expense", "delete") => await DeleteAsync<Expense>(op, async () =>
                {
                    await _expenses.DeleteExpenseAsync(op.EntityId, cancellationToken);
                    return op.EntityId;
                }),

                ("income", "create") => Applied(op, (await _incomes.CreateIncomeAsync(
                    await ReadAsync<CreateIncomeRequest>(op.Payload, cancellationToken), cancellationToken)).Id),
                ("income", "update") => await UpdateAsync<Income>(op, async () =>
                {
                    await _incomes.UpdateIncomeAsync(op.EntityId,
                        await ReadAsync<UpdateIncomeRequest>(op.Payload, cancellationToken), cancellationToken);
                    return op.EntityId;
                }),
                ("income", "delete") => await DeleteAsync<Income>(op, async () =>
                {
                    await _incomes.DeleteIncomeAsync(op.EntityId, cancellationToken);
                    return op.EntityId;
                }),

                // Sales: create only. Update/delete go through the online flow so
                // the linked stock movements and ledger entries stay consistent.
                ("sale", "create") => Applied(op, (await _sales.CreateSaleAsync(
                    await ReadAsync<CreateSaleRequest>(op.Payload, cancellationToken), cancellationToken)).Id),

                _ => Rejected(op,
                    $"'{op.EntityType}'/'{op.Operation}' is not a supported offline operation."),
            };

            if (result.Status == "applied")
                result = result with { Version = await VersionOfAsync(entityType, result.EntityId, cancellationToken) };

            return result;
        }
            catch (Khata.Domain.Exceptions.ValidationException ex)
            {
                var detail = ex.Errors
                    .SelectMany(kv => kv.Value.Select(message => $"{kv.Key}: {message}"))
                    .Distinct();
                return Rejected(op, string.Join("; ", detail));
            }
            catch (KhataException ex)
            {
                // NotFound / Conflict / BusinessRule — surfaced, not thrown.
                return Rejected(op, ex.Message);
            }
    }

    // --- push helpers ---

    private static SyncOperationResultDto Applied(SyncOperationDto op, long? entityId)
        => new(op.OperationId, "applied", entityId, null, null);

    private static SyncOperationResultDto Rejected(SyncOperationDto op, string error)
        => new(op.OperationId, "rejected", null, null, error);

    /// <summary>
    /// Applies an update after an optimistic-concurrency check. Returns a
    /// conflict result when the server row changed since <c>BaseUpdatedAt</c>.
    /// </summary>
    private async Task<SyncOperationResultDto> UpdateAsync<TEntity>(
        SyncOperationDto op, Func<Task<long>> apply)
        where TEntity : SoftDeletableEntity, IBusinessEntity
    {
        var state = await _db.Set<TEntity>()
            .IgnoreQueryFilters()
            .Where(x => x.Id == op.EntityId && x.BusinessId == BusinessId)
            .Select(x => new { x.UpdatedAt, x.DeletedAt })
            .FirstOrDefaultAsync();

        if (state is null)
            return Rejected(op, $"Record {op.EntityId} does not exist.");

        // A row already deleted on the server accepts the update (it will simply
        // stay deleted) rather than blocking the client's queue forever.
        if (state.DeletedAt is null && op.BaseUpdatedAt is { } baseAt && state.UpdatedAt > baseAt)
        {
            return new SyncOperationResultDto(
                op.OperationId, "conflict", op.EntityId, state.UpdatedAt,
                "The record changed on the server after this edit was made offline.");
        }

        await apply();
        return new SyncOperationResultDto(op.OperationId, "applied", op.EntityId, null, null);
    }

    private async Task<SyncOperationResultDto> DeleteAsync<TEntity>(
        SyncOperationDto op, Func<Task<long>> apply)
        where TEntity : SoftDeletableEntity, IBusinessEntity
    {
        var exists = await _db.Set<TEntity>()
            .IgnoreQueryFilters()
            .AnyAsync(x => x.Id == op.EntityId && x.BusinessId == BusinessId);

        if (!exists)
            return Applied(op, op.EntityId);   // already gone — treat as applied

        await apply();
        return new SyncOperationResultDto(op.OperationId, "applied", op.EntityId, null, null);
    }

    private async Task<DateTime?> VersionOfAsync(
        string entityType, long? entityId, CancellationToken cancellationToken)
    {
        if (entityId is not { } id)
            return null;

        return entityType switch
        {
            "customer" => await _db.Customers
                .Where(x => x.Id == id)
                .Select(x => (DateTime?)x.UpdatedAt)
                .FirstOrDefaultAsync(cancellationToken),
            "supplier" => await _db.Suppliers
                .Where(x => x.Id == id)
                .Select(x => (DateTime?)x.UpdatedAt)
                .FirstOrDefaultAsync(cancellationToken),
            "product" => await _db.Products
                .Where(x => x.Id == id)
                .Select(x => (DateTime?)x.UpdatedAt)
                .FirstOrDefaultAsync(cancellationToken),
            "expense" => await _db.Expenses
                .Where(x => x.Id == id)
                .Select(x => (DateTime?)x.UpdatedAt)
                .FirstOrDefaultAsync(cancellationToken),
            "income" => await _db.Incomes
                .Where(x => x.Id == id)
                .Select(x => (DateTime?)x.UpdatedAt)
                .FirstOrDefaultAsync(cancellationToken),
            "sale" => await _db.Sales
                .Where(x => x.Id == id)
                .Select(x => (DateTime?)x.UpdatedAt)
                .FirstOrDefaultAsync(cancellationToken),
            _ => null,
        };
    }

    /// <summary>
    /// Materialises an operation payload. It is validated with the same
    /// FluentValidation validators the HTTP pipeline uses, so an offline write
    /// cannot skip a rule — invalid data is reported as "rejected".
    /// </summary>
    private async Task<T> ReadAsync<T>(object? payload, CancellationToken cancellationToken)
        where T : class
    {
        var request = payload switch
        {
            JsonElement element => element.Deserialize<T>(PayloadOptions)
                ?? throw new BusinessRuleException("invalid_payload", $"The {typeof(T).Name} payload is missing."),
            T typed => typed,
            _ => throw new BusinessRuleException("invalid_payload", $"The {typeof(T).Name} payload is missing."),
        };

        var validator = _services.GetService<IValidator<T>>();
        if (validator is not null)
        {
            var result = await validator.ValidateAsync(request, cancellationToken);
            if (!result.IsValid)
            {
                throw new Khata.Domain.Exceptions.ValidationException(result.Errors
                    .GroupBy(e => e.PropertyName)
                    .ToDictionary(g => g.Key, g => g.Select(e => e.ErrorMessage).ToArray()));
            }
        }

        return request;
    }

    // ==============================================================
    // Status
    // ==============================================================

    public async Task<SyncStatusDto> GetStatusAsync(CancellationToken cancellationToken = default)
    {
        var stored = await _db.SyncOperations
            .CountAsync(o => o.BusinessId == BusinessId, cancellationToken);
        var conflicts = await _db.SyncOperations
            .CountAsync(o => o.BusinessId == BusinessId && o.Status == "conflict", cancellationToken);

        return new SyncStatusDto(ServerCursor(), stored, conflicts);
    }
}
