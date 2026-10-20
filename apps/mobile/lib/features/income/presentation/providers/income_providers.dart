import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/income_repository_impl.dart';
import '../../domain/entities/income_entity.dart';

/// Current search text for the income list.
final incomeSearchProvider = StateProvider<String>((ref) => '');

/// Income of the active business, newest first.
final incomeListProvider = FutureProvider<List<IncomeEntity>>((ref) async {
  final page = await ref.read(incomeRepositoryProvider).getIncome(
        search: ref.watch(incomeSearchProvider),
        pageSize: 100,
      );
  return page.data;
});

/// Full income record by id (edit form).
final incomeDetailProvider =
    FutureProvider.family<IncomeEntity, int>((ref, id) async {
  return ref.read(incomeRepositoryProvider).getIncomeEntry(id);
});

/// Refreshes the income list and detail providers after a mutation.
void refreshIncome(WidgetRef ref) {
  ref.invalidate(incomeListProvider);
  ref.invalidate(incomeDetailProvider);
}
