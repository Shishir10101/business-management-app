// Diagnostic: raw nepali_utils conversions vs the app's round-trip helper.
//
//   dart run tool/bs_diag.dart 1920-10-16 2027-06-15 2026-10-18
import 'package:nepali_utils/nepali_utils.dart';

import 'package:khata/core/utils/nepali_date_utils.dart';

void main(List<String> args) {
  final dates = args.isEmpty
      ? ['1920-10-16', '2026-10-18', '2027-06-15']
      : args;

  for (final iso in dates) {
    final parts = iso.split('-').map(int.parse).toList();
    final d = DateTime(parts[0], parts[1], parts[2]);
    final raw = d.toNepaliDateTime();
    final back = raw.toDateTime();
    final fixed = tryToBs(d);

    print('AD $iso');
    print('  raw toNepaliDateTime : ${raw.year}-${raw.month}-${raw.day}');
    print('  raw .toDateTime()    : ${back.year}-${back.month}-${back.day} '
        '(sameDay=${back.year == d.year && back.month == d.month && back.day == d.day})');
    print('  tryToBs (app)        : ${fixed?.year}-${fixed?.month}-${fixed?.day}');
  }

  // The library's own month lengths around the disputed months.
  for (final ym in [(1977, 6), (1977, 7), (2084, 2), (2084, 3), (2083, 7)]) {
    final days = NepaliDateTime(ym.$1, ym.$2, 1).totalDays;
    print('BS ${ym.$1}-${ym.$2} totalDays=$days');
  }
}
