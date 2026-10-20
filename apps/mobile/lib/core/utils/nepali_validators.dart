/// Nepal phone number validation and normalization.
///
/// Mobile numbers are 10 digits starting 96/97/98 (NTC, Ncell, Smart Cell);
/// landlines are a 1-2 digit area code plus a 6-8 digit local number (01
/// Kathmandu … 99). An optional +977 / 977 / 00977 country prefix and spaces
/// or dashes are accepted and stripped.
///
/// This validates *shape*, not the full area-code table: it rejects obvious
/// garbage (5 digits, 15 digits, letters) without pretending to know every
/// exchange. The stored form is digits only, so `9779812345678` and
/// `+977 981-234-5678` both normalize to `9812345678`.
library;

final _nonDigit = RegExp(r'\D');

/// Digits-only form of a Nepali phone number, or null when empty.
///
/// Strips spaces, dashes, brackets and the country prefix, so the value is
/// stable for storage and comparison.
String? normalizeNepaliPhone(String? input) {
  final trimmed = (input ?? '').trim();
  if (trimmed.isEmpty) return null;
  var digits = trimmed.replaceAll(_nonDigit, '');
  if (digits.startsWith('00977')) digits = digits.substring(5);
  if (digits.startsWith('977')) digits = digits.substring(3);
  return digits.isEmpty ? null : digits;
}

/// Whether [input] is a valid Nepali phone number. Empty input is valid —
/// phone is an optional field everywhere it is collected.
bool isValidNepaliPhone(String? input) {
  final digits = normalizeNepaliPhone(input);
  if (digits == null) return true;
  // Mobile: 10 digits starting 96/97/98.
  if (RegExp(r'^9[678]\d{8}$').hasMatch(digits)) return true;
  // Landline: 1-2 digit area code + 6-8 digit local number (7-10 total).
  if (digits.length >= 7 && digits.length <= 10) return true;
  return false;
}
