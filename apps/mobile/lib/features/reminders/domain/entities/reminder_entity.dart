/// Reminder domain entities. Pure Dart, no serialization.
///
/// The two `label(l10n)` helpers take AppLocalizations because an enum
/// cannot reach a BuildContext; call sites pass their page's instance.
library;

import '../../../../l10n/app_localizations.dart';

/// Where a reminder stands. The server sends these as strings.
enum ReminderStatus {
  pending,
  done,
  dismissed;

  static ReminderStatus fromApi(String? value) =>
      switch (value?.toLowerCase()) {
        'done' => ReminderStatus.done,
        'dismissed' => ReminderStatus.dismissed,
        _ => ReminderStatus.pending,
      };

  String get apiValue => switch (this) {
        ReminderStatus.pending => 'Pending',
        ReminderStatus.done => 'Done',
        ReminderStatus.dismissed => 'Dismissed',
      };

  String label(AppLocalizations l10n) => switch (this) {
        ReminderStatus.pending => l10n.reminderStatusPending,
        ReminderStatus.done => l10n.reminderStatusDone,
        ReminderStatus.dismissed => l10n.reminderStatusDismissed,
      };
}

/// How often a reminder comes back. `none` is a one-shot to-do.
enum ReminderRepeat {
  none,
  daily,
  weekly,
  monthly,
  yearly;

  static ReminderRepeat fromApi(String? value) =>
      switch (value?.toLowerCase()) {
        'daily' => ReminderRepeat.daily,
        'weekly' => ReminderRepeat.weekly,
        'monthly' => ReminderRepeat.monthly,
        'yearly' => ReminderRepeat.yearly,
        _ => ReminderRepeat.none,
      };

  String get apiValue => switch (this) {
        ReminderRepeat.none => 'None',
        ReminderRepeat.daily => 'Daily',
        ReminderRepeat.weekly => 'Weekly',
        ReminderRepeat.monthly => 'Monthly',
        ReminderRepeat.yearly => 'Yearly',
      };

  String label(AppLocalizations l10n) => switch (this) {
        ReminderRepeat.none => l10n.repeatOnce,
        ReminderRepeat.daily => l10n.repeatDaily,
        ReminderRepeat.weekly => l10n.repeatWeekly,
        ReminderRepeat.monthly => l10n.repeatMonthly,
        ReminderRepeat.yearly => l10n.repeatYearly,
      };
}

/// A dated to-do. `dueAt` is Nepal local wall-clock time, as the API answers.
class ReminderEntity {
  final int id;
  final String title;
  final String? notes;
  final DateTime dueAt;
  final ReminderStatus status;
  final ReminderRepeat repeat;
  final String? relatedEntityType;
  final int? relatedEntityId;
  final int? userId;
  final DateTime? completedAt;

  const ReminderEntity({
    required this.id,
    required this.title,
    this.notes,
    required this.dueAt,
    this.status = ReminderStatus.pending,
    this.repeat = ReminderRepeat.none,
    this.relatedEntityType,
    this.relatedEntityId,
    this.userId,
    this.completedAt,
  });

  /// Overdue = still pending and the due moment has passed.
  bool get isOverdue =>
      status == ReminderStatus.pending && dueAt.isBefore(DateTime.now());

  /// Due today (local date), regardless of clock time.
  bool get isDueToday {
    final now = DateTime.now();
    return status == ReminderStatus.pending &&
        dueAt.year == now.year &&
        dueAt.month == now.month &&
        dueAt.day == now.day;
  }

  bool get isRecurring => repeat != ReminderRepeat.none;
}
