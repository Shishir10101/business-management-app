import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the first-run welcome has been seen.
///
/// Read before the first frame in `main()` (like the locale and calendar) so
/// the router can decide between `/welcome` and `/login` without flashing the
/// wrong screen. Skipping the tour counts as seeing it: a shopkeeper who taps
/// "Skip" should never be shown it again.
class OnboardingController extends StateNotifier<bool> {
  OnboardingController() : super(false);

  static const storageKey = 'welcome_seen';

  /// True once the welcome has been dismissed (finished or skipped).
  bool get seen => state;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(storageKey) ?? false;
    } catch (_) {
      // No storage: show the welcome, it is harmless.
    }
  }

  Future<void> complete() async {
    if (state) return;
    state = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(storageKey, true);
    } catch (_) {
      // In-memory only; the tour may reappear next launch.
    }
  }
}

final onboardingSeenProvider =
    StateNotifierProvider<OnboardingController, bool>((ref) {
  return OnboardingController();
});
