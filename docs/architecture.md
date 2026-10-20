# Architecture

> System architecture for Nepal Digital Khata — a production-grade,
> offline-first, Nepal-focused business management application.

---

## 1. System Overview

```
┌─────────────────────────────────────────────────┐
│                   Flutter App                    │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │
│  │  Riverpod │  │ Feature  │  │  Drift/SQLite │  │
│  │  State    │  │ Modules  │  │  (offline DB) │  │
│  └────┬─────┘  └────┬─────┘  └───────┬───────┘  │
│       │              │                │          │
│       └──────────────┴────────────────┘          │
│                      │                            │
│              ┌───────┴────────┐                  │
│              │  Sync Engine    │                  │
│              │  (Dio → API)    │                  │
│              └───────┬─────────┘                  │
└──────────────────────┼───────────────────────────┘
                       │ HTTPS / JWT
┌──────────────────────┼───────────────────────────┐
│              ASP.NET Core 10 Web API              │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │
│  │  API     │→ │Application│→ │ Infrastructure│  │
│  │  Layer   │  │  Layer    │  │  Layer         │  │
│  │(Contr.)  │  │(Services) │  │(EF Core, Auth) │  │
│  └──────────┘  └──────────┘  └───────┬───────┘  │
│                                       │           │
│                              ┌────────┴────────┐  │
│                              │   PostgreSQL     │  │
│                              │   (Server DB)   │  │
│                              └─────────────────┘  │
└────────────────────────────────────────────────────┘
```

### Key Principles

| Principle | How |
|-----------|-----|
| Offline-first | Local SQLite is the source of truth on device; server sync is background |
| Clean architecture | Dependency direction: Presentation → Application → Domain ← Infrastructure |
| Tenant isolation | Every business entity carries `BusinessId`; enforced at query filter level |
| Financial immutability | Transactions are append-only; corrections create adjustment records |
| Separation of concerns | No EF entities exposed via API; DTOs with explicit mapping |
| Money safety | All monetary values stored as `numeric(18,2)`; Dart uses `int` (paisa) |

---

## 2. Monorepo Structure

```
business-management-app/
├── apps/
│   ├── mobile/                    # Flutter application
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── core/              # Shared infrastructure
│   │   │   │   ├── config/       # App config, environment
│   │   │   │   ├── constants/
│   │   │   │   ├── errors/        # Failure classes, error handling
│   │   │   │   ├── network/       # Dio setup, interceptors
│   │   │   │   ├── database/      # Drift database, shared tables
│   │   │   │   ├── router/        # GoRouter configuration
│   │   │   │   ├── theme/         # Design system tokens
│   │   │   │   ├── utils/         # Date, money, phone formatters
│   │   │   │   └── widgets/       # Shared reusable widgets
│   │   │   ├── features/
│   │   │   │   ├── auth/
│   │   │   │   ├── dashboard/
│   │   │   │   ├── businesses/
│   │   │   │   ├── products/
│   │   │   │   ├── inventory/
│   │   │   │   ├── customers/
│   │   │   │   ├── suppliers/
│   │   │   │   ├── sales/
│   │   │   │   ├── purchases/
│   │   │   │   ├── expenses/
│   │   │   │   ├── income/
│   │   │   │   ├── khata/
│   │   │   │   ├── invoices/
│   │   │   │   ├── reports/
│   │   │   │   ├── notifications/
│   │   │   │   ├── sync/
│   │   │   │   └── settings/
│   │   │   └── l10n/              # Localization files
│   │   ├── assets/
│   │   │   ├── fonts/
│   │   │   ├── icons/
│   │   │   └── images/
│   │   ├── test/                  # Widget & unit tests
│   │   ├── test_driver/           # Integration tests
│   │   └── pubspec.yaml
│   │
│   └── admin-web/                 # Future: admin web app
│
├── backend/
│   ├── src/
│   │   ├── Khata.Domain/          # Entities, value objects, domain events
│   │   ├── Khata.Application/     # Use cases, DTOs, interfaces, validators
│   │   ├── Khata.Infrastructure/  # EF Core, Identity, repos, external services
│   │   ├── Khata.Api/             # Controllers, middleware, DI, Program.cs
│   │   └── Khata.Api.sln
│   ├── tests/
│   │   ├── Khata.UnitTests/
│   │   └── Khata.IntegrationTests/
│   └── Directory.Build.props
│
├── docs/                          # This directory
├── infrastructure/
│   ├── docker-compose.dev.yml     # PostgreSQL + API for local dev
│   ├── docker-compose.prod.yml
│   ├── Dockerfile.api
│   └── init-scripts/
├── scripts/
│   ├── build.sh
│   ├── test.sh
│   └── seed-data.sh
└── .gitignore
```

---

## 3. Backend: Clean Architecture (ASP.NET Core 10)

