import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/entities/expense_entity.dart';

/// Current search text for the expense list.
final expenseSearchProvider = StateProvider<String>((ref) => '');

/// Expenses of the active business, newest first.
final expenseListProvider = FutureProvider<List<ExpenseEntity>>((ref) async {
  final page = await ref.read(expenseRepositoryProvider).getExpenses(
        search: ref.watch(expenseSearchProvider),
        pageSize: 100,
      );
  return page.data;
});

/// Full expense by id (edit form).
final expenseDetailProvider =
    FutureProvider.family<ExpenseEntity, int>((ref, id) async {
  return ref.read(expenseRepositoryProvider).getExpense(id);
});

/// Refreshes the expense list and detail providers after a mutation.
void refreshExpenses(WidgetRef ref) {
  ref.invalidate(expenseListProvider);
  ref.invalidate(expenseDetailProvider);
}
