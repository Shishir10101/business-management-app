import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app ships in English regardless of the device locale; the user opts
/// into Nepali or Hindi explicitly from Profile.
///
/// This is a deliberate choice, not an oversight: English is the language the
/// existing screenshots, demo script and widget tests assume. Following the
/// device locale would make the app switch languages mid-demo on a Nepali
/// phone.
const appLocales = <Locale>[
  Locale('en'),
  Locale('ne'),
  Locale('hi'),
];

const defaultAppLocale = Locale('en');

/// True for a language code the app actually ships translations for.
bool isSupportedLocaleCode(String? code) =>
    appLocales.any((locale) => locale.languageCode == code);

/// Human label for a locale, shown in the language switcher. Each language is
/// written in itself, which is how a user recognises their own.
String localeLabel(Locale locale) {
  switch (locale.languageCode) {
    case 'ne':
      return 'नेपाली';
    case 'hi':
      return 'हिन्दी';
    default:
      return 'English';
  }
}

/// The active UI locale.
///
/// Persisted on the device so the choice survives a restart *and* applied from
/// the account's saved `locale` on sign-in — the two used to be unrelated,
/// which is why switching the language appeared to do nothing.
class LocaleController extends StateNotifier<Locale> {
  LocaleController() : super(defaultAppLocale);

  static const storageKey = 'ui_locale';

  /// True once this device has a language of its own — either restored from
  /// disk or picked by the user in this session.
  ///
  /// The account also carries a `locale`, and it used to win on every launch:
  /// a shopkeeper who set नेपाली on their phone got English back the moment the
  /// session restored, because `applyUserLocale` overwrote the saved choice.
  /// A language chosen on this device is a device preference, so it wins; the
  /// account value is only a fallback for a fresh install.
  bool _deviceChoice = false;

  /// Whether this device has an explicit language (exposed for tests).
  bool get hasDeviceChoice => _deviceChoice;

  /// Reads the last choice from disk. Safe to call more than once.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(storageKey);
      if (isSupportedLocaleCode(saved)) {
        _deviceChoice = true;
        if (saved != state.languageCode) state = Locale(saved!);
      }
    } catch (_) {
      // No storage available: stay on the default.
    }
  }

  /// Switches the UI immediately and remembers the choice.
  Future<void> setLocale(Locale locale) async {
    if (!isSupportedLocaleCode(locale.languageCode)) return;
    _deviceChoice = true;
    if (state.languageCode != locale.languageCode) state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, locale.languageCode);
    } catch (_) {
      // The in-memory choice still applies for this session.
    }
  }

  /// Applies the locale saved on the account, when the app learns it (sign-in,
  /// profile refresh). Ignores unsupported or missing values so a half-filled
  /// profile cannot force the UI back to English.
  Future<void> applyUserLocale(String? code) async {
    if (_deviceChoice) return;
    if (!isSupportedLocaleCode(code)) return;
    if (state.languageCode == code) return;
    await setLocale(Locale(code!));
  }
}

final localeProvider =
    StateNotifierProvider<LocaleController, Locale>((ref) {
  return LocaleController();
});