### 3.1 Layer Dependencies

```
Khata.Api  →  Khata.Application  →  Khata.Domain
     ↘              ↘
  Khata.Infrastructure  →  Khata.Domain
```

**Rule:** Dependencies point inward. `Domain` depends on nothing.
`Application` depends on `Domain`. `Infrastructure` depends on `Domain` + `Application`.
`Api` depends on `Application` (and `Infrastructure` for DI wiring only, at the composition root).

### 3.2 Layer Responsibilities

#### Khata.Domain

The enterprise core. Pure C# — no EF Core, no ASP.NET, no external dependencies.

| Contains | Example |
|----------|---------|
| Entities | `Sale`, `Customer`, `Product`, `LedgerTransaction` |
| Value Objects | `Money`, `BusinessId`, `ProductId` |
| Enums | `SaleType`, `PaymentStatus`, `StockMovementType` |
| Domain Events | `SaleCreatedEvent`, `StockAdjustedEvent` |
| Domain Exceptions | `InsufficientStockException`, `DuplicateInvoiceException` |
| Interfaces (repo contracts) | `ISaleRepository`, `IProductRepository` |

#### Khata.Application

Use cases, orchestration, DTOs. Depends only on Domain.

| Contains | Example |
|----------|---------|
| Commands | `CreateSaleCommand`, `RecordPaymentCommand` |
| Queries | `GetDashboardQuery`, `GetCustomerLedgerQuery` |
| Handlers | `CreateSaleHandler`, `GetDashboardHandler` |
| DTOs | `SaleDto`, `CustomerDto`, `DashboardDto` |
| Validators | `CreateSaleValidator` (FluentValidation) |
| Interfaces (infra contracts) | `IUnitOfWork`, `ICurrentUserService`, `IDateTime` |
| Mappers | Manual mapping profiles (no AutoMapper magic — explicit) |

#### Khata.Infrastructure

Concrete implementations of Application interfaces. Depends on Domain + Application.

| Contains | Example |
|----------|---------|
| EF Core DbContext | `KhataDbContext` |
| Repositories | `SaleRepository`, `ProductRepository` |
| Identity | `AppUser` extends `IdentityUser`, `AppRole`, role/permission seeding |
| JWT | `JwtTokenService` |
| Unit of Work | `UnitOfWork` (wraps `DbContext.SaveChanges` + transaction) |
| External | `S3StorageService`, `FcmNotificationService` (stubs) |
| Migrations | EF Core migration classes |

#### Khata.Api

HTTP entry point. Depends on Application (and Infrastructure for DI registration).

| Contains | Example |
|----------|---------|
| Controllers | `AuthController`, `SalesController`, `SyncController` |
| Middleware | `ExceptionMiddleware`, `TenantMiddleware`, `RequestLoggingMiddleware` |
| DI Registration | `DependencyInjection.cs` — registers all layers |
| Filters | `ValidationFilter` (runs FluentValidation) |
| Configuration | `Program.cs` (minimal hosting model) |
| Problem Details | `ProblemDetailsOptions` customization |

### 3.3 Request Flow Example: Create Sale

```
HTTP POST /api/sales
    ↓
[TenantMiddleware]      → resolve BusinessId from JWT claim, set on ICurrentUserService
    ↓
[AuthMiddleware]         → validate JWT, set UserId on ICurrentUserService
    ↓
[ValidationFilter]      → run CreateSaleValidator on request body
    ↓
SalesController.Create()
    ↓
CreateSaleHandler.Handle()
    ├── validate business rules (stock availability, customer exists)
    ├── create Sale entity + SaleItems
    ├── reduce stock via StockMovement records
    ├── create LedgerTransaction (credit sale → customer receivable)
    ├── record Payment if cash/partial
    ├── generate invoice number (atomic sequence)
    ├── save via IUnitOfWork (single DB transaction)
    └── return SaleDto
    ↓
[ExceptionMiddleware]   → catch → ProblemDetails
```

### 3.4 Tenant Isolation (BusinessId)

Every repository query automatically filters by `BusinessId` obtained from
`ICurrentUserService.BusinessId`. This is enforced via a global EF Core query filter
on all `IBusinessEntity` implementations:

```csharp
// In KhataDbContext.OnModelCreating
foreach (var entityType in modelBuilder.Model.GetEntityTypes())
{
    if (typeof(IBusinessEntity).IsAssignableFrom(entityType.ClrType))
    {
        modelBuilder.Entity(entityType.ClrType)
            .HasQueryFilter(e => e.BusinessId == _currentUserService.BusinessId);
    }
}
```

This means even if a developer forgets to filter by business in a query,
EF Core's global filter prevents cross-tenant data leakage.

---

## 4. Flutter: Feature-Based Architecture

Each feature follows a three-layer split:

