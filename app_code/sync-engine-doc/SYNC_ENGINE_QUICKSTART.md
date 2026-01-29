# Sync Engine - Quick Start for Developers

## 🚀 30-Minute Setup Guide

This guide gets you up to speed on the sync engine implementation.

---

## Part 1: Understand the Core Concept (5 min)

### The Problem
Users want to:
- Edit shopping lists **offline**
- See changes sync **automatically** when online
- Edit on **multiple devices** simultaneously
- Never **lose data** from crashes

### The Solution
```
┌─ When you CREATE/EDIT/DELETE locally:
│  1. Update SQLite (immediate ✓)
│  2. Mark in sync_box (queue for sync)
│  3. Return to user (no network wait)
│
└─ When you go ONLINE:
   1. Sync engine batches sync_box entries
   2. Pushes to Firestore with serverTimestamp
   3. Firestore echoes back update
   4. App merges remote timestamp with local data
   5. UI automatically updates
```

---

## Part 2: Architecture Overview (10 min)

### The Three Pieces

#### 1️⃣ **Push Engine** (Local → Remote)
```
sync_box entries → Firestore Transaction → Clean up sync_box
```
- Reads pending changes from SQLite
- Sends to Firestore with LWW logic
- Deletes from sync_box when done
- Retries on error

#### 2️⃣ **Pull Engine** (Remote → Local)
```
Cold Start → Live Listeners
  (once)     (continuous)
```
- Cold start: Fetch all changes since last sync
- Live listeners: Real-time updates while app is open
- Silent update: Never writes to sync_box (prevents loops)

#### 3️⃣ **Sync Manager** (Orchestrator)
```
Monitors → Triggers Push → Triggers Pull → Manages Resources
Connectivity (10s)
```
- Monitors connectivity
- Runs periodic sync
- Syncs on reconnection
- Manages lifecycle

### The Key Insight: **Two Types of Writes**

**USER WRITE** (user initiates)
```dart
await repo.add(item);  // Add to SQLite + sync_box (IMMEDIATE)
```

**SYNC WRITE** (sync engine echoes back)
```dart
await repo.applyRemoteUpdate(data);  // Add to SQLite ONLY (silent)
```

This prevents infinite loops! 🔄➡️❌

---

## Part 3: Code Structure (5 min)

### New Directories
```
lib/
├── models/sync/             # Sync models
├── services/sync/           # Sync engines
├── repositories/sync/       # Sync interfaces & examples
└── providers/sync_manager_provider.dart
```

### Key Classes
| Class | Purpose |
|-------|---------|
| `LocalSyncEntry` | A pending sync operation |
| `ManageSyncBox` | Database CRUD for sync queue |
| `SyncEnginePush` | Pushes to Firestore |
| `SyncEnginePull` | Pulls from Firestore |
| `SyncManager` | Orchestrates everything |
| `SyncRepository` | Interface your repos implement |
| `SyncRepositoryMixin` | Helper methods for repos |

### Key Methods
```dart
// In your repository:
appendUpsertToSyncBox()   // Mark for sync (user write)
appendDeleteToSyncBox()   // Mark delete for sync (user write)
applyRemoteUpdate()       // Apply from Firestore (sync write)
isEntityDirty()          // Check if has pending changes
```

---

## Part 4: Update Your First Repository (5 min)

### See the Template
Open: `lib/repositories/sync/shopping_list_repository_sync.dart`

This shows:
- ✅ How to mark user writes for sync
- ✅ How to apply remote updates silently
- ✅ How to handle soft deletes
- ✅ How to map Firebase fields to SQLite
- ✅ How to compare timestamps

### Three Changes Per Repository

**1. Add the Imports**
```dart
import 'package:app_code/repositories/sync/sync_repository.dart';
import 'package:app_code/repositories/sync/sync_repository_mixin.dart';
import 'package:app_code/utils/monotonic_timestamp.dart';
```

**2. Implement the Interface**
```dart
class YourRepository 
    implements SyncRepository, SyncRepositoryMixin {
  
  @override
  String getEntityType() => 'your_entity_type';
  
  // ... existing code ...
}
```

**3. Update User Writes**
```dart
// Before: Just SQLite
await db.insert('table', data);

// After: SQLite + sync_box
await db.insert('table', data);
await appendUpsertToSyncBox(id, getEntityType(), timestamp);
```

