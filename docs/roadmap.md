# Roadmap

> Phased implementation plan for Nepal Digital Khata.
> Each phase must be stable before moving to the next.

---

## Phase Overview

| Phase | Focus | Status |
|-------|-------|--------|
| 1 | Foundation: Auth, DB, API, Flutter arch | Complete |
| 2 | Business setup, user profile, business switching | Complete |
| 3 | Products, categories, inventory | Complete |
| 4 | Customers, suppliers, digital khata | Complete |
| 5 | Sales, purchases, expenses, income | Complete |
| 6 | Payments, ledger, balances | Complete |
| 7 | Invoices, PDF, sharing | Complete |
| 8 | Dashboard, reports | Complete |
| 9 | Offline synchronization | Complete (reads + writes for the push-supported entities) |
| 10 | Notifications, reminders, backup | Complete (FCM push pending) |
| 11 | Nepali localization, BS calendar, polishing | Complete |
| 12 | Admin web, advanced features | Admin console + backend complete (payment/SMS/email integrations pending credentials) |

---

## Phase 1: Project Foundation

**Goal:** Working auth + database + API skeleton + Flutter project scaffold.

### Backend
- [x] Create .NET solution with 4 projects (Domain, Application, Infrastructure, Api)
- [x] Configure `Directory.Build.props` (nullable, treat warnings as errors)
- [x] Set up EF Core with PostgreSQL (Npgsql provider)
- [x] Create `AppUser`, `AppRole`, `Permission` entities
- [x] Configure ASP.NET Core Identity with custom user/role classes
- [x] Implement JWT token service (access + refresh)
- [x] Implement auth controller (register, login, refresh, logout, me)
- [x] Implement `ICurrentUserService` (resolves user/business from JWT)
- [x] Tenant isolation (EF global query filter on `IBusinessEntity.BusinessId`)
- [x] Exception handling → ProblemDetails (`GlobalExceptionHandler`)
- [x] FluentValidation pipeline
- [x] Create first EF Core migration
- [x] Set up Docker Compose for local PostgreSQL
- [x] Write unit tests for JWT token service
- [x] Write integration tests for auth endpoints

### Flutter
- [x] Create Flutter project with `pubspec.yaml` (Riverpod, Dio, Drift, GoRouter)
- [x] Set up feature-based folder structure
- [x] Configure `analysis_options.yaml` (lint rules)
- [x] Create core layer: network (Dio + interceptors), database (Drift schema), router, theme
- [x] Create auth feature: data (auth datasource, repository), domain (entities, usecases), presentation (login, register pages)
- [x] Implement secure token storage (`flutter_secure_storage`)
- [x] Implement auth state management (Riverpod StateNotifier)
- [x] Implement auth redirect in GoRouter
- [x] Drift schema skeleton (`core/database/app_database.dart`)
- [x] Write widget tests for login form
- [x] Write unit tests for auth repository logic (validators, token service)

---

## Phase 2: Business Setup

**Goal:** Users can create a business, switch between multiple businesses.

- [x] Backend: `Business`, `BusinessMember` entities + endpoints
- [x] Backend: Business switching endpoint (issues new JWT with `bid` claim)
- [x] Backend: Role/permission seeding (system roles)
- [x] Flutter: Business setup/creation flow
- [x] Flutter: Business switcher UI
- [x] Flutter: User profile page
- [x] Flutter: Staff management page (invite, roles)
- [x] Tests: business isolation (cross-business access returns 404)
- [x] Tests: permission enforcement

---

## Phase 3: Products & Inventory

**Goal:** Full product catalog + inventory management.

- [x] Backend: `Product`, `ProductCategory`, `Unit`, `Stock`, `StockMovement` entities
- [x] Backend: CRUD endpoints for products, categories, units
- [x] Backend: Inventory endpoints (list, adjust, movement history)
- [x] Backend: Low-stock query
- [x] Flutter: Product list with search (name, SKU, barcode)
- [x] Flutter: Product form (add/edit)
- [x] Flutter: Category management
- [x] Flutter: Unit management
- [x] Flutter: Inventory dashboard (stock levels, low stock)
- [x] Flutter: Stock adjustment flow
- [x] Flutter: Stock movement history
- [x] Tests: stock movement immutability
- [x] Tests: stock calculation correctness

---

## Phase 4: Customers, Suppliers, Khata

**Goal:** Party management + digital ledger. **Status: Complete.**

