import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/nepali_date_utils.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/expense_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/router/nav.dart';

/// Expenses list: search and a link to each expense's edit form.
class ExpenseListPage extends ConsumerWidget {
  const ExpenseListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final expensesAsync = ref.watch(expenseListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.expenses)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchExpenses,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (value) =>
                  ref.read(expenseSearchProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 12),
                      Text(l10n.couldNotLoadX(l10n.expenses, '$error'),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => refreshExpenses(ref),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_outlined, size: 48),
                          SizedBox(height: 12),
                          Text(l10n.noExpenses),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => refreshExpenses(ref),
                  child: ListView.builder(
                    // Clear of the extended FAB, which otherwise covers the last row.
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) =>
                        _ExpenseTile(expense: expenses[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openRoute(context, '/expenses/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.addExpense),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final ExpenseEntity expense;

  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = expense.description?.isNotEmpty == true
        ? '${expense.description}  •  ${_date(expense.expenseDate)}'
        : _date(expense.expenseDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
          child: Icon(
            Icons.receipt_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(expense.category,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: Text(
          formatPaisa(expense.amount),
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        onTap: () => openRoute(context, '/expenses/${expense.id}/edit'),
      ),
    );
  }

  static String _date(DateTime d) =>
      formatDisplayDate(d);
}
