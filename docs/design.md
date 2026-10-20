# UI/UX Design System

> Design language for Nepal Digital Khata.
> Goals: trustworthy, clean, fast, usable for non-technical shop owners,
> works on low-resolution Android devices.

---

## 1. Color Palette

### 1.1 Primary Colors

The brand is a deep money-green on warm paper — the palette a shopkeeper sees in
Khatabook and Vyapar, not a corporate blue. It replaced an earlier `#1A5276`
blue that read as "generic Material demo" on a shop counter.

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| seed / `primary` | `#0B6E4F` (deep emerald) | `#3DDC97` | App bar, FAB, active tab, primary buttons |
| `secondary` | `#E8A33D` (amber) | `#E8A33D` | Reserved for money-out / attention accents |
| `background` | `#F7F5F1` (warm paper) | `#0F1312` | Scaffold background |
| `surface` / card | `#FFFFFF` | `#1E2422` | Cards, sheets, bottom bar |
| card border | `#E6E1D8` | `#2C3431` | Hairline border — depth without shadow |
| field fill | `#F3F0EA` | `#262D2A` | Text field background |

`primary` is passed through `ColorScheme.fromSeed`, so the exact rendered value
is a tonal derivation of the seed, not the seed itself. In dark mode the seed is
the light emerald: the deep green fails contrast on a near-black surface.

### 1.2 Semantic Colors — `MoneyColors`

Money direction is one decision made once, in a `ThemeExtension` on the theme
(`core/theme/app_theme.dart`), read through `context.money`. Before this existed,
"to collect" was blue in one card, `colorScheme.error` in a list row and green in
a report — three colours for one fact.

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `positive` | `#0B6E4F` | `#3DDC97` | Money coming in: sales, receivable, profit |
| `negative` | `#B3261E` | `#FF8A7A` | Money going out: payable, expense, loss |
| `warning` | `#9A6400` | `#FFC15E` | Low stock, waiting writes, overdue |
| `neutral` | `#6B7280` | `#9AA5A0` | Settled, zero balance |
| `positiveTint` | `#E3F2EA` | `#17322A` | Chip / avatar background |
| `negativeTint` | `#FCE9E7` | `#3A211F` | Chip / avatar background |
| `warningTint` | `#FBF0DA` | `#3A2E1A` | Alert pill background |

All money is rendered with tabular figures (`AppTheme.tabularFigures`) so a
column of balances has a straight right edge.

### 1.3 Neutrals

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `bg` | `#FAFAFA` | `#121212` | App background |
| `surface` | `#FFFFFF` | `#1E1E1E` | Cards, sheets |
| `surfaceVariant` | `#F5F5F5` | `#2C2C2C` | List item backgrounds |
| `outline` | `#E0E0E0` | `#3A3A3A` | Dividers, borders |
| `textPrimary` | `#212121` | `#F5F5F5` | Body text |
| `textSecondary` | `#757575` | `#AAAAAA` | Hints, captions |
| `textDisabled` | `#BDBDBD` | `#666666` | Disabled text |

### 1.4 Financial Color Convention (Nepali market)

Following Nepali stock market convention (red = gain, green = loss),
but for business ledger context:

| Concept | Color | Rationale |
|---------|-------|-----------|
| Money owed TO us (receivable) | Green (`success`) | Positive for business |
| Money we owe (payable) | Red (`error`) | Negative for business |
| Income | Green | Positive |
| Expense | Red/Orange | Negative |
| Stock increase | Green | Positive |
| Stock decrease | Red | Negative |

> Note: This is explicitly NOT US stock market convention. In Nepal,
> green = positive/gain, red = negative/loss for business context.
> (In Nepali stock exchange, rising stocks are shown in red — but for
> a business ledger, the semantic clarity of green=positive is more
> important for non-technical users.)

---

## 2. Typography

### 2.1 Font Families

| Script | Font | Weights |
|--------|------|---------|
| Latin (English) | Poppins | 400, 500, 600, 700 |
| Devanagari (Nepali) | Noto Sans Devanagari | 400, 500, 600, 700 |
| Numerals | Poppins (tabular) | 400, 600 |

Noto Sans Devanagari is used for Nepali text rendering. Poppins handles
all Latin text and numbers. The font switch is automatic based on locale.

### 2.2 Type Scale