```
features/sales/
├── data/
│   ├── datasources/
│   │   ├── sale_local_datasource.dart    # Drift queries
│   │   └── sale_remote_datasource.dart   # Dio API calls
│   ├── models/
│   │   ├── sale_model.dart               # serialization ↔ Drift row
│   │   └── sale_item_model.dart
│   ├── repositories/
│   │   └── sale_repository_impl.dart     # coordinates local + remote + sync
│   └── mappers/
│       └── sale_mapper.dart              # model ↔ domain entity
├── domain/
│   ├── entities/
│   │   ├── sale_entity.dart              # pure business object
│   │   └── sale_item_entity.dart
│   ├── repositories/
│   │   └── sale_repository.dart          # abstract interface
│   └── usecases/
│       ├── create_sale.dart
│       ├── get_sales.dart
│       └── get_sale_detail.dart
├── presentation/
│   ├── providers/
│   │   ├── sale_providers.dart           # Riverpod definitions
│   │   └── sale_form_providers.dart
│   ├── pages/
│   │   ├── sale_list_page.dart
│   │   ├── sale_detail_page.dart
│   │   └── sale_form_page.dart
│   └── widgets/
│       ├── sale_card.dart
│       ├── sale_item_tile.dart
│       └── sale_summary_bar.dart
└── sales.dart                            # barrel export
```

### 4.1 Layer Rules

| Layer | Depends on | Contains |
|-------|-----------|----------|
| Presentation | Domain (via use cases), Data (via providers) | Pages, widgets, Riverpod providers |
| Domain | Nothing external | Entities, repository interfaces, use cases |
| Data | Domain (implements interfaces) | Drift DAOs, Dio clients, models, mappers |

### 4.2 State Management: Riverpod

```
User taps "Create Sale"
    ↓
SaleFormProvider (StateNotifier<SaleFormState>)
    validates input locally
    ↓
CreateSale use case
    writes to local Drift DB
    enqueues sync operation
    returns local sale (with localId, syncStatus: pending)
    ↓
UI updates immediately (optimistic)
    ↓
SyncEngine (background)
    picks up pending operation
    POSTs to server
    on success → updates localId → serverId mapping
    on failure → retries with backoff
```

### 4.3 Riverpod Provider Hierarchy

```dart
// Core infrastructure providers
final dioProvider = Provider<Dio>(...);
final databaseProvider = Provider<AppDatabase>(...);  // Drift
final syncEngineProvider = Provider<SyncEngine>(...);
final sharedPreferencesProvider = Provider<SharedPreferences>(...);

// Auth
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);

// Active business
final activeBusinessProvider = StateNotifierProvider<BusinessSwitcher, Business?>(...);

// Feature: Sales
final saleRepositoryProvider = Provider<SaleRepository>(...);
final saleListProvider = FutureProvider.family<List<SaleEntity>, SaleFilter>(...);
final saleDetailProvider = FutureProvider.family<SaleEntity?, String>(...);
final createSaleProvider = StateNotifierProvider<CreateSaleNotifier, AsyncValue<SaleEntity?>>(...);
```

---

## 5. Data Flow & Offline-First

### 5.1 Read Path

```
UI → Use Case → Repository
    → check if local data exists in Drift
    → if local data fresh enough → return immediately
    → if stale or absent → fetch from API → write to Drift → return
```

The user never waits for network to see their data. The app always renders
from local SQLite first, then refreshes in the background.

### 5.2 Write Path

```
UI → Use Case → Repository
    → write to local Drift DB (transaction)
    → create SyncQueueEntry (operation type, localId, payload)
    → if online → SyncEngine picks up immediately
    → if offline → SyncEngine retries when connectivity restored
    → on server response → update local record with serverId, syncStatus: synced
    → on conflict → resolve per conflict strategy (see offline-sync.md)
```

### 5.3 Sync Status Tracking

Every local record has:

| Field | Purpose |
|-------|---------|
| `localId` | UUID generated on device, used until server ID is assigned |
| `serverId` | Long/UUID from server; null until synced |
| `syncStatus` | enum: `pending`, `syncing`, `synced`, `failed`, `conflict` |
| `lastModifiedAt` | Local timestamp; sent to server for conflict detection |
| `version` | Monotonically increasing; used for optimistic concurrency |

---

## 6. Cross-Cutting Concerns

### 6.1 Error Handling

**Backend:** Centralized `ExceptionMiddleware` converts exceptions to RFC 7807
`ProblemDetails` responses:

```json
{
  "type": "https://khata.app/errors/insufficient-stock",
  "title": "Insufficient stock",
  "status": 422,
  "detail": "Product 'Rice 5kg' has only 3 units in stock; sale requests 5.",
  "instance": "/api/sales",
  "traceId": "00-abc123..."
}
```

