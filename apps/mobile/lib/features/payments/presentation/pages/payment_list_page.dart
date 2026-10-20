import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/nepali_date_utils.dart';
import '../../domain/entities/payment_entity.dart';
import '../providers/payment_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/router/nav.dart';

/// Payments list: search, a receivable/payable summary, and a link to each
/// payment's direction (receipt from a customer or payment to a supplier).
class PaymentListPage extends ConsumerWidget {
  const PaymentListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final paymentsAsync = ref.watch(paymentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.payments),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: l10n.paymentMethods,
            onPressed: () => openRoute(context, '/payments/methods'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchPartyOrReference,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (value) =>
                  ref.read(paymentSearchProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: paymentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 12),
                      Text(l10n.couldNotLoadX(l10n.payments, '$error'),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => refreshPayments(ref),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (payments) {
                return RefreshIndicator(
                  onRefresh: () async => refreshPayments(ref),
                  child: ListView(
                    // Clear of the extended FAB, which otherwise covers the last row.
                    padding: const EdgeInsets.only(bottom: 88),
                    children: [
                      const _SummaryCard(),
                      if (payments.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payments_outlined, size: 48),
                              SizedBox(height: 12),
                              Text(l10n.noPayments),
                            ],
                          ),
                        )
                      else
                        for (final payment in payments)
                          _PaymentTile(payment: payment),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openRoute(context, '/payments/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.recordPayment),
      ),
    );
  }
}

/// Receivable/payable snapshot: what to collect, what to pay, and any
/// advances sitting on either side.
class _SummaryCard extends ConsumerWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final summaryAsync = ref.watch(paymentSummaryProvider);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: summaryAsync.when(
          loading: () => const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text(l10n.couldNotLoadSummary,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
          data: (summary) {
            final advances = <String>[
              if (summary.customerAdvances > 0)
                'customers ${formatPaisa(summary.customerAdvances)}',
              if (summary.supplierAdvances > 0)
                'suppliers ${formatPaisa(summary.supplierAdvances)}',
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryRow(l10n.toCollect, formatPaisa(summary.totalReceivable)),
                _SummaryRow(l10n.toPay, formatPaisa(summary.totalPayable)),
                if (advances.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      l10n.advancesLabel(advances.join('  •  ')),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentEntity payment;

  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final receipt = payment.isReceipt;
    final color = receipt ? Colors.red.shade700 : Colors.green.shade700;
    final document =
        receipt ? payment.saleInvoiceNumber : payment.purchaseBillNumber;
    final subtitle = [
      _date(payment.paymentDate),
      receipt ? l10n.receipt : 'Payment',
      if (document != null && document.isNotEmpty) document,
    ].join('  •  ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(
            receipt ? Icons.arrow_downward : Icons.arrow_upward,
            size: 18,
            color: color,
          ),
        ),
        title: Text(
          '${payment.partyName}  •  ${payment.methodName ?? ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatPaisa(payment.amount),
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (payment.unappliedAmount > 0)
              Text(
                l10n.advanceAmount(formatPaisa(payment.unappliedAmount)),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
          ],
        ),
      ),
    );
  }

  static String _date(DateTime d) =>
      formatDisplayDate(d);
}
