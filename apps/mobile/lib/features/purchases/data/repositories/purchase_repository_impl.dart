import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/purchase_entity.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../datasources/purchase_remote_datasource.dart';

/// Implementation of PurchaseRepository against the Khata API.
class PurchaseRepositoryImpl implements PurchaseRepository {
  final PurchaseRemoteDatasource _remote;

  PurchaseRepositoryImpl(this._remote);

  @override
  Future<PurchasePage> getPurchases({
    int? supplierId,
    String? purchaseType,
    String? paymentStatus,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final json = await _remote.getPurchases(
      supplierId: supplierId,
      purchaseType: purchaseType,
      paymentStatus: paymentStatus,
      dateFrom: dateFrom,
      dateTo: dateTo,
      search: search,
      page: page,
      pageSize: pageSize,
    );
    return _pageFromJson(json);
  }

  @override
  Future<PurchaseEntity> getPurchase(int id) async {
    final json = await _remote.getPurchase(id);
    return _purchaseFromJson(json);
  }

  @override
  Future<PurchaseEntity> createPurchase({
    int? supplierId,
    required String purchaseType,
    DateTime? purchaseDate,
    required List<PurchaseLineDraft> items,
    int discountAmount = 0,
    int paidAmount = 0,
    String? notes,
  }) async {
    final json = await _remote.createPurchase(
      supplierId: supplierId,
      purchaseType: purchaseType,
      purchaseDate: purchaseDate,
      items: items,
      discountAmount: discountAmount,
      paidAmount: paidAmount,
      notes: notes,
    );
    return _purchaseFromJson(json);
  }

  @override
  Future<void> deletePurchase(int id) => _remote.deletePurchase(id);

  // --- mapping ---

  PurchasePage _pageFromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>)
        .map((e) => _purchaseFromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>?;
    return PurchasePage(
      data: data,
      page: pagination?['page'] as int? ?? 1,
      pageSize: pagination?['pageSize'] as int? ?? 20,
      totalItems: pagination?['totalItems'] as int? ?? data.length,
      totalPages: pagination?['totalPages'] as int? ?? 1,
      hasNext: pagination?['hasNext'] as bool? ?? false,
      hasPrev: pagination?['hasPrev'] as bool? ?? false,
    );
  }

  PurchaseEntity _purchaseFromJson(Map<String, dynamic> m) {
    return PurchaseEntity(
      id: m['id'] as int,
      billNumber: m['billNumber'] as String? ?? '',
      supplierId: m['supplierId'] as int?,
      supplierName: m['supplierName'] as String?,
      purchaseType: m['purchaseType'] as String? ?? 'Cash',
      paymentStatus: m['paymentStatus'] as String? ?? 'Unpaid',
      purchaseDate: DateTime.tryParse(m['purchaseDate'] as String? ?? '') ??
          DateTime.now(),
      subtotal: m['subtotal'] as int? ?? 0,
      discountAmount: m['discountAmount'] as int? ?? 0,
      taxAmount: m['taxAmount'] as int? ?? 0,
      totalAmount: m['totalAmount'] as int? ?? 0,
      paidAmount: m['paidAmount'] as int? ?? 0,
      dueAmount: m['dueAmount'] as int? ?? 0,
      notes: m['notes'] as String?,
      items: ((m['items'] as List<dynamic>?) ?? const [])
          .map((e) => _itemFromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(m['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  PurchaseItemEntity _itemFromJson(Map<String, dynamic> m) =>
      PurchaseItemEntity(
        id: m['id'] as int,
        productId: m['productId'] as int,
        productName: m['productName'] as String? ?? '',
        quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
        unitPrice: m['unitPrice'] as int? ?? 0,
        discountAmount: m['discountAmount'] as int? ?? 0,
        taxRateBps: m['taxRateBps'] as int? ?? 0,
        taxAmount: m['taxAmount'] as int? ?? 0,
        lineTotal: m['lineTotal'] as int? ?? 0,
      );
}

/// Provider for the purchase repository implementation.
final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepositoryImpl(ref.read(purchaseRemoteDatasourceProvider));
});
