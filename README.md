# Nepal Digital Khata — Business Management App

A production-quality, Nepal-focused digital business management application combining
digital khata (ledger), sales, purchases, inventory, invoicing, and reporting for
small and medium businesses in Nepal.

## Download the app

**Latest APK:** [github.com/Shishir10101/business-management-app/releases/latest](https://github.com/Shishir10101/business-management-app/releases/latest)

Every version ships as a GitHub Release with the `.apk` attached. Release assets are **not**
part of the repository file tree, so the APK will never appear in the code listing above —
it lives under **Releases**, in the right-hand sidebar of the repository page.

Installed copies check for a newer release on launch and offer the download themselves, so
publishing a release is all it takes to ship an update.

## Monorepo Structure

```
business-management-app/
├── apps/
│   └── mobile/              # Flutter app — the client that ships
├── backend/
│   ├── src/
│   │   ├── Khata.Api/           # ASP.NET Core 10 Web API
│   │   ├── Khata.Admin/         # Blazor Server admin console
│   │   ├── Khata.Domain/
│   │   ├── Khata.Application/
│   │   └── Khata.Infrastructure/
│   ├── tests/Khata.Tests/       # 394 backend tests
│   └── Khata.slnx
├── docs/                    # Architecture, security audit, roadmap
├── infrastructure/          # Dockerfile.api, docker-compose.dev.yml
├── scripts/                 # Build, release, E2E and security probes
├── .github/workflows/       # CI
└── render.yaml              # API deployment blueprint
```

## Tech Stack

| Layer        | Technology                          |
|-------------|--------------------------------------|
| Mobile       | Flutter, Dart, Riverpod, Dio, GoRouter |
| Backend      | ASP.NET Core 10, EF Core 10, C#      |
| Ledger       | PostgreSQL (Supabase)                |
| Documents    | MongoDB Atlas (audit log, sync journal, notifications, backups) |
| Admin        | Blazor Server                        |
| Auth         | ASP.NET Core Identity, JWT           |
| Infra        | Docker, GitHub Actions, Render       |

## Documentation

All architecture and design documents live in [`/docs`](./docs). Start with:

1. [Architecture](docs/architecture.md)
2. [Database Schema](docs/database.md)
3. [API Design](docs/api.md)
4. [Offline Sync](docs/offline-sync.md)
5. [Design System](docs/design.md)
6. [Security](docs/security.md)
7. [Nepal Localization](docs/nepal-localization.md)
8. [Roadmap](docs/roadmap.md)
9. [Testing](docs/testing.md)
10. [Task List](docs/task-list.md)
11. [Privacy Policy](docs/privacy.md)

Release history is in [`CHANGELOG.md`](CHANGELOG.md).

## Development

```bash
# Backend
cd backend
dotnet restore Khata.slnx
dotnet build Khata.slnx
dotnet run --project src/Khata.Api

# Backend tests — 394 tests, no credentials or network needed
# (SQLite + Mongo disabled; the suite is self-contained by design)
dotnet test backend/tests/Khata.Tests/Khata.Tests.csproj

# Mobile
cd apps/mobile
flutter pub get
flutter run

# Mobile checks — run all four after touching Dart, and re-run gen_l10n
# after any `flutter build web` (the build overwrites the generated file)
python scripts/check_flutter_syntax.py
python scripts/check_flutter_imports.py
python scripts/check_localizations.py
python scripts/gen_l10n.py --check
```

Running the API locally without PostgreSQL:

```bash
cd backend/src/Khata.Api
ASPNETCORE_ENVIRONMENT=Development ASPNETCORE_URLS=http://localhost:5000 \
  ConnectionStrings__DefaultConnection="DataSource=khata_demo.db" \
  dotnet run --no-launch-profile
```

## Status

| Phase | Focus | Status |
|-------|-------|--------|
| 1 | Foundation: auth, DB, API skeleton, Flutter architecture | ✅ Complete |
| 2 | Business setup, profile, business switching, staff management | ✅ Complete |
| 3 | Products, categories, inventory | ✅ Complete |
| 4 | Customers, suppliers, digital khata | ✅ Complete |
| 5 | Sales, purchases, expenses, income | ✅ Complete |
| 6 | Payments, ledger, balances | ✅ Complete |
| 7 | Invoices, PDF, sharing | ✅ Complete |
| 8 | Dashboard, reports | ✅ Complete |
| 9 | Offline synchronization | ✅ Reads + writes for push-supported entities |
| 10 | Notifications, reminders, backup | ✅ On-device complete · FCM push pending credentials |
| 11 | Nepali localization, BS calendar, polish | ✅ Complete (en / ne / hi) |
| 12 | Admin console, advanced features | ✅ Console complete · payment/SMS/email pending credentials |

**Not in 1.0:** Firebase push, eSewa/Khalti/Fonepay payments, SMS/email delivery,
subscription billing, background sync, dead-letter queue. Each needs a
third-party account or a billing model, not code. See
[`docs/roadmap.md`](docs/roadmap.md) for the reasoning.

## Releasing

The APK ships as a **GitHub Release asset**; installed copies read
`/releases/latest` on launch and offer the update themselves, so publishing a
release *is* shipping a version.

```bash
python scripts/release_apk.py --bump patch \
  --api-base https://<your-api-host>
```

Release notes are **not** passed on the command line. The script reads
`CHANGELOG.md`, promotes the `## [Unreleased]` section to `## [X.Y.Z] - <date>`,
and uses that section as the GitHub release body — so the notes on the release
page cannot drift from the repository, and cutting a release fails loudly if
nobody wrote them. `--notes "…"` overrides the body for a one-off.

`--api-base` is mandatory and must be public HTTPS: the app's compiled-in
default is `http://localhost:5000`, which a phone resolves to itself, so a build
without it installs and then cannot reach any server. The script refuses such a
build rather than publishing it.

**One-time setup, before the first release:**

1. **Create the upload keystore** and `apps/mobile/android/key.properties`
   (both gitignored). The release build currently falls back to the *debug* key
   and logs a warning — an APK signed with it cannot be updated in place later,
   because Android only accepts an update signed with the same key.
   ```bash
   keytool -genkey -v -keystore ~/khata-upload.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias khata
   ```
   `key.properties`:
   ```properties
   storePassword=…
   keyPassword=…
   keyAlias=khata
   storeFile=/absolute/path/to/khata-upload.jks
   ```
   Back this file up somewhere that is not git. Losing it means every installed
   copy has to be uninstalled before it can be updated.

2. **Deploy the API** and record its URL. `render.yaml` is ready; the database
   connection string, Mongo URI and admin bootstrap credentials are entered in
   the Render dashboard (they are `sync: false` on purpose).
   `ConnectionStrings__DefaultConnection` must be the Supabase **session pooler**
   host — the direct host is IPv6-only and unreachable from most Nepali ISPs.

3. **Apply migrations** to the production database. The API does not migrate on
   startup: `dotnet ef database update` with the production connection string.

**Release-day checks:** CI green · keystore present · `/health` returns `ok` ·
`python scripts/security_probe.py https://<host>` passes · a clean install
signs in and records one sale · the previous version offers the update.


## License

Proprietary. All rights reserved. See [`LICENSE`](LICENSE) for the full terms —
this is not an open-source project, and no rights are granted by the source
being readable here. Third-party dependencies keep their own licences.