- [x] Backend: `Customer`, `Supplier` entities + endpoints
- [x] Backend: `LedgerAccount`, `LedgerTransaction` entities
- [x] Backend: Ledger endpoints (customer ledger, supplier ledger)
- [x] Backend: Opening balance → ledger account + opening transaction
- [x] Flutter: Customer list + search (name, phone)
- [x] Flutter: Customer form (with opening balance)
- [x] Flutter: Supplier list + search
- [x] Flutter: Supplier form
- [x] Flutter: Customer/supplier detail with ledger timeline
- [x] Flutter: Balance display (opening, debit, credit, closing)
- [x] Tests: ledger transaction immutability
- [x] Tests: balance calculation correctness

**Implemented:** `Parties.cs` (Customer, Supplier, LedgerAccount,
LedgerTransaction), migration `AddCustomersSuppliersAndLedger`, `PartyService`
(customer/supplier CRUD + ledger), controllers `/api/customers`,
`/api/suppliers` (+ `/{id}/ledger`) with `customers.*` / `suppliers.*`
permissions. Flutter `parties` feature (list, form, ledger page) + router
routes + home tiles. 101 backend tests green (26 new).

---

## Phase 5: Sales, Purchases, Expenses, Income

**Goal:** Core transactional operations. **Status: Complete.**

- [x] Backend: `Sale`, `SaleItem` entities + endpoints
- [x] Backend: `Purchase`, `PurchaseItem` entities + endpoints
- [x] Backend: `Expense`, `Income` entities + endpoints
- [x] Backend: Sale create workflow (stock, ledger, payment, invoice number)
- [x] Backend: Purchase create workflow (stock, ledger, payment)
- [x] Backend: Sale/Purchase delete (reverse entries)
- [x] Backend: Invoice number generation (atomic sequence)
- [x] Flutter: Sale form (product picker, line items, totals calc)
- [x] Flutter: Sale list + detail
- [x] Flutter: Purchase form + list + detail
- [x] Flutter: Expense form + list
- [x] Flutter: Income form + list
- [x] Flutter: Financial calculations (discount, tax, totals)
- [x] Tests: sale workflow (stock + ledger + payment in one transaction)
- [x] Tests: partial payment handling
- [x] Tests: financial immutability (delete creates reversals)

**Implemented:** `Transactions.cs` (Sale/SaleItem, Purchase/PurchaseItem,
Expense, Income, DocumentSequence), migration
`AddSalesPurchasesExpensesIncome`, `SaleService`/`PurchaseService` (atomic
create + reversal delete), `ExpenseService`/`IncomeService`,
`TransactionSupport` helpers (`LedgerWriter`, `StockLedger`,
`DocumentNumberAllocator`), controllers `/api/sales`, `/api/purchases`,
`/api/expenses`, `/api/incomes`. Flutter features `sales`, `purchases`,
`expenses`, `income` + routes + home tiles. 146 backend tests green (45 new),
live E2E verified. Note: real `Payment` records and overpayment-to-credit
balances land in Phase 6.

---

## Phase 6: Payments, Ledger, Balances

**Goal:** Complete payment tracking + ledger reconciliation. **Status: Complete.**

- [x] Backend: `Payment`, `PaymentMethod` entities + endpoints
- [x] Backend: `IPaymentProvider` abstraction
- [x] Backend: `CashPaymentProvider` implementation
- [x] Backend: Payment → ledger transaction + sale due update
- [x] Flutter: Payment recording UI (receive from customer, pay to supplier)
- [x] Flutter: Payment method management
- [x] Flutter: Receivable/Payable summary
- [x] Tests: payment → ledger → balance chain
- [x] Tests: overpayment handling (credit balance)

**Implemented:** `Payments.cs` (`Payment` — immutable/append-only — and
`PaymentMethod`), migration `AddPaymentsAndPaymentMethods`, `IPaymentProvider`
+ `CashPaymentProvider`/`ManualPaymentProvider` + `PaymentProviderRegistry`,
`PaymentService` (payment → khata entry → linked document due/status, overpayment
as an advance, receivable/payable summary) and `PaymentMethodService` (CRUD,
single-default rule). Controllers `/api/payments` (+`/summary`) and
`/api/payment-methods`. Five methods seeded per business. Flutter `payments`
feature (list + summary card, receive/pay form, method management) + routes +
home tile. 176 backend tests green (30 new), live E2E 24/24.

---

