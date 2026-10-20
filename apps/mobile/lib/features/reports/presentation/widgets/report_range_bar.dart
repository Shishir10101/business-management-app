import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/l10n/calendar_provider.dart';
import '../../../../core/utils/nepali_date_utils.dart';
import '../../../../core/utils/scratch_files.dart';
import '../../../../core/widgets/app_date_field.dart';
import '../../../../core/widgets/khata_snackbars.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../domain/entities/report_entities.dart';
import '../providers/report_providers.dart';
import '../../../../l10n/app_localizations.dart';

/// A reusable range selector for report pages: shows the selected window in AD
/// and its BS equivalent, opens a date-range picker, and offers Day/Week/Month
/// grouping chips (hidden with `showGrouping: false`).
class ReportRangeBar extends ConsumerWidget {
  final bool showGrouping;

  const ReportRangeBar({super.key, this.showGrouping = true});

  static const _groups = <String>['day', 'week', 'month'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final range = ref.watch(reportRangeProvider);
    final groupBy = ref.watch(reportGroupByProvider);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.date_range_outlined,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${formatDisplayDate(range.from)}  →  '
                        '${formatDisplayDate(range.to)}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${formatOtherDate(range.from)}  →  '
                        '${formatOtherDate(range.to)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _pickRange(context, ref, range),
                  icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                  label: Text(l10n.change),
                ),
              ],
            ),
            if (showGrouping) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  for (final group in _groups)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_groupLabel(group, l10n)),
                        selected: groupBy == group,
                        onSelected: (_) => ref
                            .read(reportGroupByProvider.notifier)
                            .state = group,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickRange(
    BuildContext context,
    WidgetRef ref,
    ReportRange current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showAppDateRangePicker(
      context: context,
      calendar: ref.read(calendarProvider),
      initialFrom: current.from,
      initialTo: current.to,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      title: l10n.dateRange,
    );
    if (picked == null) return;
    ref.read(reportRangeProvider.notifier).state = ReportRange(
      from: DateTime(picked.start.year, picked.start.month, picked.start.day),
      to: DateTime(picked.end.year, picked.end.month, picked.end.day),
    );
  }
}

/// Downloads a report CSV and opens the share sheet. Shared by every report
/// page; mirrors the invoice PDF download-and-share flow.
Future<void> downloadAndShareCsv(
  BuildContext context,
  WidgetRef ref, {
  required String type,
  required DateTime from,
  required DateTime to,
}) async {
  final l10n = AppLocalizations.of(context);
  try {
    final bytes = await ref.read(reportRepositoryProvider).downloadCsv(
          type: type,
          from: from,
          to: to,
        );
    final path = await writeScratchFile(
      '$type-report-${_ad(from)}_${_ad(to)}.csv',
      bytes,
    );
    if (path == null) {
      // No scratch directory on the web — say so rather than leaking the
      // raw MissingPluginException into the snackbar.
      if (context.mounted) {
        showInfoSnackBar(context, l10n.fileSaveNotSupported);
      }
      return;
    }
    try {
      await Share.shareXFiles(
        [XFile(path)],
        subject: '$type report',
        text: '$type report ${_ad(from)} to ${_ad(to)}',
      );
    } catch (_) {
      if (context.mounted) showInfoSnackBar(context, l10n.savedTo('$path'));
    }
  } catch (e) {
    if (context.mounted) showErrorSnackBar(context, '$e');
  }
}

/// AD date as "yyyy-MM-dd" (the format the API expects).
String _ad(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';


String _groupLabel(String group, AppLocalizations l10n) {
  switch (group) {
    case 'week':
      return l10n.week;
    case 'month':
      return l10n.month;
    default:
      return l10n.day;
  }
}
