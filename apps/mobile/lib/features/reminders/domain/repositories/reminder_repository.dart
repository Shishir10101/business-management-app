import '../entities/reminder_entity.dart';

/// Reminders for the active business.
abstract class ReminderRepository {
  Future<List<ReminderEntity>> getReminders({ReminderStatus? status});

  Future<ReminderEntity> getReminder(int id);

  Future<ReminderEntity> createReminder({
    required String title,
    required DateTime dueAt,
    String? notes,
    ReminderRepeat repeat = ReminderRepeat.none,
    String? relatedEntityType,
    int? relatedEntityId,
  });

  Future<ReminderEntity> updateReminder(
    int id, {
    required String title,
    required DateTime dueAt,
    String? notes,
    ReminderRepeat repeat = ReminderRepeat.none,
  });

  Future<void> completeReminder(int id);
  Future<void> dismissReminder(int id);
  Future<void> deleteReminder(int id);

  /// Asks the server to fire everything now due. Returns how many fired.
  Future<int> processDue();
}
