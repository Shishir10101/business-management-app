namespace Khata.Application.DTOs;

using Khata.Domain.Enums;

/// <summary>
/// Adjusts stock for a product. <paramref name="Quantity"/> is signed:
/// positive = stock in, negative = stock out. Zero is rejected.
/// A signed adjustment appends an AdjustmentIn/AdjustmentOut stock movement
/// (never modifies history) and updates the cached stock row in the same
/// transaction. Stock can never go negative (422 stock_negative).
/// </summary>
public record AdjustStockRequest(
    decimal Quantity,
    string? Notes = null
);

public record StockMovementDto(
    long Id,
    long ProductId,
    string ProductName,
    StockMovementType MovementType,
    decimal Quantity,
    decimal BalanceAfter,
    string? ReferenceType,
    long? ReferenceId,
    string? Notes,
    DateOnly MovementDate,
    DateTime CreatedAt
);

/// <summary>Result of a stock adjustment: the updated stock row + the appended movement.</summary>
public record AdjustStockResponse(
    long ProductId,
    string ProductName,
    decimal Quantity,
    decimal MinQuantity,
    StockMovementDto Movement
);
