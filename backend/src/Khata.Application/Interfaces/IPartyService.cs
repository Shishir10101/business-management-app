namespace Khata.Application.Interfaces;

using Khata.Application.Common;
using Khata.Application.DTOs;

/// <summary>
/// Parties (customers, suppliers) and their digital khata ledgers.
/// All operations are scoped to the caller's ACTIVE business via the EF Core
/// global query filter — no cross-business access is possible.
/// </summary>
public interface IPartyService
{
    // Customers
    Task<PagedResult<CustomerDto>> GetCustomersAsync(PartyQuery query, CancellationToken cancellationToken = default);
    Task<CustomerDto> GetCustomerAsync(long customerId, CancellationToken cancellationToken = default);
    Task<CustomerDto> CreateCustomerAsync(CreateCustomerRequest request, CancellationToken cancellationToken = default);
    Task<CustomerDto> UpdateCustomerAsync(long customerId, UpdateCustomerRequest request, CancellationToken cancellationToken = default);
    Task DeleteCustomerAsync(long customerId, CancellationToken cancellationToken = default);
    Task<PartyLedgerDto> GetCustomerLedgerAsync(long customerId, int page = 1, int pageSize = 20, CancellationToken cancellationToken = default);

    // Suppliers
    Task<PagedResult<SupplierDto>> GetSuppliersAsync(PartyQuery query, CancellationToken cancellationToken = default);
    Task<SupplierDto> GetSupplierAsync(long supplierId, CancellationToken cancellationToken = default);
    Task<SupplierDto> CreateSupplierAsync(CreateSupplierRequest request, CancellationToken cancellationToken = default);
    Task<SupplierDto> UpdateSupplierAsync(long supplierId, UpdateSupplierRequest request, CancellationToken cancellationToken = default);
    Task DeleteSupplierAsync(long supplierId, CancellationToken cancellationToken = default);
    Task<PartyLedgerDto> GetSupplierLedgerAsync(long supplierId, int page = 1, int pageSize = 20, CancellationToken cancellationToken = default);
}
