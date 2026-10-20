import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/calendar_provider.dart';
import '../l10n/locale_provider.dart';
import '../utils/nepali_date_utils.dart';
import 'bs_date_picker.dart';

/// Opens the picker that matches the user's calendar choice.
///
/// Both pickers return an AD [DateTime] — the app's canonical wire format — so
/// callers never branch on the calendar. BS opens the real BS picker (year,
/// month, day chosen in Bikram Sambat); AD opens Material's picker, localized
/// to the active language.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required CalendarSystem calendar,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
  bool nepaliDigits = false,
}) {
  if (calendar == CalendarSystem.bs) {
    return showBsDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title,
      nepaliDigits: nepaliDigits,
    );
  }
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate ?? DateTime(2000),
    lastDate: lastDate ?? DateTime(2100),
    helpText: title,
  );
}

/// Range variant of [showAppDatePicker] (report windows).
Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  required CalendarSystem calendar,
  required DateTime initialFrom,
  required DateTime initialTo,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
}) {
  if (calendar == CalendarSystem.bs) {
    return showBsDateRangePicker(
      context: context,
      initialFrom: initialFrom,
      initialTo: initialTo,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title,
    );
  }
  return showDateRangePicker(
    context: context,
    firstDate: firstDate ?? DateTime(2000),
    lastDate: lastDate ?? DateTime(2100),
    initialDateRange: DateTimeRange(start: initialFrom, end: initialTo),
    helpText: title,
  );
}

/// A date input that follows the AD/BS preference.
///
/// Shows the chosen calendar as the value and the other one underneath, so a
/// shopkeeper who thinks in BS and an accountant who files in AD can read the
/// same screen. Tapping opens the matching picker; [clearable] adds an "x" for
/// optional dates (invoice due date, quotation validity).
class AppDateField extends ConsumerWidget {
  const AppDateField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.clearable = false,
    this.placeholder,
    this.helperText,
  });

  /// The selected AD date, or null when the field is optional and empty.
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;

  /// Show an "x" that clears the value (only meaningful when optional).
  final bool clearable;

  /// Text shown when [value] is null, e.g. "Not set".
  final String? placeholder;
  final String? helperText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final calendar = ref.watch(calendarProvider);
    final nepali = ref.watch(localeProvider).languageCode == 'ne';
    final current = value;
    final primary = current == null
        ? (placeholder ?? '')
        : formatDisplayDate(current, nepaliDigits: nepali);
    final secondary =
        current == null ? '' : formatOtherDate(current, nepaliDigits: nepali);

    return InkWell(
      onTap: enabled ? () => _pick(context, ref, calendar, nepali) : null,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          enabled: enabled,
          helperText: helperText,
          helperMaxLines: 2,
          suffixIcon: current != null && clearable && enabled
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(primary, style: theme.textTheme.bodyLarge),
            if (secondary.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                secondary,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    CalendarSystem calendar,
    bool nepali,
  ) async {
    final picked = await showAppDatePicker(
      context: context,
      calendar: calendar,
      initialDate: value ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: lastDate,
      title: label,
      nepaliDigits: nepali,
    );
    if (picked != null) onChanged(picked);
  }
}
