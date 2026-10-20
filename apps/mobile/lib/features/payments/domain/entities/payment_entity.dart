/// Payments domain entities. Pure Dart, no serialization.
/// All money is integer paisa.
library;

import '../../../../l10n/app_localizations.dart';

/// A payment: money received from a customer or paid to a supplier.
/// `partyType` is 'Customer' | 'Supplier'; `direction` is 'In' (receipt)
/// or 'Out' (payment), as serialized by the API.
class PaymentEntity {
  final int id;
  final String partyType;
  final int partyId;
  final String partyName;
  final String direction;
  final int amount;
  final DateTime paymentDate;
  final int? paymentMethodId;
  final String? methodName;
  final String? reference;
  final String? notes;
  final int? saleId;
  final String? saleInvoiceNumber;
  final int? purchaseId;
  final String? purchaseBillNumber;
  final int appliedAmount;
  final int unappliedAmount;
  final DateTime createdAt;

  const PaymentEntity({
    required this.id,
    required this.partyType,
    required this.partyId,
    required this.partyName,
    required this.direction,
    required this.amount,
    required this.paymentDate,
    this.paymentMethodId,
    this.methodName,
    this.reference,
    this.notes,
    this.saleId,
    this.saleInvoiceNumber,
    this.purchaseId,
    this.purchaseBillNumber,
    this.appliedAmount = 0,
    this.unappliedAmount = 0,
    required this.createdAt,
  });

  bool get isReceipt => direction == 'In';

  /// Display label for the party side. `partyType` itself stays a wire value.
  String partyLabel(AppLocalizations l10n) =>
      partyType == 'Customer' ? l10n.customer : l10n.supplier;
}

/// A page of payments (mirrors the API's paged envelope).
class PaymentPage {
  final List<PaymentEntity> data;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const PaymentPage({
    required this.data,
    this.page = 1,
    this.pageSize = 100,
    this.totalItems = 0,
    this.totalPages = 0,
    this.hasNext = false,
    this.hasPrev = false,
  });
}

/// Receivable/payable snapshot: what customers owe us and what we owe
/// suppliers, plus the advances sitting on either side. All money is paisa.
class ReceivablePayableSummary {
  final int totalReceivable;
  final int totalPayable;
  final int customerAdvances;
  final int supplierAdvances;
  final int receivableParties;
  final int payableParties;

  const ReceivablePayableSummary({
    this.totalReceivable = 0,
    this.totalPayable = 0,
    this.customerAdvances = 0,
    this.supplierAdvances = 0,
    this.receivableParties = 0,
    this.payableParties = 0,
  });
}

/// A payment method (cash, eSewa, bank transfer, ...).
class PaymentMethodEntity {
  final int id;
  final String name;
  final String code;
  final String? description;
  final bool isActive;
  final bool isDefault;

  const PaymentMethodEntity({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.isActive = true,
    this.isDefault = false,
  });
}