| Token | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| `displayLarge` | 28sp | 700 | 36sp | Dashboard totals |
| `headlineLarge` | 24sp | 600 | 32sp | Page titles |
| `headlineMedium` | 20sp | 600 | 28sp | Section headers |
| `titleLarge` | 18sp | 600 | 24sp | Card titles |
| `titleMedium` | 16sp | 500 | 22sp | List item titles |
| `bodyLarge` | 16sp | 400 | 24sp | Primary body text |
| `bodyMedium` | 14sp | 400 | 20sp | Secondary text |
| `labelLarge` | 14sp | 500 | 20sp | Button labels |
| `labelMedium` | 12sp | 500 | 16sp | Form labels |
| `caption` | 12sp | 400 | 16sp | Helper text, timestamps |

### 2.3 Number Formatting

- NPR amounts: `₨ 1,234.56` (English) / `रु १,२३४.५६` (Nepali)
- Grouping: South Asian (lakh/crore) optional — default to international grouping
- Negative amounts: prefix `-` or wrap in parentheses `(₨ 500.00)`
- Zero amounts: show `₨ 0.00`, never blank

---

## 3. Spacing & Layout

### 3.1 Spacing Scale

All paddings/margins use a 4dp grid:

| Token | Value |
|-------|-------|
| `xs` | 4dp |
| `sm` | 8dp |
| `md` | 12dp |
| `lg` | 16dp |
| `xl` | 24dp |
| `xxl` | 32dp |
| `xxxl` | 48dp |

### 3.2 Corner Radius

| Token | Value | Usage |
|-------|-------|-------|
| `sm` | 4dp | Small chips, badges |
| `md` | 8dp | Text fields, buttons |
| `lg` | 12dp | Cards |
| `xl` | 16dp | Bottom sheets |
| `full` | 9999dp | Circular avatars, FAB |

### 3.3 Screen Layout

- Max content width on tablet: 720dp (centered on larger screens)
- Bottom navigation: 5 items max (Dashboard, Transactions, Khata, Reports, More)
- FAB for primary create action (context-dependent: New Sale, New Expense, etc.)
- Min touch target: 48dp × 48dp
- Min tap spacing: 8dp

---

## 4. Component Library

### 4.1 Core Components

| Component | Variants | Notes |
|-----------|---------|-------|
| `KhataButton` | primary, secondary, outline, text, danger | Min height 48dp |
| `KhataTextField` | text, number, phone, multiline | Floating label, helper text, error text |
| `KhataDropdown` | single, searchable | Bottom-sheet picker on mobile |
| `KhataCard` | default, elevated, outlined | 12dp radius, subtle shadow |
| `KhataListTile` | default, dense, with trailing | 56-72dp height |
| `KhataChip` | filter, status, info | Color-coded by status |
| `KhataBottomSheet` | modal, persistent | Drag handle, max 80% height |
| `KhataAppBar` | default, search, tabbed | Center title, back arrow |
| `KhataFab` | default, extended, mini | Bottom-right, 16dp margin |
| `KhataTabBar` | top, bottom (nav) | Underline indicator |
| `KhataSnackBar` | info, success, error | 4s duration, action button |
| `KhataDialog` | alert, confirm, form | Dismissible on outside tap for non-destructive |

### 4.2 Domain-Specific Components

| Component | Purpose |
|-----------|---------|
| `DashboardStatCard` | Today's Sales / Purchases / Expenses / Profit |
| `AmountText` | Formats paisa int → NPR string with locale |
| `DateRangePicker` | AD/BS toggle, presets (Today, This Week, This Month) |
| `PartyPicker` | Search + select customer/supplier |
| `ProductPicker` | Search by name/SKU/barcode, add line item |
| `LineItemListEditor` | Add/remove/edit sale/purchase items |
| `LedgerTimeline` | Transaction history with running balance |
| `StockBadge` | Shows current stock, color-coded (ok/low/zero) |
| `PaymentStatusChip` | Paid (green) / Partial (amber) / Unpaid (red) |
| `SyncStatusIndicator` | Synced (check) / Pending (clock) / Failed (alert) |

---

## 5. State Patterns

Every data-driven screen must handle all four states:

### 5.1 Empty State

```
┌──────────────────────┐
│                      │
│      [icon]          │
│                      │
│  No sales yet        │
│                      │
│  Create your first   │
│  sale to get started │
│                      │
│  [+ New Sale]        │
│                      │
└──────────────────────┘
```

- Always include a call-to-action button
- Icon + title + description + CTA
- Never show a blank screen

### 5.2 Loading State

- List: shimmer placeholders (not spinners) for better perceived speed
- Detail: skeleton layout matching final content shape
- Button: disable + show spinner inside, prevent double-tap
- Full-screen: only for initial load or auth

### 5.3 Error State

