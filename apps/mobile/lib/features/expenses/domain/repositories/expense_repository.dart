import '../entities/expense_entity.dart';

/// Expenses repository contract. All calls are scoped to the active business
/// on the server.
abstract class ExpenseRepository {
  Future<ExpensePage> getExpenses({
    String? search,
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int pageSize = 100,
  });

  Future<ExpenseEntity> getExpense(int id);

  Future<ExpenseEntity> createExpense({
    required String category,
    required int amount,
    DateTime? expenseDate,
    String? description,
    String? paymentMethod,
    String? reference,
    String? notes,
  });

  Future<ExpenseEntity> updateExpense(
    int id, {
    required String category,
    required int amount,
    DateTime? expenseDate,
    String? description,
    String? paymentMethod,
    String? reference,
    String? notes,
  });

  Future<void> deleteExpense(int id);
}
