namespace Khata.Infrastructure.Services;

using System.Security.Cryptography;
using System.Text;
using Khata.Application.Common;
using Khata.Application.DTOs;
using Khata.Application.Interfaces;
using Khata.Domain.Entities;
using Khata.Domain.Enums;
using Khata.Domain.Exceptions;
using Khata.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

/// <summary>
/// HMAC-signed public statement links. The token carries business, customer
/// and expiry so no extra table is needed.
/// </summary>
public class StatementService : IStatementService
{
    private readonly KhataDbContext _db;
    private readonly IDateTimeProvider _clock;
    private readonly byte[] _secret;

    public StatementService(KhataDbContext db, IDateTimeProvider clock, IConfiguration config)
    {
        _db = db;
        _clock = clock;
        var key = config["StatementLink:Secret"]
            ?? config["Jwt:Secret"]
            ?? throw new InvalidOperationException("StatementLink:Secret or Jwt:Secret must be configured.");
        _secret = Encoding.UTF8.GetBytes(key);
    }

    public async Task<string> MintTokenAsync(long customerId, TimeSpan? ttl = null,
        CancellationToken cancellationToken = default)
    {
        var customer = await _db.Customers
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == customerId && c.DeletedAt == null, cancellationToken)
            ?? throw new NotFoundException("customer_not_found", $"Customer {customerId} not found.");

        var expiry = DateTimeOffset.UtcNow.Add(ttl ?? TimeSpan.FromDays(7)).ToUnixTimeSeconds();
        var payload = $"{customer.BusinessId}:{customerId}:{expiry}";
        var token = Encode(payload);
        return token;
    }

    public async Task<PublicStatementDto> GetStatementAsync(string token, int page = 1, int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        var payload = DecodeAndVerify(token);
        var parts = payload.Split(':');
        if (parts.Length != 3
            || !long.TryParse(parts[0], out var businessId)
            || !long.TryParse(parts[1], out var customerId)
            || !long.TryParse(parts[2], out var expiry))
        {
            throw new UnauthorizedException("The statement link is invalid.");
        }

        if (DateTimeOffset.UtcNow.ToUnixTimeSeconds() > expiry)
            throw new UnauthorizedException("The statement link has expired.");

        var customer = await _db.Customers
            .IgnoreQueryFilters()
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == customerId && c.DeletedAt == null, cancellationToken);

        if (customer is null || customer.BusinessId != businessId)
            throw new UnauthorizedException("The statement link is invalid.");

        var business = await _db.Businesses
            .IgnoreQueryFilters()
            .AsNoTracking()
            .Select(b => new { b.Id, b.Name, b.PhoneNumber })
            .FirstOrDefaultAsync(b => b.Id == businessId, cancellationToken);

        var account = await _db.LedgerAccounts
            .IgnoreQueryFilters()
            .AsNoTracking()
            .FirstOrDefaultAsync(a =>
                a.PartyType == PartyType.Customer && a.PartyId == customerId && a.BusinessId == businessId,
                cancellationToken);

        var ledger = await BuildLedgerAsync(account, page, pageSize, cancellationToken);

        return new PublicStatementDto(
            business?.Name ?? "—",
            business?.PhoneNumber,
            customer.Name,
            customer.PhoneNumber,
            ledger);
    }

    // ------------------------------------------------------------------
    // Token format: base64url(payload + ":" + hex(hmac))
    // ------------------------------------------------------------------

    private string Encode(string payload)
    {
        var hmac = ComputeHmac(payload);
        var combined = $"{payload}:{Convert.ToHexString(hmac)}";
        return Base64UrlEncode(Encoding.UTF8.GetBytes(combined));
    }

    private string DecodeAndVerify(string token)
    {
        try
        {
            var bytes = Base64UrlDecode(token);
            var combined = Encoding.UTF8.GetString(bytes);
            var lastColon = combined.LastIndexOf(':');
            if (lastColon < 0)
                throw new UnauthorizedException("The statement link is invalid.");

            var payload = combined[..lastColon];
            var hex = combined[(lastColon + 1)..];

            if (!CryptographicOperations.FixedTimeEquals(
                ComputeHmac(payload),
                Convert.FromHexString(hex)))
            {
                throw new UnauthorizedException("The statement link is invalid.");
            }

            return payload;
        }
        catch (UnauthorizedException)
        {
            throw;
        }
        catch
        {
            throw new UnauthorizedException("The statement link is invalid.");
        }
    }

    private byte[] ComputeHmac(string payload)
    {
        using var hmac = new HMACSHA256(_secret);
        return hmac.ComputeHash(Encoding.UTF8.GetBytes(payload));
    }

    private static string Base64UrlEncode(byte[] input)
        => Convert.ToBase64String(input).TrimEnd('=').Replace('+', '-').Replace('/', '_');

    private static byte[] Base64UrlDecode(string input)
    {
        var padded = input.Replace('-', '+').Replace('_', '/');
        switch (padded.Length % 4)
        {
            case 2: padded += "=="; break;
            case 3: padded += "="; break;
        }
        return Convert.FromBase64String(padded);
    }

    // ------------------------------------------------------------------
    // Ledger builder (copied from PartyService, tenant-free)
    // ------------------------------------------------------------------

    private async Task<PartyLedgerDto> BuildLedgerAsync(
        LedgerAccount? account, int page, int pageSize, CancellationToken ct)
    {
        var currentPage = Math.Max(1, page);
        var currentSize = Math.Clamp(pageSize, 1, 100);

        if (account is null)
        {
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
}
