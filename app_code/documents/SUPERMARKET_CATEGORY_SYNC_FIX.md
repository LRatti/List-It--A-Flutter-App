# Supermarket Category Sync Fix

## Problem Statement

When a user started the app anonymously, the default supermarket was correctly populated with all 17 default categories locally. However, after the user logged in and the data was synced to Firestore:

1. The default supermarket was successfully pushed to Firestore with all categories
2. Firestore echoed back the supermarket document
3. The local database was updated from the Firestore echo
4. **Result**: The supermarket became empty (no categories) in both local and Firestore

The root cause was that the Firestore supermarket document did not include the category IDs needed to reconstruct the supermarket-category relationships.

## Root Cause Analysis

### The Data Flow (Before Fix)

```
User Logs In (was anonymous)
    ↓
SyncEnginePush.processPendingSync()
    ↓
Supermarket.toJson() sends:
{
  "id": "sup123",
  "name": "Supermarket",
  "categories": [
    { full category object 1 },
    { full category object 2 },
    ...
  ],
  "isVisible": true,
  "lastModified": "2026-01-30T...",
  "createdAt": "2026-01-30T..."
}
    ↓
Firestore Document Created (stores exactly as sent)
    ↓
SyncEnginePull listens to Firestore changes
    ↓
applyRemoteUpdate() called with Firestore data
    ↓
_replaceCategories() processes the data:
    - categoryIdsData is undefined/null
    - categoriesData exists but contains... ?
    ↓
Problem: If categories array is lost or empty, no relationships created!
    ↓
Local Database: supermarket_category junction table is empty
    ↓
UI queries: getSupermarketById() → no categories found
```

### Why Categories Could Be Lost

1. **JSON Serialization Issues**: When full category objects are serialized, some information might be lost or structure might change
2. **Field Mismatch**: When deserializing, the category objects might not be reconstructed properly
3. **No Explicit ID Array**: Without an explicit `categoryIds` array in Firestore, the sync process relies on reconstructing IDs from complex objects

## Solution

Add an explicit `categoryIds` array to the supermarket's Firestore document alongside the full `categories` array. This ensures category relationships are always preserved.

### Changes Made

#### 1. **Supermarket Model** - [lib/models/supermarket.dart](lib/models/supermarket.dart#L91-L99)

Updated `toJson()` to include both full category objects AND an explicit array of category IDs:

```dart
Map<String, dynamic> toJson() {
  return {
    'id': id,
    'name': _name,
    'categories': _categories.map((cat) => cat.toJson()).toList(),
    'categoryIds': _categories.map((cat) => cat.id).toList(),  // ← NEW FIELD
    'isVisible': isVisible,
    'lastModified': lastModified?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };
}
```

**Why this works:**
- `categoryIds` is a simple array of strings: `["cat1", "cat2", "cat3", ...]`
- Firestore stores this as an array without any serialization complexity
- When syncing back, this array can be used directly to reconstruct relationships
- The `categories` array remains for backward compatibility and for upserting category data

#### 2. **Supermarket Repository** - [lib/repositories/sync/supermarket_repository_sync.dart](lib/repositories/sync/supermarket_repository_sync.dart#L207-L237)

The `_replaceCategories()` method already handles both approaches correctly:

```dart
Future<void> _replaceCategories(
  Database db,
  String supermarketId,
  dynamic categoriesData,
  dynamic categoryIdsData,
) async {
  final categoryIds = <String>[];

  // Priority 1: Use explicit categoryIds array if available
  if (categoryIdsData is List) {
    for (final id in categoryIdsData) {
      if (id is String) categoryIds.add(id);
    }
  }
  // Priority 2: Fall back to extracting IDs from category objects
  else if (categoriesData is List) {
    for (final item in categoriesData) {
      if (item is Map) {
        final id = item['id'];
        if (id is String) categoryIds.add(id);
        await _upsertCategory(db, item);
      }
    }
  }

  // Delete existing relationships
  await db.delete(
    'supermarket_category',
    where: 'supermarket_id = ?',
    whereArgs: [supermarketId],
  );

  // Create new relationships with proper ordering
  for (int i = 0; i < categoryIds.length; i++) {
    await db.insert(
      'supermarket_category',
      {
        'supermarket_id': supermarketId,
        'category_id': categoryIds[i],
        'order_index': i,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
```

