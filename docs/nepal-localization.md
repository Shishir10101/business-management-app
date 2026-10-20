# Nepal Localization

> Nepal-first design: NPR currency, Nepali + English languages,
> Bikram Sambat (BS) calendar alongside Gregorian (AD), Nepal-specific
> phone/address formatting.

---

## 1. Language Support

### 1.1 Supported Locales

| Locale Code | Language | Script |
|-------------|----------|--------|
| `ne` | Nepali | Devanagari |
| `en` | English | Latin |

### 1.2 Architecture

Flutter's built-in `intl` + ARB file system:

```
lib/l10n/
├── app_en.arb       # English strings
├── app_ne.arb       # Nepali strings
└── l10n.dart        # Code generation config
```

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

### 1.3 String Management Rules

- **Never hardcode user-facing strings in widgets.** Always use `AppLocalizations`.
- Keys follow `{feature}.{screen}.{element}` pattern: `sales.form.customerName`
- Placeholders for dynamic values: `"Hello {name}"` → `helloUser`
- Pluralization handled by ICU MessageFormat

```json
// app_en.arb
{
  "dashboardTodaySales": "Today's Sales",
  "dashboardTotalReceivable": "Total Receivable",
  "@dashboardTotalReceivable": {}
}

// app_ne.arb
{
  "dashboardTodaySales": "आजको बिक्री",
  "dashboardTotalReceivable": "कुल प्राप्य"
}
```

### 1.4 Usage in Widgets

```dart
final l = AppLocalizations.of(context)!;
Text(l.dashboardTodaySales)
```

### 1.5 Extending to New Languages

1. Create `app_{code}.arb` in `lib/l10n/`
2. Add locale to `supportedLocales` in `MaterialApp`
3. Flutter auto-generates the localization class
4. Fonts for the new script must be bundled in `pubspec.yaml`

---

## 2. Currency (NPR)

### 2.1 Formatting

```dart
class MoneyFormatter {
  static String format(int paisa, {String locale = 'en'}) {
    final rupees = paisa / 100.0;
    if (locale == 'ne') {
      // Devanagari numerals + रू prefix
      final nepaliRupees = _toDevanagari(rupees.toStringAsFixed(2));
      return 'रू $nepaliRupees';
    }
    // English numerals + ₨ prefix
    final formatter = NumberFormat.currency(
      locale: 'en_NP',
      symbol: '₨',
      decimalDigits: 2,
    );
    return formatter.format(rupees);
  }

  static String _toDevanagari(String input) {
    const map = {'0': '०', '1': '१', '2': '२', '3': '३', '4': '४',
                 '5': '५', '6': '६', '7': '७', '8': '८', '9': '९', '.': '.'};
    return input.split('').map((c) => map[c] ?? c).join();
  }
}
```

### 2.2 Examples

| Paisa | English (en) | Nepali (ne) |
|-------|-------------|-------------|
| `0` | `₨ 0.00` | `रू ०.००` |
| `50000` | `₨ 500.00` | `रू ५००.००` |
| `123456` | `₨ 1,234.56` | `रू १,२३४.५६` |

### 2.3 Internal Representation

All amounts are stored and transmitted as **integer paisa** (long/int64).
- NPR 1.00 = 100 paisa
- NPR 1,234.56 = 123456 paisa
- No floating-point arithmetic anywhere in the system

---

## 3. Bikram Sambat (BS) Calendar

### 3.1 BS vs AD

| Calendar | Era | Example Date |
|----------|-----|-------------|
| Bikram Sambat (BS) | ~57 years ahead of AD | 2083-06-22 BS |
| Gregorian (AD) | Standard | 2026-10-08 AD |

### 3.2 Conversion

```dart
// Use the `nepali_date` or `nepali_utils` package
// Or implement using a BS calendar data table (days per month vary by year)

import 'package:nepali_utils/nepali_utils.dart';

NepaliDateTime bsDate = NepaliDateTime.fromDateTime(DateTime.now());
// bsDate.year = 2083, bsDate.month = 6, bsDate.day = 22

DateTime adDate = bsDate.toDateTime();
```

### 3.3 BS Month Names

| Month # | Nepali Name | English Name |
|---------|-------------|-------------|
| 1 | बैशाख | Baishakh |
| 2 | जेठ | Jestha |
| 3 | असार | Ashar |
| 4 | साउन | Shrawan |
| 5 | भदौ | Bhadra |
| 6 | असोज | Asoj |
| 7 | कार्तिक | Kartik |
| 8 | मंसिर | Mangsir |
| 9 | पुष | Poush |
| 10 | माघ | Magh |
| 11 | फागुन | Falgun |
| 12 | चैत | Chaitra |

### 3.4 Date Display

Users can choose their preferred calendar in Settings:

| Preference | Display |
|------------|---------|
| BS | `2083-06-22` or `२०८३।६।22` |
| AD | `2026-10-08` |
| Both | `2026-10-08 (2083-06-22)` |

### 3.5 Date Picker

Custom date picker that switches between BS and AD:
- BS picker uses `nepali_date_picker` package or custom implementation
- BS month lengths vary (29-32 days) — must use BS calendar data table
- Fiscal year start/end is configurable in business settings

### 3.6 Server-Side Dates

The API always uses ISO 8601 Gregorian dates. BS conversion is purely a
client-side display concern. This avoids timezone and calendar ambiguity.

---

## 4. Phone Number Formatting

### 4.1 Nepal Phone Formats

| Type | Format | Example |
|------|--------|---------|
| Mobile | +977 9X-XXXXXXX | +977 98-1234567 |
| Mobile (local) | 9X-XXXXXXX | 98-1234567 |
| Landline | +977 0X-XXXXXXX | +977 01-4123456 |
| Landline (local) | 0X-XXXXXXX | 01-4123456 |

