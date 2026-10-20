# Testing Strategy

> Test strategy for Nepal Digital Khata.
> Financial correctness is the highest priority — money bugs are unacceptable.

---

## 1. Test Pyramid

```
        /\
       /  \        E2E / Integration
      /----\       (API + DB, Flutter integration)
     /      \     Unit Tests (domain logic, handlers)
    /--------\    (pure logic, no I/O)
   /          \   (fastest, most numerous)
```

| Layer | Target | Actual |
|-------|---------------|--------|
| Backend integration (API + DB) | 300+ | **350** (330 `[Fact]` + 6 `[Theory]`) |
| Mobile unit + widget | 100+ | **130** across 20 files |
| Browser verification | every route | full route walk in Chrome, per-pass defect log below |

---

## 2. Backend Testing

### 2.1 Unit Tests (xUnit)

**Domain layer tests** — pure business logic, no database:

```csharp
[Fact]
public void Sale_CalculateTotal_AppliesDiscountBeforeTax()
{
    var sale = new Sale(subtotal: 100000, discount: 10000, taxRate: 0.13m);
    // subtotal=1000.00, discount=100.00, taxable=900.00, tax=117.00, total=1017.00
    Assert.Equal(101700, sale.TotalAmount); // paisa
}
```

**Application handler tests** — use cases with mocked repositories:

```csharp
[Fact]
public async Task CreateSale_ReducesStock_CreatesLedgerEntry()
{
    // Arrange
    var repo = new Mock<ISaleRepository>();
    var stockRepo = new Mock<IStockRepository>();
    var uow = new Mock<IUnitOfWork>();
    var handler = new CreateSaleHandler(repo.Object, stockRepo.Object, uow.Object);

    // Act
    var result = await handler.Handle(new CreateSaleCommand { ... }, CancellationToken.None);

    // Assert
    stockRepo.Verify(r => r.ReduceStockAsync(It.IsAny<long>(), It.IsAny<decimal>()), Times.Once);
    repo.Verify(r => r.AddLedgerTransactionAsync(It.IsAny<LedgerTransaction>()), Times.Once);
    uow.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
}
```

### 2.2 Integration Tests

**API + database** using `WebApplicationFactory` + Testcontainers (PostgreSQL):

```csharp
public class SalesApiTests : IClassFixture<ApiFactory>
{
    [Fact]
    public async Task POST_Sale_CreatesSale_WithCorrectTotals()
    {
        var client = _factory.CreateClient();
        // Login → get token
        // POST /api/sales with items
        // Assert 201, verify response body
        // GET /api/sales/{id} → verify stock reduced, ledger created
    }

    [Fact]
    public async Task POST_Sale_Returns422_WhenInsufficientStock()
    {
        // Create product with 0 stock
        // Try to sell 5 units
        // Assert 422 with detail message
    }
}
```

### 2.3 Financial Calculation Tests (Critical)

These tests are mandatory and must pass 100%:

```csharp
// 1. Cash sale — full payment
[Fact] void CashSale_PaidAmountEqualsTotal_DueIsZero()

// 2. Credit sale — no payment
[Fact] void CreditSale_PaidAmountZero_DueEqualsTotal()

// 3. Partial payment
[Fact] void PartialPayment_DueEqualsTotalMinusPaid()

// 4. Discount applied before tax
[Fact] void DiscountBeforeTax_SubtotalMinusDiscount_TaxOnTaxableAmount()

// 5. Tax included (tax-inclusive pricing)
[Fact] void TaxInclusive_TotalIncludesTax_TaxExtractedCorrectly()

// 6. Line item total = qty × price − discount + tax
[Fact] void LineItemTotal_CalculatedCorrectly()

// 7. Sale reversal (delete) — stock restored, ledger reversed
[Fact] void DeleteSale_StockRestored_LedgerReversed()

// 8. Stock movement immutability
[Fact] void StockMovement_NeverUpdated_OnlyCreated()

// 9. Customer balance after multiple transactions
[Fact] void CustomerBalance_OpeningPlusCreditMinusPayment_EqualsClosing()

// 10. Supplier balance after purchase and payment
[Fact] void SupplierBalance_OpeningPlusCreditMinusPayment_EqualsClosing()

// 11. No floating point errors
[Fact] void MoneyCalculation_NoFloatingPointErrors()
{
    // Test: 0.1 + 0.2 should NOT equal 0.30000000000000004
    // In paisa: 10 + 20 = 30 (always exact with integers)
    var result = 10 + 20;
    Assert.Equal(30, result);
}
```

