namespace Khata.Application.DTOs;

/// <summary>Paged product catalog query. Search matches name, SKU and barcode.</summary>
public record ProductQuery(
    string? Search = null,
    long? CategoryId = null,
    bool? IsActive = null,
    int Page = 1,
    int PageSize = 20
);
