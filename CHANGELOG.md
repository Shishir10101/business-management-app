# Changelog

All notable changes to Nepal Digital Khata are recorded here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and
the project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Versions match the `version:` field in `apps/mobile/pubspec.yaml` and the git
tag (`vX.Y.Z`).

`scripts/release_apk.py` reads this file: the section for the version being cut
becomes the GitHub release body, so a release can never ship with notes that
disagree with the repository.

## [Unreleased]

<!--
Everything below is on `main` but not in a published APK: the `v1.0.0` tag points
at `c8e3e1c`, and seven commits plus the release-readiness work have landed since.
Kept as a comment so it never becomes the opening line of a GitHub release body.
-->

### Added

- **VAT registers** for sales and purchases (`/api/reports/vat-register/*`),
  with per-party taxable amount, tax and total, plus CSV export.
- **Receivables/payables aging** (`/api/reports/receivables-aging`) — open
  balances bucketed by invoice age, with an explicit `asOf` reference date.
- **Signed customer statement links** (`GET /s/{token}`) — an expiring,
  unguessable URL that renders a customer's whole ledger as printable HTML,
  so a shop can send a statement over Viber without an account.
- **Business suspension** via `BusinessStatusMiddleware`: an inactive user gets
  401 and an inactive or deleted business gets 403 on every endpoint except
  `/api/businesses`, with a 30-second cache evicted when an admin acts.
- **CI** (`.github/workflows/ci.yml`): backend build and test on `Khata.slnx`,
  mobile analyze, the four Dart checkers, `flutter test`, and a
  `docker build` of `Dockerfile.api`.
- **Release signing** driven by `apps/mobile/android/key.properties`, so a
  release APK is no longer signed with the debug key.
- **Adaptive vector launcher icon** and matching web icons, replacing the
  default Flutter branding.
- **Security tooling**: `scripts/security_probe.py` (45 checks),
  `scripts/check_admin_login.py`, and [`docs/SECURITY-AUDIT.md`](docs/SECURITY-AUDIT.md).

### Changed

- **Password policy, refresh-token replay detection and constant-time
  authentication.** A replayed refresh token now revokes the family; a password
  change or suspension revokes every refresh token for that user.
- **JWT validation pins `HmacSha256`** instead of accepting any algorithm the
  token names.
- **Rate limiting and security headers** on the API; forwarded headers are
  loopback-only unless `ForwardedHeaders__TrustAll=true` is set.
- **`/health` survives a database blip** and reports the ledger and Atlas
  separately, returning 503 when the ledger is down or Atlas is configured but
  unreachable.
- **`scripts/release_apk.py` refuses an unusable build**: `--api-base` is
  mandatory, must be public HTTPS, and rejects loopback and private ranges.
  `--allow-local-api` is the escape hatch for internal test builds.
- **`infrastructure/Dockerfile.api` restores `Khata.slnx`**, not the
  non-existent `Khata.sln` that made every container build fail at restore.
- **`pubspec.lock` is committed** — a release build must resolve the dependency
  graph the tests passed against.
- **Web metadata** no longer says "A new Flutter project."

### Fixed

- **`StatementLink:BaseUrl` blank value** produced a relative `/s/…` link
  instead of falling back to the configured host.
- **Customer statements were cacheable.** A bearer URL for a whole ledger
  returned `text/html` with no `Cache-Control`, so a proxy could serve it after
  the link expired. Now `no-store`, `X-Robots-Tag: noindex`, and a strict CSP.
- **Admin `/auth/signout` had no CSRF defence.** Antiforgery tokens cannot be
  rendered inside the Blazor circuit, so the endpoint checks `Origin` against
  `Host` instead and rejects a missing `Origin`.
- **Document statuses were untranslated** in list views.
- **Signing out left the ledger on the device.** `LocalCacheStore.clear()` was
  written and documented for exactly this, but nothing called it: the cache is a
  plaintext JSON file and it is not keyed by user or business, so the next
  account on a shared shop phone could read the previous tenant's data. Sign-out
  now wipes the records, the pending queue and the sync cursor.
- **`demo_session.dart` imported `app_config.dart` one directory too high.** It
  only resolved because a `package:` URI that climbs above the package root
  clamps there, so the analyzer accepted a path the import checker rejected.
- **A date-rot test.** `ReceivablesAging_BucketsOpenBalancesByInvoiceAge`
  hard-coded sale dates while asserting relative ages, so it passed on the day
  it was written and failed three weeks later with no code change. It now pins
  the reference date through the endpoint's `asOf` parameter.

### Security

Three hardening rounds, all verified against a live instance; details and
reproduction steps are in [`docs/SECURITY-AUDIT.md`](docs/SECURITY-AUDIT.md).
Residual risks are documented there rather than silently accepted: statement
tokens appear in the request log, the mobile snapshot cache is plaintext, the
admin console has no CSP, and there is no MFA.

## [1.0.0] - 2026-10-20

First published release.

### Added

- Digital khata with customers, suppliers and running balances.
- Sales, purchases, expenses and income, with payment allocation against
  invoices and a full ledger per party.
- Products, categories and inventory, including stock movements and valuation.
- Invoices with PDF generation and sharing.
- Reports: dashboard, profit and loss, sales, purchases, stock, receivables and
  payables, each exportable as CSV.
- Offline reads and writes for push-supported entities, with a local queue that
  replays on reconnect and remaps temporary ids.
- Nepali localization (en / ne / hi) with Bikram Sambat calendar support.
- Blazor admin console for businesses, users and platform operations.
- In-app update check against GitHub Releases, so publishing a release is all
  it takes to ship an update.
- On-device reminders, notifications and backup.

### Known limitations

Firebase push, eSewa/Khalti/Fonepay payments, SMS and email delivery,
subscription billing, background sync and a dead-letter queue are not in 1.0.
Each needs a third-party account or a billing model rather than code; see
[`docs/roadmap.md`](docs/roadmap.md).

[Unreleased]: https://github.com/Shishir10101/business-management-app/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Shishir10101/business-management-app/releases/tag/v1.0.0
