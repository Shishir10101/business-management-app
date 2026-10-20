# Offline Synchronization Architecture

> The mobile app is offline-first. Local SQLite (Drift) is the primary
> source of truth on-device. Server sync runs in the background.

---

## 1. Architecture Overview

```
┌─────────────── Flutter App ───────────────┐
│                                            │
│  UI ←→ UseCase ←→ Repository               │
│                    │                       │
│         ┌──────────┼──────────┐            │
│         │          │          │            │
│    Local DS    Sync Queue  Remote DS       │
│    (Drift)   (pending ops)  (Dio)          │
│         │          │          │            │
│         └──────────┼──────────┘            │
│                    │                       │
│              Sync Engine                   │
│         (background isolate)                │
└────────────────────┼───────────────────────┘
                     │ HTTPS
┌────────────────────┼───────────────────────┐
│              ASP.NET API                   │
│         /api/sync/push (batch)            │
│         /api/sync/pull (delta)            │
└────────────────────────────────────────────┘
```

### Design Principles

1. **Never block the user.** All writes go to local DB first, sync later.
2. **Never lose a transaction.** Sync queue is persistent (Drift table).
3. **Idempotent operations.** Server deduplicates by `localId` (UUID).
4. **Eventually consistent.** Conflicts are detected and surfaced, not silently lost.
5. **Minimal payload.** Only deltas are synced (modified since `lastSyncAt`).

---

## 2. Local Database (Drift/SQLite)

### 2.1 Shared Columns

Every syncable local table includes:

| Column | Type | Purpose |
|--------|------|---------|
| `local_id` | TEXT (UUID) | Client-generated primary key |
| `server_id` | INTEGER | Server-assigned ID; null until synced |
| `sync_status` | TEXT | `pending`, `syncing`, `synced`, `failed`, `conflict` |
| `last_modified_at` | INTEGER | Epoch millis; sent to server for conflict detection |
| `version` | INTEGER | Optimistic concurrency version (incremented on each edit) |
| `is_deleted` | INTEGER | 0 or 1; soft delete for sync |

### 2.2 Sync Queue Table

```sql
CREATE TABLE sync_queue (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  local_id      TEXT NOT NULL,          -- references entity.local_id
  entity_type   TEXT NOT NULL,          -- 'sale', 'product', 'customer', etc.
  operation     TEXT NOT NULL,          -- 'create', 'update', 'delete'
  payload       TEXT NOT NULL,          -- JSON snapshot of entity
  attempts      INTEGER NOT NULL DEFAULT 0,
  max_attempts  INTEGER NOT NULL DEFAULT 5,
  next_retry_at INTEGER,                -- epoch millis; null = ready now
  last_error    TEXT,
  status        TEXT NOT NULL DEFAULT 'pending',  -- 'pending', 'processing', 'failed', 'dead'
  created_at    INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL
);
CREATE INDEX ix_sync_queue_status_retry ON sync_queue(status, next_retry_at);
```

### 2.3 Sync State Table

```sql
CREATE TABLE sync_state (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
-- Keys:
-- 'last_pull_at'   → ISO timestamp of last successful pull
-- 'last_push_at'   → ISO timestamp of last successful push
-- 'device_id'      → UUID generated on first launch
```

---

## 3. Sync Engine

### 3.1 Push (Client → Server)

```
SyncEngine.pushPending():
  1. Query sync_queue WHERE status='pending' AND (next_retry_at IS NULL OR next_retry_at <= now)
  2. Batch up to 50 operations
  3. Mark as 'processing'
  4. POST /api/sync/push { operations: [...] }
  5. For each result:
     - success → update entity.server_id, entity.sync_status='synced'
     - conflict → entity.sync_status='conflict'; show notification to user
     - failed → increment attempts; if attempts < max: set next_retry_at = now + backoff
               if attempts >= max: status='dead'; surface to user
  6. Mark sync_queue entries as done (or update retry)
```

### 3.2 Pull (Server → Client)

