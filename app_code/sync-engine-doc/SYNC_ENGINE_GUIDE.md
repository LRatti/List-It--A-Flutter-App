# Sync Engine Implementation Guide

## Overview

This document explains how to integrate the Sync Engine into existing repositories. The Sync Engine provides offline-first synchronization between SQLite (local) and Firestore (remote).

## Key Concepts

### 1. **User Writes vs. Sync Writes**

Repositories must distinguish between two types of updates:

- **User Writes**: User initiates a create/update/delete action
  - Write to SQLite
  - Append to sync_box (marks for sync)
  - Returns immediately
  - Repositories emit changes to notify UI

- **Sync Writes**: Sync Engine applies remote changes
  - Write to SQLite
  - DO NOT append to sync_box (silent update)
  - Check if entity is dirty before applying
  - Repositories emit changes to notify UI

### 2. **Entity Lifecycle**

```
User Creates Entity
    ↓
Write to SQLite (set createdAt, lastModified = now)
Write to sync_box (operation: upsert)
    ↓
Sync Engine (when online):
    - Push to Firestore with serverTimestamp
    - Firestore echo listener receives update
    - Silent update applies serverTimestamp to lastModified in SQLite
    ↓
Entity has server-timestamped lastModified
```

### 3. **Soft Deletes**

```
User Deletes Entity
    ↓
Set isDeleted = 1 in SQLite
Update lastModified = now
Write to sync_box (operation: delete)
    ↓
Sync Engine:
    - Push isDeleted: true to Firestore
    - Remote listener echoes back
    - Silent update sees isDeleted: true and PHYSICALLY DELETES from SQLite
```

## Integrating a Repository

### Step 1: Update the Model

Add sync-related fields to your model:

```dart
class ShoppingList {
  final String id;
  final DateTime createdAt;
  DateTime lastModified;  // For conflict resolution
  bool isDeleted;         // For soft deletes
  
  // ... other fields
}

// Add toDatabase() and fromDatabase() methods
Map<String, dynamic> toDatabase() {
  return {
    'id': id,
    'name': _name,
    'created_at': createdAt.toIso8601String(),
    'last_modified': lastModified.toIso8601String(),
    'is_deleted': isDeleted ? 1 : 0,
    // ... other fields
  };
}
```

### Step 2: Update the Repository

Implement `SyncRepository` and add sync support:

