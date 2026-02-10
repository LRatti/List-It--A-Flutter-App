import 'package:app_code/repositories/sync/sync_repository.dart';
import 'package:app_code/repositories/sync/sync_repository_mixin.dart';
import 'package:app_code/repositories/abstract/association_repository.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:sqflite/sqflite.dart';

/// Association repository with sync support
/// Manages the associations between products, supermarkets, and categories
/// 
/// User writes (add, update, delete) append to sync_box and return immediately
/// Sync writes (applyRemoteUpdate) do NOT append to sync_box (silent updates)
/// 
/// Note: Associations don't have their own createdAt/lastModified timestamps.
/// Instead, we track them via the product's sync entry. When a product is synced,
/// its associations are synced as part of the product's data.
class AssociationRepositoryWithSync 
  with SyncRepositoryMixin
  implements SyncRepository, AssociationRepository {

  @override
  String getEntityType() => ENTITY_TYPE_ASSOCIATION;

  // ===== USER WRITES =====

  /// Add multiple associations in a single transaction (BATCH OPERATION)
  /// More efficient than calling add() multiple times
  /// Creates only one sync_box entry per product instead of multiple
  /// 
  /// [associationsByProduct]: Map of productId -> Map<supermarketId, categoryId>
  Future<void> addBatch(
    Map<String, Map<String, String>> associationsByProduct,
  ) async {
    if (associationsByProduct.isEmpty) return;

    final db = await DatabaseHelper.database;
    final processedProducts = <String>{};

    await db.transaction((txn) async {
      for (final entry in associationsByProduct.entries) {
        final productId = entry.key;
        final associations = entry.value;

        for (final assocEntry in associations.entries) {
          final supermarketId = assocEntry.key;
          final categoryId = assocEntry.value;

          // Validate input
          if (productId.isEmpty || supermarketId.isEmpty || categoryId.isEmpty) {
            throw ArgumentError(
              'Invalid association: productId=$productId, '
              'supermarketId=$supermarketId, categoryId=$categoryId',
            );
          }

          // Insert into SQLite within transaction
          await txn.insert(
            'associations',
            {
              'product_id': productId,
              'supermarket_id': supermarketId,
              'category_id': categoryId,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        processedProducts.add(productId);
      }
    });

    // Mark all affected products for sync (after transaction completes)
    // One sync_box entry per product instead of one per association
    for (final productId in processedProducts) {
      final productRows = await db.query(
        'product',
        columns: ['last_modified'],
        where: 'id = ?',
        whereArgs: [productId],
      );

      if (productRows.isNotEmpty) {
        final lastModified = _parseTimestamp(productRows.first['last_modified']);
        if (lastModified != null) {
          await appendUpsertToSyncBox(
            productId,
            ENTITY_TYPE_PRODUCT,
            lastModified,
          );
        }
      }
    }
  }

  /// Delete multiple associations in a single transaction (BATCH OPERATION)
  /// More efficient than calling delete() multiple times
  /// 
  /// [associationsToDelete]: List of (productId, supermarketId) pairs
  Future<void> deleteBatch(
    List<({String productId, String supermarketId})> associationsToDelete,
  ) async {
    if (associationsToDelete.isEmpty) return;

    final db = await DatabaseHelper.database;
    final processedProducts = <String>{};

    await db.transaction((txn) async {
      for (final assoc in associationsToDelete) {
        // Delete from SQLite within transaction
        await txn.delete(
          'associations',
          where: 'product_id = ? AND supermarket_id = ?',
          whereArgs: [assoc.productId, assoc.supermarketId],
        );

        processedProducts.add(assoc.productId);
      }
    });

    // Mark all affected products for sync
    for (final productId in processedProducts) {
      final productRows = await db.query(
        'product',
        columns: ['last_modified'],
        where: 'id = ?',
        whereArgs: [productId],
      );

      if (productRows.isNotEmpty) {
        final lastModified = _parseTimestamp(productRows.first['last_modified']);
        if (lastModified != null) {
          await appendUpsertToSyncBox(
            productId,
            ENTITY_TYPE_PRODUCT,
            lastModified,
          );
        }
      }
    }
  }

  /// Add a new association (product-supermarket-category)
  /// Marks the product for sync so associations are synced with product
  /// 
  /// Note: For multiple associations, prefer using addBatch() for better performance
  Future<void> add(
    String productId,
    String supermarketId,
    String categoryId,
  ) async {
    final db = await DatabaseHelper.database;

    // Validate input
    if (productId.isEmpty || supermarketId.isEmpty || categoryId.isEmpty) {
      throw ArgumentError(
        'Invalid association: productId=$productId, '
        'supermarketId=$supermarketId, categoryId=$categoryId',
      );
    }

    // Insert into SQLite
    await db.insert(
      'associations',
      {
        'product_id': productId,
        'supermarket_id': supermarketId,
        'category_id': categoryId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Mark the product for sync (since associations are synced as part of product)
    // Get the product's timestamp
    final productRows = await db.query(
      'product',
      columns: ['last_modified'],
      where: 'id = ?',
      whereArgs: [productId],
    );

    if (productRows.isNotEmpty) {
      final lastModified = _parseTimestamp(productRows.first['last_modified']);
      if (lastModified != null) {
        await appendUpsertToSyncBox(
          productId,
          ENTITY_TYPE_PRODUCT,
          lastModified,
        );
      }
    }
  }

  /// Update an existing association
  /// Marks the product for sync
  Future<void> update(
    String productId,
    String supermarketId,
    String categoryId,
  ) async {
    final db = await DatabaseHelper.database;

    // Validate input
    if (productId.isEmpty || supermarketId.isEmpty || categoryId.isEmpty) {
      throw ArgumentError(
        'Invalid association: productId=$productId, '
        'supermarketId=$supermarketId, categoryId=$categoryId',
      );
    }

    // Update in SQLite (using composite primary key)
    await db.update(
      'associations',
      {'category_id': categoryId},
      where: 'product_id = ? AND supermarket_id = ?',
      whereArgs: [productId, supermarketId],
    );

    // Mark the product for sync
    final productRows = await db.query(
      'product',
      columns: ['last_modified'],
      where: 'id = ?',
      whereArgs: [productId],
    );

    if (productRows.isNotEmpty) {
      final lastModified = _parseTimestamp(productRows.first['last_modified']);
      if (lastModified != null) {
        await appendUpsertToSyncBox(
          productId,
          ENTITY_TYPE_PRODUCT,
          lastModified,
        );
      }
    }
  }

  /// Delete a specific association
  /// Marks the product for sync
  Future<void> delete(
    String productId,
    String supermarketId,
  ) async {
    final db = await DatabaseHelper.database;

    // Delete from SQLite
    await db.delete(
      'associations',
      where: 'product_id = ? AND supermarket_id = ?',
      whereArgs: [productId, supermarketId],
    );

    // Mark the product for sync
    final productRows = await db.query(
      'product',
      columns: ['last_modified'],
      where: 'id = ?',
      whereArgs: [productId],
    );

    if (productRows.isNotEmpty) {
      final lastModified = _parseTimestamp(productRows.first['last_modified']);
      if (lastModified != null) {
        await appendUpsertToSyncBox(
          productId,
          ENTITY_TYPE_PRODUCT,
          lastModified,
        );
      }
    }
  }

  // ===== QUERIES =====

  /// Get all associations for a specific product
  /// Returns a map of supermarketId -> categoryId
  Future<Map<String, String>> getProductAssociations(String productId) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'associations',
      where: 'product_id = ?',
      whereArgs: [productId],
    );

    final associations = <String, String>{};
    for (final row in rows) {
      final supermarketId = row['supermarket_id'] as String;
      final categoryId = row['category_id'] as String;
      associations[supermarketId] = categoryId;
    }

    return associations;
  }

  /// Get the category for a product in a specific supermarket
  Future<String?> getCategoryForProduct(
    String productId,
    String supermarketId,
  ) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'associations',
      columns: ['category_id'],
      where: 'product_id = ? AND supermarket_id = ?',
      whereArgs: [productId, supermarketId],
    );

    return rows.isNotEmpty ? rows.first['category_id'] as String : null;
  }

  // ===== SYNC WRITES (Silent Update - NO sync_box append) =====

  /// Apply remote update from Firestore
  /// This handles association data updates received from sync engine
  /// Note: Individual associations don't get synced separately;
  /// they're synced as part of the product. However, this method
  /// is here for completeness and consistency with the sync pattern.
  @override
  Future<void> applyRemoteUpdate(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.database;
    
    // Association updates typically come as part of product updates,
    // but if they come separately, we need to handle them
    final productId = data['productId'] as String?;
    final supermarketId = data['supermarketId'] as String?;
    final categoryId = data['categoryId'] as String?;

    if (productId == null || supermarketId == null) {
      throw ArgumentError(
        'Remote association data must contain productId and supermarketId',
      );
    }

    // Check if product is dirty (has pending sync operations)
    if (await isEntityDirty(productId, ENTITY_TYPE_PRODUCT)) {
      return; // Local changes will sync and be echoed back
    }

    // Handle soft delete from remote
    if (data['isDeleted'] == true || data['is_deleted'] == 1) {
      await db.delete(
        'associations',
        where: 'product_id = ? AND supermarket_id = ?',
        whereArgs: [productId, supermarketId],
      );
      return;
    }

    // Upsert the association
    if (categoryId != null && categoryId.isNotEmpty) {
      await db.insert(
        'associations',
        {
          'product_id': productId,
          'supermarket_id': supermarketId,
          'category_id': categoryId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Get local data for an association (by product and supermarket)
  /// Returns null if association doesn't exist
  @override
  Future<Map<String, dynamic>?> getLocalData(String id) async {
    // Association IDs follow the pattern: productId_supermarketId
    final parts = id.split('_');
    if (parts.length < 2) return null;

    final productId = parts[0];
    final supermarketId = parts.sublist(1).join('_'); // Handle IDs with underscores

    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'associations',
      where: 'product_id = ? AND supermarket_id = ?',
      whereArgs: [productId, supermarketId],
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

    // Handle Firestore Timestamp object
    if (value.runtimeType.toString() == 'Timestamp') {
      try {
        return (value as dynamic).toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }

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
}
