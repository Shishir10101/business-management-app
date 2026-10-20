import '../entities/income_entity.dart';

/// Income repository contract. All calls are scoped to the active business
/// on the server.
abstract class IncomeRepository {
  Future<IncomePage> getIncome({
    String? search,
    String? source,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int pageSize = 100,
  });

  Future<IncomeEntity> getIncomeEntry(int id);

  Future<IncomeEntity> createIncome({
    required String source,
    required int amount,
    DateTime? incomeDate,
    String? description,
    String? paymentMethod,
    String? reference,
    String? notes,
  });

  Future<IncomeEntity> updateIncome(
    int id, {
    required String source,
    required int amount,
    DateTime? incomeDate,
    String? description,
    String? paymentMethod,
    String? reference,
    String? notes,
  });

  Future<void> deleteIncome(int id);
}
