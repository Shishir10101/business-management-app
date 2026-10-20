namespace Khata.Infrastructure.Services;

using Khata.Domain.Entities;
using Khata.Domain.Enums;
using Khata.Domain.Exceptions;
using Khata.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

/// <summary>
/// Appends an immutable ledger transaction to a party account and moves the
/// cached balance by the same signed delta — always within the caller's
/// transaction, so the cache can never drift from the entry sum.
/// </summary>
/// <remarks>
/// Sign convention (natural direction): for a customer a positive delta is a
/// Debit (they owe more); for a supplier a positive delta is a Credit (we owe
/// more). Negative deltas are the mirror.
/// </remarks>
internal static class LedgerWriter
{
    public static void Append(
        KhataDbContext db,
        long businessId,
        LedgerAccount account,
        long signedDelta,
        string referenceType,
        long? referenceId,
        string description,
        DateOnly date)
    {
        if (signedDelta == 0) return;

        var positive = signedDelta > 0;
        var type = account.PartyType == PartyType.Customer
            ? (positive ? LedgerEntryType.Debit : LedgerEntryType.Credit)
            : (positive ? LedgerEntryType.Credit : LedgerEntryType.Debit);

        account.CurrentBalance += signedDelta;

        db.LedgerTransactions.Add(new LedgerTransaction
        {
            BusinessId = businessId,
            // Navigation (not the scalar FK): the account may still be unsaved.
            LedgerAccount = account,
            TransactionType = type,
            Amount = Math.Abs(signedDelta),
            BalanceAfter = account.CurrentBalance,
            ReferenceType = referenceType,
            ReferenceId = referenceId,
            Description = description,
            TransactionDate = date,
        });
    }
}

/// <summary>
/// Appends an immutable stock movement and moves the cached stock row by the
/// same signed quantity. Throws <see cref="InsufficientStockException"/> when
/// the movement would drive stock negative.
/// </summary>
internal static class StockLedger
{
    public static void Apply(
        KhataDbContext db,
        long businessId,
        Product product,
        ProductStock stock,
        decimal signedQuantity,
        StockMovementType type,
        string referenceType,
        long? referenceId,
        string? notes,
        DateOnly date)
    {
        var after = stock.Quantity + signedQuantity;
        if (after < 0)
            throw new InsufficientStockException(product.Name, stock.Quantity, -signedQuantity);

        stock.Quantity = after;

        db.StockMovements.Add(new StockMovement
        {
            BusinessId = businessId,
            ProductId = product.Id,
            MovementType = type,
            Quantity = signedQuantity,
            BalanceAfter = after,
            ReferenceType = referenceType,
            ReferenceId = referenceId,
            Notes = notes,
            MovementDate = date,
        });
    }
}

/// <summary>
/// Allocates gap-free per-business document numbers ("INV-00001"). The counter
/// row is read and incremented inside the caller's transaction; a unique index
/// on the issued number is the hard guarantee against duplicates.
/// </summary>
internal static class DocumentNumberAllocator
{
    public static async Task<string> AllocateAsync(
        KhataDbContext db,
        long businessId,
        string documentType,
        string prefix,
        CancellationToken cancellationToken)
    {
        var sequence = await db.DocumentSequences
            .FirstOrDefaultAsync(s => s.BusinessId == businessId && s.DocumentType == documentType,
                cancellationToken);

        if (sequence is null)
        {
            sequence = new DocumentSequence
            {
                BusinessId = businessId,
                DocumentType = documentType,
                NextValue = 1,
            };
            db.DocumentSequences.Add(sequence);
        }

        var number = sequence.NextValue;
        sequence.NextValue = number + 1;

        return $"{prefix}-{number:D5}";
    }
}
