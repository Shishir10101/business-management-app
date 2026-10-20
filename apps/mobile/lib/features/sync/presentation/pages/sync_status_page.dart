import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/sync_entities.dart';
import '../providers/sync_providers.dart';
import '../../data/repositories/sync_repository_impl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/l10n/localized_format.dart';
import '../../../../core/offline/offline_providers.dart';
import '../../../../core/widgets/khata_snackbars.dart';

/// Sync status page: last-sync time, pending queue, a manual "Sync now"
/// trigger, and the conflicts / rejected operations surfaced by syncs.
///
/// Reach it with `context.go('/sync')` (e.g. from the offline banner's
/// conflicts chip).
class SyncStatusPage extends ConsumerStatefulWidget {
  const SyncStatusPage({super.key});

  @override
  ConsumerState<SyncStatusPage> createState() => _SyncStatusPageState();
}

class _SyncStatusPageState extends ConsumerState<SyncStatusPage> {
  @override
  void initState() {
    super.initState();
    // Bootstrap persisted state; the sync itself starts as soon as build
    // watches syncNowProvider.
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(syncRepositoryProvider);
    final at = await repo.lastSyncAt();
    final queued = await repo.queuedOperations();
    final conflicts = await repo.persistedConflicts();
    if (!mounted) return;
    if (ref.read(lastSyncAtProvider) == null && at != null) {
      ref.read(lastSyncAtProvider.notifier).state = at;
    }
    ref.read(pendingCountProvider.notifier).state = queued.length;
    if (conflicts.isNotEmpty) {
      final existing = ref.read(conflictsProvider);
      final known = {...existing.map((c) => '${c.entityType}:${c.entityId}')};
      ref.read(conflictsProvider.notifier).state = [
        ...existing,
        ...conflicts.where(
          (c) => !known.contains('${c.entityType}:${c.entityId}'),
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final theme = Theme.of(context);
    final syncState = ref.watch(syncNowProvider);
    final isSyncing = ref.watch(isSyncingProvider);
    final lastSyncAt = ref.watch(lastSyncAtProvider);
    final pending = ref.watch(pendingCountProvider);
    final conflicts = ref.watch(conflictsProvider);
    final failedQueue = ref.watch(failedQueueProvider);

    final outcome = syncState.valueOrNull;
    final rejections = outcome?.rejections ?? const <SyncRejection>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncStatusTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isSyncing)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(Icons.cloud_done,
                            color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(l10n.syncStatusTitle, style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StatusLine(
                    icon: Icons.schedule,
                    label: l10n.lastSyncLabel,
                    value: lastSyncAt == null
                        ? l10n.never
                        : _formatDateTime(lastSyncAt),
                  ),
                  _StatusLine(
                    icon: Icons.upload_file,
                    label: l10n.pendingChanges,
                    value: '$pending',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: isSyncing ? null : () => refreshSync(ref),
            icon: const Icon(Icons.sync),
            label: Text(isSyncing ? l10n.syncing : l10n.syncNow),
          ),
          const SizedBox(height: 16),
          const _OfflineDataCard(),
          const SizedBox(height: 16),
          syncState.when(
            data: (o) => _OutcomeCard(outcome: o),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: theme.colorScheme.onErrorContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.syncFailed('$error'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => refreshSync(ref),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (conflicts.isNotEmpty) ...[
            _SectionHeader(l10n.conflictsNamed(conflicts.length)),
            for (final conflict in conflicts) _ConflictTile(conflict: conflict),
          ],
          if (rejections.isNotEmpty ||
              (failedQueue.valueOrNull?.isNotEmpty ?? false)) ...[
            _SectionHeader(l10n.rejectedAndFailed),
            for (final rejection in rejections)
              _RejectionTile(rejection: rejection),
            for (final op
                in failedQueue.valueOrNull ?? const <QueuedOperation>[])
              _FailedOperationTile(operation: op),
          ],
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(title, style: theme.textTheme.titleMedium),
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.outcome});

  final SyncOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.lastCycle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CountChip(label: l10n.pushed, value: outcome.pushed),
                _CountChip(label: l10n.pulled, value: outcome.pulled),
                _CountChip(
                  label: l10n.conflicts,
                  value: outcome.conflicts,
                  warning: outcome.conflicts > 0,
                ),
                _CountChip(
                  label: l10n.rejected,
                  value: outcome.rejected,
                  warning: outcome.rejected > 0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.value,
    this.warning = false,
  });

  final String label;
  final int value;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Text(context.count(value), style: theme.textTheme.titleSmall),
      label: Text(label),
      backgroundColor: warning
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.surfaceVariant,
    );
  }
}

class _ConflictTile extends StatelessWidget {
  const _ConflictTile({required this.conflict});

  final SyncConflict conflict;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final theme = Theme.of(context);
    final server = conflict.serverVersion;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.errorContainer,
          child: const Icon(Icons.warning_amber, size: 18),
        ),
        title: Text(l10n.entityRef(conflict.entityType, int.tryParse(conflict.entityId) ?? 0)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.operationDetail(conflict.operation)),
            if (conflict.serverChangedAt != null)
              Text('${l10n.serverChanged}'
                  '${_formatDateTime(conflict.serverChangedAt!)}'),
            if (server != null)
              Text(
                l10n.serverVersion(jsonEncode(server)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            if (conflict.message != null)
              Text(conflict.message!, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _RejectionTile extends StatelessWidget {
  const _RejectionTile({required this.rejection});

  final SyncRejection rejection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.block, size: 18)),
        title: Text(l10n.entityRef(rejection.entityType, int.tryParse(rejection.entityId) ?? 0)),
        subtitle: Text(
          'rejected${rejection.error != null ? ': ${rejection.error}' : ''}',
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _FailedOperationTile extends StatelessWidget {
  const _FailedOperationTile({required this.operation});

  final QueuedOperation operation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.sync_problem, size: 18)),
        title: Text(l10n.entityRef(operation.entityType, int.tryParse(operation.entityId) ?? 0)),
        subtitle: Text(
          l10n.operationFailed(operation.operation) + ' '
          '(attempt ${operation.attempts}): ${operation.lastError ?? 'unknown error'}',
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
      '${two(dt.hour)}:${two(dt.minute)}';
}

/// What is saved on the device for offline reading, with a way to drop it.
///
/// The saved lists are a convenience cache, not synced data: clearing them
/// loses nothing (they are downloaded again on the next visit) and is the only
/// way to remove a previous session's data from a shared phone.
class _OfflineDataCard extends ConsumerWidget {
  const _OfflineDataCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stats = ref.watch(snapshotStatsProvider).valueOrNull;
    final lists = stats?.lists ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.offline_pin_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.offlineDataTitle, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.offlineDataExplainer),
            const SizedBox(height: 12),
            _StatusLine(
              icon: Icons.storage_outlined,
              label: l10n.offlineDataSavedLabel,
              value: lists == 0
                  ? l10n.never
                  : l10n.offlineDataSavedCount(lists, _size(stats!.bytes)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed:
                    lists == 0 ? null : () => _clearSavedData(context, ref),
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.offlineDataClear),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearSavedData(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.offlineDataClear),
        content: Text(l10n.offlineDataClearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.offlineDataClear),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    await clearSnapshotCache(ref);
    if (context.mounted) showInfoSnackBar(context, l10n.offlineDataCleared);
  }

  /// KB is a unit, not prose — no translation needed.
  String _size(int bytes) => '${(bytes / 1024).ceil()} KB';
}
