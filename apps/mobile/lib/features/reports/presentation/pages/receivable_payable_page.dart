import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/format_utils.dart';
import '../providers/report_providers.dart';
import '../../domain/entities/report_entities.dart';
import '../widgets/report_widgets.dart';
import '../../../../l10n/app_localizations.dart';

/// Receivables and payables, party by party, largest first.
class ReceivablePayablePage extends ConsumerWidget {
  const ReceivablePayablePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final report = ref.watch(receivablePayableProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.receivablesAndPayables)),
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ReportErrorView(
          message: l10n.couldNotLoadX(l10n.balances, '$error'),
          onRetry: () => refreshReports(ref),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => refreshReports(ref),
          child: ListView(
            children: [
              ReportTotalsGrid(totals: [
                ReportTotal(l10n.toCollect, formatPaisa(data.totalReceivable)),
                ReportTotal(l10n.toPay, formatPaisa(data.totalPayable)),
                ReportTotal(
                    l10n.customerAdvances, formatPaisa(data.customerAdvances)),
                ReportTotal(
                    l10n.supplierAdvances, formatPaisa(data.supplierAdvances)),
              ]),
              ReportSectionTitle(
                title: l10n.receivablesCount(data.receivables.length),
              ),
              if (data.receivables.isEmpty)
                ReportEmptyLine(message: l10n.nobodyOwesYou)
              else
                for (final party in data.receivables)
                  _PartyTile(party: party, isReceivable: true),
              ReportSectionTitle(title: l10n.payablesCount(data.payables.length)),
              if (data.payables.isEmpty)
                ReportEmptyLine(message: l10n.youOweNobody)
              else
                for (final party in data.payables)
                  _PartyTile(party: party, isReceivable: false),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Text(
                  l10n.advancesExplain,
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartyTile extends StatelessWidget {
  final OutstandingPartyEntity party;
  final bool isReceivable;

  const _PartyTile({required this.party, required this.isReceivable});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        isReceivable ? theme.colorScheme.error : Colors.green.shade700;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(
            isReceivable ? Icons.arrow_downward : Icons.arrow_upward,
            size: 18,
            color: color,
          ),
        ),
        title: Text(party.name),
        subtitle: Text(
          [
            if (party.phoneNumber != null && party.phoneNumber!.isNotEmpty)
              party.phoneNumber!,
            if (party.openDocuments > 0)
              '${party.openDocuments} open document(s)',
          ].join(' · '),
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          formatPaisa(party.balance),
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