### 2.4 Permission Tests

```csharp
[Fact]
public async Task POST_Sale_Returns403_WhenUserLacksPermission()
{
    // Create user with Viewer role (no sales.create permission)
    // POST /api/sales
    // Assert 403 Forbidden
}

[Fact]
public async Task GET_Sale_Returns404_WhenSaleBelongsToOtherBusiness()
{
    // Create sale in Business A
    // Switch to Business B (same user)
    // GET /api/sales/{id}
    // Assert 404 (tenant isolation prevents cross-business access)
}
```

### 2.5 Sync Tests

```csharp
[Fact]
public async Task SyncPush_DeduplicatesByLocalId()
{
    // Push same operation twice (network retry scenario)
    // Assert only one server record created
}

[Fact]
public async Task SyncPull_ReturnsChangesSinceLastSync()
{
    // Create record, sync, create another record
    // Pull with lastSyncAt = first sync time
    // Assert only second record returned
}
```

### 2.6 Robustness Tests (hostile input)

`RobustnessTests.cs` — every case was found by probing the API rather than
following the happy path. The rule they enforce: **degenerate input is a 4xx
with a readable reason, never a 500.**

| Probe | Expected |
|-------|----------|
| `POST /api/import/products` with `{"csv": null}` | 400 (binding rejects it before the importer) |
| Import a file with no `name` column | 422 naming the missing column |
| Import an amount too large for `decimal` | 422 with that row and column |
| Import 5,001 rows | 422 quoting the 5,000 limit |
| `?page=0&pageSize=0` on products / ledger | 200, clamped to page 1 / size 1 |
| `?pageSize=100000` | 200, clamped to 100 |
| `Authorization: Bearer not-a-jwt` | 401 |
| Import as a user with no business | 403 (no membership ⇒ no permissions) |

`tool/verify_offline_cache.dart` is the same idea for the Flutter side: it runs
the offline layer as a plain Dart program (40 checks) because `flutter test`
cannot start in this environment.

**Defects this pass found and fixed**

1. **Paged lists silently truncated.** The product list asked for 100 rows and
   the party lists 50, with no indication that more existed — a catalog of 300
   products looked like 100. Both lists now page with a "Load more (N
   remaining)" footer (`LoadMoreFooter`, `ProductListNotifier.loadMore`,
   `CustomerListNotifier` / `SupplierListNotifier`).
2. **Form pickers could not reach the tail of the list.** The sale/invoice/
   purchase/quotation/payment forms filtered the *first page* on the device, so
   customer #51 or product #101 was unselectable. They now read
   `customerPickerProvider` / `supplierPickerProvider` / `productPickerProvider`,
   which load every page (capped at 1,000 rows).
3. **"To collect" / "To pay" under-reported.** The party list chips summed the
   *first page* of customers/suppliers, so any shop with more than 50 parties
   saw a smaller number than it was owed. They now use the server-side payment
   summary.
4. **Offline cache size was measured in characters, not bytes.** Devanagari is
   up to 3 bytes per character, so the "3 MB" budget could reach ~9 MB on disk.
5. **`ImportService` could NRE on a null CSV.** Unreachable through HTTP (the
   binder rejects null first), but hardened anyway.

---

## 3. Flutter Testing

### 3.1 Widget Tests

