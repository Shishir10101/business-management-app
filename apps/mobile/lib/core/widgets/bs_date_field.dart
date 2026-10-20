import 'package:flutter/material.dart';

import '../utils/nepali_date_utils.dart';
import 'bs_date_picker.dart';

/// A date field that speaks both calendars.
///
/// Tapping opens the real BS picker ([showBsDatePicker]): the user chooses
/// year, month and day in Bikram Sambat, and the AD equivalent is what gets
/// stored — BS is a *display and input* concern, never persistence. The BS
/// equivalent is also shown live under the field so the AD value stays
/// legible to anyone working across both calendars.
///
/// [onChanged] fires only when the value really changes.
class BsDateField extends StatelessWidget {
  const BsDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Date',
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.showBs = true,
    this.nepaliDigits = false,
    this.helperText,
  });

  /// The selected AD date.
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;

  /// Show the BS equivalent under the field.
  final bool showBs;

  /// Render the BS date and its digits in Devanagari.
  final bool nepaliDigits;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bs = tryToBs(value);
    final bsText = bs == null
        ? null
        : nepaliDigits
            ? toDevanagariDigits(formatBs(value))
            : formatBs(value);
    final adNepali = nepaliDigits
        ? toDevanagariDigits(formatAd(value))
        : formatAd(value);

    return InkWell(
      onTap: enabled ? () => _pick(context) : null,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          enabled: enabled,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          helperText: helperText,
          helperMaxLines: 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(adNepali, style: theme.textTheme.bodyLarge),
            if (showBs && bsText != null) ...[
              const SizedBox(height: 2),
              Text(
                '${bsMonthName(bs!.month, nepali: nepaliDigits)} '
                '${nepaliDigits ? _devanagari(bs.day) : bs.day}, $bsText BS',
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

  Future<void> _pick(BuildContext context) async {
    final picked = await showBsDatePicker(
      context: context,
      initialDate: value,
      firstDate: firstDate,
      lastDate: lastDate,
      title: label,
      nepaliDigits: nepaliDigits,
    );
    if (picked != null && picked != value) onChanged(picked);
  }

  static String _devanagari(int n) => toDevanagariDigits(n.toString());
}

/// The BS equivalent of an AD date, as a compact chip-style label. Useful in
/// list rows where a full field would be too heavy.
class BsDateLabel extends StatelessWidget {
  const BsDateLabel({
    super.key,
    required this.date,
    this.nepaliDigits = false,
    this.showAd = false,
  });

  final DateTime date;
  final bool nepaliDigits;

  /// Also show the AD date, e.g. "2083-06-28 BS · 2026-10-15".
  final bool showAd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bs = formatBs(date);
    final bsOut = nepaliDigits ? toDevanagariDigits(bs) : bs;
    final ad = formatAd(date);
    return Text(
      showAd ? '$bsOut BS · $ad' : '$bsOut BS',
      style: theme.textTheme.bodySmall,
    );
  }
}

/// Month name helper re-exported so callers do not also import the utils
/// module just for a label.
String bsMonthLabel(int month, {bool nepali = false}) =>
    bsMonthName(month, nepali: nepali);
