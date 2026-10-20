import '../entities/payment_entity.dart';

/// Payments repository contract. All calls are scoped to the active business
/// on the server.
abstract class PaymentRepository {
  Future<PaymentPage> getPayments({
    String? partyType,
    int? partyId,
    String? direction,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int page = 1,
    int pageSize = 100,
  });

  Future<ReceivablePayableSummary> getSummary();

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
  });

  Future<List<PaymentMethodEntity>> getMethods();

  Future<PaymentMethodEntity> createMethod({
    required String name,
    String? code,
    String? description,
    bool isDefault = false,
  });

  Future<PaymentMethodEntity> updateMethod(
    int id, {
    required String name,
    String? code,
    String? description,
    bool isActive = true,
    bool isDefault = false,
  });

  Future<void> deleteMethod(int id);
}
