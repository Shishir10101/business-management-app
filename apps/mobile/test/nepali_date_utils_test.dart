import 'package:flutter_test/flutter_test.dart';
import 'package:khata/core/utils/nepali_date_utils.dart';

/// Edge-case coverage for the BS conversion helpers.
///
/// The table covers BS 1975-2100, so every public helper must be total:
/// out-of-range input degrades to null (or the AD fallback) and never throws.
/// These tests pin that contract, and the anchors below come from published
/// month calendars (e.g. Jestha 2084 = 15 May - 14 Jun 2027, 31 days).
void main() {
  group('tryToBs', () {
    test('converts a known date inside the table', () {
      final bs = tryToBs(DateTime(2026, 10, 15));
      expect(bs, isNotNull);
      expect(bs!.year, 2083);
      expect(bs.month, 6);
      expect(bs.day, 29);
    });

    test('is total for AD dates far outside the BS table', () {
      // 1500 AD predates the table (1918 AD) — must degrade, never throw.
      expect(tryToBs(DateTime(1500, 1, 1)), isNull);
      // 3000 AD is past the table (2044 AD).
      expect(tryToBs(DateTime(3000, 1, 1)), isNull);
    });

    test('does not drift at a month boundary (Jestha 2084 has 31 days)', () {
      // Regression: the previous implementation produced the impossible
      // 2084-02-32 here, and 2084-03-01 one day late.
      final bs = tryToBs(DateTime(2027, 6, 15));
      expect(bs, isNotNull);
      expect(bs!.year, 2084);
      expect(bs.month, 3);
      expect(bs.day, 1);
      expect(bsDaysInMonth(2084, 2), 31);
    });

    test('never produces a day outside its own month', () {
      // Regression: 1920-10-16 used to render as 1977-06-31.
      final bs = tryToBs(DateTime(1920, 10, 16));
      expect(bs, isNotNull);
      expect(bs!.year, 1977);
      expect(bs.month, 7);
      expect(bs.day, 1);
    });
  });

  group('tryToAd', () {
    test('round-trips a known BS date', () {
      final ad = tryToAd(2083, 6, 29);
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
      expect(tryToAd(2101, 1, 1), isNull);
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
      expect(bsDaysInMonth(2084, 2), 31);
    });
  });

  group('formatters', () {
    test('formatBs / formatAd emit the canonical shapes', () {
      expect(formatBs(DateTime(2026, 10, 15)), '2083-06-29');
      expect(formatAd(DateTime(2026, 10, 15)), '2026-10-15');
    });

    test('formatBs falls back instead of throwing when out of range', () {
      expect(formatBs(DateTime(1500, 1, 1)), '-');
      expect(formatBs(DateTime(1500, 1, 1), fallback: '?'), '?');
    });

    test('formatBsLabeled appends the suffix only when convertible', () {
      expect(formatBsLabeled(DateTime(2026, 10, 15), 'BS'), '2083-06-29 BS');
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
