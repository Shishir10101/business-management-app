import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/offline/offline_providers.dart';
import '../../../../core/offline/offline_queue.dart';
import '../../domain/entities/expense_entity.dart';

/// Remote data source for the expenses API.
///
/// Writes go through an [OfflineQueue], so an expense entered without a
/// connection is kept and pushed on the next sync.
class ExpenseRemoteDatasource {
  final Dio _dio;
  final OfflineQueue _queue;

  ExpenseRemoteDatasource(this._dio, {OfflineQueue? queue})
      : _queue = queue ?? OfflineQueue.disabled();

  Future<Map<String, dynamic>> getExpenses({
    String? search,
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int pageSize = 100,
  }) async {
    final response = await _dio.get('/expenses', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (category != null && category.isNotEmpty) 'category': category,
      if (dateFrom != null) 'dateFrom': _date(dateFrom),
      if (dateTo != null) 'dateTo': _date(dateTo),
      'page': page,
      'pageSize': pageSize,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getExpense(int id) async {
    final response = await _dio.get('/expenses/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createExpense({
    required String category,
    required int amount,
    DateTime? expenseDate,
    String? description,
    String? paymentMethod,
    String? reference,
    String? notes,
  }) async {
    final body = _expenseBody(
      category: category,
      amount: amount,
      expenseDate: expenseDate,
      description: description,
      paymentMethod: paymentMethod,
      reference: reference,
      notes: notes,
    );
    final result = await _queue.create(
      entityType: 'expense',
      body: body,
      send: () async =>
          (await _dio.post('/expenses', data: body)).data as Map<String, dynamic>,
    );
    return result.value!;
  }

  Future<Map<String, dynamic>> updateExpense(
    int id, {
    required String category,
    required int amount,
    DateTime? expenseDate,
    String? description,
    String? paymentMethod,
    String? reference,
    String? notes,
  }) async {
    final body = _expenseBody(
      category: category,
      amount: amount,
      expenseDate: expenseDate,
      description: description,
      paymentMethod: paymentMethod,
      reference: reference,
      notes: notes,
    );
    final result = await _queue.update(
      entityType: 'expense',
      entityId: id,
      body: body,
      send: () async =>
          (await _dio.put('/expenses/$id', data: body)).data as Map<String, dynamic>,
    );
    return result.value!;
  }

  Future<void> deleteExpense(int id) async {
    await _queue.remove(
      entityType: 'expense',
      entityId: id,
      send: () async {
        await _dio.delete('/expenses/$id');
      },
    );
  }

  static Map<String, dynamic> _expenseBody({
    required String category,
    required int amount,
    DateTime? expenseDate,
    String? description,
    String? paymentMethod,
    String? reference,
    String? notes,
  }) {
    return {
      'category': category,
      'amount': amount,
      if (expenseDate != null) 'expenseDate': _date(expenseDate),
      if (description != null && description.isNotEmpty)
        'description': description,
      if (paymentMethod != null && paymentMethod.isNotEmpty)
        'paymentMethod': paymentMethod,
      if (reference != null && reference.isNotEmpty) 'reference': reference,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
  }

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Provider for the expense remote data source.
final expenseRemoteDatasourceProvider =
    Provider<ExpenseRemoteDatasource>((ref) {
  return ExpenseRemoteDatasource(
    ref.read(dioProvider),
    queue: ref.read(offlineQueueProvider),
  );
});