```
SyncEngine.pullChanges():
  1. Read last_pull_at from sync_state
  2. GET /api/sync/pull?lastSyncAt={last_pull_at}
  3. For each entity in response:
     - If server_id exists locally: update local record with server data
     - If server_id not local: insert new record (created by another device or web)
     - Handle deletion: mark local record as deleted
  4. Update last_pull_at = response.serverTimestamp
```

### 3.3 Sync Triggers

| Trigger | Action |
|---------|--------|
| App foreground | Pull if > 5 min since last sync |
| After local write | Enqueue + push immediately if online |
| Connectivity restored | Push all pending + pull |
| Manual sync (settings) | Full push + pull |
| Periodic (background) | Every 15 min (WorkManager) if online |

### 3.4 Retry Strategy

Exponential backoff with jitter:

```
attempt 1: immediate
attempt 2: 5s + jitter(0-2s)
attempt 3: 15s + jitter(0-5s)
attempt 4: 60s + jitter(0-10s)
attempt 5: 300s + jitter(0-30s)
attempt 6+: status='dead' (requires manual retry)
```

### 3.5 Conflict Resolution

| Conflict Type | Detection | Resolution |
|---------------|----------|------------|
| Modified by other | Client sends `version`; server has higher version | Server returns current version → user decides: keep mine / keep server / merge |
| Deleted by other | Client sends update; server record is deleted | Auto-resolve: respect deletion, mark local as deleted, notify user |
| Duplicate create | Same `localId` already synced | Server returns existing `serverId` → update local mapping, no duplicate |

Conflicts are **never silently resolved**. The app shows a conflict banner
with the two versions side by side. The user chooses.

For financial records (sales, purchases, payments), conflicts are rare
because they are typically created on one device and the financial
immutability rule means they are rarely edited. The main conflict scenario
is editing a customer's name on two devices simultaneously.

---

## 4. Entity Lifecycle

### 4.1 Create Flow

```
User creates Sale (offline):
  1. Generate UUID → sale.local_id
  2. Insert into sales table (sync_status='pending', server_id=NULL)
  3. Reduce local stock (insert stock_movement)
  4. Create local ledger_transaction
  5. Insert sync_queue entry (operation='create', payload=sale JSON)
  6. UI shows sale immediately with 'pending sync' badge

Sync pushes to server:
  1. POST /api/sync/push
  2. Server creates sale → assigns server_id=34
  3. Server processes financial side effects (stock, ledger)
  4. Returns { localId: uuid, serverId: 34, status: 'success' }
  5. Client updates: sale.server_id=34, sale.sync_status='synced'
  6. Sync queue entry removed
```

### 4.2 Update Flow

```
User edits customer name (offline):
  1. Update customer record locally
  2. Increment customer.version
  3. Update customer.last_modified_at
  4. Insert sync_queue entry (operation='update', payload=customer JSON)
  5. UI shows updated name with 'pending sync' badge

Sync pushes to server:
  1. Server checks version: if server.version >= client.version → conflict
  2. If OK → update server record, increment server.version
  3. Return { status: 'success' } or { status: 'conflict', serverVersion: {...} }
```

### 4.3 Delete Flow

```
User deletes expense (offline):
  1. Mark expense.is_deleted=1 (soft delete)
  2. Insert sync_queue entry (operation='delete', payload={localId, version})
  3. UI hides expense from list

Sync pushes to server:
  1. Server soft-deletes record (sets deleted_at)
  2. Return { status: 'success' }
  3. Client removes sync_queue entry; local record stays soft-deleted
```

---

## 5. Bidirectional Sync: Relationship Handling

When a sale syncs to the server, the server creates:
- sale record
- sale_item records
- stock_movement records
- ledger_transaction records

On pull from server, the client must reconcile:
- If sale came from this device (server_id already mapped) → skip
- If sale came from another device → insert sale + sale_items + stock_movements + ledger_transactions locally

The server response for `/api/sync/pull` includes all related entities in the
payload to avoid N+1 round trips:

