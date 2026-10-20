import 'package:drift/drift.dart';

/// Local (offline-first) database schema for the mobile app.
///
/// This file defines the table layout that mirrors the server entities.
/// The generated `AppDatabase` class (queries, migrations, DAOs) is added in
/// Phase 9 (offline sync) by running build_runner:
///   flutter pub run build_runner build --delete-conflicting-outputs
///
/// Until then these table definitions compile standalone (Drift tables need
/// no code generation) and serve as the schema of record.
///
/// Conventions:
/// - Money is stored as integer paisa (mirrors the API).
/// - BusinessId on every tenant-scoped table for sync payloads and filtering.
/// - Soft delete via DeletedAt (null = not deleted).
class LocalUsers extends Table {
  IntColumn get id => integer()();
  TextColumn get email => text()();
  TextColumn get fullName => text()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get locale => text().withDefault(const Constant('ne'))();
  TextColumn get timezone =>
      text().withDefault(const Constant('Asia/Kathmandu'))();
  IntColumn get activeBusinessId => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalBusinesses extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get type => text().nullable()();
  TextColumn get panNumber => text().nullable()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get addressLine => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get district => text().nullable()();
  TextColumn get province => text().nullable()();
  TextColumn get wardNumber => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('NPR'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalBusinessMembers extends Table {
  IntColumn get id => integer()();
  IntColumn get businessId => integer()();
  IntColumn get userId => integer()();
  IntColumn get roleId => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Outbound sync queue: every mutation made offline is appended here and
/// drained by the sync engine (Phase 9). Operations are idempotent server-side.
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // e.g. "sale", "product", "payment"
  IntColumn get entityId => integer()(); // local id of the entity
  TextColumn get operation => text()(); // create | update | delete
  TextColumn get payload => text()(); // JSON serialized entity
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Tracks the last successful pull timestamp per entity type so sync can
/// request only server changes since then.
class SyncState extends Table {
  TextColumn get entityType => text()();
  DateTimeColumn get lastPulledAt => dateTime()();

  @override
  Set<Column> get primaryKey => {entityType};
}
