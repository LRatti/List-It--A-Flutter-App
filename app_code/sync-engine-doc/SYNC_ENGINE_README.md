# Sync Engine Implementation - Complete Guide

## Status

✅ **Core Sync Engine Implemented** - All architectural components created and ready for integration

## What Has Been Implemented

### 1. **Database Schema** ✅
- Added `sync_box` table to SQLite with columns:
  - `id`: Unique sync entry ID
  - `entity_id`: ID of the entity being synced
  - `entity_type`: Type of entity (e.g., 'shopping_list', 'product')
  - `operation`: Type of operation (upsert/delete)
  - `last_modified`: Timestamp for LWW conflict resolution
  - Indexes on `entity_type` and `last_modified` for efficient querying

### 2. **Core Models & Enums** ✅
- `SyncOperation` enum: `upsert`, `delete`
- `LocalSyncEntry` model: Represents a pending sync operation
- Database mapping methods (`toDatabase()`, `fromDatabase()`)

### 3. **Database Management** ✅
- `ManageSyncBox` class in `lib/services/database/sqlite/manage_sync_box.dart`
  - `addOrUpdateSyncEntry()`: Append/update with timestamp comparison
  - `getAllSyncEntries()`: Batch read for sync processing
  - `getSyncEntry()`: Check individual entries
  - `deleteSyncEntry()`: Conditional delete to prevent race conditions
  - `isEntityDirty()`: Check if entity has pending changes

### 4. **Sync Engine - Push (Local → Remote)** ✅
- `SyncEnginePush` in `lib/services/sync/sync_engine_push.dart`
- **Features**:
  - Batch read of sync_box entries
  - Firestore transaction with LWW resolution
  - Remote is newer → don't write
  - Local is newer → write with `FieldValue.serverTimestamp()`
  - Conditional post-process cleanup (`WHERE entity_id = ? AND last_modified <= ?`)
  - Error resilience: leaves entry in sync_box on failure for retry
  - Concurrency control (max 3 concurrent operations)

### 5. **Sync Engine - Pull (Remote → Local)** ✅
- `SyncEnginePull` in `lib/services/sync/sync_engine_pull.dart`
- **Strategy A - Cold Start Delta Sync**:
  - Reads `lastSyncedAt` from SharedPreferences
  - Queries Firestore for documents where `lastModified > lastSyncedAt`
  - Pagination support (batch size: 100)
  - Applies updates via `applyRemoteUpdate()` (silent, no sync_box)
  - Updates `lastSyncedAt` with newest timestamp
- **Strategy B - Live Snapshot Listeners**:
  - Sets up snapshot listeners for all entity types
  - Handles document changes (added, modified, removed)
  - Idempotent updates (same payload multiple times = same state)
  - Updates `lastSyncedAt` incrementally
- **Silent Update Logic**:
  - Check if entity is dirty (pending sync) - if yes, ignore
  - Compare timestamps - only update if remote is newer
  - Physical delete for `isDeleted=true` from remote
  - Never writes to sync_box

### 6. **Connectivity Monitoring** ✅
- `ConnectivityMonitor` in `lib/services/sync/connectivity_monitor.dart`
- Monitors internet connectivity changes
- Triggers sync on reconnection
- Handles offline periods gracefully

### 7. **Sync Manager** ✅
- `SyncManager` in `lib/services/sync/sync_manager.dart`
- **Central Coordinator**:
  - Initializes push/pull engines
  - Manages periodic sync (10-second interval, configurable)
  - Monitors connectivity
  - Triggers sync on reconnection
  - Manual sync trigger support (`triggerManualSync()`)
  - Proper resource cleanup

### 8. **Repository Sync Support** ✅
- `SyncRepository` abstract class in `lib/repositories/sync/sync_repository.dart`
  - `applyRemoteUpdate()`: Silent update interface
  - `getLocalData()`: For timestamp comparison
  - `getEntityType()`: Entity type identifier
- `SyncRepositoryMixin` in `lib/repositories/sync/sync_repository_mixin.dart`
  - `appendUpsertToSyncBox()`: User write marker
  - `appendDeleteToSyncBox()`: Delete marker
  - `isEntityDirty()`: Check pending changes
- **Entity Type Constants**:
  - `ENTITY_TYPE_SHOPPING_LIST`
  - `ENTITY_TYPE_PRODUCT`
  - `ENTITY_TYPE_PURCHASED_PRODUCT`
  - `ENTITY_TYPE_CATEGORY`
  - `ENTITY_TYPE_SUPERMARKET`
  - `ENTITY_TYPE_USER`

