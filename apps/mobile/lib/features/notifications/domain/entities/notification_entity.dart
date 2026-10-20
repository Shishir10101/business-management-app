/// Notification domain entities. Pure Dart, no serialization.
library;

import '../../../../l10n/app_localizations.dart';

/// What a notification is about. The server sends these as strings.
enum NotificationCategory {
  reminder,
  lowStock,
  paymentDue,
  backup,
  system;

  static NotificationCategory fromApi(String? value) =>
      switch (value?.toLowerCase()) {
        'reminder' => NotificationCategory.reminder,
        'lowstock' => NotificationCategory.lowStock,
        'paymentdue' => NotificationCategory.paymentDue,
        'backup' => NotificationCategory.backup,
        _ => NotificationCategory.system,
      };

  /// Matches the server enum name.
  String get apiValue => switch (this) {
        NotificationCategory.reminder => 'Reminder',
        NotificationCategory.lowStock => 'LowStock',
        NotificationCategory.paymentDue => 'PaymentDue',
        NotificationCategory.backup => 'Backup',
        NotificationCategory.system => 'System',
      };

  /// Localized display name. Takes [l10n] because an enum has no context.
  String label(AppLocalizations l10n) => switch (this) {
        NotificationCategory.reminder => l10n.categoryReminder,
        NotificationCategory.lowStock => l10n.categoryLowStock,
        NotificationCategory.paymentDue => l10n.categoryPaymentDue,
        NotificationCategory.backup => l10n.categoryBackup,
        NotificationCategory.system => l10n.categorySystem,
      };
}

/// One notification in the in-app feed.
class NotificationEntity {
  final int id;
  final String title;
  final String body;
  final NotificationCategory category;
  final String? referenceType;
  final int? referenceId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    this.referenceType,
    this.referenceId,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  NotificationEntity copyWith({
    String? title,
    String? body,
    NotificationCategory? category,
    String? referenceType,
    int? referenceId,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) =>
      NotificationEntity(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        category: category ?? this.category,
        referenceType: referenceType ?? this.referenceType,
        referenceId: referenceId ?? this.referenceId,
        isRead: isRead ?? this.isRead,
        readAt: readAt ?? this.readAt,
        createdAt: createdAt ?? this.createdAt,
      );
}

/// Per-user push preferences. The in-app feed is always written; these gate
/// only push delivery.
class NotificationSettingsEntity {
  final bool pushEnabled;
  final bool reminderEnabled;
  final bool lowStockEnabled;
  final bool paymentDueEnabled;
  final bool backupEnabled;
  final bool systemEnabled;

  const NotificationSettingsEntity({
    this.pushEnabled = true,
    this.reminderEnabled = true,
    this.lowStockEnabled = true,
    this.paymentDueEnabled = true,
    this.backupEnabled = true,
    this.systemEnabled = true,
  });

  static const allOn = NotificationSettingsEntity();

  NotificationSettingsEntity copyWith({
    bool? pushEnabled,
    bool? reminderEnabled,
    bool? lowStockEnabled,
    bool? paymentDueEnabled,
    bool? backupEnabled,
    bool? systemEnabled,
  }) =>
      NotificationSettingsEntity(
        pushEnabled: pushEnabled ?? this.pushEnabled,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        lowStockEnabled: lowStockEnabled ?? this.lowStockEnabled,
        paymentDueEnabled: paymentDueEnabled ?? this.paymentDueEnabled,
        backupEnabled: backupEnabled ?? this.backupEnabled,
        systemEnabled: systemEnabled ?? this.systemEnabled,
      );
}

/// A registered push device (FCM token).
class DeviceEntity {
  final int id;
  final String token;
  final String platform;
  final DateTime lastSeenAt;
  final bool isActive;

  const DeviceEntity({
    required this.id,
    required this.token,
    required this.platform,
    required this.lastSeenAt,
    this.isActive = true,
  });
}
