import 'package:flutter/material.dart' show Icons;
import 'package:flutter_test/flutter_test.dart';
import 'package:khata/core/utils/format_utils.dart';

/// Money formatting is the app's most-seen output and the one thing that must
/// never be wrong or ambiguous, so the rules are pinned here:
///   * integer paisa in, string out — no money value ever becomes a double
///   * Nepali/Indian 3-then-2 grouping (lakh/crore) in both locales
///   * Devanagari output switches every digit, including the paisa remainder
void main() {
  group('formatPaisa', () {
    test('unchanged below one thousand', () {
      expect(formatPaisa(0), 'Rs. 0.00');
      expect(formatPaisa(1), 'Rs. 0.01');
      expect(formatPaisa(19900), 'Rs. 199.00');
      expect(formatPaisa(99999), 'Rs. 999.99');
    });

    test('groups thousands', () {
      expect(formatPaisa(100000), 'Rs. 1,000.00');
      expect(formatPaisa(248600), 'Rs. 2,486.00');
      expect(formatPaisa(9999999), 'Rs. 99,999.99');
    });

    test('groups in lakh/crore, not western triples', () {
      expect(formatPaisa(10000000), 'Rs. 1,00,000.00');
      expect(formatPaisa(12345600), 'Rs. 1,23,456.00');
      expect(formatPaisa(123456789), 'Rs. 12,34,567.89');
    });

    test('sign sits outside the symbol', () {
      expect(formatPaisa(-19900), '-Rs. 199.00');
      expect(formatPaisa(-150000), '-Rs. 1,500.00');
    });
  });

  group('formatPaisaNepali', () {
    test('latin digits group exactly like the English formatter', () {
      expect(formatPaisaNepali(19900), 'Rs. 199.00');
      expect(formatPaisaNepali(12345600), 'Rs. 1,23,456.00');
    });

    test('devanagari output switches every digit, paisa included', () {
      // Regression: the paisa remainder used to stay ASCII ("रु. १,२३,४५६.00").
      expect(formatPaisaNepali(12345600, devanagari: true), 'रु. १,२३,४५६.००');
      expect(formatPaisaNepali(19905, devanagari: true), 'रु. १९९.०५');
      expect(formatPaisaNepali(0, devanagari: true), 'रु. ०.००');
    });

    test('sign sits outside the Devanagari symbol', () {
      expect(formatPaisaNepali(-19900, devanagari: true), '-रु. १९९.००');
    });
  });

  group('formatCount', () {
    test('groups records the same way money is grouped', () {
      expect(formatCount(0), '0');
      expect(formatCount(999), '999');
      expect(formatCount(1500), '1,500');
      expect(formatCount(123456), '1,23,456');
    });

    test('devanagari option', () {
      expect(formatCount(1500, devanagari: true), '१,५००');
    });
  });

  group('formatQuantity', () {
    test('drops the trailing .0 on whole quantities', () {
      expect(formatQuantity(25), '25');
      expect(formatQuantity(0), '0');
    });

    test('keeps fractional weights', () {
      expect(formatQuantity(7.5), '7.5');
      expect(formatQuantity(0.25), '0.25');
    });

    test('devanagari option keeps the fraction', () {
      expect(formatQuantityNepali(7.5, devanagari: true), '७.५');
      expect(formatQuantityNepali(25, devanagari: true), '२५');
    });
  });

  group('movement metadata', () {
    test('icons cover every server enum and fall through safely', () {
      expect(movementTypeIcon('Opening'), Icons.flag_outlined);
      expect(movementTypeIcon('Purchase'), Icons.shopping_bag_outlined);
      expect(movementTypeIcon('Sale'), Icons.point_of_sale_outlined);
      expect(movementTypeIcon('AdjustmentIn'), Icons.add_circle_outlined);
      expect(movementTypeIcon('AdjustmentOut'), Icons.remove_circle_outlined);
      // An unknown future enum must not crash the row.
      expect(movementTypeIcon('SomethingNew'), Icons.swap_vert_outlined);
    });
  });
}
