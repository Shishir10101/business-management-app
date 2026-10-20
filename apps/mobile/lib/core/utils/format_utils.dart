import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../../l10n/app_localizations.dart';
import 'nepali_date_utils.dart';

/// Formats an integer amount of paisa as a rupee string.
/// 19900 -> "Rs. 199.00"; 12345600 -> "Rs. 1,23,456.00". No floating-point
/// money: all arithmetic stays in paisa.
///
/// Grouping is the Nepali/Indian 3-then-2 pattern (lakh/crore), the same rule
/// the Nepali-locale formatter uses — a shop's monthly turnover crosses
/// thousands within days, and "Rs. 248600.00" is unreadable in a list row.
/// Delegating to [formatPaisaNepali] keeps one implementation of the rule.
String formatPaisa(int paisa) => formatPaisaNepali(paisa);

/// Formats paisa with Nepali place-value grouping: 12345678 paisa renders as
/// "Rs. 1,23,456.78" — lakh/crore, not western thousands.
///
/// [devanagari] converts every digit, including the paisa remainder
/// ("रु. १,२३,४५६.७८").
///
/// Grouping is delegated to `NepaliNumberFormat`, which already implements the
/// 3-then-2s rule. Only the integer rupee part is handed to it and the paisa
/// remainder is appended as text, so no money value ever passes through a
/// `double`.
String formatPaisaNepali(int paisa, {bool devanagari = false}) {
  final negative = paisa < 0;
  final abs = paisa.abs();
  final rupees = abs ~/ 100;
  final cents = abs % 100;

  final grouped = NepaliNumberFormat(
    language: devanagari ? Language.nepali : Language.english,
    decimalDigits: 0,
  ).format<int>(rupees);

  // The paisa remainder must switch scripts with the rest of the number —
  // "रु. १,२३,४५६.00" mixes Devanagari and ASCII digits in one amount.
  final centsText = devanagari
      ? toDevanagariDigits(cents.toString().padLeft(2, '0'))
      : cents.toString().padLeft(2, '0');
  final symbol = devanagari ? 'रु.' : 'Rs.';
  final body = '$symbol $grouped.$centsText';
  return negative ? '-$body' : body;
}

/// Formats a plain count (a quantity of records, not money) with the same
/// Devanagari option. 1234 -> "1,234" / "१,२३४".
String formatCount(int value, {bool devanagari = false}) {
  final text = NepaliNumberFormat(
    language: devanagari ? Language.nepali : Language.english,
    decimalDigits: 0,
  ).format<int>(value);
  return text;
}

/// Stock quantity formatted for display, with an optional Devanagari pass.
/// Keeps the existing trailing-zero trimming for fractional weights.
String formatQuantityNepali(double quantity, {bool devanagari = false}) {
  final base = formatQuantity(quantity);
  return devanagari ? toDevanagariDigits(base) : base;
}

/// Formats a stock quantity (kg can be fractional): trims trailing zeros.
/// 25.0 -> "25", 7.5 -> "7.5".
String formatQuantity(double quantity) {
  if (quantity == quantity.truncateToDouble()) {
    return quantity.toInt().toString();
  }
  return quantity.toString();
}

/// Label for a stock movement type coming from the API as a string
/// ("Opening", "Purchase", "Sale", "AdjustmentIn", ...).
///
/// The server sends the enum name, so the mapping lives here and the wording
/// comes from [l10n]; an unknown type falls through unchanged rather than
/// being silently blanked.
String movementTypeLabel(String type, AppLocalizations l10n) {
  switch (type) {
    case 'Opening':
      return l10n.openingStock;
    case 'Purchase':
      return l10n.purchase;
    case 'Sale':
      return l10n.sale;
    case 'ReturnIn':
      return l10n.returnIn;
    case 'ReturnOut':
      return l10n.returnOut;
    case 'AdjustmentIn':
      return l10n.stockAdded;
    case 'AdjustmentOut':
      return l10n.stockRemoved;
    default:
      return type;
  }
}

/// Icon for a stock movement type (in = green-ish arrow down into box, etc.).
IconData movementTypeIcon(String type) {
  switch (type) {
    case 'Opening':
      return Icons.flag_outlined;
    case 'Purchase':
      return Icons.shopping_bag_outlined;
    case 'Sale':
      return Icons.point_of_sale_outlined;
    case 'ReturnIn':
      return Icons.keyboard_return_outlined;
    case 'ReturnOut':
      return Icons.undo_outlined;
    case 'AdjustmentIn':
      return Icons.add_circle_outline;
    case 'AdjustmentOut':
      return Icons.remove_circle_outline;
    default:
      return Icons.swap_vert_outlined;
  }
}
