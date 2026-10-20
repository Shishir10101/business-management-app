import 'package:flutter/material.dart';

import '../../../../core/utils/format_utils.dart';
import '../../domain/entities/report_entities.dart';
import '../../../../l10n/app_localizations.dart';

/// Shared palette for report charts (pie/bar slices), cycled by index.
const reportChartColors = <Color>[
  Color(0xFF1565C0),
  Color(0xFF2E7D32),
  Color(0xFFEF6C00),
  Color(0xFF6A1B9A),
  Color(0xFF00838F),
  Color(0xFFC62828),
  Color(0xFF4527A0),
  Color(0xFF558B2F),
];

/// Colour for the [index]-th chart slice, wrapping around the palette.
Color reportColorAt(int index) =>
    reportChartColors[index % reportChartColors.length];

/// A padded card used for every block on a report page.
class ReportCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;

  const ReportCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

/// A left-aligned heading above a report block.
class ReportSectionTitle extends StatelessWidget {
  final String title;

  const ReportSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

/// A muted single line shown when a report block has no data.
class ReportEmptyLine extends StatelessWidget {
  final String message;

  const ReportEmptyLine({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

/// Full-screen error state with a Retry button, shared by every report page.
class ReportErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ReportErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}

/// One figure in a [ReportTotalsGrid].
class ReportTotal {
  final String label;
  final String value;

  const ReportTotal(this.label, this.value);
}

/// A two-column grid of headline figures.
class ReportTotalsGrid extends StatelessWidget {
  final List<ReportTotal> totals;

  const ReportTotalsGrid({super.key, required this.totals});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final total in totals)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      total.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      total.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A ranked top-item row (top product / customer / supplier).
class ReportRankedTile extends StatelessWidget {
  final int rank;
  final TopItemEntity item;

  const ReportRankedTile({super.key, required this.rank, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
          child: Text(
            '$rank',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        title: Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${formatQuantity(item.quantity)} units · ${item.count} docs',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          formatPaisa(item.amount),
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
