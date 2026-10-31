"""Generate lib/core/utils/nepali_date_utils.dart with the vetted BS table.

The table comes from the `nepali-datetime` dataset (1975-2100), spot-checked
against published month calendars. Run once; the output is committed.
"""

import csv
import os

import nepali_datetime as nd

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "apps", "mobile", "lib", "core", "utils", "nepali_date_utils.dart")

rows = {int(r["Year"]): r for r in csv.DictReader(open(nd.CALENDAR_PATH, encoding="utf-8"))}
enc = {"29": "9", "30": "0", "31": "1", "32": "2"}

chars = []
for year in range(1975, 2101):
    values = [v for k, v in rows[year].items() if k != "Year"]
    assert len(values) == 12, (year, values)
    for value in values:
        assert value in enc, (year, value)
        chars.append(enc[value])
table = "".join(chars)
assert len(table) == 126 * 12

lines = "\n".join(f"    '{table[i:i + 96]}'" for i in range(0, len(table), 96))

header = '''/// Bikram Sambat (BS) calendar helpers.
///
/// The app stores and transmits every date in AD (ISO-8601), because that is
/// what the API, the database and every existing screen agree on. BS is a
/// *display* concern: Nepali users read dates in BS, so we convert at the
/// edge and never let a BS value leak into persistence.
///
/// Conversion is done here, from an embedded month-length table, rather than
/// through `nepali_utils`. That library's `toNepaliDateTime()` applies a
/// "+1 day" compensation whenever the device is in Nepal time (UTC+05:45),
/// which is this app's primary market: on a Nepali phone every AD -> BS
/// conversion came out one day late, and its BS -> AD inverse was off by one
/// in the other direction. Worse, its month table disagrees with the published
/// calendar for several years (Jestha 2084 is 31 days, not 32), which produced
/// impossible dates such as 2084-02-32.
///
/// The table below is the settled dataset (1975-2100 BS), and the arithmetic
/// is done entirely in UTC so neither the device timezone nor daylight saving
/// can shift a date.
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

/// First and last BS year the table covers.
const int _firstBsYear = 1975;
const int _lastBsYear = 2100;

/// Month lengths for [_firstBsYear]..[_lastBsYear], one character per month:
/// `9` = 29 days, `0` = 30, `1` = 31, `2` = 32. 126 years x 12 months.
///
/// Source: the `nepali-datetime` BS dataset, verified against published month
/// calendars for 2062, 2083 and 2084 (e.g. Jestha 2084 runs 15 May - 14 Jun
/// 2027, 31 days). Do not edit by hand; regenerate with
/// `scripts/verify_calendar.py`'s sibling generator if the dataset changes.
const String _monthLengths =
'''

body = ''';

/// BS [year]-01-01 as an AD instant (UTC). BS 1975-01-01 = 1918-04-13, the
/// anchor the dataset is defined against; BS 2000-01-01 then lands on
/// 1943-04-14, which is the published Nepali New Year for that year.
final DateTime _anchor = DateTime.utc(1918, 4, 13);

/// Days in a BS month, or `null` when the year/month is outside the table.
int? _monthLength(int year, int month) {
  if (year < _firstBsYear || year > _lastBsYear) return null;
  if (month < 1 || month > 12) return null;
  final index = (year - _firstBsYear) * 12 + (month - 1);
  // '9' encodes 29 (the only length that does not follow the pattern), so
  // '0'..'2' map to 30..32 and '9' is handled separately.
  final digit = _monthLengths.codeUnitAt(index) - 0x30;
  return digit == 9 ? 29 : digit + 30;
}

/// Cumulative days from BS 1975-01-01 to the first day of each year, plus a
/// final entry holding the total day count (used as an upper bound).
final List<int> _yearStarts = _buildYearStarts();

List<int> _buildYearStarts() {
  final starts = List<int>.filled(_lastBsYear - _firstBsYear + 2, 0);
  var total = 0;
  for (var year = _firstBsYear; year <= _lastBsYear; year++) {
    starts[year - _firstBsYear] = total;
    for (var month = 1; month <= 12; month++) {
      total += _monthLength(year, month)!;
    }
  }
  starts[_lastBsYear - _firstBsYear + 1] = total;
  return starts;
}

/// BS year/month/day for an AD [dateTime], or `null` when out of range.
///
/// The date part is compared in UTC, so a device in Nepal time and a device in
/// UTC produce the same answer for the same calendar day.
NepaliDateTime? tryToBs(DateTime dateTime) {
  try {
    final days = DateTime.utc(dateTime.year, dateTime.month, dateTime.day)
        .difference(_anchor)
        .inDays;

    if (days < 0 || days >= _yearStarts.last) return null;

    // Binary search: the last year whose start is <= days.
    var low = 0;
    var high = _lastBsYear - _firstBsYear;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (_yearStarts[mid] <= days) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }

    final year = _firstBsYear + low;
    var remaining = days - _yearStarts[low];
    var month = 1;
    while (true) {
      final length = _monthLength(year, month)!;
      if (remaining < length) break;
      remaining -= length;
      month++;
    }

    return NepaliDateTime(
      year,
      month,
      remaining + 1,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );
  } catch (_) {
    return null;
  }
}

/// BS -> AD. Returns `null` when the BS date is outside the supported range or
/// the day does not exist in that month.
DateTime? tryToAd(
  int bsYear,
  int bsMonth,
  int bsDay, {
  int hour = 0,
  int minute = 0,
}) {
  final length = _monthLength(bsYear, bsMonth);
  if (length == null || bsDay < 1 || bsDay > length) return null;

  var offset = _yearStarts[bsYear - _firstBsYear];
  for (var month = 1; month < bsMonth; month++) {
    offset += _monthLength(bsYear, month)!;
  }

  final ad = _anchor.add(Duration(days: offset + bsDay - 1));
  // Build a *local* midnight from the UTC components: the caller only wants
  // the calendar day, and constructing from the UTC instant would shift it
  // for every timezone west of Kathmandu.
  return DateTime(ad.year, ad.month, ad.day, hour, minute);
}

/// "2083-06-28" for an AD date, or the fallback when BS is unavailable.
String formatBs(DateTime dateTime, {String fallback = '-'}) {
  final bs = tryToBs(dateTime);
  if (bs == null) return fallback;
  return '${bs.year}-${_two(bs.month)}-${_two(bs.day)}';
}

/// "2083-06-28 BS" — for labels that sit next to an AD date and need to be
/// unambiguous about which calendar they are in.
String formatBsLabeled(
  DateTime dateTime,
  String bsSuffix, {
  String fallback = '-',
}) {
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
int? bsDaysInMonth(int bsYear, int bsMonth) => _monthLength(bsYear, bsMonth);

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
'''

with open(OUT, "w", encoding="utf-8", newline="\n") as f:
    f.write(header)
    f.write(lines)
    f.write(body)

print("wrote", OUT, "table chars:", len(table))
