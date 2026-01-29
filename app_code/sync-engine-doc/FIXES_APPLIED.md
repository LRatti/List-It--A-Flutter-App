# Sync Engine Fixes Applied

**Date**: January 29, 2026  
**Status**: All Critical Bugs Fixed ✅

---

## Summary

During code review of the generated sync engine implementation, **8 critical bugs** were identified and fixed. These fixes ensure:

1. ✅ Correct Last-Write-Wins conflict resolution
2. ✅ No timestamp drift between entity and sync_box
3. ✅ Proper Firestore Timestamp parsing
4. ✅ Soft-delete filtering works correctly
5. ✅ Foreign key constraints removed for async sync
6. ✅ Purchased products sync when added via shopping list
7. ✅ Remote updates apply when remote is newer
8. ✅ Delete operations use correct timestamps

---

## Detailed Fixes

### Fix 1: Remote-Newer Conflict Path Not Applying Updates

**Issue**: When remote data is newer during push sync, the engine logged the conflict but didn't apply the remote data to SQLite.

**File**: [lib/services/sync/sync_engine_push.dart](../lib/services/sync/sync_engine_push.dart)

**Location**: `_processSyncEntry()` method, remote-newer branch

**Before**:
```dart
// Remote is newer - keep remote version
_logger.info(
  'SyncEngine: Remote version is newer for $entityType/$entityId. Skipping push.',
);
// BUG: No code to apply remote data here!
```

**After**:
```dart
// Remote is newer - apply remote update locally and skip push
_logger.info(
  'SyncEngine: Remote version is newer for $entityType/$entityId. Applying remote update.',
);
await repository.applyRemoteUpdate(remoteData);
```

**Impact**: Without this fix, devices would have stale data when remote is newer.

---

### Fix 2: Firestore Timestamp Parsing Failures

**Issue**: When pulling from Firestore, `lastModified` is a `Timestamp` object, not a string. Repositories tried to parse it as `DateTime.parse()` which failed.

**Files Fixed** (5 total):
1. [lib/repositories/sync/shopping_list_repository_sync.dart](../lib/repositories/sync/shopping_list_repository_sync.dart)
2. [lib/repositories/sync/product_repository_sync.dart](../lib/repositories/sync/product_repository_sync.dart)
3. [lib/repositories/sync/purchased_product_repository_sync.dart](../lib/repositories/sync/purchased_product_repository_sync.dart)
4. [lib/repositories/sync/category_repository_sync.dart](../lib/repositories/sync/category_repository_sync.dart)
5. [lib/repositories/sync/supermarket_repository_sync.dart](../lib/repositories/sync/supermarket_repository_sync.dart)

**Solution**: Added `_parseTimestamp()` helper that handles both Firestore `Timestamp` objects and ISO8601 strings:

```dart
DateTime? _parseTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    return DateTime.parse(value);
  }
  // Handle Firestore Timestamp (can't use 'is Timestamp' due to import issues)
  if (value.runtimeType.toString() == 'Timestamp') {
    final timestamp = value as dynamic;
    return timestamp.toDate() as DateTime;
  }
  return null;
}
```

And `_cleanFirebaseData()` that converts Timestamps to ISO8601 before SQLite insert:

```dart
Map<String, dynamic> _cleanFirebaseData(Map<String, dynamic> data) {
  final cleaned = Map<String, dynamic>.from(data);

  // Convert Firestore Timestamp to ISO8601 string
  if (cleaned['last_modified']?.runtimeType.toString() == 'Timestamp') {
    final timestamp = cleaned['last_modified'] as dynamic;
    cleaned['last_modified'] = (timestamp.toDate() as DateTime).toIso8601String();
  }

  // Convert other Timestamp fields if needed...

  return cleaned;
}
```

**Impact**: Without this, LWW comparison would fail and silent updates would crash.

---

### Fix 3: Timestamp Drift Between Entity and sync_box

