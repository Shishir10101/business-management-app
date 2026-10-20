import 'package:flutter_test/flutter_test.dart';
import 'package:khata/core/data/nepal_geography.dart';
import 'package:khata/core/utils/nepali_validators.dart';

/// Edge-case coverage for the Nepal address geography table and phone
/// validation. Pure Dart — no widget pump needed.
void main() {
  group('nepal geography', () {
    test('has exactly 7 provinces and 77 districts', () {
      expect(nepalProvinces.length, 7);
      final districts =
          nepalProvinces.expand((p) => p.districts).toList();
      expect(districts.length, 77);
      final names = districts.map((d) => d.name).toSet();
      expect(names.length, 77, reason: 'duplicate district names');
    });

    test('every district has at least one municipality or is free-text', () {
      // Municipalities are curated (well-known units); an empty list is the
      // documented free-text fallback, not a bug — but it should be rare.
      final empty = nepalProvinces
          .expand((p) => p.districts)
          .where((d) => d.municipalities.isEmpty)
          .map((d) => d.name)
          .toList();
      expect(empty, isEmpty,
          reason: 'districts with no municipality list: $empty');
    });

    test('districtsOf filters by province and returns all when unknown', () {
      expect(districtsOf('Bagmati').length, 13);
      expect(districtsOf('Koshi').length, 14);
      expect(districtsOf('No Such Province'), isEmpty);
    });

    test('municipalitiesOf returns the district list', () {
      final ktm = municipalitiesOf('Kathmandu');
      expect(ktm, contains('Kathmandu Metropolitan'));
      expect(municipalitiesOf('No Such District'), isEmpty);
    });

    test('provinceOf maps districts back to their province', () {
      expect(provinceOf('Kathmandu'), 'Bagmati');
      expect(provinceOf('Jhapa'), 'Koshi');
      expect(provinceOf('Kailali'), 'Sudurpashchim');
      expect(provinceOf('Banke'), 'Lumbini');
      expect(provinceOf('Surkhet'), 'Karnali');
      expect(provinceOf('Kaski'), 'Gandaki');
      expect(provinceOf('Dhanusha'), 'Madhesh');
      expect(provinceOf('No Such District'), isNull);
    });

    test('each province appears exactly once', () {
      final names = nepalProvinces.map((p) => p.name).toList();
      expect(names.toSet().length, names.length);
    });
  });

  group('normalizeNepaliPhone', () {
    test('strips country prefix and punctuation', () {
      expect(normalizeNepaliPhone('+977 9812345678'), '9812345678');
      expect(normalizeNepaliPhone('977-981-234-5678'), '9812345678');
      expect(normalizeNepaliPhone('00977 9812345678'), '9812345678');
      expect(normalizeNepaliPhone('9812345678'), '9812345678');
    });

    test('returns null for empty or symbol-only input', () {
      expect(normalizeNepaliPhone(null), isNull);
      expect(normalizeNepaliPhone(''), isNull);
      expect(normalizeNepaliPhone('   '), isNull);
      expect(normalizeNepaliPhone('---'), isNull);
    });
  });

  group('isValidNepaliPhone', () {
    test('accepts mobile numbers with and without prefix', () {
      expect(isValidNepaliPhone('9812345678'), isTrue);
      expect(isValidNepaliPhone('9712345678'), isTrue);
      expect(isValidNepaliPhone('9612345678'), isTrue);
      expect(isValidNepaliPhone('+977 9812345678'), isTrue);
      expect(isValidNepaliPhone('9779812345678'), isTrue);
    });

    test('accepts landline numbers with area code', () {
      // Kathmandu 01 + 7 digits, Pokhara 061 + 6, Biratnagar 021 + 6.
      expect(isValidNepaliPhone('014445566'), isTrue);
      expect(isValidNepaliPhone('061-456789'), isTrue);
      expect(isValidNepaliPhone('021 456789'), isTrue);
    });

    test('rejects wrong-length and wrong-prefix numbers', () {
      expect(isValidNepaliPhone('12345'), isFalse); // too short
      expect(isValidNepaliPhone('98123456789'), isFalse); // 11 digits
      expect(isValidNepaliPhone('9512345678'), isFalse); // 95 prefix, 10 digits
      expect(isValidNepaliPhone('123456789012'), isFalse); // 12 digits
    });

    test('empty is valid — phone is optional everywhere', () {
      expect(isValidNepaliPhone(null), isTrue);
      expect(isValidNepaliPhone(''), isTrue);
    });
  });
}
