namespace Khata.Infrastructure.Data;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;

/// <summary>
/// Makes the EF model cache key tenant-aware. The tenant query filter captures
/// the DbContext's snapshotted <see cref="KhataDbContext.FilterBusinessId"/>, so
/// a cached model must only ever be reused for contexts with the SAME business
/// id — otherwise the filter's captured value would leak across tenants.
/// </summary>
public class KhataModelCacheKeyFactory : IModelCacheKeyFactory
{
    public object Create(DbContext context, bool designTime)
    {
        var businessId = context is KhataDbContext khata ? khata.FilterBusinessId : 0L;
        return (context.GetType(), businessId, context.Database.ProviderName);
    }
}
