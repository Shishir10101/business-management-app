# Task List & Risk Assessment

> Detailed phased task breakdown, MVP definition, and technical risk
> analysis for Nepal Digital Khata.

---

## 1. Technical Risks

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|-----------|--------|------------|
| R1 | **Floating-point money errors** | High | Critical | Use integer paisa everywhere (DB numeric, API int, Dart int). No `double` for money. |
| R2 | **Offline sync data loss** | Medium | Critical | Persistent sync queue in SQLite; idempotent server endpoints; dead letter queue; manual retry. |
| R3 | **Sync conflicts corrupting ledger** | Medium | High | Financial transactions are append-only; edits create adjustment entries; conflict UI for reference data only. |
| R4 | **Cross-business data leakage** | Low | Critical | EF Core global query filters on BusinessId; integration tests for tenant isolation. |
| R5 | **EF Core migration issues on production DB** | Medium | High | Test migrations on staging; never auto-apply in prod; backup before migration. |
| R6 | **Large Drift DB on low-end devices** | Medium | Medium | Paginated local queries; archive old data; optional data pruning settings. |
| R7 | **BS calendar conversion edge cases** | Medium | Low | Use verified BS calendar data table; test against known date pairs; handle leap-month variations. |
| R8 | **Nepali Unicode search issues** | Low | Medium | PostgreSQL ICU collation; SQLite NOCASE collation; test with Devanagari strings. |
| R9 | **Payment provider API changes** | Medium | Medium | IPaymentProvider abstraction; no tight coupling; integrate only with real API docs. |
| R10 | **JWT token theft** | Low | High | Refresh token rotation; short access token lifetime; secure storage; revoke on suspicious activity. |
| R11 | **Flutter app size on low-end devices** | Medium | Low | Tree-shake icons; WebP images; deferred component loading (future); code splitting. |
| R12 | **Concurrent stock modification** | Medium | High | Optimistic concurrency (version field); row-level locking on stock update in same transaction. |

---

## 2. MVP vs Later Features

### 2.1 MVP (Phases 1-8)

Must-have features for a usable product:

| Feature | MVP | Notes |
|---------|-----|-------|
| User registration & login | ✅ | Email + password |
| Multi-business | ✅ | Create + switch |
| Products & categories | ✅ | CRUD + search |
| Inventory management | ✅ | Stock tracking, adjustments, low-stock alerts |
| Customers & suppliers | ✅ | CRUD + opening balance |
| Digital Khata (ledger) | ✅ | Ledger transactions, running balance |
| Sales | ✅ | Cash + credit + partial payment |
| Purchases | ✅ | Cash + credit + partial payment |
| Expenses & income | ✅ | CRUD + categorization |
| Payments | ✅ | Record payments, update balances |
| Invoices | ✅ | Generate PDF, share |
| Quotations | ✅ | Create + convert to sale |
| Dashboard | ✅ | Today's stats, trends, receivable/payable |
| Reports | ✅ | Sales, P&L, stock, ledger, receivable/payable |
| Staff & permissions | ✅ | RBAC with 7 roles |
| Basic offline support | ✅ | Local DB + sync queue structure (even if Phase 9 is the full implementation) |

### 2.2 V1.1 (After MVP)

| Feature | Priority |
|---------|----------|
| Full offline sync (Phase 9) | High |
| Push notifications | High |
| Reminders (payment due, low stock) | High |
| Data backup & restore | High |
| Excel import (products, customers) | Medium |

### 2.3 V1.2 (Localization Polish)

| Feature | Priority |
|---------|----------|
| Full Nepali language (Devanagari) | High |
| BS calendar integration | High |
| NPR formatting (Devanagari numerals) | High |
| Nepal address structure | Medium |
| Performance optimization for low-end devices | Medium |

### 2.4 V2.0 (Advanced)

| Feature | Priority |
|---------|----------|
| Admin web app | Medium |
| Payment provider integrations (eSewa, Khalti, Fonepay) | High (when credentials available) |
| QR payments | Medium |
| SMS reminders | Low |
| Email notifications | Low |
| Subscription/billing | Low |
| Advanced reporting | Low |

---

## 3. Phase 1 Task Breakdown (Detailed)

### 3.1 Backend

| # | Task | Priority | Depends On |
|---|------|----------|------------|
| 1.1 | Create .NET solution `Khata.sln` with 4 projects | P0 | - |
| 1.2 | Configure `Directory.Build.props` (nullable, warnings as errors, LangVersion latest) | P0 | 1.1 |
| 1.3 | Add NuGet: EF Core 10 + Npgsql, ASP.NET Identity, JWT, FluentValidation, Serilog | P0 | 1.1 |
| 1.4 | Create `Khata.Domain` project: base entity classes, enums, value objects | P0 | 1.1 |
| 1.5 | Create `Khata.Application` project: `ICurrentUserService`, `IUnitOfWork`, interfaces | P0 | 1.4 |
| 1.6 | Create `Khata.Infrastructure` project: `KhataDbContext`, Identity configuration | P0 | 1.4, 1.5 |
| 1.7 | Create `Khata.Api` project: `Program.cs`, middleware, DI registration | P0 | 1.6 |
| 1.8 | Implement `AppUser` (extends IdentityUser) with Nepali fields | P0 | 1.6 |
| 1.9 | Implement `AppRole`, `Permission`, `RolePermission` entities | P0 | 1.4 |
| 1.10 | Configure ASP.NET Identity (password policy, lockout, token providers) | P0 | 1.6 |
| 1.11 | Implement `JwtTokenService` (access + refresh, claims) | P0 | 1.5 |
| 1.12 | Implement `AuthController` (register, login, refresh, logout, me, profile) | P0 | 1.11 |
| 1.13 | Implement `CurrentUserService` (resolves from HttpContext claims) | P0 | 1.5 |
| 1.14 | Implement `TenantMiddleware` (validate business context) | P0 | 1.13 |
| 1.15 | Implement `ExceptionMiddleware` (ProblemDetails) | P0 | 1.7 |
| 1.16 | Implement `ValidationBehavior` (FluentValidation MediatR pipeline) | P0 | 1.5 |
| 1.17 | Create `Business` entity + `BusinessMember` entity | P0 | 1.4 |
| 1.18 | Seed system roles + permissions on first run | P0 | 1.9 |
| 1.19 | Create first EF Core migration | P0 | 1.6 |
| 1.20 | Set up `docker-compose.dev.yml` (PostgreSQL 16) | P0 | - |
| 1.21 | Write `appsettings.json` + `appsettings.Development.json` | P0 | 1.7 |
| 1.22 | Write unit tests: JWT token service | P1 | 1.11 |
| 1.23 | Write integration tests: register, login, refresh | P1 | 1.12 |
| 1.24 | Write integration tests: tenant isolation | P1 | 1.14 |

