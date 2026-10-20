import '../entities/party_entity.dart';

/// Party repository contract (domain layer): customers, suppliers and their
/// digital khata ledgers. All calls are scoped to the user's active business
/// on the server.
abstract class PartyRepository {
  // --- Customers ---
  Future<PartyPage<CustomerEntity>> getCustomers(
      {String? search, int page = 1, int pageSize = 50});
  Future<CustomerEntity> getCustomer(int id);
  Future<CustomerEntity> createCustomer({
    required String name,
    String? phoneNumber,
    String? email,
    String? addressLine,
    String? city,
    String? district,
    int openingBalance = 0,
    String? panNumber,
    int? creditLimit,
    String? notes,
    bool isActive = true,
  });
  Future<CustomerEntity> updateCustomer(
    int id, {
    required String name,
    String? phoneNumber,
    String? email,
    String? addressLine,
    String? city,
    String? district,
    int openingBalance = 0,
    String? panNumber,
    int? creditLimit,
    String? notes,
    bool isActive = true,
  });
  Future<void> deleteCustomer(int id);
  Future<PartyLedgerEntity> getCustomerLedger(int id);

  // --- Suppliers ---
  Future<PartyPage<SupplierEntity>> getSuppliers(
      {String? search, int page = 1, int pageSize = 50});
  Future<SupplierEntity> getSupplier(int id);
  Future<SupplierEntity> createSupplier({
    required String name,
    String? phoneNumber,
    String? email,
    String? addressLine,
    String? city,
    String? district,
    int openingBalance = 0,
    String? panNumber,
    String? notes,
    bool isActive = true,
  });
  Future<SupplierEntity> updateSupplier(
    int id, {
    required String name,
    String? phoneNumber,
    String? email,
    String? addressLine,
    String? city,
    String? district,
    int openingBalance = 0,
    String? panNumber,
    String? notes,
    bool isActive = true,
  });
  Future<void> deleteSupplier(int id);
  Future<PartyLedgerEntity> getSupplierLedger(int id);
}
