# SQLite Database Migration Guide

## Schema Changes for Sync Engine

This document describes the schema changes made to support the sync engine implementation with timestamps and soft deletes.

### New Fields Added to All Tables

**`last_modified` (TEXT)**: ISO 8601 formatted timestamp
- Records when an entity was last modified
- Used for conflict detection in the sync engine
- Always defaults to current time on creation
- Must be updated every time the entity changes

**`is_deleted` (INTEGER)**: Boolean flag (0 = active, 1 = deleted)
- Implements soft deletes
- Critical for syncing deletions to Firebase
- Items marked as deleted can be filtered out from queries
- Enables recovery of "accidentally" deleted items

### Tables Modified

1. **shopping_list**
   - Added: `last_modified TEXT NOT NULL`
   - Added: `is_deleted INTEGER NOT NULL DEFAULT 0`

2. **product**
   - Added: `last_modified TEXT NOT NULL`
   - Added: `is_deleted INTEGER NOT NULL DEFAULT 0`

3. **category**
   - Added: `last_modified TEXT NOT NULL`
   - Added: `is_deleted INTEGER NOT NULL DEFAULT 0`

4. **supermarket**
   - Added: `last_modified TEXT NOT NULL`
   - Added: `is_deleted INTEGER NOT NULL DEFAULT 0`

5. **purchased_product**
   - Added: `last_modified TEXT NOT NULL`
   - Added: `is_deleted INTEGER NOT NULL DEFAULT 0`

### Migration Steps for Existing Database

If you have an existing database with data, you need to migrate it:

```dart
// In database_helper.dart, update the version
static Future<Database> _initDb() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'shopping_app.db');

  return openDatabase(
    path,
    version: 2,  // Increment from 1 to 2
    onCreate: _createDb,
    onUpgrade: _migrateDb,  // Add this callback
  );
}

static Future<void> _migrateDb(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Add columns to all tables
    final now = DateTime.now().toIso8601String();
    
    await db.execute('''
      ALTER TABLE shopping_list 
      ADD COLUMN last_modified TEXT NOT NULL DEFAULT '$now'
    ''');
    await db.execute('''
      ALTER TABLE shopping_list 
      ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0
    ''');
    
    // Repeat for other tables...
    await db.execute('''
      ALTER TABLE product 
      ADD COLUMN last_modified TEXT NOT NULL DEFAULT '$now'
    ''');
    await db.execute('''
      ALTER TABLE product 
      ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0
    ''');
    
    // ... and so on for category, supermarket, purchased_product
  }
}
```

### Conflict Resolution Strategy

The sync engine uses **"Last-Write-Wins"** (LWW) conflict resolution:

```dart
// Pseudo-code for conflict resolution
Product cloudVersion = await firebase.getProduct(id);
Product localVersion = await sqlite.getProduct(id);

if (cloudVersion.lastModified > localVersion.lastModified) {
  // Cloud version is newer, update local
  await sqlite.updateProduct(cloudVersion);
} else {
  // Local version is newer, update cloud
  await firebase.setProduct(localVersion);
}
```

### Soft Delete Behavior

Instead of physically deleting records, mark them as deleted:

```dart
// In database manager
Future<void> deleteProduct(String id) async {
  // 1. Mark as deleted in SQLite (soft delete)
  final product = await sqlite.getProductById(id);
  product.isDeleted = true;
  product.lastModified = DateTime.now();
  await sqlite.updateProduct(product);
  
  // 2. Sync to Firebase asynchronously
  _firebaseManager.syncDeletedProduct(product).catchError(...);
}

// Queries should exclude deleted items by default
static Future<List<Product>> getAllProducts() async {
  final db = await DatabaseHelper.database;
  final productRows = await db.query(
    'product',
    where: 'is_deleted = ?',
    whereArgs: [0],  // Only get active items
  );
  // ... process results
}
```

### Querying Deleted Items

To retrieve deleted items (e.g., for recovery UI):

```dart
static Future<List<Product>> getDeletedProducts() async {
  final db = await DatabaseHelper.database;
  final productRows = await db.query(
    'product',
    where: 'is_deleted = ?',
    whereArgs: [1],  // Only get deleted items
  );
  // ... process results
}
```

### Timestamp Best Practices

1. **Always use UTC**: Store timestamps in UTC (which `DateTime.now()` and `DateTime.now().toUtc()` do)
2. **Update on every change**: Whenever you modify an entity, update `lastModified`
3. **Handle parsing**: Always use `DateTime.tryParse()` with a fallback to `DateTime.now()`
4. **ISO 8601 format**: Use `toIso8601String()` for serialization

```dart
// Good practice
product.setName("New Name");
product.lastModified = DateTime.now();  // Update timestamp
await saveProduct(product);

// In constructors, always default to now()
class Product {
  late DateTime lastModified;
  
  Product({
    ...
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();
}
```

### Future Improvements

1. **Vector Clocks**: For more sophisticated conflict detection across multiple devices
2. **Tombstones Table**: Separate table to track deleted items for cleanup
3. **Replication Log**: Table to track all changes for advanced sync strategies
4. **Partial Indexes**: Index on `is_deleted = 0` for faster queries

```sql
-- Example: Create index for faster queries of active items
CREATE INDEX idx_product_active ON product(is_deleted) 
WHERE is_deleted = 0;
```

---

For questions about the sync engine implementation, refer to the database_manager_repository classes.
