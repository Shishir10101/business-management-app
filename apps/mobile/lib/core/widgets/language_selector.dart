import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/locale_provider.dart';

/// The three languages as tappable chips, applying instantly.
///
/// This is the control that belongs on the very first screen: a shopkeeper who
/// reads Nepali should not have to sign in, find Profile and scroll to a
/// dropdown before the app speaks their language.
class LanguageChips extends ConsumerWidget {
  /// Tighter padding for use inside a form or a sheet.
  final bool compact;

  const LanguageChips({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final locale in appLocales)
          ChoiceChip(
            label: Text(
              localeLabel(locale),
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: locale.languageCode == current.languageCode
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            selected: locale.languageCode == current.languageCode,
            showCheckmark: false,
            selectedColor: theme.colorScheme.primary,
            backgroundColor: theme.cardTheme.color,
            side: BorderSide(color: theme.dividerTheme.color ?? Colors.grey),
            visualDensity:
                compact ? VisualDensity.compact : VisualDensity.standard,
            onSelected: (_) =>
                ref.read(localeProvider.notifier).setLocale(locale),
          ),
      ],
    );
  }
}

/// Compact language switcher for an app bar (login, register).
///
/// A menu rather than chips: the sign-in screen is already dense, and the
/// current language is visible on the button itself.
class LanguageMenuButton extends ConsumerWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final theme = Theme.of(context);
    // Inherit rather than read `appBarTheme`: this button also sits on the
    // welcome and login screens, which have no app bar — there the app bar
    // foreground is white and the label vanished into the paper background.
    final color = IconTheme.of(context).color ?? theme.colorScheme.onSurface;

    return PopupMenuButton<Locale>(
      tooltip: localeLabel(current),
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.translate, size: 20),
          const SizedBox(width: 4),
          Text(
            current.languageCode.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
      onSelected: (locale) =>
          ref.read(localeProvider.notifier).setLocale(locale),
      itemBuilder: (context) => [
        for (final locale in appLocales)
          PopupMenuItem(
            value: locale,
            child: Row(
              children: [
                Icon(
                  locale.languageCode == current.languageCode
                      ? Icons.check
                      : Icons.check_box_outline_blank,
                  size: 18,
                  color: locale.languageCode == current.languageCode
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Text(localeLabel(locale)),
              ],
            ),
          ),
      ],
    );
  }
}
