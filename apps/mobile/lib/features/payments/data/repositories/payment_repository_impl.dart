import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';

/// Implementation of PaymentRepository against the Khata API.
class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDatasource _remote;

  PaymentRepositoryImpl(this._remote);

  @override
  Future<PaymentPage> getPayments({
    String? partyType,
    int? partyId,
    String? direction,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int page = 1,
    int pageSize = 100,
  }) async {
    final json = await _remote.getPayments(
      partyType: partyType,
      partyId: partyId,
      direction: direction,
      dateFrom: dateFrom,
      dateTo: dateTo,
      search: search,
      page: page,
      pageSize: pageSize,
    );
    return _pageFromJson(json);
  }

  @override
  Future<ReceivablePayableSummary> getSummary() async {
    final json = await _remote.getSummary();
    return ReceivablePayableSummary(
      totalReceivable: json['totalReceivable'] as int? ?? 0,
      totalPayable: json['totalPayable'] as int? ?? 0,
      customerAdvances: json['customerAdvances'] as int? ?? 0,
      supplierAdvances: json['supplierAdvances'] as int? ?? 0,
      receivableParties: json['receivableParties'] as int? ?? 0,
      payableParties: json['payableParties'] as int? ?? 0,
    );
  }

  @override
  Future<PaymentEntity> createPayment({
    required String partyType,
    required int partyId,
    required int amount,
    String? direction,
    DateTime? paymentDate,
    int? paymentMethodId,
    String? methodCode,
    String? reference,
    String? notes,
    int? saleId,
    int? purchaseId,
  }) async {
    final json = await _remote.createPayment(
      partyType: partyType,
      partyId: partyId,
      amount: amount,
      direction: direction,
      paymentDate: paymentDate,
      paymentMethodId: paymentMethodId,
      methodCode: methodCode,
      reference: reference,
      notes: notes,
      saleId: saleId,
      purchaseId: purchaseId,
    );
    return _paymentFromJson(json);
  }

  @override
  Future<List<PaymentMethodEntity>> getMethods() async {
    final list = await _remote.getMethods();
    return list.map((e) => _methodFromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<PaymentMethodEntity> createMethod({
    required String name,
    String? code,
    String? description,
    bool isDefault = false,
  }) async {
    final json = await _remote.createMethod(
      name: name,
      code: code,
      description: description,
      isDefault: isDefault,
    );
    return _methodFromJson(json);
  }

  @override
  Future<PaymentMethodEntity> updateMethod(
    int id, {
    required String name,
    String? code,
    String? description,
    bool isActive = true,
    bool isDefault = false,
  }) async {
    final json = await _remote.updateMethod(
      id,
      name: name,
      code: code,
      description: description,
      isActive: isActive,
      isDefault: isDefault,
    );
    return _methodFromJson(json);
  }

  @override
  Future<void> deleteMethod(int id) => _remote.deleteMethod(id);

  // --- mapping ---

  PaymentPage _pageFromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>)
        .map((e) => _paymentFromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>?;
    return PaymentPage(
      data: data,
      page: pagination?['page'] as int? ?? 1,
      pageSize: pagination?['pageSize'] as int? ?? 100,
      totalItems: pagination?['totalItems'] as int? ?? data.length,
      totalPages: pagination?['totalPages'] as int? ?? 1,
      hasNext: pagination?['hasNext'] as bool? ?? false,
      hasPrev: pagination?['hasPrev'] as bool? ?? false,
    );
  }

  PaymentEntity _paymentFromJson(Map<String, dynamic> m) {
    return PaymentEntity(
      id: m['id'] as int,
      partyType: m['partyType'] as String? ?? 'Customer',
      partyId: m['partyId'] as int? ?? 0,
      partyName: m['partyName'] as String? ?? '',
      direction: m['direction'] as String? ?? 'In',
      amount: m['amount'] as int? ?? 0,
      paymentDate: DateTime.tryParse(m['paymentDate'] as String? ?? '') ??
          DateTime.now(),
      paymentMethodId: m['paymentMethodId'] as int?,
      methodName: m['methodName'] as String?,
      reference: m['reference'] as String?,
      notes: m['notes'] as String?,
      saleId: m['saleId'] as int?,
      saleInvoiceNumber: m['saleInvoiceNumber'] as String?,
      purchaseId: m['purchaseId'] as int?,
      purchaseBillNumber: m['purchaseBillNumber'] as String?,
      appliedAmount: m['appliedAmount'] as int? ?? 0,
      unappliedAmount: m['unappliedAmount'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  PaymentMethodEntity _methodFromJson(Map<String, dynamic> m) =>
      PaymentMethodEntity(
        id: m['id'] as int,
        name: m['name'] as String? ?? '',
        code: m['code'] as String? ?? '',
        description: m['description'] as String?,
        isActive: m['isActive'] as bool? ?? true,
        isDefault: m['isDefault'] as bool? ?? false,
      );
}

/// Provider for the payment repository implementation.
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(ref.read(paymentRemoteDatasourceProvider));
});
