import 'package:flutter_test/flutter_test.dart';
import 'package:khata/core/utils/nepali_date_utils.dart';

/// Edge-case coverage for the BS conversion helpers.
///
/// `nepali_utils` asserts for BS years outside 1970-2250, so every public
/// helper must be total: out-of-range input degrades to null (or the AD
/// fallback) and never throws. These tests pin that contract.
void main() {
  group('tryToBs', () {
    test('converts a known date inside the table', () {
      final bs = tryToBs(DateTime(2026, 10, 15));
      expect(bs, isNotNull);
      expect(bs!.year, 2083);
      expect(bs.month, 6);
      expect(bs.day, 28);
    });

    test('is total for AD dates far outside the BS table', () {
      // 1500 AD predates BS 1970 (~1913 AD) — must degrade, never throw.
      expect(tryToBs(DateTime(1500, 1, 1)), isNull);
      // 3000 AD is past BS 2250 (~2193 AD).
      expect(tryToBs(DateTime(3000, 1, 1)), isNull);
    });
  });

  group('tryToAd', () {
    test('round-trips a known BS date', () {
      final ad = tryToAd(2083, 6, 28);
      expect(ad, isNotNull);
      expect(ad!.year, 2026);
      expect(ad.month, 10);
      expect(ad.day, 15);
    });

    test('round-trips a spread of dates across the table', () {
      final samples = <DateTime>[
        DateTime(2020, 4, 13), // new-year boundary season
        DateTime(2021, 7, 17),
        DateTime(2022, 11, 5),
        DateTime(2023, 2, 14),
        DateTime(2024, 8, 30),
        DateTime(2025, 12, 1),
        DateTime(2026, 10, 15),
        DateTime(2027, 5, 9),
        DateTime(2028, 1, 31),
      ];
      for (final d in samples) {
        final bs = tryToBs(d);
        expect(bs, isNotNull, reason: 'tryToBs failed for $d');
        final back = tryToAd(bs!.year, bs.month, bs.day);
        expect(back, isNotNull, reason: 'tryToAd failed for BS $bs');
        expect(back!.year, d.year);
        expect(back.month, d.month);
        expect(back.day, d.day);
      }
    });

    test('rejects out-of-range BS years', () {
      expect(tryToAd(1969, 1, 1), isNull);
      expect(tryToAd(2251, 1, 1), isNull);
    });

    test('rejects impossible months and days', () {
      expect(tryToAd(2083, 0, 1), isNull);
      expect(tryToAd(2083, 13, 1), isNull);
      expect(tryToAd(2083, 6, 0), isNull);
      expect(tryToAd(2083, 6, 40), isNull);
    });
  });

  group('bsDaysInMonth', () {
    test('returns 29-32 for a valid month and null out of range', () {
      final days = bsDaysInMonth(2083, 6);
      expect(days, isNotNull);
      expect(days!, greaterThanOrEqualTo(29));
      expect(days, lessThanOrEqualTo(32));
      expect(bsDaysInMonth(2083, 13), isNull);
      expect(bsDaysInMonth(1969, 1), isNull);
    });
  });

  group('formatters', () {
    test('formatBs / formatAd emit the canonical shapes', () {
      expect(formatBs(DateTime(2026, 10, 15)), '2083-06-28');
      expect(formatAd(DateTime(2026, 10, 15)), '2026-10-15');
    });

    test('formatBs falls back instead of throwing when out of range', () {
      expect(formatBs(DateTime(1500, 1, 1)), '-');
      expect(formatBs(DateTime(1500, 1, 1), fallback: '?'), '?');
    });

    test('formatBsLabeled appends the suffix only when convertible', () {
      expect(formatBsLabeled(DateTime(2026, 10, 15), 'BS'), '2083-06-28 BS');
      expect(formatBsLabeled(DateTime(1500, 1, 1), 'BS'), '-');
    });

    test('parseIsoDate parses the wire format and tolerates junk', () {
      expect(parseIsoDate('2026-10-15'), DateTime(2026, 10, 15));
      expect(parseIsoDate(null), isNull);
      expect(parseIsoDate(''), isNull);
      expect(parseIsoDate('not-a-date'), isNull);
    });
  });

  group('month names', () {
    test('English and Devanagari lists stay 12 long and aligned', () {
      expect(bsMonthNamesEnglish.length, 12);
      expect(bsMonthNamesNepali.length, 12);
      expect(bsMonthName(1), 'Baishakh');
      expect(bsMonthName(1, nepali: true), 'बैशाख');
      expect(bsMonthName(12), 'Chaitra');
    });

    test('out-of-range month returns empty, never throws', () {
      expect(bsMonthName(0), '');
      expect(bsMonthName(13), '');
    });
  });

  group('toDevanagariDigits', () {
    test('maps Latin digits and passes everything else through', () {
      expect(toDevanagariDigits('2083-06-28'), '२०८३-०६-२८');
      expect(toDevanagariDigits('Baishakh 12'), 'Baishakh १२');
      expect(toDevanagariDigits(''), '');
    });
  });
}