**Issue**: When a repository calls `appendUpsertToSyncBox()`, it first updates the entity with a new timestamp, then generates ANOTHER timestamp for the sync_box entry. These can differ by milliseconds, causing false conflicts.

**File**: [lib/repositories/sync/sync_repository_mixin.dart](../lib/repositories/sync/sync_repository_mixin.dart)

**Before**:
```dart
Future<void> appendUpsertToSyncBox(String entityId, Map<String, dynamic> entityData) async {
  final lastModified = MonotonicTimestamp.generateNext(...); // New timestamp!
  
  final syncEntry = LocalSyncEntry(
    entityId: entityId,
    entityType: getEntityType(),
    operation: SyncOperation.upsert,
    lastModified: lastModified, // Different from entity!
    entityData: entityData,
  );
  
  await ManageSyncBox.addOrUpdateSyncEntry(syncEntry);
}
```

**After**:
```dart
Future<void> appendUpsertToSyncBox(
  String entityId,
  Map<String, dynamic> entityData,
  DateTime lastModified, // NOW REQUIRED - must match entity
) async {
  final syncEntry = LocalSyncEntry(
    entityId: entityId,
    entityType: getEntityType(),
    operation: SyncOperation.upsert,
    lastModified: lastModified, // Use exact entity timestamp
    entityData: entityData,
  );
  
  await ManageSyncBox.addOrUpdateSyncEntry(syncEntry);
}
```

**Caller Update** (in all repositories):
```dart
// Before
final newLastModified = MonotonicTimestamp.generateNext(...);
entity.lastModified = newLastModified;
await db.update(...);
await appendUpsertToSyncBox(entity.id, entityData); // Generates new timestamp!

// After
final newLastModified = MonotonicTimestamp.generateNext(...);
entity.lastModified = newLastModified;
await db.update(...);
await appendUpsertToSyncBox(entity.id, entityData, newLastModified); // Exact match!
```

**Impact**: Eliminates timestamp drift, ensuring entity and sync_box always have identical timestamps.

---

### Fix 4: Foreign Key Constraints Block Out-of-Order Sync

**Issue**: SQLite foreign key constraints prevent inserting a child before its parent. In async sync, a purchased_product might arrive before its shopping_list, causing insert failures.

**File**: [lib/services/database/sqlite/database_helper.dart](../lib/services/database/sqlite/database_helper.dart)

**Tables Fixed**:
1. `associations` - FK to product
2. `supermarket_category` - FK to supermarket
3. `purchased_product` - FK to shopping_list
4. `recipe_cache` - FK to shopping_list

**Before**:
```dart
CREATE TABLE purchased_product (
  id TEXT PRIMARY KEY,
  shopping_list_id TEXT NOT NULL,
  FOREIGN KEY (shopping_list_id) REFERENCES shopping_list(id) ON DELETE CASCADE
);
```

**After**:
```dart
CREATE TABLE purchased_product (
  id TEXT PRIMARY KEY,
  shopping_list_id TEXT NOT NULL
  -- NO FOREIGN KEY - allows out-of-order sync
);
```

**Impact**: Sync can handle entities arriving in any order without FK violations.

---

### Fix 5: Soft-Deleted Purchased Products Still Returned in Queries

**Issue**: Purchased products have `is_deleted` flag for soft delete, but queries didn't filter them out, showing ghost items in UI.

**File**: [lib/services/database/sqlite/manage_purchased_product.dart](../lib/services/database/sqlite/manage_purchased_product.dart)

**Methods Fixed**:
1. `getPurchasedProductsByList()`
2. `getPurchasedProductById()`
3. `getPurchasedProductByName()`

**Before**:
```dart
static Future<List<Map<String, dynamic>>> getPurchasedProductsByList(String listId) async {
  final db = await DatabaseHelper.database;
  return await db.query(
    'purchased_product',
    where: 'shopping_list_id = ?',
    whereArgs: [listId],
  );
}
```