```dart
testWidgets('SaleForm validates required fields', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: SaleFormPage(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  ));

  // Tap "Save" without filling fields
  await tester.tap(find.byKey(const Key('saveButton')));
  await tester.pumpAndSettle();

  // Verify validation errors shown
  expect(find.text('At least one item is required'), findsOneWidget);
});
```

### 3.2 Unit Tests

```dart
group('MoneyFormatter', () {
  test('formats paisa to NPR string in English', () {
    expect(MoneyFormatter.format(123456, locale: 'en'), '₨ 1,234.56');
  });

  test('formats paisa to NPR string in Nepali', () {
    expect(MoneyFormatter.format(123456, locale: 'ne'), 'रू १,२३४.५६');
  });

  test('handles zero', () {
    expect(MoneyFormatter.format(0, locale: 'en'), '₨ 0.00');
  });
});

group('BsDateConverter', () {
  test('converts AD to BS correctly', () {
    final bs = BsDateConverter.fromAd(DateTime(2026, 10, 8));
    expect(bs.year, 2083);
    expect(bs.month, 6);
    expect(bs.day, 22);
  });

  test('converts BS to AD correctly', () {
    final ad = BsDateConverter.toAd(NepaliDate(2083, 6, 22));
    expect(ad.year, 2026);
    expect(ad.month, 10);
    expect(ad.day, 8);
  });
});
```

### 3.3 Sync Engine Tests

```dart
group('SyncEngine', () {
  test('enqueues operation on local write', () {
    // Write to local DB
    // Verify sync_queue has pending entry
  });

  test('updates server_id after successful push', () {
    // Mock API returns serverId=34
    // Verify local record updated with server_id=34, sync_status=synced
  });

  test('retries with backoff on failure', () {
    // Mock API returns 500
    // Verify attempts incremented, next_retry_at set
  });

  test('marks as conflict when server version differs', () {
    // Mock API returns 409 conflict
    // Verify entity sync_status=conflict
  });
});
```

---

## 4. Test Data

### 4.1 Seed Data for Tests

A `TestDataSeeder` creates a consistent test environment:

- 1 business: "Test Kirana Store"
- 1 owner user
- 5 products (with various prices, stock levels)
- 3 customers (with opening balances)
- 2 suppliers
- Reference units, categories, payment methods

### 4.2 Money Test Values

Use values that expose floating-point issues:

```csharp
// Good test values:
[0.01, 0.10, 0.20, 0.30, 0.70, 1.23, 99.99, 100.00, 9999.99]
// In paisa:
[1, 10, 20, 30, 70, 123, 9999, 10000, 999999]
```

---

## 5. CI/CD Pipeline

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  backend-test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: test
        ports: ['5432:5432']
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '10.0.x'
      - run: dotnet restore backend/src/Khata.Api.sln
      - run: dotnet build backend/src/Khata.Api.sln --no-restore
      - run: dotnet test backend/tests/Khata.UnitTests --no-build
      - run: dotnet test backend/tests/Khata.IntegrationTests --no-build

  mobile-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
      - run: flutter pub get
        working-directory: apps/mobile
      - run: flutter analyze
        working-directory: apps/mobile
      - run: flutter test
        working-directory: apps/mobile
```

---

## 6. Coverage Targets

| Layer | Target |
|-------|--------|
| Domain (backend) | 90%+ |
| Application handlers | 80%+ |
| API controllers | 70%+ |
| Flutter domain/usecases | 80%+ |
| Flutter widgets | 50%+ (critical screens only) |

Coverage is measured but not enforced as a gate — **test quality** matters
more than line count. A 90% coverage suite of meaningless tests is worse
than a 60% suite of targeted financial correctness tests.

---

## 7. Browser Verification (real Chrome)

The mobile suite cannot run in the development sandbox (`flutter test` fails on
the `flutter_tester` websocket upgrade), so the UI is verified by driving the
**built web bundle** in a real Chrome via Playwright:

```
python scripts/e2e/seed_demo_account.py     # demo user + business
dotnet run --project src/Khata.Api          # API on :5182
cd apps/mobile && flutter build web --output build/site \
  --dart-define=API_BASE_URL=http://127.0.0.1:5182
