# Product comparison — what a real khata app has

A pass over the products a Nepali shopkeeper would otherwise install, and what
we took from each. Written 2026-10-18, after the offline-write and
language/calendar work.

## Who we compared against

| Product | Where it wins | What we took |
|---|---|---|
| **Khatabook** (IN) | Dead-simple ledger; the *person* is the home screen, not a menu; huge type; one-tap "you gave / you got" | Quick actions above the numbers; party-first wording ("To collect", "To pay") |
| **Vyapar** (IN) | Polished invoice/POS flow, GST reports, WhatsApp-first sharing, colored action tiles | Quick-action row on the dashboard; tonal icon chips instead of flat tiles |
| **Khata / KhataBook Nepal** | Nepali + BS dates everywhere, simple daily totals | BS-first display option, "today" in the header |
| **OkCredit** (IN) | Reminder nudges for receivables, extremely light UI | Reminder module (already built) + "To collect" prominence |
| **Tally** | Double-entry correctness, audit trail | Our ledger + soft-delete history already match this |
| **Zoho Books / QuickBooks** | Reports depth, multi-currency, bank feeds | Reports exist (sales/P&L/expense/income/stock/receivables); bank feeds are out of scope |
| **Square POS / Shopify POS** | Fast repeated entry, barcode, receipt printing | Barcode field exists; scanning/printing not yet |

## Where we were behind (and what changed now)

| Gap | Before | Now |
|---|---|---|
| Daily actions buried | Home was a 13-tile grid; starting a sale took a scroll and a hunt | **Quick actions** row: New sale · Add expense · Record payment · Add customer |
| Header carried no information | App bar said "Digital Khata" under the shop name | It shows **today's date in the chosen calendar** (AD or BS) |
| Theme looked like a Material demo | Corporate blue, grey cards, heavy 1px elevation everywhere | **Money-green brand + warm paper background**, white cards with a hairline border, amber accent reserved for money-out, 16px radii, tinted input fields |
| Empty screens read like bugs | A single grey sentence | **`EmptyState`**: soft icon medallion, one line, and the action that fixes it ("Add product", "Add customer") |
| Dark mode was an afterthought | Pure `#121212` + `#1E1E1E` | Tuned surfaces (`#0F1312` / `#1E2422`), readable emerald (`#3DDC97`), themed nav bar and sheets |

## Where we are still behind (ranked, not started)

1. **WhatsApp sharing of a khata reminder / invoice** — every Indian competitor
   does this and it is the #1 collection tool. `share_plus` is already wired for
   PDFs, so this is a small addition: build a `wa.me` deep link with the balance.
2. **Barcode scanning** — the field exists but there is no camera scan. Needs a
   platform project (`mobile_scanner`), so it is blocked on the same thing FCM is.
3. **Receipt printing** (Bluetooth 58 mm) — table stakes for a counter shop.
4. **Recurring invoices / auto-reminders** — reminders exist, but a recurring
   invoice does not.
5. **Multi-currency** — NPR only. A border shop may bill in INR; the schema has a
   currency field on `Business` but nothing reads it.
6. **Bank feed / reconciliation** — bank accounts exist as a payment target, not
   as a statement to reconcile against.
7. **Onboarding tour** — a first-run shop sees an empty dashboard with no
   explanation. A 3-step "add a product → add a customer → make a sale" would
   lift activation more than any visual change.
8. **Bulk actions on lists** (multi-select delete/archive) — competitors have it;
   ours is one-row-at-a-time.

## Deliberate differences

- **No ads, no credit-score upselling.** Khatabook/OkCredit monetise the ledger
  by selling lending; a paid khata should not.
- **Offline writes** — none of the Indian apps handle a lost connection as
  carefully (queue + temp ids + conflict surface). This is our real edge.
- **BS calendar as a first-class choice**, not a display toggle buried in
  settings.

---

## Second pass (2026-10-18, evening) — structure, not just surface

The first pass restyled the screens but left the app's **shape** wrong: one
home screen with twenty tiles and no bottom bar, and every navigation a
`context.go` that replaced the stack. That is the opposite of how the products
we are competing with are built, so this pass copied their structure.

### What each product does that we now do

| Product | The pattern | What changed here |
|---|---|---|
| **Khatabook** | Person-first khata: tap a name → their ledger, not an edit form | Party row opens the khata; edit moved into a per-row menu |
| **Vyapar / Karobar** | Five-item bottom bar, everything else under More | `StatefulShellRoute` with Home · Sales · Parties · Items · More |
| **OkCredit** | Today's number is the hero of the home screen | A single high-contrast "Today's sales" card replaces four equal stat boxes |
| **Khatabook / OkCredit** | A "what just happened" feed on home | `Recent activity` — last five sales with paid/unpaid state |
| **Vyapar** | Alert strip for stock and pending work | Low-stock and unsynced-write pills, only when non-zero |
| **Karobar / Khatabook** | WhatsApp is the collection channel | Share a written payment reminder from any party row |
| **All of them** | A new shop is walked through the first three steps | `Get started` card with live checkmarks (product → customer → sale) |

### Also fixed while in there

- **No screen had a back button.** Every navigation used `context.go`, which
  replaces the whole stack, so a pushed form was a dead end on Android. Now
  `openRoute()` pushes everything except tab roots.
- **One colour for money direction.** `MoneyColors` is a `ThemeExtension`
  (`positive` / `negative` / `warning` / `neutral` + tints), read via
  `context.money`. "To collect" was blue on the dashboard, red in the customer
  list and green in a report; the design doc has always said green-in/red-out.
- **`Advance`, `Credit` and `bal` were hardcoded English** in the party list and
  the ledger — visible as untranslated words in the Nepali UI.
- **`test/theme_test.dart` was red**: it still asserted the old corporate-blue
  primary (`#1A5276`) two palettes after the theme moved on.
- **FABs were pale tonal surfaces** (they read as disabled). Now filled with the
  brand colour, which is the primary action on every list screen.
- **No onboarding at all** — gap #7 from the first pass. A fresh install now
  opens a three-slide welcome that is skippable, and the language choice lives
  on that screen (and on sign-in and sign-up) instead of being buried in
  Profile.
- **The language choice reset on restart.** `applyUserLocale` overwrote the
  saved device preference with the account's `locale` on every sign-in, so a
  shopkeeper who set नेपाली got English back after a relaunch. A device choice
  now wins (and is pushed to the account so a new device inherits it). The
  earlier "persists across reload" check had passed because `page.goto('#/…')`
  is a same-document navigation — it never reloaded.

### Still open (unchanged priorities)

1. Barcode scanning and 58 mm receipt printing — both need a platform project.
2. `wa.me` deep link straight into a chat (needs `url_launcher`); the share
   sheet reaches the same place in one extra tap.
3. Recurring invoices; multi-currency; bank-feed reconciliation.
4. Bill-image capture on transactions; invoice logo/signature in the PDF.
5. FCM push, payment providers, SMS/email — all credential-gated.