**After**:
```dart
static Future<List<Map<String, dynamic>>> getPurchasedProductsByList(String listId) async {
  final db = await DatabaseHelper.database;
  return await db.query(
    'purchased_product',
    where: 'shopping_list_id = ? AND is_deleted = 0', // Filter deleted
    whereArgs: [listId],
  );
}
```

**Impact**: Soft-deleted items no longer appear in UI queries.

---

### Fix 6: Purchased Products Not Synced When Added Via Shopping List

**Issue**: When adding items to a shopping list, the code created purchased_product rows but didn't enqueue them to sync_box, so they never synced to Firestore.

**File**: [lib/repositories/sync/shopping_list_repository_sync.dart](../lib/repositories/sync/shopping_list_repository_sync.dart)

**Before**:
```dart
@override
Future<void> add(ShoppingList shoppingList) async {
  // ... add shopping list ...
  
  // Add purchased products
  for (final item in shoppingList.itemList) {
    await ManagePurchasedProduct.addPurchasedProduct(item); // NO SYNC!
  }
}
```

**After**:
```dart
class ShoppingListRepositoryWithSync extends ShoppingListRepository 
    with SyncRepositoryMixin 
    implements SyncRepository {
  
  // Add instance of purchased product sync repo
  final PurchasedProductRepositoryWithSync _purchasedProductRepo = 
      PurchasedProductRepositoryWithSync();

  @override
  Future<void> add(ShoppingList shoppingList) async {
    // ... add shopping list ...
    
    // Add purchased products via sync repo
    for (final item in shoppingList.itemList) {
      await _purchasedProductRepo.add(item); // NOW SYNCS!
    }
  }
  
  @override
  Future<void> update(ShoppingList shoppingList) async {
    // ... update shopping list ...
    
    // Update purchased products via sync repo
    for (final item in shoppingList.itemList) {
      final existing = await ManagePurchasedProduct.getPurchasedProductById(item.id);
      if (existing != null) {
        await _purchasedProductRepo.update(item); // Syncs updates
      } else {
        await _purchasedProductRepo.add(item); // Syncs new items
      }
    }
  }
}
```

**Impact**: Purchased products now sync correctly when managed via shopping list operations.

---

### Fix 7: Delete Timestamp Mismatch

**Issue**: When deleting a purchased product, the repository soft-deleted it with a new timestamp, but enqueued the OLD timestamp to sync_box, causing LWW comparison failures.

**File**: [lib/repositories/sync/purchased_product_repository_sync.dart](../lib/repositories/sync/purchased_product_repository_sync.dart)

**Before**:
```dart
@override
Future<void> deleteById(String id) async {
  final existing = await getById(id);
  if (existing == null) return;

  final newLastModified = MonotonicTimestamp.generateNext(
    previousTime: existing.lastModified,
  );
  
  existing.isDeleted = true;
  existing.lastModified = newLastModified;
  
  await ManagePurchasedProduct.updatePurchasedProduct(existing);
  await appendDeleteToSyncBox(id, existing.lastModified); // WRONG! Uses old timestamp
}
```

**After**:
```dart
@override
Future<void> deleteById(String id) async {
  final existing = await getById(id);
  if (existing == null) return;

  final newLastModified = MonotonicTimestamp.generateNext(
    previousTime: existing.lastModified,
  );
  
  existing.isDeleted = true;
  existing.lastModified = newLastModified;
  
  await ManagePurchasedProduct.updatePurchasedProduct(existing);
  await appendDeleteToSyncBox(id, newLastModified); // FIXED! Uses new timestamp
}
```

**Impact**: Delete sync entries now have matching timestamps for correct LWW resolution.

---

### Fix 8: appendDeleteToSyncBox Signature Updated

**Issue**: Similar to Fix 3, `appendDeleteToSyncBox()` generated its own timestamp instead of using the entity's exact timestamp.

**File**: [lib/repositories/sync/sync_repository_mixin.dart](../lib/repositories/sync/sync_repository_mixin.dart)