```
┌──────────────────────┐
│                      │
│      [alert]         │
│                      │
│  Failed to load       │
│                      │
│  Check your internet │
│  connection and try  │
│  again.              │
│                      │
│  [Retry]             │
│                      │
└──────────────────────┘
```

- Show user-friendly message (not stack trace)
- Retry button
- If offline, show "You're offline" with cached data if available

### 5.4 Confirmation State

For destructive or financial actions:

```
┌──────────────────────┐
│  Delete Sale #00123? │
│                      │
│  This will create    │
│  reverse entries     │
│  in the ledger.      │
│                      │
│  This action cannot  │
│  be undone.          │
│                      │
│  [Cancel]  [Delete]  │
└──────────────────────┘
```

- Always require confirmation for: delete, payment, balance adjustment
- Show the financial impact in plain language
- Primary action uses danger color for destructive ops

---

## 6. Navigation

### 6.0 First run — language before credentials

`/welcome` is the first screen on a fresh install: three slides, the language
choice, and two exits (**Skip** and **Get started**) that both mark the tour as
seen. The chips sit *above* the pager and apply instantly, so the slides
re-render in the chosen language — the clearest proof the switch worked.

The same `LanguageMenuButton` (translate icon + current code) is on sign-in and
sign-up, so the language is reachable at every point before the app proper.
`OnboardingController` persists `welcome_seen` and is loaded before `runApp`,
which is what lets the router choose `/welcome` vs `/login` without a flash.

"Try the demo" only exists in builds compiled with
`--dart-define=DEMO_EMAIL=… --dart-define=DEMO_PASSWORD=…`; no credentials are
in source.

### 6.1 Bottom Navigation (5 tabs)

Built as a `StatefulShellRoute.indexedStack` (`features/shell/`). Each branch
keeps its own navigator, so switching tabs preserves scroll position and any
screen pushed inside that branch.

| Tab | Icon | Branch routes |
|-----|------|---------------|
| Home | home | `/` |
| Sales | receipt_long | `/sales` |
| Parties | people | `/customers`, `/suppliers` (segmented toggle) |
| Items | inventory_2 | `/products`, `/inventory` |
| More | grid_view | `/more` |

Suppliers and Inventory share the Parties/Items branches instead of taking a
sixth tab: they are the same job seen from the other side, and six tabs truncate
labels in Nepali.

### 6.2 "More" page

Not a bottom sheet — a grouped scroll: the shop header (name + both balances,
tap to switch business), then **Sales & documents**, **Items & stock**,
**Insights**, **Tools & settings**, **Account**. It is the only place the
overflow lives; the home screen no longer carries a 20-tile grid.

### 6.2.1 Push vs replace

`openRoute(context, path)` (`core/router/nav.dart`) is the one navigation entry
point. Tab roots replace the stack; everything else **pushes**, so a form or
detail screen always has a back arrow. The app previously called `context.go`
everywhere, which meant no screen ever had a back button.

### 6.3 Deep Linking

Routes use GoRouter with full URL paths:
- `/sales/34` → sale detail
- `/customers/5/ledger` → customer ledger
- `/reports/profit-loss` → P&L report

---

## 7. Theming

### 7.1 Theme Structure

```dart
class KhataTheme {
  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A5276),
      brightness: Brightness.light,
    ),
    textTheme: _buildTextTheme(Brightness.light),
    ...
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E86C1),
      brightness: Brightness.dark,
    ),
    textTheme: _buildTextTheme(Brightness.dark),
    ...
  );
}
```

### 7.2 Theme Persistence

User's theme preference (light/dark/system) stored in SharedPreferences.
Defaults to system setting.

---

## 8. Accessibility

| Guideline | Implementation |
|-----------|---------------|
| Min touch target | 48dp × 48dp |
| Contrast ratio | WCAG AA (4.5:1 for body, 3:1 for large) |
| Semantics | Semantic labels on all interactive elements |
| Font scaling | Respect `MediaQuery.textScaleFactor` up to 1.5x |
| Screen reader | Test with TalkBack on Android |

---

## 9. Performance Budget

| Metric | Target |
|--------|--------|
| Cold start (first frame) | < 2s on mid-range Android |
| Page navigation | < 300ms perceived |
| List scroll | 60fps (no jank) |
| Local DB query | < 50ms |
| Image load | < 500ms (cached after first load) |

### Low-Resolution Device Support

- Support down to 360×640 (5.0" WVGA)
- Test on: Android 10 emulator, 1GB RAM, 32GB storage
- No blur effects or heavy shadows on low-end
- Images: WebP, 2x density max
- Avoid large font sizes that cause horizontal scroll
