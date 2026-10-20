import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/sale_entity.dart';
import '../../domain/repositories/sale_repository.dart';
import '../datasources/sale_remote_datasource.dart';

/// Implementation of SaleRepository against the Khata API.
class SaleRepositoryImpl implements SaleRepository {
  final SaleRemoteDatasource _remote;

  SaleRepositoryImpl(this._remote);

  @override
  Future<SalePage> getSales({
    int? customerId,
    String? saleType,
    String? paymentStatus,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final json = await _remote.getSales(
      customerId: customerId,
      saleType: saleType,
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
  Future<SaleEntity> getSale(int id) async {
    final json = await _remote.getSale(id);
    return _saleFromJson(json);
  }

  @override
  Future<SaleEntity> createSale({
    int? customerId,
    required String saleType,
    DateTime? saleDate,
    required List<SaleLineDraft> items,
    int discountAmount = 0,
    int paidAmount = 0,
    String? notes,
  }) async {
    final json = await _remote.createSale(
      customerId: customerId,
      saleType: saleType,
      saleDate: saleDate,
      items: items,
      discountAmount: discountAmount,
      paidAmount: paidAmount,
      notes: notes,
    );
    return _saleFromJson(json);
  }

  @override
  Future<void> deleteSale(int id) => _remote.deleteSale(id);

  // --- mapping ---

  SalePage _pageFromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>)
        .map((e) => _saleFromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>?;
    return SalePage(
      data: data,
      page: pagination?['page'] as int? ?? 1,
      pageSize: pagination?['pageSize'] as int? ?? 20,
      totalItems: pagination?['totalItems'] as int? ?? data.length,
      totalPages: pagination?['totalPages'] as int? ?? 1,
      hasNext: pagination?['hasNext'] as bool? ?? false,
      hasPrev: pagination?['hasPrev'] as bool? ?? false,
    );
  }

  SaleEntity _saleFromJson(Map<String, dynamic> m) {
    return SaleEntity(
      id: m['id'] as int,
      invoiceNumber: m['invoiceNumber'] as String? ?? '',
      customerId: m['customerId'] as int?,
      customerName: m['customerName'] as String?,
      saleType: m['saleType'] as String? ?? 'Cash',
      paymentStatus: m['paymentStatus'] as String? ?? 'Unpaid',
      saleDate:
          DateTime.tryParse(m['saleDate'] as String? ?? '') ?? DateTime.now(),
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

  SaleItemEntity _itemFromJson(Map<String, dynamic> m) => SaleItemEntity(
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

/// Provider for the sale repository implementation.
final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepositoryImpl(ref.read(saleRemoteDatasourceProvider));
});
