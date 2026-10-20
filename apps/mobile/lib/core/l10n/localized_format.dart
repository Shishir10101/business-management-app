import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/locale_provider.dart';
import '../utils/format_utils.dart';
import '../utils/nepali_date_utils.dart';

/// Locale-aware formatting in one place.
///
/// Pages previously called `formatPaisa(...)` and `formatAd(...)` directly.
/// Those still exist and still return the AD/Latin form, so nothing breaks.
/// These helpers sit on top and switch behaviour on the active locale, which
/// is what a page should use when it wants to respect the language setting.
extension LocalizedFormatting on WidgetRef {
  /// True when the UI is in Nepali.
  bool get isNepali => watch(localeProvider).languageCode == 'ne';

  /// Money, grouped Nepali-style and in Devanagari numerals under Nepali.
  String money(int paisa) =>
      isNepali ? formatPaisaNepali(paisa, devanagari: true) : formatPaisa(paisa);

  /// A plain count. Nepali renders it in Devanagari.
  String count(int value) =>
      isNepali ? formatCount(value, devanagari: true) : formatCount(value);

  /// A date. English shows the AD date; Nepali shows "BS (AD)".
  String date(DateTime value) => isNepali
      ? '${formatBs(value)} BS (${formatAd(value)})'
      : formatAd(value);
}

/// The same helpers for places that hold a `BuildContext` but no `WidgetRef`
/// (dialogs, `showDatePicker` callbacks, stateless helpers).
extension LocalizedFormattingContext on BuildContext {
  bool get isNepali =>
      Localizations.localeOf(this).languageCode == 'ne';

  String money(int paisa) =>
      isNepali ? formatPaisaNepali(paisa, devanagari: true) : formatPaisa(paisa);

  String count(int value) =>
      isNepali ? formatCount(value, devanagari: true) : formatCount(value);

  String date(DateTime value) => isNepali
      ? '${formatBs(value)} BS (${formatAd(value)})'
      : formatAd(value);
}
