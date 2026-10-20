import 'package:flutter_test/flutter_test.dart';
import 'package:khata/core/update/app_version.dart';

void main() {
  group('AppVersion.tryParse', () {
    test('accepts a bare version', () {
      expect(AppVersion.tryParse('1.2.3'), const AppVersion(1, 2, 3));
    });

    test('accepts a git tag with the v prefix', () {
      expect(AppVersion.tryParse('v1.2.3'), const AppVersion(1, 2, 3));
    });

    test('ignores the Flutter build number', () {
      // pubspec says 1.0.0+1; the +1 must not make it a different version.
      expect(AppVersion.tryParse('1.0.0+1'), const AppVersion(1, 0, 0));
    });

    test('ignores a prerelease suffix', () {
      expect(AppVersion.tryParse('v1.2.3-beta.4'), const AppVersion(1, 2, 3));
    });

    test('rejects garbage rather than guessing', () {
      expect(AppVersion.tryParse(null), isNull);
      expect(AppVersion.tryParse(''), isNull);
      expect(AppVersion.tryParse('latest'), isNull);
      expect(AppVersion.tryParse('1.2'), isNull);
    });
  });

  group('ordering', () {
    test('compares numerically, not lexically', () {
      // The whole reason this class exists: "1.10.0" < "1.9.0" as strings.
      final newer = AppVersion.tryParse('v1.10.0')!;
      final older = AppVersion.tryParse('v1.9.0')!;
      expect(newer > older, isTrue);
      expect(older < newer, isTrue);
      expect('1.10.0'.compareTo('1.9.0') < 0, isTrue,
          reason: 'string comparison gets this backwards');
    });

    test('walks major, then minor, then patch', () {
      expect(const AppVersion(2, 0, 0) > const AppVersion(1, 99, 99), isTrue);
      expect(const AppVersion(1, 2, 0) > const AppVersion(1, 1, 99), isTrue);
      expect(const AppVersion(1, 1, 2) > const AppVersion(1, 1, 1), isTrue);
    });

    test('equal versions compare as equal', () {
      expect(const AppVersion(1, 0, 0).compareTo(const AppVersion(1, 0, 0)), 0);
      expect(const AppVersion(1, 0, 0) > const AppVersion(1, 0, 0), isFalse);
    });

    test('a release newer than the installed build is detected', () {
      final installed = AppVersion.tryParse('1.0.0')!;
      expect(AppVersion.tryParse('v1.0.1')! > installed, isTrue);
      expect(AppVersion.tryParse('v1.0.0')! > installed, isFalse,
          reason: 're-installing the same version must not prompt');
      expect(AppVersion.tryParse('v0.9.9')! > installed, isFalse);
    });
  });

  test('toString round-trips through tryParse', () {
    const version = AppVersion(3, 14, 1);
    expect(AppVersion.tryParse(version.toString()), version);
  });
}
