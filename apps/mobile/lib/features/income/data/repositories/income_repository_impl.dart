import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/income_entity.dart';
import '../../domain/repositories/income_repository.dart';
import '../datasources/income_remote_datasource.dart';

/// Implementation of IncomeRepository against the Khata API.
class IncomeRepositoryImpl implements IncomeRepository {
  final IncomeRemoteDatasource _remote;

  IncomeRepositoryImpl(this._remote);

  @override
  Future<IncomePage> getIncome({
    String? search,
    String? source,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int pageSize = 100,
  }) async {
    final json = await _remote.getIncome(
      search: search,
      source: source,
      dateFrom: dateFrom,
      dateTo: dateTo,
      page: page,
      pageSize: pageSize,
    );
    return _pageFromJson(json);
  }

  @override
  Future<IncomeEntity> getIncomeEntry(int id) async {
    final json = await _remote.getIncomeEntry(id);
    return _incomeFromJson(json);
  }

  @override
  Future<IncomeEntity> createIncome({
    required String source,
    required int amount,
    DateTime? incomeDate,
    String? description,
    String? paymentMethod,
    String? reference,
    String? notes,
  }) async {
    final json = await _remote.createIncome(
      source: source,
      amount: amount,
      incomeDate: incomeDate,
      description: description,
      paymentMethod: paymentMethod,
      reference: reference,
      notes: notes,
    );
    return _incomeFromJson(json);
  }

  @override
  Future<IncomeEntity> updateIncome(
    int id, {
    required String source,
    required int amount,
    DateTime? incomeDate,
    String? description,
    String? paymentMethod,
    String? reference,
    String? notes,
  }) async {
    final json = await _remote.updateIncome(
      id,
      source: source,
      amount: amount,
      incomeDate: incomeDate,
      description: description,
      paymentMethod: paymentMethod,
      reference: reference,
      notes: notes,
    );
    return _incomeFromJson(json);
  }

  @override
  Future<void> deleteIncome(int id) => _remote.deleteIncome(id);

  // --- mapping ---

  IncomePage _pageFromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>)
        .map((e) => _incomeFromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>?;
    return IncomePage(
      data: data,
      page: pagination?['page'] as int? ?? 1,
      pageSize: pagination?['pageSize'] as int? ?? 20,
      totalItems: pagination?['totalItems'] as int? ?? data.length,
      totalPages: pagination?['totalPages'] as int? ?? 1,
      hasNext: pagination?['hasNext'] as bool? ?? false,
      hasPrev: pagination?['hasPrev'] as bool? ?? false,
    );
  }

  IncomeEntity _incomeFromJson(Map<String, dynamic> m) {
    return IncomeEntity(
      id: m['id'] as int,
      source: m['source'] as String? ?? '',
      amount: m['amount'] as int? ?? 0,
      incomeDate:
          DateTime.tryParse(m['incomeDate'] as String? ?? '') ?? DateTime.now(),
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

/// Provider for the income repository implementation.
final incomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  return IncomeRepositoryImpl(ref.read(incomeRemoteDatasourceProvider));
});