**How it works:**
1. Checks for explicit `categoryIds` array first (preferred, robust)
2. Falls back to extracting IDs from `categories` objects (backward compatible)
3. Deletes old supermarket-category relationships
4. Creates new relationships using the IDs, preserving order via `order_index`

### Data Flow (After Fix)

```
User Logs In (was anonymous)
    ↓
SyncEnginePush.processPendingSync()
    ↓
Supermarket.toJson() sends:
{
  "id": "sup123",
  "name": "Supermarket",
  "categories": [
    { full category object 1 },
    { full category object 2 },
    ...
  ],
  "categoryIds": ["cat1", "cat2", ...],  ← ✅ NEW
  "isVisible": true,
  "lastModified": "2026-01-30T...",
  "createdAt": "2026-01-30T..."
}
    ↓
Firestore Document Stored (includes categoryIds array)
    ↓
SyncEnginePull listens to Firestore changes
    ↓
applyRemoteUpdate() called with Firestore data
    ↓
_replaceCategories() processes the data:
    - categoryIdsData = ["cat1", "cat2", ...]  ✅
    - Uses categoryIds directly (robust)
    ↓
Local Database: supermarket_category junction table recreated:
    - (sup123, cat1, order_index=0)
    - (sup123, cat2, order_index=1)
    - ...
    ↓
UI queries: getSupermarketById() → finds all categories ✅
```

## Firestore Document Structure

The supermarket document in Firestore now looks like:

```json
{
  "id": "sup123",
  "name": "Supermarket",
  "isVisible": true,
  "createdAt": "2026-01-30T10:00:00Z",
  "lastModified": "2026-01-30T10:00:00Z",
  "categories": [
    {
      "id": "cat1",
      "name": "Meat",
      "isVisible": true,
      "createdAt": "2026-01-30T10:00:00Z",
      "lastModified": "2026-01-30T10:00:00Z"
    },
    {
      "id": "cat2",
      "name": "Wine Shop",
      "isVisible": true,
      "createdAt": "2026-01-30T10:00:00Z",
      "lastModified": "2026-01-30T10:00:00Z"
    },
    ...
  ],
  "categoryIds": ["cat1", "cat2", "cat3", ...]  ← ✅ NEW
}
```

## Benefits

1. **Robust**: Explicit ID array is simple and immune to serialization issues
2. **Backward Compatible**: Still supports the full `categories` array for data completeness
3. **Ordering Preserved**: The array order in `categoryIds` ensures category order is maintained across sync
4. **Scalable**: Simple array of strings is efficient in Firestore
5. **Debuggable**: Easy to inspect what categories are linked to what supermarket in Firestore Console

## Testing the Fix

### Manual Test
1. Clear app data
2. Launch app (anonymous)
3. Verify default supermarket has 17 categories visible
4. Open Firebase Console → Users → supermarkets document
5. Verify `categoryIds` array is present with all 17 IDs
6. Log in with an account
7. Wait 10-15 seconds for sync
8. Open supermarket screen
9. **Expected**: Supermarket still has all 17 categories (fixed!)
10. Check Firestore - supermarket still has `categoryIds` array

### Debug Checks
```dart
// Check local supermarket-category relationships
final db = await DatabaseHelper.database;
final relations = await db.query('supermarket_category', 
  where: 'supermarket_id = ?',
  whereArgs: [supermarketId]);
print('Relations: ${relations.length}'); // Should be 17

// Check Firestore document
firebase firestore:documents get Users/{uid}/supermarket/{supermarketId}
// Should see categoryIds array with 17 IDs
```

## Files Modified

1. `lib/models/supermarket.dart` - Added `categoryIds` to `toJson()`
2. `lib/services/sync/sync_engine_push.dart` - Enhanced dependency pushing logic (for future use)

## Related Documentation

- [Default Categories Sync Fix](DEFAULT_CATEGORIES_SYNC_FIX.md) - How default categories are loaded
- [Sync Engine README](sync-engine-doc/SYNC_ENGINE_README.md) - Complete sync architecture
- [Supermarket Implementation](supermarket-category/SUPERMARKET_IMPLEMENTATION.md) - Feature overview