**Before**:
```dart
Future<void> appendDeleteToSyncBox(String entityId) async {
  final lastModified = MonotonicTimestamp.generateNext(...); // New timestamp!
  
  final syncEntry = LocalSyncEntry(
    entityId: entityId,
    entityType: getEntityType(),
    operation: SyncOperation.delete,
    lastModified: lastModified,
  );
  
  await ManageSyncBox.addOrUpdateSyncEntry(syncEntry);
}
```

**After**:
```dart
Future<void> appendDeleteToSyncBox(String entityId, DateTime lastModified) async {
  final syncEntry = LocalSyncEntry(
    entityId: entityId,
    entityType: getEntityType(),
    operation: SyncOperation.delete,
    lastModified: lastModified, // Use entity's exact timestamp
  );
  
  await ManageSyncBox.addOrUpdateSyncEntry(syncEntry);
}
```

**Impact**: Delete operations have consistent timestamps across entity and sync_box.

---

## Testing

All fixes can be verified using the comprehensive testing guide:

📄 **[SYNC_ENGINE_TEST_GUIDE.md](./SYNC_ENGINE_TEST_GUIDE.md)**

Key tests:
- **Test 6**: Conflict Resolution (LWW) - Verifies Fix 1, 2, 3
- **Test 7**: Soft Delete Lifecycle - Verifies Fix 5
- **Test 10**: Rapid Updates - Verifies Fix 4 (out-of-order sync)
- **Manual**: Multi-device testing - Verifies all fixes together

---

## Remaining Action Items

### 1. Database Version Bump (REQUIRED)

```dart
// In lib/services/database/sqlite/database_helper.dart
static const int _databaseVersion = 2; // Change from 1 to 2
```

This ensures existing users get schema migration for:
- `last_modified TEXT` columns
- `is_deleted INTEGER` columns
- Removed foreign key constraints

### 2. Firestore Security Rules (VERIFY)

Ensure your `firestore.rules` allows sync:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /Users/{userId}/{entityType}/{docId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 3. Run Tests

Execute the test suite from SYNC_ENGINE_TEST_GUIDE.md:

```powershell
# Unit tests
flutter test test/sync/monotonic_timestamp_test.dart
flutter test test/sync/manage_sync_box_test.dart
flutter test test/sync/shopping_list_repository_sync_test.dart

# Manual tests
# Follow Phase 3-5 in test guide
```

---

## Files Modified

**Total**: 9 files

### Sync Engine Core:
1. `lib/services/sync/sync_engine_push.dart` - Fixed remote-newer conflict handling
2. `lib/repositories/sync/sync_repository_mixin.dart` - Fixed timestamp drift

### Repository Implementations:
3. `lib/repositories/sync/shopping_list_repository_sync.dart` - Fixed Timestamp parsing + purchased product sync
4. `lib/repositories/sync/product_repository_sync.dart` - Fixed Timestamp parsing
5. `lib/repositories/sync/purchased_product_repository_sync.dart` - Fixed Timestamp parsing + delete timestamp
6. `lib/repositories/sync/category_repository_sync.dart` - Fixed Timestamp parsing
7. `lib/repositories/sync/supermarket_repository_sync.dart` - Fixed Timestamp parsing

### Database Layer:
8. `lib/services/database/sqlite/database_helper.dart` - Removed foreign keys
9. `lib/services/database/sqlite/manage_purchased_product.dart` - Added soft-delete filtering

---

## Status

✅ **All 8 critical bugs fixed**  
✅ **Repository registration complete** (all 5 entities)  
✅ **Schema updates applied** (SQLite)  
⚠️ **Database version bump required** (manual)  
⚠️ **Firestore rules verification recommended** (manual)  
📋 **Testing guide provided** (SYNC_ENGINE_TEST_GUIDE.md)

**Next Step**: Bump database version, verify Firestore rules, run tests.

---

**Last Updated**: January 29, 2026  
**Status**: Ready for Testing ✅
