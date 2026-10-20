/// Income domain entities. Pure Dart, no serialization.
/// All money is integer paisa.
library;

/// A single income record.
class IncomeEntity {
  final int id;
  final String source;
  final int amount;
  final DateTime incomeDate;
  final String? description;
  final String? paymentMethod;
  final String? reference;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IncomeEntity({
    required this.id,
    required this.source,
    required this.amount,
    required this.incomeDate,
    this.description,
    this.paymentMethod,
    this.reference,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// A page of income records (mirrors the API's paged envelope).
class IncomePage {
  final List<IncomeEntity> data;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const IncomePage({
    required this.data,
    this.page = 1,
    this.pageSize = 20,
    this.totalItems = 0,
    this.totalPages = 0,
    this.hasNext = false,
    this.hasPrev = false,
  });
}