**4. Add Sync Write**
```dart
@override
Future<void> applyRemoteUpdate(Map<String, dynamic> data) async {
  // Check if dirty (local changes pending)
  if (await isEntityDirty(data['id'], getEntityType())) {
    return; // Skip, local wins
  }
  
  // Merge to SQLite (no sync_box touch)
  await db.insert_or_update('table', data);
}
```

---

## Part 5: Register Your Repository (1 min)

### Update the Provider
File: `lib/providers/real_app_providers/sync_manager_provider.dart`

```dart
final syncRepositoryRegistryProvider = FutureProvider<Map<String, SyncRepository>>((ref) async {
  final shoppingListRepo = ShoppingListRepositoryWithSync();
  final productRepo = YourProductRepository();  // ADD THIS
  
  return {
    ENTITY_TYPE_SHOPPING_LIST: shoppingListRepo,
    ENTITY_TYPE_PRODUCT: productRepo,  // ADD THIS
  };
});
```

---

## Part 6: Test It (5 min)

### Manual Test Flow

**Step 1: Offline Write**
```
1. Open app
2. Disable WiFi/cellular (airplane mode)
3. Create/edit a shopping list
4. Close and reopen app
5. Verify changes persisted (SQLite)
6. Query: SELECT * FROM sync_box WHERE entity_type='shopping_list'
7. Verify entry exists
```

**Step 2: Sync Push**
```
1. From step above, enable WiFi
2. Wait 10 seconds (periodic sync)
3. Check Firestore console
4. Verify document created/updated with serverTimestamp
5. Check sync_box again
6. Verify entry was deleted (sync successful)
```

**Step 3: Sync Pull (Multi-Device)**
```
1. Device A: Create list offline
2. Device A: Go online, sync completes
3. Device B: App receives Firestore update via listener
4. Device B: Verify change appears in UI automatically
```

---

## Part 7: Understand Key Concepts (10 min)

### Concept 1: Monotonic Timestamps
```dart
// Problem: Rapid updates cause false conflicts
item.lastModified = DateTime.now();     // ❌ Can be same ms

// Solution: Use monotonic generator
item.lastModified = MonotonicTimestamp.generateNext(
  previousTime: item.lastModified       // ✅ Always increases
);
```

### Concept 2: Dirty State
```dart
// Scenario: Local edit not yet synced, remote sends update
// Solution: Check if entity is "dirty"

if (await isEntityDirty(id, type)) {
  return; // Don't overwrite, local changes win
}
apply_remote_update();  // Only if clean
```

### Concept 3: Soft Delete
```dart
// Instead of:
await db.delete('shopping_list', ...);  // ❌ Data lost forever

// Use:
item.isDeleted = true;
await db.update('shopping_list', ...);  // ✅ Marked but recoverable
await appendDeleteToSyncBox(...);
```

### Concept 4: Silent Update
```dart
// User write:
await repo.add(item);  // Appends to sync_box

// Sync echo (from Firestore listener):
await repo.applyRemoteUpdate(remoteData);  // NO sync_box append!
// This prevents: Local change → sync → echo → new sync entry (loop!)
```

### Concept 5: Sync_Box Queue
```
Entity Write Event → sync_box Entry Created
        ↓
   Wait for Sync
        ↓
Sync Engine Processes → Firestore Update
        ↓
      Success
        ↓
   Delete from sync_box (cleanup)
```

---

## 📋 Checklist: Get Sync Working

### Day 1: Setup
- [ ] Read `SYNC_ENGINE_SUMMARY.md` (5 min)
- [ ] Read this guide (15 min)
- [ ] Review `shopping_list_repository_sync.dart` (10 min)

### Day 2: Update Repos
- [ ] Audit Firestore schema (has `lastModified`?)
- [ ] Check SQLite columns exist (`lastModified`, `isDeleted`)
- [ ] Update ShoppingListRepository (30 min)
- [ ] Test offline write + online sync (30 min)
- [ ] Update ProductRepository (20 min)
- [ ] Update other 3-4 repos (follow same pattern)

