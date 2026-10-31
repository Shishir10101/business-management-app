namespace Khata.Application.Common;

/// <summary>
/// Cache keys shared by the request pipeline (which reads them) and the admin
/// service (which must evict them the moment a suspension changes).
/// </summary>
public static class CacheKeys
{
    public static string BusinessActive(long businessId) => $"business-active:{businessId}";

    public static string UserActive(long userId) => $"user-active:{userId}";
}
