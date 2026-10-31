# Security audit — Nepal Digital Khata

Date: 2026-10-20
Scope: `backend/src/Khata.Api`, `backend/src/Khata.Admin`, `apps/mobile` (Android config and token storage)
Method: source review, authenticated API probing (live instance), browser checks on the admin console, and regression tests.

Everything below was reproduced against a running instance before it was fixed, and is covered by a test or a probe check afterwards.

---

## Summary

| # | Severity | Area | Finding | Status |
|---|----------|------|---------|--------|
| 1 | High | Authorization | `/api/sync/push` checked only `sync.use`, so a SalesStaff could delete products and an InventoryStaff could record sales | Fixed |
| 2 | High | Session | A suspended account could keep refreshing tokens for 30 days | Fixed |
| 3 | High | Tenancy | Suspending a business did nothing; a tenant Admin could also clear the flag itself | Fixed |
| 4 | High | Authorization | A business Admin could promote itself (or an accomplice) to Owner, and demote/remove the Owner | Fixed |
| 5 | High | Traffic | `X-Forwarded-For` was trusted from any caller, defeating per-IP rate limiting and poisoning audit IPs | Fixed |
| 6 | Medium | Session | Changing a password left every refresh token alive | Fixed |
| 7 | Medium | Auth | Registration confirmed whether an email existed | Fixed |
| 8 | Medium | Output | Report CSV exports allowed spreadsheet formula injection | Fixed |
| 9 | Medium | Public links | Statement link TTL was unbounded: `ttlDays=999999999` returned 500, large values minted a permanent public ledger | Fixed |
| 10 | Medium | Admin console | Login form had CSRF protection disabled, an open redirect via `returnUrl`, no `admin.access` check, and a non-Secure cookie behind TLS proxies | Fixed |
| 11 | Low | Disclosure | `/health` published the DB provider, Atlas database name and exception type | Fixed |
| 12 | Low | Disclosure | Every response advertised `Server: Kestrel` | Fixed |
| 13 | Low | Bootstrap | The demo SuperAdmin password was created on **any** SQLite deployment | Fixed |
| 14 | Low | Notifications | Device-token lookup compared an untrimmed token, creating duplicates | Fixed |
| 15 | Low | Logic | Sign-in ignored the user's selected business (always the first membership) | Fixed |
| 16 | Low | i18n | Hindi (`hi`) was rejected by the API although the app ships it | Fixed |
| 17 | Low | Validation | Password minimum was 8 in the validator and 10 in Identity | Fixed |
| 18 | Low | Logic | A SuperAdmin lost `admin.access` after switching into a business | Fixed |

### Round 4 — release hardening (2026-10-30)

| # | Severity | Area | Finding | Status |
|---|----------|------|---------|--------|
| 19 | Medium | Disclosure | The public statement page is a bearer URL for a customer's whole ledger, returned as HTML with **no `Cache-Control`** — cacheable by proxies, CDNs and the back-forward cache after the link expired — and no CSP or `noindex` | Fixed |
| 20 | Low | Admin console | `/auth/signout` had antiforgery disabled and no origin check, so any site could force-log an administrator out | Fixed |
| 21 | Low | Auth | JWT validation accepted any algorithm the token's own header named, instead of only the one this API issues | Fixed |

Verified and left unchanged: tenant isolation (global query filter), JWT signature/algorithm handling, refresh-token rotation and reuse detection, pagination clamps, SQL injection resistance, HTML escaping in public statements, storage path traversal protection, CORS, security headers, mobile secure storage, and cleartext-HTTP blocking.

---

## Details

### 1. Sync push bypassed entity permissions (High)

`SyncController.Push` required `sync.use`, but `SyncService` then dispatched every entity type to its domain service, which performs no permission checks (they live on the REST controllers). Roles that legitimately hold `sync.use` but not the entity right could therefore write anything:

- SalesStaff → `product/delete`, `expense/create`, `income/create`, `supplier/create`
- InventoryStaff → `sale/create`, `expense/create`
- Accountant → `customer/create`, `product/create`, `sale/create`

Impact: a sales clerk could wipe the catalog or record revenue; an inventory clerk could book sales. The role boundary was bypassed by choosing a different URL.

