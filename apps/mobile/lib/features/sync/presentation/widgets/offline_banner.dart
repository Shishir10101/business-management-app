import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/connectivity_provider.dart';
import '../providers/sync_providers.dart';

/// Slim banner shown while the device is offline. When earlier syncs left
/// conflicts behind, a tappable chip leads to the sync status page.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final offline = ref.watch(isOfflineProvider);
    final conflicts = ref.watch(conflictsProvider);
    final pending = ref.watch(pendingCountProvider);

    return offline.when(
      data: (isOffline) {
        if (!isOffline) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context);
        final conflictCount = conflicts.length;
        final note = pending > 0
            ? '${l10n.offlineBannerNote} · ${l10n.pendingWritesCount(pending)}'
            : l10n.offlineBannerNote;
        return Material(
          color: theme.colorScheme.errorContainer,
          child: InkWell(
            onTap: () => context.go('/sync'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.cloud_off,
                      size: 18, color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  if (conflictCount > 0)
                    ActionChip(
                      avatar: const Icon(Icons.warning_amber, size: 16),
                      label: Text(l10n.conflictsCount(conflictCount)),
                      onPressed: () => context.go('/sync'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