### 9. **Utility Functions** ✅
- `MonotonicTimestamp` in `lib/utils/monotonic_timestamp.dart`
  - `generateNext()`: Ensures strictly increasing timestamps
  - `merge()`: Combines local and server time

### 10. **Riverpod Integration** ✅
- `sync_manager_provider.dart` with:
  - `syncRepositoryRegistryProvider`: Maps entity types to repositories
  - `syncManagerProvider`: Provides initialized SyncManager
  - `syncInitializedProvider`: Tracks initialization status
- Auto-initialization in `main.dart`
- Proper lifecycle management and disposal

### 11. **Documentation** ✅
- `SYNC_ENGINE_GUIDE.md`: Complete integration guide with examples
- Inline code comments explaining sync flow
- Testing patterns and troubleshooting guide

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
│          (Watches Riverpod providers)                        │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│                    Repository Layer                          │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ User Writes              │  Sync Writes (Silent)        ││
│  │ ├─ add()                 │  ├─ applyRemoteUpdate()     ││
│  │ ├─ update()              │  └─ NO sync_box append      ││
│  │ ├─ delete()              │                              ││
│  │ └─ sync_box append       │  Entity Check:              ││
│  │                          │  ├─ if dirty: ignore        ││
│  │                          │  ├─ if remote newer: apply  ││
│  │                          │  └─ if deleted: phys del    ││
│  └─────────────────────────────────────────────────────────┘│
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│                     SQLite Database                          │
│  ┌──────────────────┐    ┌─────────────────────────────────┐│
│  │ Entity Tables    │    │  sync_box (Queue)              ││
│  │ ├─ shopping_list │    │  ├─ id                         ││
│  │ ├─ product       │    │  ├─ entity_id                  ││
│  │ ├─ purchased...  │    │  ├─ entity_type                ││
│  │ └─ category      │    │  ├─ operation                  ││
│  │                  │    │  └─ last_modified              ││
│  └──────────────────┘    └─────────────────────────────────┘│
│                                                               │
│  lastModified, isDeleted columns on all synced tables       │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│                      Sync Engine                             │
│  ┌──────────────────────────┐  ┌────────────────────────────┐│
│  │   Push (Local → Remote)  │  │  Pull (Remote → Local)     ││
│  │   SyncEnginePush         │  │  SyncEnginePull            ││
│  │                          │  │                            ││
│  │ ├─ Read sync_box batch   │  │ ├─ Cold Start (Delta)      ││
│  │ ├─ Firestore transaction │  │ │ ├─ Read lastSyncedAt    ││
│  │ ├─ LWW resolution        │  │ │ ├─ Query > lastSyncedAt  ││
│  │ ├─ serverTimestamp()     │  │ │ └─ Pagination            ││
│  │ └─ Cleanup sync_box      │  │ │                          ││
│  │                          │  │ └─ Live Listeners          ││
│  │   Errors → Retry Later   │  │   (Snapshot listeners)    ││
│  └──────────────────────────┘  └────────────────────────────┘│
│                                                               │
│              Managed by: SyncManager                         │
│              ├─ Periodic sync (10s interval)                │
│              ├─ Connectivity monitoring                     │
│              ├─ Sync on reconnection                        │
│              └─ Lifecycle management                        │
└────────────────────────────┬────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────┐
│                    Firestore Database                        │
│  Collections:                                                │
│  └─ Users/{uid}/                                             │
│     ├─ shopping_list   (+ lastModified, isDeleted)          │
│     ├─ product         (+ lastModified)                      │
│     ├─ purchased_product (+ lastModified, isDeleted)        │
│     ├─ category        (+ lastModified)                      │
│     └─ supermarket     (+ lastModified)                      │
│                                                               │
│  All lastModified use: serverTimestamp()                    │
└────────────────────────────────────────────────────────────┘
```

## Key Features Implemented

### ✅ Offline-First Writes
- User writes immediately go to SQLite
- sync_box marks changes for background sync
- Returns to UI immediately
- No blocking network calls

### ✅ Last-Write-Wins (LWW) Conflict Resolution
- Uses `lastModified` timestamps
- Firestore transaction ensures consistency
- Server timestamp takes precedence after sync

### ✅ Soft Deletes
- User delete sets `isDeleted = 1` locally
- Sync marks with `operation: delete`
- Remote echo triggers physical delete from SQLite
- Queries filter out soft-deleted items

### ✅ Monotonic Timestamps
- Prevents false conflicts from rapid updates
- `generateNext()` ensures strictly increasing time
- Used for both local writes and merges

### ✅ Dirty State Tracking
- Entities with pending sync are "dirty"
- Silent updates skip dirty entities
- Preserves local changes until synced

### ✅ Crash Recovery
- sync_box entries persist across crashes
- Retry on reconnection
- Conditional delete prevents race conditions

### ✅ Multi-Device Sync
- Push sync sends local changes
- Pull sync receives changes from other devices
- Live listeners keep app in sync during usage
- Cold start catches up on app restart

### ✅ Connectivity Awareness
- Monitors online/offline status
- Auto-triggers sync on reconnection
- Graceful degradation offline

## Next Steps for Full Integration

### 1. **Update All Repositories** (CRITICAL)
   - Implement `SyncRepository` interface
   - Add `SyncRepositoryMixin`
   - Update user write methods to append to sync_box
   - Implement `applyRemoteUpdate()` for silent updates
   - Include field name mapping (Firebase → SQLite)

   **Repositories to Update**:
   - `ShoppingListRepository` → Use `shopping_list_repository_sync.dart` as template
   - `ProductRepository`
   - `PurchasedProductRepository`
   - `CategoryRepository`
   - `SupermarketRepository`
   - Any others handling synced data

### 2. **Register Repositories in Sync Manager**
   - Update `syncRepositoryRegistryProvider` in `sync_manager_provider.dart`
   - Map entity types to repository instances
   - Ensure all synced entities are registered

### 3. **Update Firestore Schema** (if needed)
   - Ensure all synced documents have `lastModified` field
   - Set `lastModified` to `serverTimestamp()` on create/update
   - Add `isDeleted` boolean field for soft deletes
   - Use user-scoped collections: `Users/{uid}/{entity_type}`

### 4. **Update Models**
   - Ensure all synced models have:
     - `createdAt` (set once at creation)
     - `lastModified` (updated on every change)
     - `isDeleted` (for soft deletes)
   - Implement `toDatabase()` and `fromDatabase()` methods
   - Support field name mapping

### 5. **Test Sync Workflow**
   - **Offline write**: Edit locally, verify sync_box entry
   - **Sync push**: Go online, verify Firestore update
   - **Sync pull**: Edit on another device, verify local update
   - **Conflict resolution**: Modify locally and remotely simultaneously
   - **Soft delete**: Delete locally, verify physical delete on echo
   - **Crash recovery**: Kill app during sync, restart
   - **Connectivity**: Toggle airplane mode, verify reconnection

### 6. **Update UI Providers**
   - Ensure Riverpod providers watch SQLite directly
   - UI automatically updates when repositories change SQLite
   - No direct Firestore queries from UI

### 7. **Enable Firebase Offline Persistence** (Optional)
   - Firestore can cache queries offline
   - Configure in `main.dart`:
     ```dart
     FirebaseFirestore.instance.settings = 
         const Settings(persistenceEnabled: true);
     ```

### 8. **Add Sync Status Indicator** (UX)
   - Show sync status in UI: pending, syncing, synced
   - Use `syncManagerProvider` to track status
   - Display sync errors to user

## File Structure

```
lib/
├── models/
│   ├── sync/
│   │   ├── sync_operation.dart          ✅
│   │   └── local_sync_entry.dart        ✅
│   └── [existing models]
├── repositories/
│   ├── sync/
│   │   ├── sync_repository.dart         ✅
│   │   ├── sync_repository_mixin.dart   ✅
│   │   └── shopping_list_repository_sync.dart  ✅ (example)
│   ├── abstract/
│   │   └── [existing abstracts]
│   └── real_app_repo/
│       └── [to be updated with sync support]
├── services/
│   ├── sync/
│   │   ├── sync_engine_push.dart        ✅
│   │   ├── sync_engine_pull.dart        ✅
│   │   ├── sync_manager.dart            ✅
│   │   └── connectivity_monitor.dart    ✅
│   ├── database/
│   │   ├── sqlite/
│   │   │   ├── database_helper.dart     ✅ (updated)
│   │   │   ├── manage_sync_box.dart     ✅
│   │   │   └── [existing managers]
│   │   └── firebase/
│   │       └── [existing firebase code]
│   └── [existing services]
├── providers/
│   └── real_app_providers/
│       ├── sync_manager_provider.dart   ✅
│       └── [existing providers]
├── utils/
│   ├── monotonic_timestamp.dart         ✅
│   └── [existing utilities]
└── [existing directories]