## Phase 7: Invoices, PDF, Sharing

**Goal:** Professional invoicing with PDF generation. **Status: Complete** (two
items scoped differently — noted below).

- [x] Backend: `Invoice`, `InvoiceItem`, `Quotation`, `QuotationItem` entities
- [x] Backend: Invoice/quotation CRUD endpoints
- [x] Backend: PDF generation service (QuestPDF)
- [x] Backend: Custom invoice template (business info, items, totals)
- [x] Backend: file-storage abstraction for invoice PDFs — `IFileStorage` +
      `LocalFileStorage`. An **S3-compatible provider is not wired** (no
      credentials available); the interface is ready for it.
- [x] Flutter: Invoice form (from sale or standalone)
- [x] Flutter: Invoice preview — PDF is downloaded to a temp file and handed to
      the OS (`share_plus`), so it opens in the device's PDF app. There is **no
      embedded PDF viewer** (that would need the `printing` package).
- [x] Flutter: Share invoice (WhatsApp, email, print via the OS share sheet)
- [x] Flutter: Quotation form + convert-to-sale flow
- [x] Tests: PDF generation correctness
- [x] Tests: invoice number uniqueness

**Implemented:** `Documents.cs` (Invoice/InvoiceItem, Quotation/QuotationItem),
migration `AddInvoicesAndQuotations`, `IDocumentPdfGenerator` +
`QuestPdfDocumentGenerator` (letterhead, party block, item table, totals,
notes/terms, page numbers), `IFileStorage` + `LocalFileStorage` (with path
traversal protection), `InvoiceService` / `QuotationService`, controllers
`/api/invoices` (+`/pdf`), `/api/quotations` (+`/pdf`, `/{id}/convert`), new
`invoices.*` / `quotations.*` permissions. Invoices share the sales `INV-#####`
series; quotations use `QT-#####`. Flutter `invoices` and `quotations` features
+ routes + home tiles. 204 backend tests green (28 new), live E2E 33/33
including real PDF downloads.

**Note:** this phase also fixed a latent problem — the Flutter app had **18
broken relative imports** (off-by-one `../` from an earlier folder restructure)
and **16 identifiers used without importing their declaring file**, so it had
never actually compiled. All are fixed and now verified by an import-resolution
check (see the testing notes).

---

## Phase 8: Dashboard & Reports

**Goal:** Business insights and analytics. **Status: Complete.**

