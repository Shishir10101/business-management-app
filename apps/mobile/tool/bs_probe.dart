import 'package:khata/core/utils/nepali_date_utils.dart';

void main() {
  final now = DateTime.now();
  print('today AD : ${formatAd(now)}');
  final bs = tryToBs(now);
  print('today BS : ${bs?.year}-${bs?.month}-${bs?.day}');
  for (final d in [
    DateTime(2026, 10, 18),
    DateTime(2026, 4, 14),
    DateTime(2000, 1, 1),
    DateTime(2027, 1, 1),
  ]) {
    final n = tryToBs(d);
    final back = tryToAd(n!.year, n.month, n.day);
    print('${formatAd(d)} -> BS ${n.year}-${n.month}-${n.day} -> AD ${back == null ? "null" : formatAd(back)}'
        '  roundtrip=${back != null && back.year == d.year && back.month == d.month && back.day == d.day}');
  }
  setActiveCalendar(CalendarSystem.bs);
  print('display BS: ${formatDisplayDate(DateTime(2026, 10, 18))}');
  print('other  AD : ${formatOtherDate(DateTime(2026, 10, 18))}');
  setActiveCalendar(CalendarSystem.ad);
  print('display AD: ${formatDisplayDate(DateTime(2026, 10, 18))}');
  print('other  BS : ${formatOtherDate(DateTime(2026, 10, 18))}');
}