**Flutter:** `Failure` sealed class hierarchy; Riverpod states wrap
`AsyncValue<T>` with `when(data:, loading:, error:)`. No raw exceptions
propagated to widgets.

### 6.2 Logging

| Layer | Tool | Level |
|-------|------|-------|
| Backend | Serilog → structured JSON → stdout (Docker) / file | Info+ |
| Flutter | `dart:developer` + custom logger → file (rotated) | Debug in dev, Warning+ in prod |

### 6.3 Validation

| Layer | Approach |
|-------|----------|
| Backend API | FluentValidation on every command DTO |
| Backend Domain | Domain invariants in entity constructors / methods |
| Flutter | Form validation in presentation layer + domain entity validation |

Never rely on client-side validation alone. The API always validates.

### 6.4 Localization (Backend)

The backend API remains locale-agnostic. All dates in API payloads use
ISO 8601 (Gregorian). The Flutter client converts to Bikram Sambat for
display. Money is always returned as integer paisa; the client formats
to NPR string.

### 6.5 Money Handling

| Layer | Type | Rationale |
|-------|------|-----------|
| PostgreSQL | `numeric(18,2)` | Exact decimal, no float drift |
| C# Domain | `decimal` | Native decimal type |
| API DTO | `long` (paisa) | Integer, no floating point in JSON |
| Drift/SQLite | `INTEGER` (paisa) | Integer, safe for offline |
| Dart Domain | `int` (paisa) | Integer arithmetic only |

Conversion: NPR 1,234.56 → `123456` paisa (integer) in all API and local DB.
Display: `₹1,234.56` or `रु १,२३४.५६` depending on locale.

---

## 7. Dependency Rule Enforcement

### Backend

Enforced via project references in `.csproj`:

```xml
<!-- Khata.Domain/Khata.Domain.csproj -->
<!-- No project references. Zero external deps except System.* -->

<!-- Khata.Application/Khata.Application.csproj -->
<ProjectReference Include="Khata.Domain" />

<!-- Khata.Infrastructure/Khata.Infrastructure.csproj -->
<ProjectReference Include="Khata.Domain" />
<ProjectReference Include="Khata.Application" />

<!-- Khata.Api/Khata.Api.csproj -->
<ProjectReference Include="Khata.Application" />
<ProjectReference Include="Khata.Infrastructure" />
```

A Roslyn analyzer (custom or via ArchUnit-style tests) can be added later
to enforce that Domain does not reference Infrastructure, etc.

### Flutter

Enforced via import discipline + `lint` package rules:

```yaml
# analysis_options.yaml
lint:
  rules:
    - avoid_relative_lib_imports  # force package: imports
    - always_use_package_imports
```

Feature-to-feature imports are prohibited except through exported domain interfaces.
A `import_lint` package can enforce this later.

---

## 8. Technology Decisions & Rationale

| Decision | Choice | Why |
|----------|--------|-----|
| State management | Riverpod 2.x | Compile-safe, testable, no `BuildContext` dependency |
| HTTP client | Dio | Interceptors, form data, cancel tokens |
| Local DB | Drift (SQLite) | Type-safe queries, migrations, reactive streams |
| Routing | GoRouter | Declarative, deep-linkable, auth-redirect |
| Backend ORM | EF Core 10 | Mature, migrations, query filters, transaction scope |
| Auth | ASP.NET Identity + JWT | Battle-tested password hashing, refresh tokens |
| API style | REST + ProblemDetails | Simplicity, standard error format, easy to cache |
| Money type | Integer paisa | Eliminates floating-point errors everywhere |
| Payment abstraction | `IPaymentProvider` interface | Decouples from specific provider (eSewa/Khalti/Fonepay) |
| CI/CD | GitHub Actions | Native to GitHub, matrix builds, cache support |

---

## 9. Scalability Considerations (Future)

| Concern | Strategy |
|---------|---------|
| Read scaling | Read replicas for reporting queries |
| Sync throughput | Batch sync operations; server-side bulk endpoints |
| Multi-tenancy | Shared database with `BusinessId` discriminator (current) → schema-per-tenant (future, if needed) |
| Background jobs | Hangfire or Quartz.NET for scheduled reminders, backup tasks |
| Caching | Redis for frequently-read reference data (product catalog, customer list) |
| File storage | S3-compatible (MinIO for self-hosted, Cloudflare R2 for managed) |

---

## 10. Glossary

| Term | Definition |
|------|-----------|
| Khata | Nepali for ledger/account book; the core financial tracking system |
| Bikram Sambat (BS) | Nepali calendar system, ~57 years ahead of Gregorian |
| Paisa | Sub-unit of NPR; 1 NPR = 100 paisa |
| Digital Khata | Digital ledger tracking customer/supplier credit-debit |
| Sync Queue | Local queue of operations pending server synchronization |
| Tenant | A single Business entity; all data is isolated per tenant |