### 3.2 Flutter

| # | Task | Priority | Depends On |
|---|------|----------|------------|
| 1.25 | `flutter create` + configure `pubspec.yaml` | P0 | - |
| 1.26 | Add packages: riverpod, dio, drift, go_router, flutter_secure_storage, etc. | P0 | 1.25 |
| 1.27 | Configure `analysis_options.yaml` | P0 | 1.25 |
| 1.28 | Create folder structure: core/ + features/auth/ | P0 | 1.25 |
| 1.29 | Core: theme (`KhataTheme` light + dark) | P0 | 1.28 |
| 1.30 | Core: network (`DioClient` with auth interceptor, refresh interceptor) | P0 | 1.28 |
| 1.31 | Core: database (Drift `AppDatabase` skeleton) | P0 | 1.28 |
| 1.32 | Core: router (GoRouter with auth redirect) | P0 | 1.30 |
| 1.33 | Core: config (environment, API base URL) | P0 | 1.28 |
| 1.34 | Auth feature: data (auth datasource, repository) | P0 | 1.30 |
| 1.35 | Auth feature: domain (entities, usecases) | P0 | 1.34 |
| 1.36 | Auth feature: presentation (login page, register page) | P0 | 1.35 |
| 1.37 | Auth feature: providers (auth state notifier) | P0 | 1.36 |
| 1.38 | Core: shared widgets (KhataButton, KhataTextField, etc.) | P0 | 1.29 |
| 1.39 | Landing/onboarding page | P0 | 1.32 |
| 1.40 | Write widget tests: login form | P1 | 1.36 |
| 1.41 | Write unit tests: auth repository | P1 | 1.34 |

---

## 4. Phase 2-12 Task Summary

Each phase follows the same pattern: Backend entities + endpoints → Flutter features → Tests.

### Phase 2: Business Setup
- Business CRUD + member management + switching
- Flutter: business setup wizard, switcher, profile, staff

### Phase 3: Products & Inventory
- Product/category/unit/stock/stock_movement entities + endpoints
- Flutter: product catalog, inventory management

### Phase 4: Customers, Suppliers, Khata
- Customer/supplier/ledger_account/ledger_transaction entities + endpoints
- Flutter: party management, ledger views

### Phase 5: Sales, Purchases, Expenses, Income
- Sale/sale_item/purchase/purchase_item/expense/income entities + endpoints
- Flutter: transaction forms, lists, details

### Phase 6: Payments, Ledger, Balances
- Payment/payment_method entities + endpoints, IPaymentProvider abstraction
- Flutter: payment recording, receivable/payable

### Phase 7: Invoices, PDF, Sharing
- Invoice/invoice_item/quotation/quotation_item entities + endpoints + PDF generation
- Flutter: invoice form, preview, share

### Phase 8: Dashboard & Reports
- Dashboard aggregation + report queries
- Flutter: dashboard, chart widgets, report pages

### Phase 9: Offline Sync
- Sync push/pull endpoints + conflict detection
- Flutter: Drift schema, sync engine, queue, conflict UI

### Phase 10: Notifications, Reminders, Backup
- Notification/reminder entities + FCM + background jobs
- Flutter: notifications, reminders, backup/restore

### Phase 11: Localization, BS Calendar, Polish
- Complete ARB files, BS date picker, NPR formatting, performance

### Phase 12: Admin Web & Advanced
- Admin web app, payment integrations, QR payments, SMS/email

---

## 5. Definition of Done

A feature is **complete** when ALL of the following are true:

- [ ] Entity + configuration in Domain
- [ ] Repository interface in Application
- [ ] Repository implementation in Infrastructure
- [ ] EF Core migration created
- [ ] DTO + validator created
- [ ] Controller endpoint created
- [ ] Permission attribute on endpoint
- [ ] Global query filter (if business entity)
- [ ] Integration test passes
- [ ] Flutter data layer (datasource, model, repository impl)
- [ ] Flutter domain layer (entity, repository interface, usecase)
- [ ] Flutter presentation (page, widgets, providers)
- [ ] Widget test for critical screens
- [ ] Empty/loading/error states implemented
- [ ] Localization keys added (en + ne)
- [ ] No hardcoded strings in widgets
- [ ] Code reviewed
- [ ] No analyzer warnings