- [x] Backend: Dashboard aggregation queries (today's sales, expenses, profit)
- [x] Backend: Sales trend, expense trend, profit trend queries
- [x] Backend: Receivable/Payable summary
- [x] Backend: Stock value calculation
- [x] Backend: Report endpoints (sales, purchases, expenses, income, P&L, stock, receivable/payable)
- [x] Backend: Report export — **CSV** (escaped fields, UTF-8 BOM for Excel).
      Excel/PDF export is **not implemented**; see the note below.
- [x] Flutter: Dashboard page with stat cards
- [x] Flutter: Chart widgets (fl_chart — line, bar and pie)
- [x] Flutter: Report list + detail pages
- [x] Flutter: Date range picker (AD + BS via nepali_utils)
- [x] Flutter: Report export (CSV download + OS share sheet)
- [x] Tests: dashboard aggregation accuracy
- [x] Tests: P&L calculation correctness

**Implemented:** `ReportService` + `ReportsController` (`/api/reports/…`),
`ReportDtos.cs`, new `reports.export` permission (granted to Manager and
Accountant). No migration — reports are read-only. Flutter `dashboard` and
`reports` features with fl_chart, and the home page extended with stat cards
and a 14-day trend chart. 221 backend tests green (17 new), live E2E 28/28.

**Notes**
- Revenue excludes VAT; cost of goods uses each product's **current** cost price
  (the app does not snapshot cost at sale time).
- `decimal` quantities are aggregated in memory — SQLite stores decimals as
  text, so summing them server-side is not reliable.
- The range is capped at 366 days to protect the server from unbounded scans.
- Excel/PDF export was replaced by CSV (the roadmap said "PDF/Excel"). CSV is
  what accountants actually import, and it needs no extra dependency.
- Run `python scripts/check_flutter_imports.py` after touching Flutter files:
  `dart format` only parses syntax and cannot catch the unresolvable-import
  class of error (see the Phase 7 note).

---

## Phase 9: Offline Synchronization

**Goal:** Full offline-first operation with reliable sync.
**Status: complete for the entities the push protocol supports (2026-10-18).
Reads for the catalog and parties work offline, and every save for customers,
suppliers, products, expenses, incomes and new sales is queued when the
connection is gone. Purchases, payments, quotations and invoices remain
online-only by design (see notes).**

- [x] Backend: `/api/sync/push` (batch, idempotent)
- [x] Backend: `/api/sync/pull` (delta since timestamp)
- [x] Backend: `SyncOperation` entity for tracking (the idempotency ledger)
- [x] Backend: Conflict detection (optimistic concurrency)
- [ ] Flutter: Drift database schema (mirror of server entities) — **a JSON-file
      cache is used instead; see notes**
- [x] Flutter: Sync queue implementation
- [x] Flutter: **Offline reads** — snapshot cache for the product list,
      categories, units, customer list and supplier list, with a "showing saved
      data" note (2026-10-17; see `docs/offline-sync.md` §9)
- [x] Flutter: Sync engine (push, pull, retry)
- [x] Flutter: Connectivity detection (connectivity_plus) + auto-sync on reconnect
- [x] Flutter: Sync status indicator (offline banner + `/sync` page)
- [x] Flutter: Conflict list UI
- [ ] Flutter: Background sync (WorkManager periodic) — **not implemented; no
      Android/iOS project exists in this repo yet**
- [ ] Flutter: Dead letter queue UI — the `/sync` page lists failed operations;
      there is no dead-letter (auto-failed) queue yet
- [x] Flutter: **Offline writes** — customer, supplier, product, expense, income
      (create/update/delete) and sale (create) are queued when the connection is
      gone, with a temporary id that the push cycle swaps for the server's
      (2026-10-18; see `docs/offline-sync.md` §10)
- [x] Tests: offline sale creation → sync
- [x] Tests: conflict detection and resolution
- [x] Tests: no data loss on connectivity loss (cursor/soft-delete correctness)

### Notes — two latent bugs this phase uncovered and fixed
1. **Soft delete was a hard delete.** `SoftDeletableEntity` did not implement
   `ISoftDeletable`, so the DbContext's soft-delete loop never matched anything
   and every `Remove()`-based delete hard-deleted the row — destroying the
   history that the `DeletedAt` columns, indexes and "the khata ledger is
   immutable and history must survive" comments all promise. Fixed by making the
   base class implement the interface. All 221 pre-existing tests still pass.
2. **A soft delete never bumped `UpdatedAt`.** The audit-stamping loop ran
   *before* the soft-delete conversion, so a row flipped to `Modified` escaped
   stamping. Fixed by converting soft deletes first. Without this, deletions are
   invisible to any delta sync (`UpdatedAt`-keyed).

Also: the sync cursor is pulled back one second because SQLite stores
whole-second precision — repeats are idempotent, a miss is data loss.

### Still to do for true offline-first screens
- **More cached reads**: ledger detail, reports, the dashboard and the
  invoice/quotation lists still call the API only. The snapshot cache is a
  one-line change per read (`CachedReader.read`), so these are additive.
- **Optimistic list injection**: a record created offline is queued but not
  added to the cached list, so it appears after the next sync (the form says so).
- **`baseUpdatedAt` on offline updates**: the list entities do not keep the
  server's `updatedAt`, so an offline edit is applied last-write-wins instead of
  being reported as a conflict.
- **Drift** (the roadmap's choice) needs `build_runner`, which cannot run in this
  sandbox. The caches are JSON documents for now; swap the internals on a dev
  machine and the rest of the layer is unchanged.
- Push supports create/update/delete for customer, supplier, product, expense,
  income, and create-only for sales. Purchases, payments, quotations and
  invoices are online-only — the server has no push operation for them.

---

## Phase 10: Notifications, Reminders, Backup

**Goal:** Push notifications + reminders + data backup.

**Status:** Backend COMPLETE and verified live (277/277 tests, 63/63 E2E).
Flutter layer COMPLETE for the on-device features that need no external
credentials; FCM push and Excel import remain open (see below).

### Backend (done)

- [x] Backend: `Notification`, `Reminder` entities + endpoints
- [x] Backend: FCM integration (notification dispatch)
- [x] Backend: Reminder scheduling (Hangfire/Quartz background jobs)
- [x] Backend: Data export endpoint (JSON/Excel)
- [ ] Flutter: FCM device registration  *(needs a Firebase project)*
- [ ] Flutter: Local notifications (flutter_local_notifications)  *(needs a platform project)*
- [x] Flutter: Reminder management UI
- [x] Flutter: Notification settings
- [x] Flutter: Data backup/restore UI
- [x] Flutter: Excel import (products, customers) — **CSV** end-to-end; see notes
- [x] Tests: notification delivery
- [x] Tests: backup/restore integrity

**Delivered:**

- Entities `Notification` (per-user feed, `ReadAt`), `DeviceRegistration`
  (unique FCM token), `NotificationSettings` (per-user/business push toggles,
  `IsCategoryEnabled`), `Reminder` (`DueAt`, `Status`, `Repeat`, optional
  related entity) — plus `BackupRestoreEntry`, the restore id ledger.
- `NotificationService` (feed, unread count, mark-read/read-all, soft delete,
  device register/unregister, settings, `CreateAndDispatchAsync`),
  `ReminderService` (CRUD, complete/dismiss, `ProcessDueRemindersAsync`),
  `BackupService` (export snapshot, merge-only restore).
- `FcmNotificationDispatcher` — FCM HTTP v1, gated on
  `Notifications:Firebase:ProjectId` + `:AccessToken`. Returns `Disabled` when
  unconfigured, so the feature degrades cleanly until credentials exist.
- Endpoints: `/api/notifications` (feed, `unread-count`, `{id}/read`,
  `read-all`, delete, `devices` GET/POST/DELETE, `settings` GET/PUT),
  `/api/reminders` (CRUD, `complete`, `dismiss`, `process-due`),
  `/api/backup` (`export` as a JSON download, `restore`).
- Permissions `notifications`/`reminders`/`backup` + Manager/Accountant seeds.
- Migrations `20261015095814_AddNotificationsRemindersBackup`,
  `20261015103708_AddBackupRestoreLedger` (PostgreSQL DDL verified).
- `Khata.Application.Common.LocalTime` — Nepal (UTC+05:45) normalization at
  the DTO boundary.

**Flutter (done):**

- `features/notifications/` — in-app feed with an unread badge, an
  unread-only toggle, a category filter, mark-one/mark-all read and delete,
  plus a settings page (master push switch, five dependent category switches,
  a read-only list of registered devices). The feed filter is part of the
  provider key, so each filter fetches and caches independently.
- `features/reminders/` — list split into "Needs attention" (overdue) and
  "Scheduled", status filter, a manual due-check action, and per-item
  complete/dismiss/delete. Create/edit form with date + time pickers and a
  repeat selector; `dueAt` is sent as naive Nepal-local wall-clock time.
- `features/backup/` — export writes `khata-backup.json` to the app documents
  folder and hands it to the share sheet; restore either replays that saved
  copy or accepts pasted JSON, behind a confirmation dialog, and reports a
  per-entity added/kept breakdown.
- Routes `/notifications`, `/notifications/settings`, `/reminders`,
  `/reminders/new`, `/reminders/:id/edit`, `/backup`; three new home tiles.
- Widget tests: `test/notification_pages_test.dart` (11),
  `test/reminder_list_page_test.dart` (9), `test/backup_page_test.dart` (4).
- ARB keys for every new string are staged in `app_en.arb` / `app_ne.arb`
  (267 keys, in parity) but the pages still render literal English, matching
  the rest of the app — no page consumes `AppLocalizations` yet. Wiring is the
  Phase 11 localization pass, not a Phase 10 gap.

- Scheduling uses `POST /api/reminders/process-due` rather than a Hangfire or
  Quartz dependency. It is deliberately idempotent and bounded (`Take(200)`),
  so a client, a cron job, or a future scheduler can drive it.
- FCM needs the user's Firebase project; until then push is a logged no-op and
  in-app notifications still work. The device-registration endpoint and the
  settings/devices UI exist and are exercised, but nothing obtains a token on
  the client yet.
- Restore is a MERGE: rows the target already has are skipped, never
  overwritten (money rows are immutable). Payload ids taken by another
  business are re-homed onto free ids and references remapped; the ledger
  makes a repeat restore idempotent. Derived ledgers (ledger accounts/entries,
  stock movements) are NOT in the payload by design — a restore reproduces the
  documents, not the derived caches.
- Restore deliberately does **not** add a file-picker dependency. It reads the
  snapshot this screen saved and also accepts pasted JSON, which keeps the
  round trip working without `pub get` or platform changes.

**CSV import (the Phase 10 remainder, done 2026-10-17):**

- **CSV import replaces "Excel import"** (same decision as the Phase 8 export:
  CSV is what Excel and Sheets both save, and it needs no new dependency —
  reading `.xlsx` would mean a package such as ClosedXML for a format the user
  has to convert anyway). `CsvReader` is a small RFC 4180 parser: quoted
  fields, doubled quotes, embedded commas/newlines, CRLF, BOM, blank lines.
- Import is **all-or-nothing**: one invalid row refuses the whole file (422
  with the preview) and writes nothing. Rows are validated with the *same*
  FluentValidation validators the REST endpoints use, so an import can never
  accept a row `POST /api/products` would reject.
- **Never overwrite**: a row that already exists is skipped, so re-running the
  same file is safe. Product identity = SKU (else name); customer = name +
  phone. A barcode shared with a *different* product is a row error rather
  than the 409 the product service would raise mid-file.
- Categories named in the file are **created** if missing (a category is only a
  grouping label). Units are **not** auto-created — a unit changes what a
  quantity means, so the file must use one that exists.
- Money in the file is rupees (`1,234.50`, `Rs 1,234.50`, `रु 1200`) → integer
  paisa; `taxRate` is a percentage (`13` or `13%`) → basis points. `12x` fails
  to parse rather than silently importing as 12.
- Header lookup ignores case/spaces/underscores and accepts synonyms
  (`Product Name`, `cost_price`, `Qty`, `VAT`) plus Nepali headers (`नाम`,
  `मूल्य`, `इकाई`, `फोन`, `जिल्ला`). Unmatched headers are reported as
  "ignored" so nothing is silently dropped.
- Endpoints: `/api/import/{products|customers}/template` (CSV download),
  `POST /api/import/{entity}/preview` (dry run), `POST /api/import/{entity}`
  (200 result / 422 preview). Permissions `import.products` /
  `import.customers` (Owner, Admin, Manager).
- Flutter: `/import` — entity chips, copy-template, paste-from-clipboard, check,
  then import behind a confirmation. There is **no file picker** dependency, so
  the file reaches the app through the clipboard (same approach as backup
  restore); that is the remaining UX gap for a 500-row file.
- Limits: 5,000 rows / 2,000,000 characters per file.

---

## Phase 11: Nepali Localization, BS Calendar, Polish

**Goal:** Full Nepali language support + BS calendar + UX polish.

**Status:** COMPLETE (2026-10-16), extended 2026-10-18 with a third language and
a calendar choice. English, Nepali **and Hindi** ship in exact parity (769 ARB
keys each), the language switch applies instantly and survives a restart (it
previously did nothing — see `docs/nepal-localization.md` §9.1), and the user can
read and pick dates in **AD or BS** anywhere in the app. The BS conversion was
also one day off on Nepal-time devices and is now round-trip corrected. The real
BS date picker and BS range picker ship, the Nepal address form (province →
district → municipality cascading dropdowns over all 7 provinces and 77
districts) replaces the free-text fields, phone validation follows the Nepali
mobile/landline shape, and the polish pass (staggered entrance animation, chart
repaint boundaries, theme-aware chart grids, dark-theme
dividers/dialogs/snackbars/bottom sheets) is done. Everything is verified with
the four sandbox checkers plus a browser run.

- [x] Flutter: Complete ARB files (ne + en) for all strings — 752 keys, exact
      parity, every page wired (912 `l10n.*` references)
- [x] Flutter: BS date picker component — `showBsDatePicker` in
      `core/widgets/bs_date_picker.dart`: BS year/month/day wheels, day count
      clamped to the real BS month length via `bsDaysInMonth`, optional
      Devanagari digits, AD `firstDate`/`lastDate` bounds mapped to BS,
      "Today" quick-select. Wired into `BsDateField` and all six form pages
      (expense, income, invoice, reminder, payment, quotation).
- [x] Flutter: BS range picker — `showBsDateRangePicker` (two-step From/To
      dialog sharing the same wheels), wired into `ReportRangeBar`.
- [x] Flutter: AD ↔ BS conversion utility — `core/utils/nepali_date_utils.dart`
      (total helpers over `nepali_utils`, which asserts outside BS 1970-2250)
- [x] Flutter: NPR formatting (Devanagari numerals) —
      `core/l10n/localized_format.dart` + `formatPaisaNepali`
- [x] Flutter: Nepal address form — `core/data/nepal_geography.dart` (7
      provinces, 77 districts, well-known municipalities) + cascading
      `NepalAddressFields` widget in party and business setup forms
- [x] Flutter: Phone number formatting/validation —
      `core/utils/nepali_validators.dart` (mobile 96/97/98 + landline area
      codes, country-prefix stripping), wired into party, business and
      register forms
- [x] Flutter: Performance optimization — `RepaintBoundary` around every
      chart (home trend, report line/pie), theme-aware chart grid lines,
      entrance animations capped and non-replaying
- [x] Flutter: Animations polish — `FadeSlideIn` (staggered dashboard stat
      cards, grid fade), shared wheel component, consistent dialog themes
- [x] Flutter: Empty/loading/error/confirmation states for all screens —
      audited; every async list/detail page uses `.when()` with a retry
      action, inline load errors localized
- [x] Flutter: Dark theme finalization — error borders, dividers, dialogs,
      snackbars and bottom sheets themed in both light and dark
- [x] Tests: localization completeness — `check_localizations.py` gate (912
      refs in scope with known keys), plus ARB parity enforcement
- [x] Tests: BS date conversion edge cases —
      `test/nepali_date_utils_test.dart` (round trips, out-of-range years,
      impossible months/days, formatter fallbacks)
- [x] Tests: Nepal geography + phone validation —
      `test/nepal_geography_test.dart` (7 provinces/77 districts, cascading
      lookups, mobile/landline shapes)
- [x] Tests: entrance animation — `test/fade_slide_in_test.dart`

---

## Phase 12: Admin Web & Advanced Features

**Goal:** Admin dashboard + advanced features.

**Status:** COMPLETE for everything not gated on third-party credentials
(2026-10-16). The admin backend (SuperAdmin role, cross-tenant user and
business management, statistics, audit log, feature flags, support
tickets, all behind `admin.access`) is covered by 11 integration tests,
and the **admin web console** (`backend/src/Khata.Admin`, Blazor Server)
is built and verified end-to-end in a real browser — sign in, suspend a
user, audit trail, flag toggle, ticket creation, sign-out — with zero
console errors. Remaining: payment providers (eSewa/Khalti/Fonepay), QR
payment, SMS reminders, email notifications, subscription/billing — all
of which need provider credentials or a billing model.

- [x] Admin web app — `backend/src/Khata.Admin` (Blazor Web App,
      Interactive Server). Cookie-authenticated: signs in through the API,
      carries the JWT as an encrypted cookie claim, and serves Dashboard,
      Users, Businesses, Support tickets, Audit log and Feature flags.
      Bootstrap: the first SuperAdmin is seeded from
      `Admin:Bootstrap:Email`/`Password` (SQLite demo mode uses
      `admin@khata.local` / `Admin@12345`).
- [x] User management — `/api/admin/users` (list/search, suspend/activate
      with reasons, suspended users cannot authenticate)
- [x] Business management — `/api/admin/businesses` (list/search/filter,
      suspend/activate)
- [ ] Subscription/billing
- [x] System statistics — `/api/admin/statistics` (users, businesses,
      sales/payments totals, ticket counts)
- [x] Support ticket system — `/api/admin/support-tickets` (create, status
      workflow Open → InProgress → Resolved → Closed, resolution notes)
- [x] Audit log viewer — `/api/admin/audit-logs` (every admin mutation is
      recorded with actor, action, entity and reason)
- [x] Feature flags — `/api/admin/feature-flags` (5 seeded flags: eSewa,
      Khalti, QR, SMS, email — all default off until credentials exist)
- [ ] Payment provider integration (eSewa, Khalti, Fonepay) — when credentials available
- [ ] QR payment
- [ ] SMS reminders
- [ ] Email notifications

---

## MVP Definition

**MVP = Phases 1-8** (foundation through dashboard/reports).

An MVP without offline sync (Phase 9) is acceptable for initial release
if the app requires internet. However, the architecture must be ready
for offline sync from Phase 1 (local Drift DB, sync queue structure).

| Priority | Features |
|----------|---------|
| **MVP** | Auth, Business, Products, Inventory, Customers, Suppliers, Sales, Purchases, Expenses, Income, Payments, Ledger, Invoices, Dashboard, Reports |
| **V1.1** | Offline sync, notifications, reminders |
| **V1.2** | Nepali localization, BS calendar |
| **V2.0** | Backup, admin web, payment integrations |