```dart
import 'package:app_code/repositories/sync/sync_repository.dart';
import 'package:app_code/repositories/sync/sync_repository_mixin.dart';
import 'package:app_code/services/database/sqlite/manage_sync_box.dart';
import 'package:app_code/utils/monotonic_timestamp.dart';

class ShoppingListRepository 
    implements SyncRepository 
    with SyncRepositoryMixin {

  @override
  String getEntityType() => ENTITY_TYPE_SHOPPING_LIST;

  // ===== USER WRITES =====

  /// User initiates a create
  Future<void> add(ShoppingList list) async {
    final db = await DatabaseHelper.database;
    
    // Set initial timestamps
    list.createdAt = DateTime.now();
    list.lastModified = list.createdAt;
    list.isDeleted = false;
    
    // Write to SQLite
    await db.insert('shopping_list', list.toDatabase());
    
    // Append to sync_box (IMPORTANT: marks for sync)
    await appendUpsertToSyncBox(
      list.id,
      getEntityType(),
      list.lastModified,
    );
    
    // Notify listeners
    // (If using Riverpod, invalidate the provider)
  }

  /// User initiates an update
  Future<void> update(ShoppingList list) async {
    final db = await DatabaseHelper.database;
    
    // Update lastModified using monotonic timestamp
    list.lastModified = MonotonicTimestamp.generateNext(
      previousTime: list.lastModified,
    );
    
    // Write to SQLite
    await db.update(
      'shopping_list',
      list.toDatabase(),
      where: 'id = ?',
      whereArgs: [list.id],
    );
    
    // Append to sync_box
    await appendUpsertToSyncBox(
      list.id,
      getEntityType(),
      list.lastModified,
    );
  }

  /// User initiates a delete (soft delete)
  Future<void> delete(ShoppingList list) async {
    final db = await DatabaseHelper.database;
    
    // Update lastModified
    list.lastModified = MonotonicTimestamp.generateNext(
      previousTime: list.lastModified,
    );
    list.isDeleted = true;
    
    // Update in SQLite (DO NOT physically delete)
    await db.update(
      'shopping_list',
      list.toDatabase(),
      where: 'id = ?',
      whereArgs: [list.id],
    );
    
    // Append to sync_box
    await appendDeleteToSyncBox(
      list.id,
      getEntityType(),
      list.lastModified,
    );
  }

  // ===== SYNC WRITES (Silent Updates) =====

  /// Apply remote update from Firestore (NO sync_box write)
  @override
  Future<void> applyRemoteUpdate(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.database;
    final entityId = data['id'] as String?;
    
    if (entityId == null) {
      throw ArgumentError('Remote data must have id field');
    }

    // Check if entity is dirty (has pending sync)
    if (await isEntityDirty(entityId, getEntityType())) {
      // Entity has local changes, ignore remote update
      // Local changes will sync to server and be echoed back
      return;
    }

    // Parse remote data
    final remoteLastModified = _parseTimestamp(data['lastModified']);
    final localData = await getLocalData(entityId);

    // Compare timestamps
    if (localData != null) {
      final localLastModified = _parseTimestamp(
        localData['lastModified'] as dynamic,
      );
      
      if (localLastModified != null && remoteLastModified != null) {
        if (localLastModified.isAfter(remoteLastModified)) {
          // Local is newer, skip update
          return;
        }
      }
    }

    // Handle soft delete from remote
    if (data['isDeleted'] == true || data['is_deleted'] == 1) {
      // PHYSICALLY DELETE from SQLite for soft-deleted entities
      await db.delete(
        'shopping_list',
        where: 'id = ?',
        whereArgs: [entityId],
      );
      return;
    }

    // Apply update
    final exists = localData != null;
    if (exists) {
      await db.update(
        'shopping_list',
        _cleanFirebaseData(data),
        where: 'id = ?',
        whereArgs: [entityId],
      );
    } else {
      await db.insert(
        'shopping_list',
        _cleanFirebaseData(data),
      );
    }
  }

  /// Get local data for comparison
  @override
  Future<Map<String, dynamic>?> getLocalData(String id) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'shopping_list',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    
    return rows.isNotEmpty ? rows.first : null;
  }

  // ===== HELPERS =====

  /// Parse timestamp from various formats
  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Clean Firebase data for SQLite insertion
  Map<String, dynamic> _cleanFirebaseData(Map<String, dynamic> data) {
    // Remove Firestore-specific fields that shouldn't go to SQLite
    final cleaned = Map<String, dynamic>.from(data);
    cleaned.remove('firestore_timestamp');
    // Ensure timestamps are ISO8601 strings
    if (cleaned['lastModified'] != null) {
      cleaned['last_modified'] = cleaned['lastModified'].toString();
      cleaned.remove('lastModified');
    }
    return cleaned;
  }

  /// Query all non-deleted shopping lists
  Future<List<ShoppingList>> getAll() async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'shopping_list',
      where: 'is_deleted = 0',
    );
    
    return rows
        .map((row) => ShoppingList.fromDatabase(row))
        .toList();
  }
}
```

### Step 3: Register in Sync Manager Provider

Update [sync_manager_provider.dart](sync_manager_provider.dart):

```dart
final syncRepositoryRegistryProvider = FutureProvider<Map<String, SyncRepository>>((ref) async {
  final shoppingListRepo = ShoppingListRepository(); // or from Riverpod
  final productRepo = ProductRepository();

  return {
    ENTITY_TYPE_SHOPPING_LIST: shoppingListRepo,
    ENTITY_TYPE_PRODUCT: productRepo,
    // Add more repositories
  };
});
```

### Step 4: Update Riverpod Providers

Invalidate Riverpod providers after user writes to trigger UI updates:

```dart
Future<void> add(ShoppingList list, WidgetRef ref) async {
  await repository.add(list);
  // Invalidate provider to notify UI
  ref.invalidate(shoppingListsProvider);
}
```

## Database Schema Considerations

### Disable Foreign Keys for Synced Tables

Since Firestore syncs asynchronously, child entities may arrive before parents. Configure database:

```dart
await db.execute('PRAGMA foreign_keys = OFF');
```

For synced entities, let repositories handle logical cascading deletes during silent updates.

## Testing the Sync Engine

### Test 1: Offline Write

