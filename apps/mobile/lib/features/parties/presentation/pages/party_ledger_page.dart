import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/nepali_date_utils.dart';
import '../../domain/entities/party_entity.dart';
import '../providers/party_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

/// Digital khata ledger for one party: running balance summary plus the
/// immutable transaction timeline (newest first).
class PartyLedgerPage extends ConsumerWidget {
  final PartyKind kind;
  final int partyId;

  const PartyLedgerPage({
    super.key,
    required this.kind,
    required this.partyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final ledgerAsync = ref.watch(partyLedgerProvider((kind, partyId)));
    final isCustomer = kind == PartyKind.customer;
    final partyName = isCustomer
        ? ref.watch(customerDetailProvider(partyId)).valueOrNull?.name
        : ref.watch(supplierDetailProvider(partyId)).valueOrNull?.name;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(partyName ?? (isCustomer ? 'Customer' : 'Supplier')),
            Text(
              isCustomer ? l10n.customerKhata : l10n.supplierKhata,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
      body: ledgerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(l10n.couldNotLoadX(l10n.khata, '$error'),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => refreshParties(ref),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (ledger) {
          final summary = ledger.summary;
          final closing = summary.closingBalance;
          final closingLabel = closing == 0
              ? l10n.settled
              : isCustomer
                  ? (closing > 0 ? l10n.toCollect : l10n.advance)
                  : (closing > 0 ? l10n.toPay : l10n.advance);

          return RefreshIndicator(
            onRefresh: () async => refreshParties(ref),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // --- balance summary ---
                Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.closingBalance,
                            style: theme.textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              formatPaisa(closing.abs()),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: closing == 0
                                    ? theme.colorScheme.primary
                                    : (isCustomer
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.primary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(closingLabel),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _SummaryRow(
                            label: l10n.opening,
                            value: formatPaisa(summary.openingBalance.abs())),
                        _SummaryRow(
                          label: l10n.totalDebit,
                          value: formatPaisa(summary.totalDebit),
                          help:
                              l10n.ledgerOwesYouHint,
                        ),
                        _SummaryRow(
                          label: l10n.totalCredit,
                          value: formatPaisa(summary.totalCredit),
                          help:
                              l10n.ledgerYouOweHint,
                        ),
                      ],
                    ),
                  ),
                ),
                // --- timeline ---
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child:
                      Text(l10n.transactions, style: theme.textTheme.titleSmall),
                ),
                if (ledger.transactions.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text(l10n.noTransactions)),
                  )
                else
                  ...ledger.transactions.map((txn) => _LedgerTile(
                        transaction: txn,
                        isCustomer: isCustomer,
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final String? help;

  const _SummaryRow({required this.label, required this.value, this.help});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// One row of the khata timeline: type, description/date, signed amount and
/// the running balance after it.
class _LedgerTile extends StatelessWidget {
  final LedgerTransactionEntity transaction;
  final bool isCustomer;

  const _LedgerTile({required this.transaction, required this.isCustomer});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final debit = transaction.isDebit;
    // Debit grows what they owe (still unpaid, so the warning colour); credit
    // settles it. Read from the theme extension so dark mode gets the lifted
    // green rather than a hardcoded shade that fails contrast.
    final money = context.money;
    final color = debit ? money.negative : money.positive;
    final sign = debit ? '+' : '−';
    final subtitleParts = [
      _formatDate(transaction.transactionDate),
      if (transaction.description != null &&
          transaction.description!.isNotEmpty)
        transaction.description!
      else
        transaction.referenceLabel(l10n),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(
            debit ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
            size: 18,
          ),
        ),
        title: Text(
          debit ? l10n.debit : l10n.credit,
          style: theme.textTheme.titleSmall,
        ),
        subtitle: Text(subtitleParts.join(' • ')),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$sign ${formatPaisa(transaction.amount)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              l10n.balanceShort(formatPaisa(transaction.balanceAfter.abs())),
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      formatDisplayDate(date);
}