Fix: `SyncService.RequiredPermission` maps each `(entity, operation)` to the same permission its REST endpoint requires, and rejects the operation per-item (`"You do not have permission for this operation."`) without failing the rest of the batch.
Files: `backend/src/Khata.Infrastructure/Services/SyncService.cs`
Test: `SalesStaff_CannotWriteOtherEntitiesThroughSyncPush`

### 2. Suspended users could refresh indefinitely (High)

`JwtTokenService.RefreshTokenAsync` never looked at `AppUser.IsActive`. An account suspended from the admin console kept minting 15-minute access tokens for the 30-day life of its refresh token, so suspension was advisory.

Fix: refresh refuses an inactive account and revokes the whole token family; `AdminService.SetUserActiveAsync(false)` revokes every live refresh token; the request pipeline also rejects a token belonging to a now-inactive user (401).
Files: `JwtTokenService.cs`, `AdminService.cs`, `Middleware/BusinessStatusMiddleware.cs`
Tests: `SuspendedUser_CannotRefreshAndItsAccessTokenStopsWorking`

### 3. Business suspension was cosmetic (High)

`Business.IsActive` was written by the admin console and never read anywhere on the request path: suspended shops kept full access. Worse, `PUT /api/businesses/{id}` copied `isActive` from the request body, so a tenant Admin could un-suspend the business the platform had just suspended.

Fix:
- `BusinessStatusMiddleware` refuses tenant requests whose `bid` points at an inactive/deleted business (403), with a short cache that is evicted on suspend/activate.
- `UpdateBusinessAsync` no longer accepts `IsActive` from the tenant.
- Login/refresh only select active businesses, and suspended ones disappear from the business list.
- `/api/businesses` stays reachable so the client can recover (list, create, switch).

Files: `Middleware/BusinessStatusMiddleware.cs`, `BusinessService.cs`, `AuthRepository.cs`, `JwtTokenService.cs`
Tests: `SuspendedBusiness_IsRefused_ButTheOwnerCanStillRecover`, `TenantAdmin_CannotChangeThePlatformSuspensionFlag`

### 4. Admin → Owner escalation (High)

`EnsureManagerRole` accepted Owner **or** Admin for member management, and neither `InviteMemberAsync` nor `UpdateMemberRoleAsync` restricted the Owner role itself. An Admin could promote itself to Owner (full control, including deleting the business) or demote/remove the real Owner.

Fix: only an Owner can grant or revoke the Owner role, in invite, role change and removal.
Files: `BusinessService.cs`
Test: `Admin_CannotPromoteItselfOrAnyoneElseToOwner`

### 5. X-Forwarded-For trusted from anyone (High)

`ForwardedHeadersOptions.KnownProxies`/`KnownIPNetworks` were cleared unconditionally, so any client could set its own apparent IP. Since the rate limiter partitions on `Connection.RemoteIpAddress`, rotating the header gave an unlimited brute-force budget; audit rows recorded attacker-chosen IPs.

Fix: default to the framework's loopback-only trust. A platform deployment opts in explicitly with `ForwardedHeaders__TrustAll=true` (set in `render.yaml`) or a list of proxies/networks. Verified from a non-loopback address: rotating `X-Forwarded-For` no longer avoids the 429.
Files: `Program.cs`, `render.yaml`
Probe: `security_probe.py --rate-limit-only`

### 6. Password change did not end other sessions (Medium)

A user changing their password after a suspected compromise kept every existing refresh token, so the thief's session survived 30 more days.

Fix: `AuthController.ChangePassword` revokes all refresh tokens for the user after a successful change.
Files: `AuthController.cs`, `ITokenService.RevokeAllForUserAsync`
Test: `ChangePassword_RevokesEveryRefreshToken`

### 7. Account enumeration at registration (Medium)

`POST /api/auth/register` answered `The email 'x' is already registered`, turning the form into an oracle for a leaked address list. Login was already hardened against this (constant-time dummy hash); registration was not.

Fix: generic 400 that does not echo the address or confirm existence.
Files: `AuthController.cs`
Test: `Register_WithAnExistingEmail_DoesNotEchoTheAddressBack`

### 8. CSV formula injection (Medium)

Report exports escaped quotes and commas but not leading `= + - @`. A customer or expense description such as `=HYPERLINK("http://evil","open")` executes when the accountant opens the file in Excel or Sheets.

