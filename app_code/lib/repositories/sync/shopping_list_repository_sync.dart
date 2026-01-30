import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/repositories/abstract/shopping_list_repository.dart';
import 'package:app_code/repositories/sync/sync_repository.dart';
import 'package:app_code/repositories/sync/sync_repository_mixin.dart';
import 'package:app_code/repositories/sync/purchased_product_repository_sync.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_shopping_list.dart';
import 'package:app_code/services/database/sqlite/manage_purchased_product.dart';
import 'package:app_code/utils/monotonic_timestamp.dart';
import 'package:sqflite/sqflite.dart';

/// ShoppingListRepository with sync support
/// Implements both local-only persistence and sync capabilities
/// 
/// User writes (add, update, delete) append to sync_box and return immediately
/// Sync writes (applyRemoteUpdate) do NOT append to sync_box (silent updates)
class ShoppingListRepositoryWithSync 
  with SyncRepositoryMixin
  implements ShoppingListRepository, SyncRepository {

  // Use a shared instance of purchased product repository for sync
  final PurchasedProductRepositoryWithSync _purchasedProductRepo = PurchasedProductRepositoryWithSync();

  @override
  String getEntityType() => ENTITY_TYPE_SHOPPING_LIST;

  // ===== USER WRITES (triggers sync_box append) =====

  /// User initiates create - marks for sync
  @override
  Future<void> add(ShoppingList list) async {
    final db = await DatabaseHelper.database;

    // Initialize timestamps for new entity
    list.lastModified = list.createdAt;
    list.isDeleted = false;

    // Insert into SQLite
    await db.insert(
      'shopping_list',
      list.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Add related products if any
    final products = list.getProducts();
    if (products.isNotEmpty) {
      for (final item in products) {
        // Use the purchased product repo to ensure sync
        await _purchasedProductRepo.add(item);
      }
    }

    // IMPORTANT: Append to sync_box to mark for sync
    await appendUpsertToSyncBox(
      list.id,
      getEntityType(),
      list.lastModified!,
    );
  }

  /// User initiates update - marks for sync
  @override
  Future<void> update(ShoppingList list) async {
    final db = await DatabaseHelper.database;

    // Update timestamp using monotonic clock
    list.lastModified = MonotonicTimestamp.generateNext(
      previousTime: list.lastModified,
    );

    // Update in SQLite
    await db.update(
      'shopping_list',
      list.toDatabase(),
      where: 'id = ?',
      whereArgs: [list.id],
    );

    // Sync products for this list
    final products = list.getProducts();
    if (products.isNotEmpty) {
      final existing =
          await ManagePurchasedProduct.getPurchasedProductsByList(list.id);
      final existingIds = existing.map((pp) => pp.id).toSet();

      for (final item in products) {
        if (existingIds.contains(item.id)) {
          await _purchasedProductRepo.update(item);
        } else {
          await _purchasedProductRepo.add(item);
        }
      }
    }

    // IMPORTANT: Append to sync_box
    await appendUpsertToSyncBox(
      list.id,
      getEntityType(),
      list.lastModified!,
    );
  }

  /// User initiates soft delete - marks for sync
  /// Note: Does NOT physically delete, just marks isDeleted=1
  /// IMPORTANT: Also marks all associated purchased_products for deletion
  @override
  Future<void> delete(ShoppingList list) async {
    final db = await DatabaseHelper.database;

    // Update timestamp
    list.lastModified = MonotonicTimestamp.generateNext(
      previousTime: list.lastModified,
    );
    list.isDeleted = true;

    // Update in SQLite (soft delete)
    await db.update(
      'shopping_list',
      list.toDatabase(),
      where: 'id = ?',
      whereArgs: [list.id],
    );

    // CRITICAL: Cascade delete all purchased products associated with this list
    // Must mark them for sync deletion so Firestore also removes them
    final products = await ManagePurchasedProduct.getPurchasedProductsByList(list.id);
    for (final product in products) {
      if (!product.isDeleted) {
        // Mark for soft delete and sync via the purchased product repository
        product.isDeleted = true;
        // Use the repository delete method to ensure proper sync_box append
        await _purchasedProductRepo.delete(product);
      }
    }

    // IMPORTANT: Append to sync_box with delete operation
    await appendDeleteToSyncBox(
      list.id,
      getEntityType(),
      list.lastModified!,
    );
  }

  // ===== QUERIES (excludes soft-deleted items) =====

  @override
  Future<List<ShoppingList>> getAll() async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'shopping_list',
      where: 'is_deleted = 0',
    );

    final result = <ShoppingList>[];
    for (final row in rows) {
      final list = ShoppingList.fromDatabase(row);

      final products = await ManagePurchasedProduct.getPurchasedProductsByList(list.id);
      list.setPurchasedProducts(products);

      result.add(list);
    }

    return result;
  }

  /// Get shopping list by ID (excludes soft-deleted)
  Future<ShoppingList?> getById(String id) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'shopping_list',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );

    if (rows.isEmpty) return null;

    final list = ShoppingList.fromDatabase(rows.first);
    final products = await ManagePurchasedProduct.getPurchasedProductsByList(id);
    list.setPurchasedProducts(products);

    return list;
  }

  // ===== SYNC WRITES (Silent Update - NO sync_box append) =====

  /// Apply remote update from Firestore
  /// Implements silent update logic:
  /// - Check if entity is dirty (pending sync)
  /// - Compare timestamps for LWW
  /// - Handle soft deletes (physical delete if isDeleted=true from remote)
  /// - DO NOT append to sync_box
  @override
  Future<void> applyRemoteUpdate(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.database;
    final entityId = data['id'] as String?;

    if (entityId == null) {
      throw ArgumentError('Remote data must contain id field');
    }

    // Check if entity is dirty (has pending sync operations)
    // If dirty, ignore remote update to preserve local changes
    if (await isEntityDirty(entityId, getEntityType())) {
      return; // Local changes will sync and be echoed back
    }

    // Get local data for timestamp comparison
    final localData = await getLocalData(entityId);

    // Compare timestamps - only apply if remote is newer
    final remoteLastModified = _parseTimestamp(data['lastModified'] ?? data['last_modified']);
    if (localData != null) {
      final localLastModified = _parseTimestamp(localData['last_modified']);

      if (localLastModified != null && remoteLastModified != null) {
        if (localLastModified.isAfter(remoteLastModified)) {
          // Local is newer, skip remote update
          return;
        }
      }
    }

    // Handle soft delete from remote
    // When Firestore says isDeleted=true, PHYSICALLY DELETE from local SQLite
    if (data['isDeleted'] == true || data['is_deleted'] == 1) {
      await db.delete(
        'shopping_list',
        where: 'id = ?',
        whereArgs: [entityId],
      );
      // Also cascade delete products
      await db.delete(
        'purchased_product',
        where: 'list_id = ?',
        whereArgs: [entityId],
      );
      return;
    }

    // Apply update to SQLite
    final cleanedData = _cleanFirebaseData(data);
    final exists = localData != null;

    if (exists) {
      await db.update(
        'shopping_list',
        cleanedData,
        where: 'id = ?',
        whereArgs: [entityId],
      );
    } else {
      await db.insert(
        'shopping_list',
        cleanedData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Note: Products will be synced separately if they're in the registry
  }

  /// Get local data for a shopping list (used by sync engine for comparison)
  /// IMPORTANT: Returns soft-deleted items too (needed for DELETE sync operations)
  /// The sync engine needs to see deleted items to propagate the deletion to Firestore
  @override
  Future<Map<String, dynamic>?> getLocalData(String id) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'shopping_list',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return rows.isNotEmpty ? rows.first : null;
  }

  // ===== HELPERS =====

  /// Parse timestamp from various formats (Timestamp object, ISO8601 string, etc.)
  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }

    // Handle Firestore Timestamp object
    if (value.runtimeType.toString() == 'Timestamp') {
      try {
        // Access toDate() method dynamically
        return (value as dynamic).toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }

    // Handle Firestore Timestamp as map (serialized)
    if (value is Map && value.containsKey('_seconds')) {
      try {
        final seconds = value['_seconds'] as int;
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// Clean Firestore data for SQLite insertion
  /// Converts Firestore field names to SQLite column names
  Map<String, dynamic> _cleanFirebaseData(Map<String, dynamic> data) {
    final cleaned = Map<String, dynamic>.from(data);

    // Remove Firestore-specific fields
    cleaned.remove('firestore_timestamp');

    // Convert Timestamp fields to ISO8601 strings
    if (cleaned['lastModified'] != null) {
      final parsed = _parseTimestamp(cleaned['lastModified']);
      cleaned['last_modified'] = parsed?.toIso8601String() ?? DateTime.now().toIso8601String();
      cleaned.remove('lastModified');
    }

    if (cleaned['createdAt'] != null) {
      final parsed = _parseTimestamp(cleaned['createdAt']);
      cleaned['created_at'] = parsed?.toIso8601String() ?? DateTime.now().toIso8601String();
      cleaned.remove('createdAt');
    } else if (cleaned['created_at'] != null) {
      final parsed = _parseTimestamp(cleaned['created_at']);
      cleaned['created_at'] = parsed?.toIso8601String() ?? DateTime.now().toIso8601String();
    }

    if (cleaned['deletionTimestamp'] != null) {
      final parsed = _parseTimestamp(cleaned['deletionTimestamp']);
      cleaned['deletion_timestamp'] = parsed?.toIso8601String();
      cleaned.remove('deletionTimestamp');
    }

    // Convert field names from camelCase to snake_case
    // Convert field names from camelCase to snake_case
    if (cleaned.containsKey('supermarketId')) {
      cleaned['supermarket_id'] = cleaned['supermarketId'];
      cleaned.remove('supermarketId');
    }

    if (cleaned.containsKey('totalPrice')) {
      cleaned['total_price'] = cleaned['totalPrice'];
      cleaned.remove('totalPrice');
    }

    if (cleaned.containsKey('isRegistered')) {
      cleaned['is_registered'] = cleaned['isRegistered'] ? 1 : 0;
      cleaned.remove('isRegistered');
    }

    if (cleaned.containsKey('isInTheTrash')) {
      cleaned['is_in_the_trash'] = cleaned['isInTheTrash'] ? 1 : 0;
      cleaned.remove('isInTheTrash');
    }

    if (cleaned.containsKey('isDeleted')) {
      cleaned['is_deleted'] = cleaned['isDeleted'] ? 1 : 0;
      cleaned.remove('isDeleted');
    }
    
    // Ensure required fields have default values if missing
    if (!cleaned.containsKey('created_at') || cleaned['created_at'] == null) {
      cleaned['created_at'] = DateTime.now().toIso8601String();
    }
    if (!cleaned.containsKey('last_modified') || cleaned['last_modified'] == null) {
      cleaned['last_modified'] = DateTime.now().toIso8601String();
    }

    return cleaned;
  }
}
