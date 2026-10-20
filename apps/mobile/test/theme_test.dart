import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:khata/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    // The brand is a deep money-green, not the corporate blue this test used
    // to assert — it had been red since the theme was rebuilt and nobody
    // noticed because `flutter test` cannot run in this sandbox. Asserting a
    // hue *range* rather than an exact seed keeps the test honest: the seed
    // goes through ColorScheme.fromSeed, which may nudge the exact value.
    test('light theme is built on a green primary', () {
      final primary = AppTheme.light().colorScheme.primary;
      final hue = HSLColor.fromColor(primary).hue;
      expect(hue, inInclusiveRange(120, 180), reason: 'green hue, got $hue');
      expect(HSLColor.fromColor(primary).lightness, lessThan(0.5));
    });

    test('dark theme primary is a readable green', () {
      final primary = AppTheme.dark().colorScheme.primary;
      final hue = HSLColor.fromColor(primary).hue;
      expect(hue, inInclusiveRange(120, 180), reason: 'green hue, got $hue');
      expect(HSLColor.fromColor(primary).lightness, greaterThan(0.5));
    });

    test('light theme uses Material 3', () {
      final theme = AppTheme.light();
      expect(theme.useMaterial3, isTrue);
    });

    test('dark theme uses Material 3', () {
      final theme = AppTheme.dark();
      expect(theme.useMaterial3, isTrue);
    });

    test('both themes carry the money colour extension', () {
      expect(AppTheme.light().extension<MoneyColors>(), isNotNull);
      expect(AppTheme.dark().extension<MoneyColors>(), isNotNull);
    });

    test('money colours are distinguishable in both themes', () {
      for (final money in [MoneyColors.light, MoneyColors.dark]) {
        expect(money.positive, isNot(money.negative));
        expect(money.positive, isNot(money.warning));
        expect(money.negative, isNot(money.warning));
      }
      // Green in, red out — the direction every khata app uses.
      expect(HSLColor.fromColor(MoneyColors.light.positive).hue,
          inInclusiveRange(120, 180));
      expect(HSLColor.fromColor(MoneyColors.light.negative).hue,
          anyOf(lessThan(25), greaterThan(340)));
    });

    test('money colours lerp without throwing', () {
      final mid = MoneyColors.light.lerp(MoneyColors.dark, 0.5);
      expect(mid, isA<MoneyColors>());
      expect(MoneyColors.light.lerp(null, 0.5), MoneyColors.light);
    });

    test('the primary action button is filled, not a pale tonal surface', () {
      final theme = AppTheme.light();
      expect(theme.floatingActionButtonTheme.backgroundColor,
          theme.colorScheme.primary);
    });
  });

  group('Login form validation', () {
    test('email validation accepts valid email', () {
      final regex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
      expect(regex.hasMatch('test@example.com'), isTrue);
      expect(regex.hasMatch('user.name@domain.np'), isTrue);
    });

    test('email validation rejects invalid email', () {
      final regex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
      expect(regex.hasMatch('notanemail'), isFalse);
      expect(regex.hasMatch('missing@domain'), isFalse);
      expect(regex.hasMatch(''), isFalse);
    });

    test('password validation requires minimum 8 characters', () {
      expect('1234567'.length >= 8, isFalse);
      expect('12345678'.length >= 8, isTrue);
    });

    test('password validation requires at least one digit', () {
      expect(RegExp(r'\d').hasMatch('password'), isFalse);
      expect(RegExp(r'\d').hasMatch('password1'), isTrue);
    });
  });
}
