import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/khata_snackbars.dart';
import '../../data/repositories/reminder_repository_impl.dart';
import '../../domain/entities/reminder_entity.dart';
import '../providers/reminder_providers.dart';
import '../../../../l10n/app_localizations.dart';

/// Reminders, split into what needs attention now and what is still ahead.
///
/// Two sections rather than one list: an overdue reminder is the whole point
/// of the feature, so it must not be buried under future ones.
class ReminderListPage extends ConsumerStatefulWidget {
  const ReminderListPage({super.key});

  @override
  ConsumerState<ReminderListPage> createState() => _ReminderListPageState();
}

class _ReminderListPageState extends ConsumerState<ReminderListPage> {
  ReminderStatus? _status = ReminderStatus.pending;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);


    final remindersAsync = ref.watch(reminderListProvider(_status));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoryReminders),
        actions: [
          PopupMenuButton<ReminderStatus?>(
            tooltip: l10n.filter,
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _status = value),
            itemBuilder: (context) => [
              PopupMenuItem(value: null, child: Text(l10n.all)),
              ...ReminderStatus.values.map(
                (s) => PopupMenuItem(value: s, child: Text(s.label(l10n))),
              ),
            ],
          ),
          IconButton(
            tooltip: l10n.checkDueReminders,
            icon: const Icon(Icons.play_circle_outline),
            onPressed: _processDue,
          ),
        ],
      ),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(l10n.couldNotLoadX(l10n.reminders, '$error'),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(reminderListProvider(_status)),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (reminders) {
          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm_off, size: 48),
                  SizedBox(height: 12),
                  Text(l10n.noReminders),
                ],
              ),
            );
          }

          final now = reminders.where(
            (r) => r.status == ReminderStatus.pending && r.isOverdue,
          );
          final ahead = reminders.where((r) => !now.contains(r));

          return RefreshIndicator(
            onRefresh: () async => refreshReminders(ref),
            child: ListView(
              // Clear of the extended FAB, which otherwise covers the last row.
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                if (now.isNotEmpty) ...[
                  _SectionHeader(l10n.needsAttention),
                  ...now.map((r) => _ReminderTile(reminder: r)),
                ],
                if (ahead.isNotEmpty) ...[
                  _SectionHeader(
                    now.isEmpty ? 'Reminders' : 'Scheduled',
                  ),
                  ...ahead.map((r) => _ReminderTile(reminder: r)),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/reminders/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.addReminder),
      ),
    );
  }

  Future<void> _processDue() async {
    final l10n = AppLocalizations.of(context);
    try {
      final fired = await ref.read(reminderRepositoryProvider).processDue();
      refreshReminders(ref);
      if (mounted) {
        showInfoSnackBar(
          context,
          fired == 0 ? l10n.nothingDue : '$fired reminder(s) fired',
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '$e');
    }
  }
}

class _ReminderTile extends ConsumerWidget {
  const _ReminderTile({required this.reminder});

  final ReminderEntity reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);


    final theme = Theme.of(context);
    final overdue = reminder.isOverdue;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: overdue
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            overdue ? Icons.alarm_on : Icons.alarm,
            size: 20,
            color: overdue ? theme.colorScheme.onErrorContainer : null,
          ),
        ),
        title: Text(
          reminder.title,
          style: overdue
              ? theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)
              : null,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminder.notes != null && reminder.notes!.isNotEmpty)
              Text(reminder.notes!),
            const SizedBox(height: 4),
            Text(
              '${_formatDue(reminder.dueAt, l10n)}'
              '${reminder.isRecurring ? ' · ${reminder.repeat.label(l10n)}' : ''}'
              '${overdue ? ' · ${l10n.overdue}' : ''}'
              '${reminder.status != ReminderStatus.pending
                  ? ' · ${reminder.status.label(l10n)}'
                  : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: overdue ? theme.colorScheme.error : null,
              ),
            ),
          ],
        ),
        isThreeLine: reminder.notes != null && reminder.notes!.isNotEmpty,
        onTap: () => context.push('/reminders/${reminder.id}/edit'),
        trailing: reminder.status == ReminderStatus.pending
            ? PopupMenuButton<String>(
                onSelected: (value) async {
                  try {
                    final repository = ref.read(reminderRepositoryProvider);
                    switch (value) {
                      case 'complete':
                        await repository.completeReminder(reminder.id);
                        if (context.mounted) {
                          showInfoSnackBar(context, l10n.markedDone);
                        }
                      case 'dismiss':
                        await repository.dismissReminder(reminder.id);
                      case 'delete':
                        await repository.deleteReminder(reminder.id);
                    }
                    refreshReminders(ref);
                  } catch (e) {
                    if (context.mounted) showErrorSnackBar(context, '$e');
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'complete', child: Text(l10n.markDone)),
                  PopupMenuItem(value: 'dismiss', child: Text(l10n.dismiss)),
                  PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                ],
              )
            : null,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      );
}

/// "Today 5:30 PM", "Tomorrow 9:00 AM", or a plain date further out.
/// Takes [l10n] explicitly: this is a top-level helper, so it has no context.
String _formatDue(DateTime value, AppLocalizations l10n) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(value.year, value.month, value.day);
  final clock = _clock(value);

  final delta = day.difference(today).inDays;
  if (delta == 0) return l10n.todayAt(clock);
  if (delta == 1) return l10n.tomorrowAt(clock);
  if (delta == -1) return l10n.yesterdayAt(clock);
  final date = '${value.year}-${_two(value.month)}-${_two(value.day)}';
  return delta < 0 ? '$date $clock' : '$date $clock';
}

String _clock(DateTime value) {
  final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final suffix = value.hour < 12 ? 'AM' : 'PM';
  return '$hour12:${_two(value.minute)} $suffix';
}

String _two(int value) => value.toString().padLeft(2, '0');
