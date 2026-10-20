import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/offline/offline_providers.dart';
import '../../../../core/offline/offline_queue.dart';
import '../../domain/entities/income_entity.dart';

/// Remote data source for the income API.
///
/// Writes go through an [OfflineQueue], so income entered without a connection
/// is kept and pushed on the next sync.
class IncomeRemoteDatasource {
  final Dio _dio;
  final OfflineQueue _queue;

  IncomeRemoteDatasource(this._dio, {OfflineQueue? queue})
      : _queue = queue ?? OfflineQueue.disabled();

  Future<Map<String, dynamic>> getIncome({
    String? search,
    String? source,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int pageSize = 100,
  }) async {
    final response = await _dio.get('/incomes', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (source != null && source.isNotEmpty) 'source': source,
      if (dateFrom != null) 'dateFrom': _date(dateFrom),
      if (dateTo != null) 'dateTo': _date(dateTo),
      'page': page,
      'pageSize': pageSize,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getIncomeEntry(int id) async {
    final response = await _dio.get('/incomes/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createIncome({
    required String source,
    required int amount,
    DateTime? incomeDate,
    String? description,
    String? paymentMethod,
    String? reference,
    String? notes,
  }) async {
    final body = _incomeBody(
      source: source,
      amount: amount,
      incomeDate: incomeDate,
      description: description,
      paymentMethod: paymentMethod,
      reference: reference,
      notes: notes,
    );
    final result = await _queue.create(
      entityType: 'income',
      body: body,
      send: () async =>
          (await _dio.post('/incomes', data: body)).data as Map<String, dynamic>,
    );
    return result.value!;
  }

  Future<Map<String, dynamic>> updateIncome(
    int id, {
    required String source,
    required int amount,
    DateTime? incomeDate,
    String? description,
    String? paymentMethod,
    String? reference,
    String? notes,
  }) async {
    final body = _incomeBody(
      source: source,
      amount: amount,
      incomeDate: incomeDate,
      description: description,
      paymentMethod: paymentMethod,
      reference: reference,
      notes: notes,
    );
    final result = await _queue.update(
      entityType: 'income',
      entityId: id,
      body: body,
      send: () async =>
          (await _dio.put('/incomes/$id', data: body)).data as Map<String, dynamic>,
    );
    return result.value!;
  }

  Future<void> deleteIncome(int id) async {
    await _queue.remove(
      entityType: 'income',
      entityId: id,
      send: () async {
        await _dio.delete('/incomes/$id');
      },
    );
  }

  static Map<String, dynamic> _incomeBody({
    required String source,
    required int amount,
    DateTime? incomeDate,
    String? description,
    String? paymentMethod,
    String? reference,
    String? notes,
  }) {
    return {
      'source': source,
      'amount': amount,
      if (incomeDate != null) 'incomeDate': _date(incomeDate),
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

/// Provider for the income remote data source.
final incomeRemoteDatasourceProvider = Provider<IncomeRemoteDatasource>((ref) {
  return IncomeRemoteDatasource(
    ref.read(dioProvider),
    queue: ref.read(offlineQueueProvider),
  );
});
