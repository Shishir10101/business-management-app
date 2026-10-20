/// Bikram Sambat (BS) calendar helpers.
///
/// The app stores and transmits every date in AD (ISO-8601), because that is
/// what the API, the database and every existing screen agree on. BS is a
/// *display* concern: Nepali users read dates in BS, so we convert at the
/// edge and never let a BS value leak into persistence.
///
/// Everything here is total — none of these calls throw. `NepaliDateTime`
/// asserts for years outside 1970-2250 BS, and a label must never take a page
/// down, so out-of-range input degrades to the AD date instead.
library;

import 'package:nepali_utils/nepali_utils.dart';

/// Which calendar the UI reads and writes dates in.
///
/// The wire format never changes: every date is stored and sent as AD
/// (ISO-8601). This only decides what the user *sees* and which picker opens.
enum CalendarSystem { ad, bs }

CalendarSystem _activeCalendar = CalendarSystem.ad;

/// The calendar the UI is currently showing. Set by `calendarProvider` when the
/// preference loads or changes; read by [formatDisplayDate].
///
/// This is module state on purpose — the same approach `Intl.defaultLocale`
/// takes. Dates are rendered from ~20 small `_date()` helpers spread over the
/// presentation layer; threading a provider through every one of them would add
/// a `ref` to widgets that otherwise need none, for a value that is genuinely
/// app-global.
CalendarSystem get activeCalendar => _activeCalendar;

void setActiveCalendar(CalendarSystem calendar) => _activeCalendar = calendar;

