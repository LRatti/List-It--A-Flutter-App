# Default Categories Sync Fix

## Problem Statement

Default categories were not being synced to Firestore on app startup. They were saved locally in SQLite but never appeared in the Firestore database, even after the sync-engine should have processed them.

## Root Cause Analysis

The issue was in the **initialization flow** in `lib/services/mock/mock_data_seed.dart`:

### Before Fix (Broken)
```
Default Categories Loaded from JSON
    ↓
ManageCategory.addCategory() called directly
    ↓
SQLite: Categories saved ✓
    ↓
sync_box: NO ENTRY CREATED ✗ (PROBLEM!)
    ↓
SyncEnginePush.processPendingSync(): No entries in sync_box, nothing to push
    ↓
Firestore: Categories never synced ✗
```

**Why it failed:**
- `ManageCategory.addCategory()` is a **low-level database method** that only touches SQLite
- It does **NOT** append to `sync_box`, which is the queue for the sync-engine
- The sync-engine only processes entries in `sync_box` — it has no knowledge of changes made directly via low-level methods
- As a result, default categories were stuck in local storage with no path to Firestore

## Solution

Use the **sync-aware repositories** instead of low-level database methods:

### After Fix (Correct)
```
Default Categories Loaded from JSON
    ↓
CategoryRepositoryWithSync.add() called
    ↓
SQLite: Categories saved ✓
    ↓
sync_box: Entry created ✓ (FIXED!)
    ↓
SyncEnginePush.processPendingSync(): Reads sync_box, finds entries, pushes to Firestore
    ↓
Firestore: Categories synced successfully ✓
```

### Code Changes

**File:** `lib/services/mock/mock_data_seed.dart`

#### 1. Added Imports
```dart
import 'package:app_code/repositories/sync/category_repository_sync.dart';
import 'package:app_code/repositories/sync/supermarket_repository_sync.dart';
```

#### 2. Updated Category Seeding
```dart
// BEFORE (Wrong - bypasses sync)
for (final category in defaultCategories) {
  await ManageCategory.addCategory(category);
}

// AFTER (Correct - uses sync-aware repository)
final categoryRepo = CategoryRepositoryWithSync();
for (final category in defaultCategories) {
  await categoryRepo.add(category);  // ← Queues to sync_box
}
```

#### 3. Updated Supermarket Seeding
```dart
// BEFORE (Wrong - bypasses sync)
await ManageSupermarket.addSupermarket(defaultSupermarket);

// AFTER (Correct - uses sync-aware repository)
final supermarketRepo = SupermarketRepositoryWithSync();
await supermarketRepo.add(defaultSupermarket);  // ← Queues to sync_box
```

## How It Works

### CategoryRepositoryWithSync.add()
```dart
Future<void> add(Category category) async {
  category.createdAt = DateTime.now();
  category.lastModified = category.createdAt;

  // 1. Save to SQLite
  await ManageCategory.addCategory(category);

  // 2. Queue for sync (KEY FIX)
  await appendUpsertToSyncBox(
    category.id,
    getEntityType(),
    category.lastModified!,
  );
}
```

The repository does **two things**:
1. Persists to SQLite (same as before)
2. **Appends to sync_box** (new, critical step)

### Sync Flow
1. **Cold Start:** SyncEnginePush reads sync_box entries
2. **Push Phase:** Sends entries to Firestore with Last-Write-Wins conflict resolution
3. **Cleanup Phase:** Deletes sync_box entry on success
4. **Result:** Categories available in Firestore

## Key Principle

**Always use sync-aware repositories for user-initiated operations**, not low-level database methods:

| Use Case | Correct Method | Why |
|----------|---|---|
| User creates category | `CategoryRepositoryWithSync.add()` | Queues to sync_box |
| Receive from Firestore | `CategoryRepositoryWithSync.applyRemoteUpdate()` | Applies silently, no loop |
| Initialization/Seeding | `CategoryRepositoryWithSync.add()` | Still needs sync queuing |
| Unit tests | `ManageCategory.addCategory()` | OK - testing database layer only |

## Testing the Fix

### Manual Test
1. Clear app data
2. Restart app (triggers seedMockDataIfEmpty)
3. **Expected:** Default supermarket with 17 categories visible
4. Wait 10-15 seconds
5. **Expected:** Categories appear in Firestore Users/{uid}/category

### Debug Checks
```dart
// Check sync_box has entries
final entries = await ManageSyncBox.getAllSyncEntries();
print('Pending syncs: ${entries.length}'); // Should be 18+ (17 categories + 1 supermarket)

// Force sync
final syncManager = await ref.watch(syncManagerProvider.future);
await syncManager.triggerManualSync();

// Check Firestore
firebase firestore:documents get Users/{uid}/category
```

## Impact

- ✅ Default categories now sync to Firestore on app startup
- ✅ Users can access them on other devices after login
- ✅ Consistent data across all sync-aware repositories
- ✅ No changes to sync-engine or database schema

## Files Modified

- `lib/services/mock/mock_data_seed.dart` - Use sync-aware repositories during initialization

## Related Documentation

- [Sync Engine README](sync-engine-doc/SYNC_ENGINE_README.md) - Complete sync architecture
- [Supermarket Implementation](supermarket-category/SUPERMARKET_IMPLEMENTATION.md) - Feature overview
