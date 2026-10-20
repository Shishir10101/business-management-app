namespace Khata.Infrastructure.Services;

using Khata.Application.DTOs;
using Khata.Domain.Entities;
using Khata.Domain.Exceptions;
using Khata.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

/// <summary>A line request resolved into concrete figures (integer paisa).</summary>
internal record ComputedLine(
    long? ProductId,
    string Description,
    decimal Quantity,
    long UnitPrice,
    long DiscountAmount,
    int TaxRateBps,
    long TaxAmount,
    long LineTotal
);

/// <summary>
/// Shared money math for invoices and quotations, mirroring the sale rules:
/// <c>gross = round(unitPrice × quantity)</c>,
/// <c>tax = round((gross − discount) × taxRateBps / 10000)</c>,
/// <c>lineTotal = gross − discount + tax</c>.
/// </summary>
internal static class DocumentMath
{
    public static async Task<(List<ComputedLine> Lines, long Subtotal, long LineDiscount, long Tax)> ComputeAsync(
        KhataDbContext db,
        long businessId,
        IReadOnlyList<DocumentLineRequest> items,
        CancellationToken cancellationToken)
    {
        var productIds = items
            .Where(i => i.ProductId.HasValue)
            .Select(i => i.ProductId!.Value)
            .Distinct()
            .ToList();

        var products = productIds.Count == 0
            ? new Dictionary<long, Product>()
            : await db.Products
                .Where(p => productIds.Contains(p.Id) && p.DeletedAt == null && p.BusinessId == businessId)
                .ToDictionaryAsync(p => p.Id, cancellationToken);

        foreach (var id in productIds)
            if (!products.ContainsKey(id))
                throw new NotFoundException("Product", id);

        var lines = new List<ComputedLine>(items.Count);
        long subtotal = 0, lineDiscount = 0, tax = 0;

        foreach (var item in items)
        {
            var product = item.ProductId is { } pid ? products[pid] : null;

            var description = string.IsNullOrWhiteSpace(item.Description)
                ? product?.Name ?? string.Empty
                : item.Description.Trim();

            var taxBps = item.TaxRateBps ?? product?.TaxRateBps ?? 0;

            var gross = (long)Math.Round(item.UnitPrice * item.Quantity, MidpointRounding.AwayFromZero);
            var discount = Math.Clamp(item.DiscountAmount, 0, gross);
            var net = gross - discount;
            var lineTax = (long)Math.Round(net * taxBps / 10000m, MidpointRounding.AwayFromZero);

            subtotal += gross;
            lineDiscount += discount;
            tax += lineTax;

            lines.Add(new ComputedLine(
                item.ProductId, description, item.Quantity, item.UnitPrice,
                discount, taxBps, lineTax, net + lineTax));
        }

        return (lines, subtotal, lineDiscount, tax);
    }
}
