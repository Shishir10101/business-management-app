import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/nepali_date_utils.dart';

/// The calendar the UI reads and writes dates in (AD / BS).
///
/// Persisted on the device, because it is a reading preference rather than an
/// account setting: a shopkeeper who thinks in BS wants BS on this phone even
/// before the profile request comes back.
class CalendarController extends StateNotifier<CalendarSystem> {
  CalendarController() : super(CalendarSystem.ad) {
    // Keep the formatter in step from the very first frame.
    setActiveCalendar(state);
  }

  static const storageKey = 'ui_calendar';

  /// Reads the saved preference. Safe to call more than once.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(storageKey);
      if (saved == 'bs') await setCalendar(CalendarSystem.bs);
      if (saved == 'ad') await setCalendar(CalendarSystem.ad);
    } catch (_) {
      // No storage (browser without it, or a locked profile): keep AD.
    }
  }

  Future<void> setCalendar(CalendarSystem calendar) async {
    setActiveCalendar(calendar);
    if (state != calendar) state = calendar;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        storageKey,
        calendar == CalendarSystem.bs ? 'bs' : 'ad',
      );
    } catch (_) {
      // The in-memory choice still applies for this session.
    }
  }

  Future<void> toggle() => setCalendar(
        state == CalendarSystem.bs ? CalendarSystem.ad : CalendarSystem.bs,
      );
}

final calendarProvider =
    StateNotifierProvider<CalendarController, CalendarSystem>((ref) {
  return CalendarController();
});
