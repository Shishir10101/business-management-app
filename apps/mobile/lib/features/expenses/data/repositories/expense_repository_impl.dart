import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_remote_datasource.dart';

/// Implementation of ExpenseRepository against the Khata API.
class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDatasource _remote;

  ExpenseRepositoryImpl(this._remote);

  @override
  Future<ExpensePage> getExpenses({
    String? search,
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int pageSize = 100,
  }) async {
    final json = await _remote.getExpenses(
      search: search,
      category: category,
      dateFrom: dateFrom,
      dateTo: dateTo,
      page: page,
      pageSize: pageSize,
    );
    return _pageFromJson(json);
  }

  @override
  Future<ExpenseEntity> getExpense(int id) async {
    final json = await _remote.getExpense(id);
    return _expenseFromJson(json);
  }

  @override
  Future<ExpenseEntity> createExpense({
    required String category,
    required int amount,
    DateTime? expenseDate,
    String? description,
    String? paymentMethod,
    String? reference,
    String? notes,
  }) async {
    final json = await _remote.createExpense(
      category: category,
      amount: amount,
      expenseDate: expenseDate,
      description: description,
      paymentMethod: paymentMethod,
      reference: reference,
      notes: notes,
    );
    return _expenseFromJson(json);
  }

  @override
  Future<ExpenseEntity> updateExpense(
    int id, {
    required String category,
    required int amount,
    DateTime? expenseDate,
    String? description,
    String? paymentMethod,
    String? reference,
    String? notes,
  }) async {
    final json = await _remote.updateExpense(
      id,
      category: category,
      amount: amount,
      expenseDate: expenseDate,
      description: description,
      paymentMethod: paymentMethod,
      reference: reference,
      notes: notes,
    );
    return _expenseFromJson(json);
  }

  @override
  Future<void> deleteExpense(int id) => _remote.deleteExpense(id);

  // --- mapping ---

  ExpensePage _pageFromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>)
        .map((e) => _expenseFromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>?;
    return ExpensePage(
      data: data,
      page: pagination?['page'] as int? ?? 1,
      pageSize: pagination?['pageSize'] as int? ?? 20,
      totalItems: pagination?['totalItems'] as int? ?? data.length,
      totalPages: pagination?['totalPages'] as int? ?? 1,
      hasNext: pagination?['hasNext'] as bool? ?? false,
      hasPrev: pagination?['hasPrev'] as bool? ?? false,
    );
  }

  ExpenseEntity _expenseFromJson(Map<String, dynamic> m) {
    return ExpenseEntity(
      id: m['id'] as int,
      category: m['category'] as String? ?? '',
      amount: m['amount'] as int? ?? 0,
      expenseDate: DateTime.tryParse(m['expenseDate'] as String? ?? '') ??
          DateTime.now(),
      description: m['description'] as String?,
      paymentMethod: m['paymentMethod'] as String?,
      reference: m['reference'] as String?,
      notes: m['notes'] as String?,
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(m['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Provider for the expense repository implementation.
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl(ref.read(expenseRemoteDatasourceProvider));
});