```json
{
  "serverTimestamp": "2026-10-08T10:06:30Z",
  "sales": [...],
  "saleItems": [...],
  "stockMovements": [...],
  "ledgerTransactions": [...],
  "payments": [...],
  "customers": [...],
  "products": [...]
}
```

---

## 6. Network Detection

```dart
// connectivity_plus package
final connectivityStream = Connectivity().onConnectivityChanged;

// SyncEngine listens and triggers sync when:
// - Status changes from none → wifi/mobile
// - After a 2-second debounce to avoid rapid reconnect thrash
```

### Connectivity States

| State | Behavior |
|-------|----------|
| WiFi | Full sync (push + pull) |
| Mobile data | Full sync (push + pull) |
| None (offline) | All writes go to local DB; sync queue accumulates |
| Unknown | Treat as offline; attempt sync on next change event |

---

## 7. Error Handling

| Error | Action |
|-------|--------|
| 401 Unauthorized | Refresh token; if refresh fails → logout user |
| 409 Conflict | Mark entity as 'conflict'; show conflict resolution UI |
| 422 Business rule violation | Mark as 'failed'; show error to user; do not retry |
| 429 Rate limited | Read `Retry-After` header; set next_retry_at |
| 500 Server error | Retry with backoff (likely transient) |
| Network timeout | Retry with backoff |
| Payload too large | Split batch; retry with smaller batch |

### Dead Letter Queue

After 5 failed attempts, a sync_queue entry is marked `dead`. The user
sees a persistent notification: "1 operation failed to sync. Tap to review."
Tapping opens a screen listing dead operations with error details and
manual retry / discard options.

---

## 8. Sync Status UI

### 8.1 Global Indicator

A small icon in the app bar shows sync status:

| State | Icon | Color |
|-------|------|-------|
| All synced | check_circle | success (green) |
| Syncing | cloud_upload | primary (blue) |
| Pending operations | cloud_off | warning (amber) |
| Failed operations | error_outline | error (red) |

### 8.2 Per-Record Badge

Each list item that is pending sync shows a small amber dot in the corner.
Tapping the dot shows "Pending sync — will upload when online."

### 8.3 Sync Settings

In Settings > Sync:
- Last sync time
- Pending operations count
- Failed operations count
- Manual "Sync Now" button
- Auto-sync toggle (on/off)
- Sync on WiFi only toggle

---

## 9. Offline Reads (as built)

The protocol above keeps the *server* and the *queue* honest. Reading a screen
offline is a separate problem, and it is solved with a much smaller mechanism
than a full local database.

### 9.1 What is cached

A **snapshot cache** (`lib/core/offline/snapshot_cache.dart`) stores the last
response body a list screen rendered, keyed by query:

```
b7-u42:products:list:::<search>:<categoryId>:<page>:<pageSize>
b7-u42:products:categories
b7-u42:customers:list::1:50
```

The prefix is `b<business>-u<user>`, decoded from the JWT's `bid` and `sub`
claims — the same values the server scopes every query by — so a list cached in
one business can never be served in another. Without a token nothing is cached.

This is deliberately **not** the sync store (`features/sync/data/local`): that
one mirrors server rows for push/pull and is only filled by a sync. A screen
never has to understand the sync payload shape, and a failed read never touches
sync state.

### 9.2 Read path

`readThroughCache` (`lib/core/offline/cached_read.dart`):

1. Call the API. On success, write the body to the cache and return it.
2. On failure, fall back **only** when it is a network failure — no response,
   timeout, DNS, or a 5xx. A 4xx (`401`, `404`, `422`) is a real answer and is
   rethrown: stale data must never hide a permission or validation problem.
3. With nothing cached, rethrow — the screen shows its normal error state.

Screens show a note (`CachedDataNote`) naming the time the copy was saved when
a read was served from disk, and it clears itself as soon as a live read
succeeds.

### 9.3 Limits

- One JSON file (`khata_snapshots.json`), at most 24 snapshots / 3 MB; the
  least-recently-used entry is dropped first.
- Every cache operation degrades to "no cache" instead of throwing: a missing
  documents directory, a corrupt file or a full disk must never take a screen
  down. `SnapshotCache.isPersistent` reports whether writes reach the disk.
