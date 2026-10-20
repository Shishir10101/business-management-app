import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../offline/offline_providers.dart';

/// Slim note above a list that is showing the saved copy because the network
/// failed.
///
/// [group] is the same key the repository reports to [cachedReadProvider]
/// ('products', 'customers', 'suppliers'), so the note appears only on the
/// screen whose data actually came from disk.
class CachedDataNote extends ConsumerWidget {
  final String group;

  const CachedDataNote({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAt =
        ref.watch(cachedReadProvider.select((groups) => groups[group]));
    if (savedAt == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off,
              size: 16,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _message(context, l10n, savedAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The time is shown only for a copy saved today — an older one would need a
  /// date, and a bare time would then read as if it were fresh.
  String _message(
    BuildContext context,
    AppLocalizations l10n,
    DateTime savedAt,
  ) {
    final now = DateTime.now();
    final sameDay = savedAt.year == now.year &&
        savedAt.month == now.month &&
        savedAt.day == now.day;
    if (!sameDay) return l10n.cachedDataNote;

    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(savedAt),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return l10n.cachedDataNoteAt(time);
  }
}