### 4.2 Validation

Nepali mobile prefixes: `97`, `98`, `99` (after the leading `9`)
Landline area codes: `01` (Kathmandu), `011`, `021`, `031`, `041`, `051`, etc.

```dart
bool isValidNepaliPhone(String phone) {
  // Normalize: remove spaces, dashes, parentheses
  phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  if (phone.startsWith('+977')) phone = phone.substring(4);
  else if (phone.startsWith('977')) phone = phone.substring(3);
  return RegExp(r'^(9[7-9]\d{7}|0[1-9]\d{6,7})$').hasMatch(phone);
}
```

---

## 5. Nepal Address Structure

Nepal uses: Province → District → Municipality/Rural Municipality → Ward → Street/Tole

```json
{
  "province": "Bagmati",
  "district": "Kathmandu",
  "municipality": "Kathmandu Metropolitan City",
  "wardNumber": "5",
  "tole": "Chabahil"
}
```

The address form adapts:
- Province dropdown (7 provinces)
- District dropdown (filtered by province)
- Municipality/Rural Municipality dropdown (filtered by district)
- Ward number field
- Tole/Street free text

Province/district/municipality data is bundled as a local JSON asset
(no API dependency for this reference data).

---

## 6. Locale Switching

Users can switch language in Settings. The change takes effect immediately
via `Riverpod` state:

```dart
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref);
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._ref) : super(const Locale('en')) {
    _loadSaved();
  }
  // Load from SharedPreferences, switch, persist
}
```

Theme and locale are independent settings (user can have English + dark theme).

---

## 7. Backend Localization

The backend is locale-agnostic:
- All API responses use ISO 8601 dates (Gregorian)
- All money values are integer paisa
- Error messages use machine-readable codes (not localized text)
- The `Accept-Language` header is stored but does not affect API responses

This keeps the API stateless and testable. Localization is 100% client-side.

---

## 8. Nepali Unicode Support

- All text fields must properly handle Devanagari Unicode (UTF-8)
- Search must work with Nepali Unicode text (PostgreSQL `ILIKE` with proper collation)
- Sorting: PostgreSQL collation `und-x-icu` for Unicode-correct ordering
- Drift/SQLite: `COLLATE NOCASE` for case-insensitive search
- No transliteration required — store exactly what the user types

---

## 9. Three Languages, as built (2026-10-18)

| Locale | File | Keys | Notes |
|---|---|---|---|
| English | `app_en.arb` | 769 | template; the fallback and the language of the screenshots |
| नेपाली | `app_ne.arb` | 769 | Devanagari digits for money, counts and dates |
| हिन्दी | `app_hi.arb` | 769 | for the cross-border trade; Latin digits, NPR stays `रु.` |

Parity is exact — `scripts/gen_l10n.py --check` fails if a key is missing from
any ARB, and `check_localizations.py` fails if a page references a key that is
not in the template.

### 9.1 Why switching did not work before

Three separate faults, all fixed:

1. **The switch never reached the app.** The profile dropdown wrote a local
   `_locale` field and only sent it to the API on save; `localeProvider` — the
   provider `MaterialApp.router` watches — was never updated, so no screen ever
   changed language.
2. **It was disabled.** The dropdown was `onChanged: _editing ? … : null`, so it
   did nothing at all until "Edit profile" was pressed.
3. **The stored choice was ignored.** `localeProvider` started at English on
   every launch and nothing read `user.locale`, so a Nepali account opened in
   English while the dropdown *claimed* नेपाली.

Now: `LocaleController` (a `StateNotifier`) is loaded from
`shared_preferences` before the first frame, applied the moment a session
becomes available (`applyUserLocale`), and the dropdown switches instantly
without entering edit mode.

### 9.2 AD / BS calendar choice

`calendarProvider` persists a `CalendarSystem` (AD or BS). It is a *reading*
preference, not an account field: a shopkeeper who thinks in BS wants BS on this
phone even before the profile request returns.

- **Display**: `formatDisplayDate` renders the chosen calendar; `formatOtherDate`
  renders the other one underneath. Every date field shows both, so an
  accountant filing in AD and a shopkeeper reading in BS can share a screen.
- **Input**: `AppDateField` opens the BS picker or Material's AD picker depending
  on the setting. Both return an AD `DateTime` — BS never reaches the wire.
- **Everywhere else**: the list/detail `_date()` helpers call
  `formatDisplayDate`, so a report, a ledger row and a document header all
  follow the same switch.

### 9.3 The off-by-one this uncovered

`nepali_utils` 3.0.8 adds a day to AD→BS on devices in Nepal time (UTC+05:45) —
its "1986 compensation" is applied to every date after 1986. On this machine
`2026-10-18` rendered as **2083-07-02** instead of **2083-07-01**, while BS→AD
was correct. `tryToBs` now converts, round-trips the result and steps back a day
only when the two disagree, so it is correct on any device timezone:

```
2026-10-18 -> BS 2083-07-01 -> AD 2026-10-18   roundtrip ok
2026-04-14 -> BS 2083-01-01 -> AD 2026-04-14   (Baishakh 1)
```

Verified in Chrome: with BS selected the expense form reads "2083-07-01 BS /
2026-10-18" and the BS picker opens (years २०८२–२०८४, months असोज/कार्तिक/मंसिर);
with AD selected the same field reads "2026-10-18 / 2083-07-01 BS" and Material's
Gregorian picker opens. `scripts/e2e/check_language_calendar.py` asserts all of
it (10/10).