python scripts/e2e/walk_app.py              # sign in, walk every route, screenshot
python scripts/e2e/probe_not_found.py       # feature-specific probes
python scripts/e2e/check_offline_writes.py  # offline write → queue → sync
```

`check_offline_writes.py` is the offline-write regression check: it signs in,
creates a customer online (proving the write path still reaches the API), then
sets the browser offline, creates another one, and expects the form to close
with "Saved offline — it will sync when you reconnect" over the *cached* list.
It then goes back online, taps **Sync Now**, and looks for that customer in the
list — i.e. it proves the queued write was pushed and remapped, not just stored.

Two traps that cost a run each when writing these probes:

- `flt-semantics` wrappers *contain* inputs, so `hasInput` is true for the
  full-page node too. Clicking its centre hits whatever widget sits mid-screen
  (for us: the "Sign up" link). Select a node that is one field tall
  (`28 <= h <= 80`) instead.
- The forms are taller than a phone viewport. A semantics rect below the fold
  yields a click that silently misses — scroll first, then re-read the tree.

Reading state works through Flutter's semantics tree: the walk queries
`flt-semantics` nodes in the light DOM and clicks by their bounding-box centre,
after clicking `flt-semantics-placeholder` to enable semantics. Pixel-level
verification is not possible (the CanvasKit context cannot be re-acquired from
JS), so shape and layout assertions come from semantics rects and screenshots.

### Defects found this way (and fixed)

| Defect | Symptom in the browser | Fix |
|---|---|---|
| Dashboard stat cards clipped | Four cards were a horizontal 150 px row; the last was unreachable | 2×2 grid with `IntrinsicHeight` |
| Regression from that fix | **No dashboard body at all** — `CrossAxisAlignment.stretch` on a `Row` inside a scroll view got unbounded height and stretched each row to the full viewport (828 px), pushing the chart and tiles off-screen | `mainAxisSize: min` + `IntrinsicHeight`. **Never use bare `stretch` on a `Row` under a sliver/scroll view** |
| Import page showed no column hint | `TextField.hintText` never rendered on web | Always-visible expected-columns panel |
| Bank accounts error state | Raw `Text(_error!)` with no way to retry | `_ErrorState` with a retry action |
| Money not grouped the Nepali way | `Rs. 12345600` → "Rs. 123456.00" | `formatPaisa` delegates to the lakh/crore formatter; all 121 call sites follow |
| Devanagari paisa stayed ASCII | "रु. १,२३,४५६.00" — the decimal part was not converted | Convert the remainder too |
| Hardcoded English low-stock note | Compared `label == 'Inventory'`, which is never true in the Nepali build | `showLowStock` flag + localized `lowStockNote` |
| Unknown route showed a framework error screen | English-only "Page Not Found" that printed `GoException: no routes for location: …` — an opaque message that can leak an internal path | `errorBuilder` on the `GoRouter` → `RouteNotFoundScreen`, localized, themed, recovery action |
| Save reported an error *after* it worked | A form opened as the first route (deep link, browser reload) hit `GoError: There is nothing to pop` from `context.pop()`, so a successful save showed a red snackbar and left the form open | `_leaveForm()`: pop when possible, otherwise `context.go('/customers' \| '/suppliers' \| '/products')` |

### Known intermittent (web-only, not yet reproduced)

A fragment navigation to a Windows path (`#C:/Users/…/PortableGit/`) was observed
**twice in ~10 walks**, landing on the not-found screen. It could not be
reproduced in 9 instrumented runs (JS traps on `location.hash`, `location.href`,
`history.pushState` and `history.replaceState`, across both a sit-on-dashboard
and a full route walk). The string appears **nowhere in the built bundle** and
the app contains no code path that could produce it, so it is suspected to come
from the browser/tooling rather than the app. The user-visible half is now
handled: that location shows a localized screen with a way back instead of a
raw exception.