Fix: prefix a single quote on formula-leading text, while leaving plain negative numbers untouched so totals still parse.
Files: `ReportService.cs`
Test: `ReportExport_NeutralisesSpreadsheetFormulaInjection`

### 9. Unbounded statement-link TTL (Medium)

`ttlDays` went straight into `TimeSpan.FromDays`. `int.MaxValue` produced a 500; a merely large value produced a public, never-expiring customer ledger.

Fix: clamp to −365…90 days. Negative values are kept deliberately: they mint an already-expired link, which is how a shared URL is retired.
Files: `StatementsController.cs`
Test: `StatementLink_TtlIsBounded_AndDoesNotCrash`

### 10. Admin console sign-in (Medium)

Four separate problems in the sign-in flow:

1. `/auth/signin` had `.DisableAntiforgery()` — login CSRF.
2. `returnUrl.StartsWith('/')` accepted `//evil.example`, an open redirect.
3. The comment claimed the account's `admin.access` was verified; the code only signed the cookie. A business owner could enter the console (every API call then 403'd).
4. `CookieSecurePolicy.SameAsRequest` behind a TLS-terminating proxy issues a non-Secure admin cookie.

Fix: antiforgery token on the form and validation on the endpoint; `IsLocalPath` rejects protocol-relative and backslash targets; sign-in calls an admin-only endpoint with the fresh token and refuses non-admins with `error=forbidden`; cookie is `Always` outside Development; HSTS, HTTPS redirection and security headers added; forwarded headers configured.
Files: `Khata.Admin/Program.cs`, `AdminApiClient.cs`, `Login.razor`
Verified with a real browser: form token present, admin signs in, business user is refused, `//evil.example` lands back on `/`.

### 11–14. Low-severity hardening

- `/health` now returns only `status` + `ok` flags; details go to the log.
- Kestrel's `Server` header disabled.
- The demo SuperAdmin (`admin@khata.local` / `Admin@12345`) is only seeded in Development/Testing on SQLite, never in Production.
- Device tokens are trimmed before lookup.

### 15–18. Functional bugs found while testing

- **Sign-in ignored the selected business.** `activeBusiness` was assigned `businesses[0]` before the saved selection was consulted, making the switch endpoint's effect vanish on the next login.
- **Hindi was rejected.** The validator allowed `ne`/`en` while the app ships `hi`.
- **Password policy mismatch.** 8–9 character passwords passed validation and then failed in Identity with the wrong message.
- **SuperAdmin lost admin rights after switching** into a business, because the switch path did not merge platform permissions the way login did.

---

## Round 4 details

### 19. Public statement page was cacheable (Medium)

`GET /s/{token}` returns a customer's full ledger — business name, phone, every
transaction, closing balance — as `text/html`. The response carried no cache
directive at all, and HTML is the one content type an intermediary is allowed to
cache *heuristically*, without being told to.

Impact: the link is a bearer credential with a life of up to 90 days. After it
expires, the page could still be served from a proxy cache, a CDN edge, or the
browser's back-forward cache — on a shop's shared phone, that means the next
person to press "back" reads the ledger. There was also no `noindex`, so a leaked
URL could be crawled and archived permanently.

Fix: `Cache-Control: no-store, no-cache, must-revalidate, max-age=0`, `Pragma:
no-cache`, `X-Robots-Tag: noindex, nofollow, noarchive, nosnippet`, and a strict
CSP (`default-src 'none'; style-src 'unsafe-inline'; img-src data:; base-uri
'none'; form-action 'none'; frame-ancestors 'none'`) — the page loads nothing, so
it can deny everything except its inline stylesheet. Verified in a real browser:
no console errors, no CSP violations, layout intact.

Related: `StatementLink:BaseUrl` was applied with `?.TrimEnd('/') ?? fallback`,
so a *blank* configured value produced a relative `/s/…` link instead of falling
back. Now uses `IsNullOrWhiteSpace`.

Files: `Controllers/StatementsController.cs`
Test: `PublicStatement_IsNotCacheableAndCarriesACsp`

### 20. Sign-out CSRF in the admin console (Low)

`/auth/signout` called `.DisableAntiforgery()` and the form in `MainLayout.razor`
carries no token — it cannot, because the layout renders inside the Blazor
circuit, where `<AntiforgeryToken />` emits nothing. `SameSite=Strict` already
stopped the cookie travelling on a cross-site POST, but the endpoint itself
accepted the request.

