import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/reminder_entity.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../datasources/reminder_remote_datasource.dart';

/// ReminderRepository backed by the Khata API.
class ReminderRepositoryImpl implements ReminderRepository {
  ReminderRepositoryImpl(this._remote);

  final ReminderRemoteDatasource _remote;

  @override
  Future<List<ReminderEntity>> getReminders({ReminderStatus? status}) async {
    final payload = await _remote.list(status: status?.apiValue);
    final rows = (payload['data'] as List<dynamic>?) ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(_fromJson)
        .toList(growable: false);
  }

  @override
  Future<ReminderEntity> getReminder(int id) async =>
      _fromJson(await _remote.getById(id));

  @override
  Future<ReminderEntity> createReminder({
    required String title,
    required DateTime dueAt,
    String? notes,
    ReminderRepeat repeat = ReminderRepeat.none,
    String? relatedEntityType,
    int? relatedEntityId,
  }) async {
    final payload = await _remote.create({
      'title': title,
      'notes': notes,
      'dueAt': formatLocal(dueAt),
      'repeat': repeat.apiValue,
      if (relatedEntityType != null) 'relatedEntityType': relatedEntityType,
      if (relatedEntityId != null) 'relatedEntityId': relatedEntityId,
    });
    return _fromJson(payload);
  }

  @override
  Future<ReminderEntity> updateReminder(
    int id, {
    required String title,
    required DateTime dueAt,
    String? notes,
    ReminderRepeat repeat = ReminderRepeat.none,
  }) async {
    final payload = await _remote.update(id, {
      'title': title,
      'notes': notes,
      'dueAt': formatLocal(dueAt),
      'repeat': repeat.apiValue,
    });
    return _fromJson(payload);
  }

  @override
  Future<void> completeReminder(int id) => _remote.complete(id);

  @override
  Future<void> dismissReminder(int id) => _remote.dismiss(id);

  @override
  Future<void> deleteReminder(int id) => _remote.delete(id);

  @override
  Future<int> processDue() => _remote.processDue();

  /// Sends a Nepal-local wall-clock string with no offset, which is the form
  /// the API reads as local time. `toIso8601String()` on a local DateTime
  /// would be close but carries microseconds the API ignores; trimming is
  /// deliberate so the wire format stays stable.
  static String formatLocal(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)}'
        'T${two(value.hour)}:${two(value.minute)}:00';
  }

  static ReminderEntity _fromJson(Map<String, dynamic> json) => ReminderEntity(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        notes: json['notes'] as String?,
        dueAt:
            DateTime.tryParse(json['dueAt'] as String? ?? '') ?? DateTime.now(),
        status: ReminderStatus.fromApi(json['status'] as String?),
        repeat: ReminderRepeat.fromApi(json['repeat'] as String?),
        relatedEntityType: json['relatedEntityType'] as String?,
        relatedEntityId: (json['relatedEntityId'] as num?)?.toInt(),
        userId: (json['userId'] as num?)?.toInt(),
        completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
      );
}

/// Provider for the reminder repository.
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepositoryImpl(ref.read(reminderRemoteDatasourceProvider));
});
