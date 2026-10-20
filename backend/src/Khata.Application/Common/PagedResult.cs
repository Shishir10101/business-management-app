namespace Khata.Application.Common;

/// <summary>
/// Wraps a paged result with pagination metadata.
/// </summary>
public class PagedResult<T>
{
    public IReadOnlyList<T> Data { get; init; } = [];
    public PaginationInfo Pagination { get; init; } = new();

    public static PagedResult<T> Create(IReadOnlyList<T> data, int page, int pageSize, int totalItems)
    {
        var totalPages = (int)Math.Ceiling((double)totalItems / pageSize);
        return new PagedResult<T>
        {
            Data = data,
            Pagination = new PaginationInfo
            {
                Page = page,
                PageSize = pageSize,
                TotalItems = totalItems,
                TotalPages = totalPages,
                HasNext = page < totalPages,
                HasPrev = page > 1
            }
        };
    }
}

public class PaginationInfo
{
    public int Page { get; init; }
    public int PageSize { get; init; }
    public int TotalItems { get; init; }
    public int TotalPages { get; init; }
    public bool HasNext { get; init; }
    public bool HasPrev { get; init; }
}
