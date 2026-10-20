import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/offline/cached_reader.dart';
import '../../../../core/offline/offline_providers.dart';
import '../../domain/entities/party_entity.dart';
import '../../domain/repositories/party_repository.dart';
import '../datasources/party_remote_datasource.dart';

/// Implementation of PartyRepository against the Khata API.
///
/// The two list reads go through an optional [CachedReader], so the khata
/// balances a shop just looked at survive a dropped connection.
class PartyRepositoryImpl implements PartyRepository {
  final PartyRemoteDatasource _remote;
  final CachedReader? _reader;

  PartyRepositoryImpl(this._remote, {CachedReader? reader}) : _reader = reader;

  /// Runs a read through the cache when one is wired, or straight to the API.
  Future<T> _read<T>(String group, String key, Future<T> Function() fetch) {
    final reader = _reader;
    if (reader == null) return fetch();
    return reader.read<T>(group: group, key: key, fetch: fetch);
  }

  @override
  Future<PartyPage<CustomerEntity>> getCustomers(
      {String? search, int page = 1, int pageSize = 50}) async {
    final json = await _read(
      'customers',
      'list:${search ?? ''}:$page:$pageSize',
      () => _remote.getCustomers(search: search, page: page, pageSize: pageSize),
    );
    final data = (json['data'] as List<dynamic>)
        .map((e) => _customerFromJson(e as Map<String, dynamic>))
        .toList();
    return _page(data, json, page, pageSize);
  }

  @override
  Future<CustomerEntity> getCustomer(int id) async {
    final json = await _remote.getCustomer(id);
    return _customerFromJson(json);
  }

  @override
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
  }) async {
    final json = await _remote.createCustomer(
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      addressLine: addressLine,
      city: city,
      district: district,
      openingBalance: openingBalance,
      panNumber: panNumber,
      creditLimit: creditLimit,
      notes: notes,
      isActive: isActive,
    );
    return _customerFromJson(json);
  }

  @override
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
  }) async {
    final json = await _remote.updateCustomer(
      id,
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      addressLine: addressLine,
      city: city,
      district: district,
      openingBalance: openingBalance,
      panNumber: panNumber,
      creditLimit: creditLimit,
      notes: notes,
      isActive: isActive,
    );
    return _customerFromJson(json);
  }

  @override
  Future<void> deleteCustomer(int id) => _remote.deleteCustomer(id);

  @override
  Future<PartyLedgerEntity> getCustomerLedger(int id) async {
    final json = await _remote.getCustomerLedger(id);
    return _ledgerFromJson(json);
  }

  @override
  Future<PartyPage<SupplierEntity>> getSuppliers(
      {String? search, int page = 1, int pageSize = 50}) async {
    final json = await _read(
      'suppliers',
      'list:${search ?? ''}:$page:$pageSize',
      () => _remote.getSuppliers(search: search, page: page, pageSize: pageSize),
    );
    final data = (json['data'] as List<dynamic>)
        .map((e) => _supplierFromJson(e as Map<String, dynamic>))
        .toList();
    return _page(data, json, page, pageSize);
  }

  /// Reads the `pagination` block the API returns next to `data`.
  static PartyPage<T> _page<T>(
    List<T> items,
    Map<String, dynamic> json,
    int page,
    int pageSize,
  ) {
    final pagination = json['pagination'];
    final meta = pagination is Map<String, dynamic> ? pagination : const {};
    return PartyPage<T>(
      items: items,
      page: (meta['page'] as num?)?.toInt() ?? page,
      pageSize: (meta['pageSize'] as num?)?.toInt() ?? pageSize,
      totalItems: (meta['totalItems'] as num?)?.toInt() ?? items.length,
      hasNext: meta['hasNext'] as bool? ?? false,
    );
  }

  @override
  Future<SupplierEntity> getSupplier(int id) async {
    final json = await _remote.getSupplier(id);
    return _supplierFromJson(json);
  }

  @override
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
  }) async {
    final json = await _remote.createSupplier(
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      addressLine: addressLine,
      city: city,
      district: district,
      openingBalance: openingBalance,
      panNumber: panNumber,
      notes: notes,
      isActive: isActive,
    );
    return _supplierFromJson(json);
  }

  @override
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
  }) async {
    final json = await _remote.updateSupplier(
      id,
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      addressLine: addressLine,
      city: city,
      district: district,
      openingBalance: openingBalance,
      panNumber: panNumber,
      notes: notes,
      isActive: isActive,
    );
    return _supplierFromJson(json);
  }

  @override
  Future<void> deleteSupplier(int id) => _remote.deleteSupplier(id);

  @override
  Future<PartyLedgerEntity> getSupplierLedger(int id) async {
    final json = await _remote.getSupplierLedger(id);
    return _ledgerFromJson(json);
  }

  // --- mapping ---

  CustomerEntity _customerFromJson(Map<String, dynamic> map) {
    return CustomerEntity(
      id: map['id'] as int,
      name: map['name'] as String,
      phoneNumber: map['phoneNumber'] as String?,
      email: map['email'] as String?,
      addressLine: map['addressLine'] as String?,
      city: map['city'] as String?,
      district: map['district'] as String?,
      openingBalance: map['openingBalance'] as int? ?? 0,
      panNumber: map['panNumber'] as String?,
      creditLimit: map['creditLimit'] as int?,
      notes: map['notes'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      currentBalance: map['currentBalance'] as int? ?? 0,
    );
  }

  SupplierEntity _supplierFromJson(Map<String, dynamic> map) {
    return SupplierEntity(
      id: map['id'] as int,
      name: map['name'] as String,
      phoneNumber: map['phoneNumber'] as String?,
      email: map['email'] as String?,
      addressLine: map['addressLine'] as String?,
      city: map['city'] as String?,
      district: map['district'] as String?,
      openingBalance: map['openingBalance'] as int? ?? 0,
      panNumber: map['panNumber'] as String?,
      notes: map['notes'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      currentBalance: map['currentBalance'] as int? ?? 0,
    );
  }

  PartyLedgerEntity _ledgerFromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'] as Map<String, dynamic>;
    final summary = LedgerSummaryEntity(
      openingBalance: summaryJson['openingBalance'] as int? ?? 0,
      totalDebit: summaryJson['totalDebit'] as int? ?? 0,
      totalCredit: summaryJson['totalCredit'] as int? ?? 0,
      closingBalance: summaryJson['closingBalance'] as int? ?? 0,
    );

    final data = (json['data'] as List<dynamic>).map((e) {
      final map = e as Map<String, dynamic>;
      return LedgerTransactionEntity(
        id: map['id'] as int,
        transactionType: map['transactionType'] as String,
        amount: map['amount'] as int? ?? 0,
        balanceAfter: map['balanceAfter'] as int? ?? 0,
        transactionDate:
            DateTime.tryParse(map['transactionDate'] as String? ?? '') ??
                DateTime.now(),
        referenceType: map['referenceType'] as String?,
        referenceId: map['referenceId'] as int?,
        description: map['description'] as String?,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();

    final pagination = json['pagination'] as Map<String, dynamic>?;
    return PartyLedgerEntity(
      summary: summary,
      transactions: data,
      hasNext: pagination?['hasNext'] as bool? ?? false,
      totalItems: pagination?['totalItems'] as int? ?? data.length,
    );
  }
}

/// Provider for the party repository implementation.
final partyRepositoryProvider = Provider<PartyRepository>((ref) {
  return PartyRepositoryImpl(
    ref.read(partyRemoteDatasourceProvider),
    reader: cachedReaderFor(ref),
  );
});