docs/
├── SYNC_ENGINE_GUIDE.md                 ✅
└── SYNC_ENGINE_README.md                ✅ (this file)
```

## Configuration

### Periodic Sync Interval
Location: `lib/services/sync/sync_manager.dart`
```dart
static const Duration _periodicSyncInterval = Duration(seconds: 10);
```

### Batch Size for Delta Sync
Location: `lib/services/sync/sync_engine_pull.dart`
```dart
.limit(100); // Documents per query
```

### Concurrency Control
Location: `lib/services/sync/sync_engine_push.dart`
```dart
const int maxConcurrency = 3; // Parallel transactions
```

## Testing Checklist

- [ ] Offline write creates sync_box entry
- [ ] Online sync pushes to Firestore
- [ ] Pull sync fetches remote changes
- [ ] Snapshot listeners work correctly
- [ ] Conflict resolution (LWW) works
- [ ] Soft deletes work (local isDeleted=1 → remote echo → physical delete)
- [ ] Crash recovery retries sync
- [ ] Connectivity monitoring triggers sync
- [ ] Dirty state prevents overwrites
- [ ] Monotonic timestamps prevent false conflicts
- [ ] Multi-device sync works
- [ ] No infinite loops in sync

## Troubleshooting

### Sync Not Starting
1. Check connectivity monitor initialization
2. Verify `syncManagerProvider` in `main.dart`
3. Check Firebase auth (user must be logged in)
4. Check logs for initialization errors

### Infinite Sync Loop
1. Ensure repositories DON'T append to sync_box in `applyRemoteUpdate()`
2. Verify silent update logic is implemented correctly
3. Check timestamp comparisons

### Data Not Syncing
1. Verify repository is in registry
2. Check Firestore rules (must allow user access)
3. Verify sync_box entries are created
4. Check logs for transaction errors
5. Ensure Firestore has `lastModified` field

### Lost Deletes
1. Verify soft delete logic (isDeleted=1, don't physical delete)
2. Check sync_box append for delete operation
3. Verify remote echo triggers physical delete

## Security Notes

1. **Firestore Rules**: Ensure rules allow user to access only their data:
   ```
   match /Users/{uid} {
     allow read, write: if request.auth.uid == uid;
   }
   ```

2. **Timestamps**: Server timestamps can't be spoofed
   - Use `FieldValue.serverTimestamp()` in push
   - Trust remote `lastModified` for conflict resolution

3. **Soft Deletes**: Physical deletion only on remote echo
   - Prevents accidental permanent loss
   - Allows audit trail via Firestore logs

## Performance Considerations

1. **Batch Processing**: Max 3 concurrent push transactions (configurable)
2. **Delta Sync**: Only fetches modified documents since last sync
3. **Live Listeners**: Efficient streaming updates
4. **Indexes**: Created on `entity_type` and `last_modified` for queries
5. **Soft Deletes**: Filtered in queries (no orphaned records in UI)

## Known Limitations & Future Work

### Current Limitations
1. No encryption of sensitive data in sync_box
2. No bandwidth optimization for large files
3. No conflict resolution UI for user intervention
4. Manual repositories setup (could be code-generated)

### Future Enhancements
1. **Bidirectional Sync Status**: Show which changes need syncing
2. **Selective Sync**: Allow user to choose which entities to sync
3. **Conflict Resolution UI**: Let user choose which version to keep
4. **Compression**: Compress large documents before sync
5. **Partial Sync**: Sync specific fields only
6. **Encryption**: Encrypt sensitive fields in transit/storage
7. **Bandwidth Management**: Queue sync by priority

## Support & Debugging

### Enable Debug Logging
The sync engine uses `logger` package. Configure logging:

```dart
// In any file
import 'package:logger/logger.dart';

final logger = Logger(
  level: Level.debug,
  // Enable all logs for debugging
);
```

### Monitor Sync Status
```dart
// In UI
ref.watch(syncManagerProvider).when(
  data: (syncManager) {
    return Text('Sync Ready: ${syncManager.isInitialized}');
  },
  loading: () => Text('Initializing...'),
  error: (err, stack) => Text('Error: $err'),
);
```

### Check Sync Queue
```dart
// Debug: See pending operations
final entries = await ManageSyncBox.getAllSyncEntries();
for (final entry in entries) {
  print('${entry.entityType}/${entry.entityId}: ${entry.operation}');
}
```

## Contact & Questions

For questions about the sync implementation, refer to:
- [SYNC_ENGINE_GUIDE.md](SYNC_ENGINE_GUIDE.md) - Integration guide
- Inline code comments
- Test files (create test_sync.dart)

---

**Last Updated**: January 29, 2026  
**Status**: Core Implementation Complete, Ready for Repository Integration
