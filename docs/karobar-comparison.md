# Khata vs Karobar — competitive comparison

**Compared against:** Karobar – Nepali Digital Khata (`com.bytecaretech.merokarobar`),
developed by ByteCare Technology / BizSphere. Researched from its Play Store and
App Store listings and the developer's own site on 2026-10-16.

*Caveat, stated plainly: this is a comparison against Karobar's **published
feature list**, not a hands-on evaluation. The Play Store does not permit a
direct APK download, so the app was not installed or instrumented here. Every
"Karobar has / lacks" claim below comes from its own marketing copy; every
"Khata has / lacks" claim was verified against this repository's code.*

## Scale and positioning

| | Karobar | Khata |
|---|---|---|
| Developer | ByteCare Technology (now BizSphere) | This project |
| Reach | 200,000+ businesses in Nepal (developer's claim) | Pre-launch |
| Platforms | Android, iOS, web | Android, iOS, **web**, + admin console |
| Positioning | All-in-one business management for Nepali SMEs | Digital khata, sales, purchases, inventory, invoicing, reporting |

Karobar is a mature commercial product with a large installed base. Khata is an
academic/MVP project with a cleaner architecture and a few things Karobar does
not have (a real platform admin console, an offline-first sync engine, a
province/district address model).

## Feature-by-feature

### Where Khata is ahead

| Capability | Khata | Karobar |
|---|---|---|
| Offline-first sync engine | Snapshot cache for reads + push/pull delta protocol with conflict records (write queueing still pending) | "Works offline & online" (no detail published) |
| Platform admin console | Built (`Khata.Admin`): cross-tenant user/business management, audit log, feature flags, support tickets | "Desktop login" for business users only |
| Nepal address model | All 7 provinces, 77 districts, cascading municipality dropdowns | Not mentioned |
| BS date picker | Native BS year/month/day wheels with real month lengths, plus a BS range picker | "Nepali calendar" (no detail) |
| Tenant isolation | EF global query filter, enforced by 350 integration tests | Not verifiable |
| Localization | 761 ARB keys, exact en/ne parity, verified by a checker | Nepali language |
| Test coverage | 350 backend + 130 mobile unit/widget tests, browser-verified end to end | Not verifiable |

### Where we are at parity

| Capability | Notes |
|---|---|
| Multi-business | Both support it |
| Staff roles & permissions | Ours: 7 seeded roles with granular permission codes |
| Khata / ledgers | Customer and supplier ledgers with balances |
| Sales, purchases, expenses, income | Both |
| Inventory | Categories, low-stock alerts, stock movements |
| Invoicing & quotations | Both generate and share |
| Reports | Ours: 6 report types (sales, profit & loss, expenses, income, stock valuation, receivable/payable) with date ranges. Theirs: "20+ reports" — almost certainly the same data sliced more ways |
| Wholesale pricing | We have cost / selling / wholesale on every product |
| Payment reminders | We have reminders with due dates and repeat options; delivery is in-app, push needs a Firebase project |
| Backup | Ours: full JSON backup + restore with idempotency guards |
| Business logo | `LogoUrl` exists on the business in both |

### Where Karobar is ahead (our gaps)

| Gap | What Karobar advertises | Our status |
|---|---|---|
| **Bill image capture** | "Take photos of paper bills and store them securely" | Product images only — nothing attaches to a transaction |
| **Invoice branding in the PDF** | Logo, signature, multiple style options | PDF generates, and `LogoUrl` exists on the business, but the generator does not use it; no signature, no styles |
| **Excel data import** | "Import existing customer and product data from Excel" | CSV import for products and customers (template, preview, all-or-nothing); `.xlsx` not supported yet |
| **Share transaction links** | "Send your customers an online link to view their transactions" | Nothing — would need a public web view |
| **Personal finance** | Track personal income, expenses, credits | Nothing |
| **Business & greeting cards** | Share personalised cards to customers | Nothing |

## What this says about priorities

Karobar's differentiators are **convenience and trust**, not accounting depth:
attach the paper bill, compute the EMI, import last year's spreadsheet, share a
transaction link. Those are the friction points of a Nepali shopkeeper who is
replacing a paper bahi khata — and they are exactly what remains in the gap table.

Khata's differentiators are **architecture**: a real sync engine, enforced
tenant isolation, a test suite, and an admin console. Those matter for a
platform, not for the shopkeeper's first ten minutes.

The honest read: Karobar still wins on day-one usability, Khata wins on
engineering. The work below has been closing the highest-value usability gaps
without giving up the architecture.

## Closed in response (this pass)

1. **Business calculators** — EMI, simple/compound interest, profit margin.
   Pure Dart domain logic with unit tests; no backend needed.
2. **App lock** — PIN stored in secure storage, enforced on app resume and when
   the app is backgrounded.
3. **Bank account management** — the previously dead `BusinessBankAccount`
   entity wired end to end: API, service, mobile list/form, and payment history
   per account.
4. **CSV import** — products and customers, with a copyable template, a dry-run
   preview, all-or-nothing commit, and a "never overwrite" rule. Validation
   reuses the very same FluentValidation validators the write endpoints use, so
   an imported row is held to exactly the standard a typed row is.
5. **Nepal number formatting** — every amount is now grouped in the lakh/crore
   convention (Rs. 1,23,456.00) instead of Western 3-digit grouping, with
   Devanagari digits in the Nepali locale.
6. **Offline reads** — product, customer and supplier lists fall back to a
   snapshot cache on a network error, with a note telling the user the copy is
   saved rather than live.
7. **Routing polish** — an unmatched location now shows a localized,
   themed "page not found" screen with a way back, instead of go_router's
   default English-only screen that prints the raw exception.

Still open, deliberately not attempted here because they need infrastructure
Karobar has and we do not:

- **Share transaction links** — needs a public, unauthenticated web view of a
  customer's ledger, which is a new attack surface and a hosting decision.
- **Excel (`.xlsx`) import** — the CSV importer above is the hard 80%; an
  `.xlsx` reader is a parser swap, not a redesign.
- **Bill image capture** — needs file storage wired into the API (an
  `IFileStorage` abstraction already exists), plus attachment rows on
  transactions.
- **Invoice logo/signature** — the field exists; it needs the PDF generator
  to consume it and a signature asset per business.
- **Personal finance** — a separate module, not a patch.
- **Offline writes** — reads fall back to the cache, but every save still goes
  straight to the API. Writes need the sync queue wired into the repositories.