### Day 3: Register & Test
- [ ] Register all repos in provider (5 min)
- [ ] Test multi-device sync (30 min)
- [ ] Test conflict resolution (30 min)
- [ ] Test soft deletes (20 min)
- [ ] Test crash recovery (15 min)

### Day 4: Polish
- [ ] Add sync status UI indicator (optional)
- [ ] Write integration tests
- [ ] Documentation
- [ ] Performance testing

---

## 🐛 Debugging Tips

### Check Sync Queue
```dart
final entries = await ManageSyncBox.getAllSyncEntries();
entries.forEach((e) => print('$e.entityType/$e.entityId: $e.operation'));
```

### Force Sync
```dart
final syncManager = await ref.watch(syncManagerProvider.future);
await syncManager.triggerManualSync();
```

### Check Firestore Doc
```bash
# In Firebase Console or CLI:
firebase firestore:documents get Users/{userId}/shopping_list/{listId}
```

### View Logs
```dart
// Look for: "SyncEngine:" prefix in logs
// Example: "SyncEngine: Processing 5 pending sync entries"
```

---

## 📚 When You Need Help

| Topic | Read |
|-------|------|
| Full architecture | `SYNC_ENGINE_README.md` |
| How to integrate | `SYNC_ENGINE_GUIDE.md` |
| What's left to do | `SYNC_ENGINE_UNRESOLVED.md` |
| Checklist | `SYNC_ENGINE_CHECKLIST.md` |
| API reference | Inline code comments |

---

## ⚡ Common Mistakes to Avoid

### ❌ Mistake 1: Appending to sync_box in applyRemoteUpdate()
```dart
// WRONG:
@override
Future<void> applyRemoteUpdate(Map<String, dynamic> data) {
  await db.insert('table', data);
  await appendUpsertToSyncBox(...);  // ❌ CREATES LOOP!
}

// RIGHT:
@override
Future<void> applyRemoteUpdate(Map<String, dynamic> data) {
  await db.insert('table', data);  // ✅ Just SQLite, no sync_box
}
```

### ❌ Mistake 2: Physically deleting instead of soft delete
```dart
// WRONG:
await db.delete('shopping_list', ...);  // ❌ Data gone forever

// RIGHT:
item.isDeleted = true;
await db.update('shopping_list', item.toDatabase());
await appendDeleteToSyncBox(...);
```

### ❌ Mistake 3: Not comparing timestamps before applying remote
```dart
// WRONG:
@override
Future<void> applyRemoteUpdate(Map<String, dynamic> data) async {
  await db.insert('table', data);  // ❌ Overwrites local changes!
}

// RIGHT:
if (await isEntityDirty(id, type)) return;
if (local.lastModified > remote.lastModified) return;
await db.insert('table', data);  // ✅ Safe merge
```

### ❌ Mistake 4: Not updating sync_box on user writes
```dart
// WRONG:
Future<void> update(Item item) async {
  await db.update('table', item.toDatabase());
  // ❌ Change won't sync!
}

// RIGHT:
Future<void> update(Item item) async {
  item.lastModified = MonotonicTimestamp.generateNext(...);
  await db.update('table', item.toDatabase());
  await appendUpsertToSyncBox(item.id, type, item.lastModified);  // ✅
}
```

---

## 🎯 Success Criteria

When you're done, verify:
- [x] Can edit offline, changes persist
- [x] Online sync pushes to Firestore  
- [x] Other devices receive updates in real-time
- [x] Conflicts resolved correctly (LWW)
- [x] Soft deletes work
- [x] App survives crashes
- [x] No data duplication
- [x] No infinite loops

---

## Next Steps After Setup

1. **Performance**: Monitor sync times, optimize if needed
2. **UI**: Add sync status indicators
3. **Error Handling**: Handle network errors gracefully
4. **Testing**: Write unit and E2E tests
5. **Analytics**: Track sync success rates

---

## TL;DR - Just Do This

1. Open `shopping_list_repository_sync.dart` (it's a template)
2. Apply same pattern to your repos
3. Register in `sync_manager_provider.dart`
4. Test: offline write → online sync → verify Firestore
5. Done! ✨

---

**Questions?** See the detailed guides or check inline code comments.

**Ready to code?** Start with updating `ShoppingListRepository` - the template is right there! 🚀

---

**Created**: January 29, 2026  
**Time to First Sync**: ~15 minutes with this guide
