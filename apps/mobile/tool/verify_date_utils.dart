// Runs the assertions from test/nepali_date_utils_test.dart without the
// Flutter test harness (which cannot start in this sandbox), plus an
// exhaustive round-trip over the whole supported table.
//
//   dart run tool/verify_date_utils.dart
import 'package:khata/core/utils/nepali_date_utils.dart';

var failures = 0;

void check(String label, bool ok, [String extra = '']) {
  if (!ok) {
    failures++;
    print('FAIL $label $extra');
  }
}

void main() {
  // --- known anchors (published calendar) ---
  final bs = tryToBs(DateTime(2026, 10, 15));
  check('2026-10-15 -> 2083-06-29',
      bs != null && bs.year == 2083 && bs.month == 6 && bs.day == 29,
      '${bs?.year}-${bs?.month}-${bs?.day}');

  final today = tryToBs(DateTime(2026, 10, 20));
  check('2026-10-20 -> 2083-07-03',
      today != null && today.year == 2083 && today.month == 7 && today.day == 3,
      '${today?.year}-${today?.month}-${today?.day}');

  final newYear = tryToBs(DateTime(2026, 4, 14));
  check('2026-04-14 -> 2083-01-01',
      newYear != null && newYear.year == 2083 && newYear.month == 1 && newYear.day == 1,
      '${newYear?.year}-${newYear?.month}-${newYear?.day}');

  // --- the two bugs this rewrite fixed ---
  final june15 = tryToBs(DateTime(2027, 6, 15));
  check('2027-06-15 -> 2084-03-01 (was 2084-02-32)',
      june15 != null && june15.year == 2084 && june15.month == 3 && june15.day == 1,
      '${june15?.year}-${june15?.month}-${june15?.day}');

  check('Jestha 2084 has 31 days (was 32)', bsDaysInMonth(2084, 2) == 31,
      '${bsDaysInMonth(2084, 2)}');

  final old = tryToBs(DateTime(1920, 10, 16));
  check('1920-10-16 -> 1977-07-01 (was invalid 1977-06-31)',
      old != null && old.year == 1977 && old.month == 7 && old.day == 1,
      '${old?.year}-${old?.month}-${old?.day}');

  // --- totality ---
  check('1500 AD degrades to null', tryToBs(DateTime(1500, 1, 1)) == null);
  check('3000 AD degrades to null', tryToBs(DateTime(3000, 1, 1)) == null);
  check('BS 1969 rejected', tryToAd(1969, 1, 1) == null);
  check('BS 2251 rejected', tryToAd(2251, 1, 1) == null);
  check('month 0 rejected', tryToAd(2083, 0, 1) == null);
  check('month 13 rejected', tryToAd(2083, 13, 1) == null);
  check('day 0 rejected', tryToAd(2083, 6, 0) == null);
  check('day 40 rejected', tryToAd(2083, 6, 40) == null);

  // --- exhaustive: every day in the table converts and round-trips ---
  var day = DateTime(1918, 4, 13);
  final end = DateTime(2043, 12, 31);
  var count = 0;
  while (!day.isAfter(end)) {
    final n = tryToBs(day);
    if (n == null) {
      day = DateTime(day.year, day.month, day.day + 1);
      continue;
    }
    count++;
    final length = bsDaysInMonth(n.year, n.month);
    if (length == null || n.day < 1 || n.day > length!) {
      check('valid BS day', false, '$day -> ${n.year}-${n.month}-${n.day}');
    }
    final back = tryToAd(n.year, n.month, n.day);
    if (back == null ||
        back.year != day.year ||
        back.month != day.month ||
        back.day != day.day) {
      check('round-trip', false, '$day -> ${n.year}-${n.month}-${n.day} -> $back');
    }
    day = DateTime(day.year, day.month, day.day + 1);
  }

  // --- formatters ---
  check('formatBs', formatBs(DateTime(2026, 10, 15)) == '2083-06-29',
      formatBs(DateTime(2026, 10, 15)));
  check('formatAd', formatAd(DateTime(2026, 10, 15)) == '2026-10-15');
  check('formatBs fallback', formatBs(DateTime(1500, 1, 1)) == '-');
  check('formatBsLabeled',
      formatBsLabeled(DateTime(2026, 10, 15), 'BS') == '2083-06-29 BS');
  check('formatBsLabeled fallback', formatBsLabeled(DateTime(1500, 1, 1), 'BS') == '-');
  check('formatBsLong english',
      formatBsLong(DateTime(2026, 10, 15)) == 'Ashwin 29, 2083',
      formatBsLong(DateTime(2026, 10, 15)));
  check('parseIsoDate', parseIsoDate('2026-10-15') == DateTime(2026, 10, 15));
  check('parseIsoDate junk', parseIsoDate('not-a-date') == null);
  check('month names', bsMonthName(1) == 'Baishakh' && bsMonthName(1, nepali: true) == 'बैशाख');
  check('devanagari', toDevanagariDigits('2083-06-28') == '२०८३-०६-२८');

  print('checked $count AD days');
  print(failures == 0 ? 'ALL CHECKS PASSED' : '$failures CHECK(S) FAILED');
}