- Covered today: product list, categories, units, customer list, supplier list.
  Ledger detail, reports and the dashboard still read from the API only.
- The sync page shows how much is saved and can clear it (a shared phone should
  not keep the previous user's balances).
- Verification: `tool/verify_offline_cache.dart` runs the whole layer as a plain
  Dart program (`dart run tool/verify_offline_cache.dart`), because
  `flutter test` cannot start in this environment. `test/offline_cache_test.dart`
  covers the same cases for CI.

---

## 10. Offline Writes (as built)

Phase 9's last gap: the queue, the push endpoint and the conflict UI all
existed, but every form still POSTed straight to the API and failed when the
signal dropped. Saves now survive a dead connection.

### 10.1 Where the queue is applied

`lib/core/offline/offline_queue.dart` — `OfflineQueue`, the write-side twin of
`readThroughCache`. Each **remote data source** wraps its write calls:

```dart
final result = await _queue.create(
  entityType: 'customer',
  body: body,                                   // the exact body the API gets
  send: () async => (await _dio.post('/customers', data: body)).data,
);
return result.value!;                           // server body, or an optimistic one
```

Because the *same* map is both the HTTP body and the queued payload, the
offline path cannot drift from the online one. Wired today:

| Entity | create | update | delete |
|---|---|---|---|
| customer | ✅ | ✅ | ✅ |
| supplier | ✅ | ✅ | ✅ |
| product | ✅ | ✅ | ✅ |
| expense | ✅ | ✅ | ✅ |
| income | ✅ | ✅ | ✅ |
| sale | ✅ | — (online only) | — (online only) |

Purchases, payments, quotations and invoices stay online-only: the server's
push protocol has no operation for them (stock movements and ledger entries are
derived from the document), so queueing them would only produce rejections.
Categories and units are also online-only for the same reason.

### 10.2 What may be queued

Only a request that never got an answer (`isWriteInterruption`): no response at
all, a connection/receive timeout, `SocketException`, `TimeoutException`,
`HttpException`.

- A **4xx** is a refusal (validation, permission, not found) — rethrown, the
  form shows the error, nothing is queued.
- A **5xx** may have committed the write before it failed. Replaying it could
  create a second sale or payment, so it is rethrown as an error and the user
  decides whether to retry.
- A **cancelled** request is never queued.

### 10.3 Temporary ids and the remap

A record created offline does not have a server id yet, so the queue invents
one: negative (it can never collide with a real id), derived from the clock,
and used as the operation's `entityId`. The form receives an optimistic body
(`{...body, id: -1234…}`) so it can close normally.

When the push succeeds, the server answers with the id it assigned.
`SyncRepositoryImpl._pushQueue` then calls `LocalCacheStore.remapEntityId`,
which moves the cached row to the real id **and rewrites every still-queued
operation for that record**. Without this, an offline create followed by an
offline edit would be rejected forever with "record does not exist". The
`duplicate` status carries the same id, so a client that crashed between
applying and remapping repairs itself on the next sync.

### 10.4 What the user sees

- The form says **"Saved offline — it will sync when you reconnect"** instead of
  the usual "Saved". The forms compare `OfflineQueue.queuedCount` before and
  after the save, so the message is accurate per save.
- The offline banner is now localized and appends the waiting count
  (`Offline — changes will sync when you're back · 3 waiting`).
- `/sync` lists the pending operations and the failed ones as before.

### 10.5 Known limits

- A queued create is **not** injected into the cached list, so an item created
  offline appears after the next sync, not immediately. The snackbar says so.
- Offline updates carry no `baseUpdatedAt` (the list entities do not keep the
  server's `updatedAt`), so the server applies them last-write-wins instead of
  reporting a conflict.
- A queued write is replayed exactly once per sync cycle; a network failure
  during push keeps the operation queued and bumps its `attempts`.
- Verification: `dart run tool/verify_offline_queue.dart` (47 checks) and
  `test/offline_queue_test.dart` for CI.
