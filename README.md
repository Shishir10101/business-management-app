# Nepal Digital Khata — Business Management App

A production-quality, Nepal-focused digital business management application combining
digital khata (ledger), sales, purchases, inventory, invoicing, and reporting for
small and medium businesses in Nepal.

## Monorepo Structure

```
business-management-app/
├── apps/
│   ├── mobile/          # Flutter mobile app (primary client)
│   └── admin-web/       # Admin web app (future)
├── backend/             # ASP.NET Core 10 Web API
│   ├── src/
│   └── tests/
├── docs/                # Architecture & design documentation
├── infrastructure/      # Docker, CI/CD, deployment configs
├── scripts/             # Build & utility scripts
└── .gitignore
```

## Tech Stack

| Layer        | Technology                          |
|-------------|--------------------------------------|
| Mobile       | Flutter, Dart, Riverpod, Dio, Drift |
| Backend      | ASP.NET Core 10, EF Core 10, C#      |
| Database     | PostgreSQL (server), SQLite (local)  |
| Auth         | ASP.NET Core Identity, JWT           |
| Infra        | Docker, GitHub Actions, S3-compatible |
| Notifications | Firebase Cloud Messaging            |

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

## Development

```bash
# Backend
cd backend
dotnet restore Khata.slnx
dotnet build Khata.slnx
dotnet run --project src/Khata.Api

# Backend tests (39 tests: JWT unit + validator unit + API integration on SQLite)
dotnet test backend/tests/Khata.Tests/Khata.Tests.csproj

# Mobile (dart pub get also works without the Flutter tool)
cd apps/mobile
flutter pub get
flutter run
```

## Status

| Phase | Focus | Status |
|-------|-------|--------|
| 1 | Foundation: auth, DB, API skeleton, Flutter architecture | ✅ Complete |
| 2 | Business setup, profile, business switching, staff management | ✅ Complete |
| 3 | Products, categories, inventory | ⏳ Next |
| 4-12 | Khata, transactions, payments, invoices, reports, sync, ... | Pending |

See [docs/roadmap.md](docs/roadmap.md) for the full plan.

## License

Proprietary. All rights reserved.
