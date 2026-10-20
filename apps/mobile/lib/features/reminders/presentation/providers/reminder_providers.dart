import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/reminder_repository_impl.dart';
import '../../domain/entities/reminder_entity.dart';

/// Reminder list for the active business. `null` status means "all".
final reminderListProvider =
    FutureProvider.family<List<ReminderEntity>, ReminderStatus?>(
        (ref, status) async {
  return ref.read(reminderRepositoryProvider).getReminders(status: status);
});

/// Pending reminders only — what the home page needs for its due badge.
final pendingRemindersProvider =
    FutureProvider<List<ReminderEntity>>((ref) async {
  return ref.read(reminderRepositoryProvider).getReminders(
        status: ReminderStatus.pending,
      );
});

/// Pending reminders that are due now or overdue (not just upcoming).
final dueRemindersProvider = FutureProvider<List<ReminderEntity>>((ref) async {
  final pending = await ref.watch(pendingRemindersProvider.future);
  return pending.where((r) => r.isOverdue || r.isDueToday).toList()
    ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
});

/// Refreshes every reminder view after a mutation.
void refreshReminders(WidgetRef ref) {
  ref.invalidate(reminderListProvider);
  ref.invalidate(pendingRemindersProvider);
  ref.invalidate(dueRemindersProvider);
}
