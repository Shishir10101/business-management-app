import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/khata_snackbars.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_providers.dart';
import '../../../../l10n/app_localizations.dart';

/// Push preferences. The in-app feed is always written regardless of these —
/// they gate push delivery only, which is why the page says so.
class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationSettings)),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(l10n.couldNotLoadX(l10n.settings, '$error'),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(notificationSettingsProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (settings) => ListView(
          children: [
            _SectionHeader(l10n.pushNotifications),
            SwitchListTile(
              title: Text(l10n.enablePush),
              subtitle: Text(l10n.enablePushSubtitle),
              value: settings.pushEnabled,
              onChanged: (value) => _save(
                ref,
                context,
                settings.copyWith(pushEnabled: value),
              ),
            ),
            const Divider(),
            const _SectionHeader('Categories'),
            ..._categoryTiles(settings, l10n).map(
              (tile) => SwitchListTile(
                title: Text(tile.title),
                subtitle: Text(tile.subtitle),
                value: tile.value,
                // Sub-toggles are meaningless while push is off.
                onChanged: settings.pushEnabled
                    ? (value) =>
                        _save(ref, context, tile.apply(settings, value))
                    : null,
              ),
            ),
            const Divider(),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                l10n.notificationsInAppNoteFull,
              ),
            ),
            const _RegisteredDevices(),
          ],
        ),
      ),
    );
  }

  static List<_CategoryTile> _categoryTiles(
          NotificationSettingsEntity settings, AppLocalizations l10n) =>
      [
        _CategoryTile(
          title: l10n.categoryReminders,
          subtitle: l10n.categoryRemindersSubtitle,
          value: settings.reminderEnabled,
          apply: (s, v) => s.copyWith(reminderEnabled: v),
        ),
        _CategoryTile(
          title: l10n.lowStockAlert,
          subtitle: l10n.categoryLowStockSubtitle,
          value: settings.lowStockEnabled,
          apply: (s, v) => s.copyWith(lowStockEnabled: v),
        ),
        _CategoryTile(
          title: l10n.categoryPaymentDue,
          subtitle: l10n.categoryPaymentDueSubtitle,
          value: settings.paymentDueEnabled,
          apply: (s, v) => s.copyWith(paymentDueEnabled: v),
        ),
        _CategoryTile(
          title: l10n.categoryBackup,
          subtitle: l10n.categoryBackupSubtitle,
          value: settings.backupEnabled,
          apply: (s, v) => s.copyWith(backupEnabled: v),
        ),
        _CategoryTile(
          title: l10n.categorySystem,
          subtitle: l10n.categorySystemSubtitle,
          value: settings.systemEnabled,
          apply: (s, v) => s.copyWith(systemEnabled: v),
        ),
      ];

  static Future<void> _save(
    WidgetRef ref,
    BuildContext context,
    NotificationSettingsEntity next,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(notificationRepositoryProvider).updateSettings(next);
      ref.invalidate(notificationSettingsProvider);
      if (context.mounted) showInfoSnackBar(context, l10n.settingsSaved);
    } catch (e) {
      if (context.mounted) showErrorSnackBar(context, '$e');
    }
  }
}

class _CategoryTile {
  final String title;
  final String subtitle;
  final bool value;
  final NotificationSettingsEntity Function(NotificationSettingsEntity, bool)
      apply;

  const _CategoryTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.apply,
  });
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

/// Read-only view of the devices that would receive a push. Registration
/// happens automatically on sign-in; this is here so the user can see it
/// worked.
class _RegisteredDevices extends ConsumerWidget {
  const _RegisteredDevices();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final devicesAsync = ref.watch(deviceListProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(l10n.registeredDevices),
        devicesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.couldNotLoadX(l10n.devices, '$error')),
          ),
          data: (devices) {
            if (devices.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(16),
                child: Text(l10n.noDevices),
              );
            }
            return Column(
              children: devices
                  .map((device) => ListTile(
                        leading: Icon(_platformIcon(device.platform)),
                        title: Text(device.platform),
                        subtitle: Text(
                          device.isActive ? 'Active' : 'Inactive',
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  static IconData _platformIcon(String platform) =>
      switch (platform.toLowerCase()) {
        'android' => Icons.android,
        'ios' => Icons.phone_iphone,
        'web' => Icons.language,
        _ => Icons.devices,
      };
}