Fix: an `Origin` check that rejects the request unless the origin's authority
equals the request host. Browsers send `Origin` on every POST, so a missing
header is treated as untrusted rather than waved through.

Files: `Khata.Admin/Program.cs`

### 21. JWT algorithm not pinned (Low)

`TokenValidationParameters` set `ValidateIssuerSigningKey` but not
`ValidAlgorithms`, so the `alg` header of the incoming token chose the
verification algorithm. The classic confusion attack (present an HS256 token
signed with an RSA public key) is only reachable once an asymmetric key exists in
the key set — there is none today — but pinning the algorithm costs one line and
removes the class.

Fix: `ValidAlgorithms = [SecurityAlgorithms.HmacSha256]`.

Files: `Khata.Api/Program.cs`

### Verified, no change needed

- 393 → 394 backend tests pass; `security_probe.py` 45/45.
- Rate limiting re-checked **from a non-loopback address with the shipped
  limits** (10/min): trips at the 10th request and `X-Forwarded-For` cannot reset
  the budget.
- `dotnet list package --vulnerable --include-transitive`: no known CVEs in any
  of the six projects.
- Refresh tokens are stored as a hash with a unique index; replay of a rotated
  token revokes the whole family.
- 500s return an opaque ProblemDetails body; no stack traces or messages.
- Every controller requires `[Authorize]` and per-endpoint permission policies;
  the only anonymous endpoints are `POST /api/auth/{register,login,refresh}`,
  `GET /health` and `GET /s/{token}`.
- Mobile: tokens live in `flutter_secure_storage`, there is no
  `badCertificateCallback`, and nothing logs a token.

---

## Residual risks (not changed)

1. **Access tokens survive logout for up to 15 minutes.** Refresh tokens are revoked; a JWT cannot be un-issued without a per-request token version. The middleware now covers suspension, which is the higher-risk case. Consider a `tv` claim + cache if immediate logout is required.
2. **No email verification.** Anyone can register an address they do not own. Add verification before enabling email-based recovery.
3. **Release APK is signed with the debug keystore** (`android/app/build.gradle.kts`). The debug key is public: anyone can produce an APK that Android accepts as an update. Create a private keystore before distributing.
4. **Live credentials sit in `appsettings.Development.json`** (Supabase password, Atlas URI). The file is gitignored and was never committed, but it is plaintext on disk — prefer `dotnet user-secrets`, and rotate if it was ever shared.
5. **No MFA for platform administrators.** The console can suspend every tenant; a single password is a thin control.
6. **Statement links cannot be revoked early** beyond minting an expired replacement; they are bearer URLs until expiry.
7. **Statement tokens appear in the request log.** `UseSerilogRequestLogging` records `RequestPath`, which for `GET /s/{token}` is the bearer credential itself. Anyone with log access (the Render dashboard, a log drain) can read a customer's ledger until the token expires. Fixing it properly means a custom request-logging template that redacts `/s/` — worth doing before logs leave the host.
8. **The mobile snapshot cache is plaintext.** `core/offline/snapshot_cache.dart` writes customer names, phones and balances to the app documents directory unencrypted, so a rooted device or an ADB backup exposes them. Acceptable for an offline-first khata on a shopkeeper's own phone; encrypt the cache if the threat model includes device seizure.
9. **The admin console sets no CSP.** It is Blazor Server, whose framework script and inline styles make a useful policy fiddly; the console is at least authenticated, `X-Frame-Options: DENY`, and not linked publicly.

---

## Reproducing

```bash
# API on a throwaway SQLite database, raised auth limit so the full probe can run
cd backend/src/Khata.Api
ASPNETCORE_ENVIRONMENT=Development ASPNETCORE_URLS=http://127.0.0.1:5099 \
ConnectionStrings__DefaultConnection="DataSource=khata_sec.db" \
RateLimiting__AuthPermitLimit=1000 dotnet run --no-launch-profile

python scripts/security_probe.py http://127.0.0.1:5099
```

```bash
# Rate limiting must be checked with the shipped limits, from a non-loopback
# address (loopback is a trusted proxy by design)
python scripts/security_probe.py http://<LAN-IP>:5099 --rate-limit-only
```

Regression tests: `backend/tests/Khata.Tests/Integration/SecurityRegressionTests.cs`
Admin console browser check: `scripts/check_admin_login.py`