```dart
test('offline write creates sync_box entry', () async {
  final repo = ShoppingListRepository();
  final list = ShoppingList(name: 'Test');
  
  // Write offline
  await repo.add(list);
  
  // Verify sync_box entry exists
  final syncEntry = await ManageSyncBox.getSyncEntry(
    list.id,
    ENTITY_TYPE_SHOPPING_LIST,
  );
  
  expect(syncEntry, isNotNull);
  expect(syncEntry!.operation, SyncOperation.upsert);
});
```

### Test 2: Remote Update (Silent)

```dart
test('remote update doesnt create sync_box entry', () async {
  final repo = ShoppingListRepository();
  final remoteData = {
    'id': 'test-id',
    'name': 'Remote',
    'lastModified': DateTime.now().toIso8601String(),
    'isDeleted': false,
  };
  
  // Apply remote update
  await repo.applyRemoteUpdate(remoteData);
  
  // Verify NO sync_box entry created
  final syncEntry = await ManageSyncBox.getSyncEntry(
    'test-id',
    ENTITY_TYPE_SHOPPING_LIST,
  );
  
  expect(syncEntry, isNull);
});
```

### Test 3: Soft Delete

```dart
test('soft delete sets isDeleted flag', () async {
  final repo = ShoppingListRepository();
  var list = ShoppingList(id: 'test', name: 'Test');
  
  await repo.add(list);
  list = (await repo.getById('test'))!;
  
  // Delete
  await repo.delete(list);
  
  // Verify isDeleted = true
  final row = await db.query(
    'shopping_list',
    where: 'id = ?',
    whereArgs: ['test'],
  );
  
  expect(row[0]['is_deleted'], 1);
});
```

## Common Patterns

### Pattern 1: Monotonic Timestamps

Always use monotonic timestamps for user writes:

```dart
entity.lastModified = MonotonicTimestamp.generateNext(
  previousTime: entity.lastModified,
);
```

### Pattern 2: Dirty Checking

Before applying remote updates, check if entity is dirty:

```dart
if (await isEntityDirty(entityId, getEntityType())) {
  return; // Skip update, local changes take priority
}
```

### Pattern 3: Timestamp Comparison

When comparing timestamps:

```dart
if (remoteTime != null && localTime != null) {
  if (localTime.isAfter(remoteTime)) {
    // Local is newer, don't update
    return;
  }
}
```

## Troubleshooting

### Issue: Infinite Sync Loop

**Cause**: Repository appends to sync_box in applyRemoteUpdate()

**Fix**: Use the SyncRepositoryMixin methods which only write to sync_box for user writes, not sync writes.

### Issue: Lost Updates

**Cause**: Sync_box entries deleted before transaction completes

**Fix**: Use conditional delete: `WHERE entity_id = ? AND last_modified <= ?`

### Issue: Orphaned Records

**Cause**: Child entities synced before parent

**Fix**: Don't use FOREIGN KEY constraints for synced tables. Handle cascading deletes in applyRemoteUpdate().

### Issue: Stale lastSyncedAt

**Cause**: Timestamp not updated after processing batch

**Fix**: Update lastSyncedAt with max(previousLastSyncedAt, newestSeenTimestamp) after each batch.

## Next Steps

1. **Update all entity repositories** to implement SyncRepository
2. **Register repositories** in syncRepositoryRegistryProvider
3. **Test offline-first workflow** with manual sync testing
4. **Monitor logs** for sync engine operation
5. **Handle edge cases** (crashes, network failures, etc.)

## API Reference

### ManageSyncBox

```dart
// Add or update entry
addOrUpdateSyncEntry(LocalSyncEntry entry)

// Get all entries
getAllSyncEntries({String? entityType})

// Get specific entry
getSyncEntry(String entityId, String entityType)

// Delete after successful sync
deleteSyncEntry(String entityId, String entityType, DateTime lastModified)

// Check if entity is dirty
isEntityDirty(String entityId, String entityType)
```

### MonotonicTimestamp

```dart
// Generate next timestamp
generateNext({DateTime? previousTime})

// Merge local and server time
merge(DateTime localTime, DateTime? serverTime)
```

### SyncRepositoryMixin

```dart
// Append operations to sync queue
appendUpsertToSyncBox(String entityId, String entityType, DateTime? currentLastModified)
appendDeleteToSyncBox(String entityId, String entityType, DateTime? currentLastModified)

// Query sync status
isEntityDirty(String entityId, String entityType)
```
