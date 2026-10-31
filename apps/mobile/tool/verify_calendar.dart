// Exhaustive AD<->BS conversion dump, for diffing against an independent
// implementation (see scripts/verify_calendar.py).
//
//   dart run tool/verify_calendar.dart ad    # AD date -> BS
//   dart run tool/verify_calendar.dart bs    # BS date -> AD
//
// Output is one "input,output" pair per line, ISO dates, for every day in the
// range both implementations support (BS 1975-2100 / AD 1918-2044).
import 'package:khata/core/utils/nepali_date_utils.dart';

void main(List<String> args) {
  final mode = args.isEmpty ? 'ad' : args.first;

  if (mode == 'ad') {
    // Every AD day that maps into BS 1975-2099.
    var day = DateTime(1918, 1, 1);
    final end = DateTime(2043, 12, 31);
    while (!day.isAfter(end)) {
      final bs = tryToBs(day);
      if (bs != null && bs.year >= 1975 && bs.year <= 2099) {
        print('${_iso(day.year, day.month, day.day)},'
            '${bs.year}-${bs.month}-${bs.day}');
      }
      day = DateTime(day.year, day.month, day.day + 1);
    }
  } else {
    // Every BS day in the supported range, including the last day of each
    // month — that is where an off-by-one month length shows up.
    for (var year = 1975; year <= 2099; year++) {
      for (var month = 1; month <= 12; month++) {
        final days = bsDaysInMonth(year, month);
        if (days == null) {
          print('MISSING,$year-$month');
          continue;
        }
        for (var day = 1; day <= days; day++) {
          final ad = tryToAd(year, month, day);
          print('$year-$month-$day,'
              '${ad == null ? "null" : _iso(ad.year, ad.month, ad.day)}');
        }
      }
    }
  }
}

String _iso(int y, int m, int d) =>
    '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-'
    '${d.toString().padLeft(2, '0')}';
