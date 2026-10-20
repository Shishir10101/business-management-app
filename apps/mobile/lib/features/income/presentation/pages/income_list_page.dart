import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/nepali_date_utils.dart';
import '../../domain/entities/income_entity.dart';
import '../providers/income_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/router/nav.dart';

/// Income list: search and a link to each income record's edit form.
class IncomeListPage extends ConsumerWidget {
  const IncomeListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final incomeAsync = ref.watch(incomeListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.income)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchIncome,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (value) =>
                  ref.read(incomeSearchProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: incomeAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 12),
                      Text(l10n.couldNotLoadX(l10n.income, '$error'),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => refreshIncome(ref),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.savings_outlined, size: 48),
                          SizedBox(height: 12),
                          Text(l10n.noIncome),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => refreshIncome(ref),
                  child: ListView.builder(
                    // Clear of the extended FAB, which otherwise covers the last row.
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: entries.length,
                    itemBuilder: (context, index) =>
                        _IncomeTile(income: entries[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openRoute(context, '/income/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.addIncome),
      ),
    );
  }
}

class _IncomeTile extends StatelessWidget {
  final IncomeEntity income;

  const _IncomeTile({required this.income});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = income.description?.isNotEmpty == true
        ? '${income.description}  •  ${_date(income.incomeDate)}'
        : _date(income.incomeDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade700.withOpacity(0.12),
          child: Icon(
            Icons.savings_outlined,
            size: 18,
            color: Colors.green.shade700,
          ),
        ),
        title:
            Text(income.source, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: Text(
          formatPaisa(income.amount),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        onTap: () => openRoute(context, '/income/${income.id}/edit'),
      ),
    );
  }

  static String _date(DateTime d) =>
      formatDisplayDate(d);
}