/// BS year/month/day for an AD [dateTime], or `null` when out of range.
///
/// `nepali_utils` 3.0.8 applies an unconditional "+1 day" compensation for
/// dates after 1986 when the device is in Nepal time (UTC+05:45) — which is
/// this app's primary market. The result is that AD -> BS comes out one day
/// ahead (2026-10-18 rendered as 2083-07-02 instead of 2083-07-01), while
/// BS -> AD is correct. Rather than trusting either direction, convert and
/// check the round trip; step back a day only when it disagrees.
NepaliDateTime? tryToBs(DateTime dateTime) {
  try {
    var bs = dateTime.toNepaliDateTime();
    if (!_sameDay(bs.toDateTime(), dateTime)) {
      bs = DateTime(dateTime.year, dateTime.month, dateTime.day - 1)
          .toNepaliDateTime();
    }
    // `toNepaliDateTime` can return a value with a zeroed year for inputs
    // outside the table; treat that as a failure rather than rendering it.
    if (bs.year < 1970 || bs.year > 2250) return null;
    return bs;
  } catch (_) {
    return null;
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;


/// BS -> AD. Returns `null` when the BS date is outside the supported range.
DateTime? tryToAd(int bsYear, int bsMonth, int bsDay,
    {int hour = 0, int minute = 0}) {
  try {
    if (bsYear < 1970 || bsYear > 2250) return null;
    if (bsMonth < 1 || bsMonth > 12) return null;
    if (bsDay < 1 || bsDay > 32) return null;
    final bs = NepaliDateTime(bsYear, bsMonth, bsDay, hour, minute);
    // Guard against a day that does not exist in that BS month.
    if (bs.day != bsDay || bs.month != bsMonth) return null;
    return bs.toDateTime();
  } catch (_) {
    return null;
  }
}

/// "2083-06-28" for an AD date, or the AD date when BS is unavailable.
String formatBs(DateTime dateTime, {String fallback = '-'}) {
  final bs = tryToBs(dateTime);
  if (bs == null) return fallback;
  return '${bs.year}-${_two(bs.month)}-${_two(bs.day)}';
}

/// "2083-06-28 BS" — for labels that sit next to an AD date and need to be
/// unambiguous about which calendar they are in.
String formatBsLabeled(DateTime dateTime, String bsSuffix,
    {String fallback = '-'}) {
  final text = formatBs(dateTime, fallback: fallback);
  return text == fallback ? text : '$text $bsSuffix';
}

/// "28 Ashoj 2083" in the given language, falling back to the AD date.
String formatBsLong(DateTime dateTime, {Language language = Language.english}) {
  final bs = tryToBs(dateTime);
  if (bs == null) return formatAd(dateTime);
  try {
    return NepaliDateFormat.yMMMMd(language).format(bs);
  } catch (_) {
    return formatAd(dateTime);
  }
}

/// "yyyy-MM-dd" in AD — the canonical wire format.
String formatAd(DateTime dateTime) =>
    '${dateTime.year}-${_two(dateTime.month)}-${_two(dateTime.day)}';

/// The date as the user's chosen calendar wants to read it.
///
/// AD: "2026-10-18". BS: "2083-07-01 BS" (Devanagari digits under Nepali).
/// Falls back to the AD date when the BS conversion is unavailable, so a date
/// label can never blank out.
String formatDisplayDate(DateTime dateTime, {bool nepaliDigits = false}) {
  if (_activeCalendar == CalendarSystem.ad) {
    return nepaliDigits ? toDevanagariDigits(formatAd(dateTime)) : formatAd(dateTime);
  }
  final bs = tryToBs(dateTime);
  if (bs == null) return formatAd(dateTime);
  final text = '${bs.year}-${_two(bs.month)}-${_two(bs.day)}';
  return nepaliDigits ? '${toDevanagariDigits(text)} BS' : '$text BS';
}

/// The same date in the *other* calendar, for the secondary line of a date
/// field — so a user who works across both never has to convert by hand.
String formatOtherDate(DateTime dateTime, {bool nepaliDigits = false}) {
  if (_activeCalendar == CalendarSystem.ad) {
    final bs = tryToBs(dateTime);
    if (bs == null) return '';
    final text = '${bs.year}-${_two(bs.month)}-${_two(bs.day)}';
    return nepaliDigits ? '${toDevanagariDigits(text)} BS' : '$text BS';
  }
  return nepaliDigits ? toDevanagariDigits(formatAd(dateTime)) : formatAd(dateTime);
}

/// Parses the first date out of a "yyyy-MM-dd" string, or `null`.
DateTime? parseIsoDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

/// The BS month names, 1-indexed, in English transliteration. Handy for
/// dropdowns where `nepali_utils`' formatter is overkill.
const bsMonthNamesEnglish = <String>[
  'Baishakh',
  'Jestha',
  'Ashadh',
  'Shrawan',
  'Bhadra',
  'Ashwin',
  'Kartik',
  'Mangsir',
  'Poush',
  'Magh',
  'Falgun',
  'Chaitra',
];

/// The BS month names in Devanagari.
const bsMonthNamesNepali = <String>[
  'बैशाख',
  'जेठ',
  'असार',
  'साउन',
  'भदौ',
  'असोज',
  'कार्तिक',
  'मंसिर',
  'पुष',
  'माघ',
  'फाल्गुन',
  'चैत',
];

/// Month name for a 1-12 BS month, tolerating an out-of-range index.
String bsMonthName(int month, {bool nepali = false}) {
  if (month < 1 || month > 12) return '';
  return nepali ? bsMonthNamesNepali[month - 1] : bsMonthNamesEnglish[month - 1];
}

/// Number of days in a BS month, or `null` when out of range.
int? bsDaysInMonth(int bsYear, int bsMonth) {
  try {
    if (bsYear < 1970 || bsYear > 2250) return null;
    if (bsMonth < 1 || bsMonth > 12) return null;
    return NepaliDateTime(bsYear, bsMonth, 1).totalDays;
  } catch (_) {
    return null;
  }
}

String _two(int value) => value.toString().padLeft(2, '0');

/// Latin digits -> Devanagari digits (U+0030..U+0039 -> U+0966..U+096F).
///
/// Deliberately NOT `NepaliUnicode.convert` from `nepali_utils`: that is a
/// romanization transliterator ("a" -> "अ"), so feeding it "2083-06-28"
/// produces gibberish. Any non-digit character is passed through unchanged.
String toDevanagariDigits(String input) {
  const zero = 0x0966; // ०
  const latinZero = 0x30; // 0
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    if (rune >= latinZero && rune <= latinZero + 9) {
      buffer.writeCharCode(zero + (rune - latinZero));
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}
