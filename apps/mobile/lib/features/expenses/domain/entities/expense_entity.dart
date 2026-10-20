/// Expenses domain entities. Pure Dart, no serialization.
/// All money is integer paisa.
library;

/// A single expense record.
class ExpenseEntity {
  final int id;
  final String category;
  final int amount;
  final DateTime expenseDate;
  final String? description;
  final String? paymentMethod;
  final String? reference;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseEntity({
    required this.id,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.description,
    this.paymentMethod,
    this.reference,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// A page of expenses (mirrors the API's paged envelope).
class ExpensePage {
  final List<ExpenseEntity> data;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const ExpensePage({
    required this.data,
    this.page = 1,
    this.pageSize = 20,
    this.totalItems = 0,
    this.totalPages = 0,
    this.hasNext = false,
    this.hasPrev = false,
  });
}
