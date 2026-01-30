import 'package:app_code/models/product.dart';
import 'package:app_code/repositories/sync/sync_repository.dart';
import 'package:app_code/repositories/sync/sync_repository_mixin.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_product.dart';
import 'package:app_code/utils/monotonic_timestamp.dart';
import 'package:sqflite/sqflite.dart';

/// Product repository with sync support
/// User writes append to sync_box; remote updates are silent
class ProductRepositoryWithSync 
  with SyncRepositoryMixin
  implements SyncRepository {
  @override
  String getEntityType() => ENTITY_TYPE_PRODUCT;

  // ===== USER WRITES =====

  Future<void> add(Product product) async {
    product.createdAt = DateTime.now();
    product.lastModified = product.createdAt;

    await ManageProduct.addProduct(product);

    await appendUpsertToSyncBox(
      product.id,
      getEntityType(),
      product.lastModified!,
    );
  }

  Future<void> update(Product product) async {
    product.lastModified = MonotonicTimestamp.generateNext(
      previousTime: product.lastModified,
    );

    await ManageProduct.updateProduct(product);

    await appendUpsertToSyncBox(
      product.id,
      getEntityType(),
      product.lastModified!,
    );
  }

  Future<void> deleteById(String id) async {
    final local = await ManageProduct.getProductById(id);

    await ManageProduct.deleteProduct(id);

    await appendDeleteToSyncBox(
      id,
      getEntityType(),
      local!.lastModified!,
    );
  }

  Future<Product?> getById(String id) => ManageProduct.getProductById(id);

  Future<List<Product>> getAll() => ManageProduct.getAllProducts();

  // ===== SYNC WRITES (Silent Update) =====

  @override
  Future<void> applyRemoteUpdate(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.database;
    final entityId = data['id'] as String?;

    if (entityId == null) {
      throw ArgumentError('Remote data must contain id field');
    }

    if (await isEntityDirty(entityId, getEntityType())) {
      return;
    }

    final localData = await getLocalData(entityId);
    final remoteLastModified = _parseTimestamp(data['lastModified'] ?? data['last_modified']);

    if (localData != null) {
      final localLastModified = _parseTimestamp(localData['last_modified']);
      if (localLastModified != null && remoteLastModified != null) {
        if (localLastModified.isAfter(remoteLastModified)) {
          return;
        }
      }
    }

    if (data['isDeleted'] == true || data['is_deleted'] == 1) {
      await db.delete('associations', where: 'product_id = ?', whereArgs: [entityId]);
      await db.delete('product', where: 'id = ?', whereArgs: [entityId]);
      return;
    }

    final cleanedData = _cleanFirebaseData(data);
    final exists = localData != null;

    if (exists) {
      await db.update(
        'product',
        cleanedData,
        where: 'id = ?',
        whereArgs: [entityId],
      );
    } else {
      await db.insert(
        'product',
        cleanedData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await _replaceAssociations(db, entityId, data['associations']);
  }

  @override
  Future<Map<String, dynamic>?> getLocalData(String id) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'product',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return rows.isNotEmpty ? rows.first : null;
  }

  // ===== HELPERS =====

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

  Map<String, dynamic> _cleanFirebaseData(Map<String, dynamic> data) {
    final cleaned = Map<String, dynamic>.from(data);

    cleaned.remove('associations');

    if (cleaned.containsKey('isVisible')) {
      cleaned['is_visible'] = cleaned['isVisible'] == true ? 1 : 0;
      cleaned.remove('isVisible');
    }

    if (cleaned.containsKey('createdAt')) {
      final parsed = _parseTimestamp(cleaned['createdAt']);
      cleaned['created_at'] = parsed?.toIso8601String() ?? DateTime.now().toIso8601String();
      cleaned.remove('createdAt');
    }

    if (cleaned.containsKey('lastModified')) {
      final parsed = _parseTimestamp(cleaned['lastModified']);
      cleaned['last_modified'] = parsed?.toIso8601String() ?? DateTime.now().toIso8601String();
      cleaned.remove('lastModified');
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

  Future<void> _replaceAssociations(
    Database db,
    String productId,
    dynamic associationsData,
  ) async {
    await db.delete(
      'associations',
      where: 'product_id = ?',
      whereArgs: [productId],
    );

    if (associationsData == null) return;

    if (associationsData is Map) {
      for (final entry in associationsData.entries) {
        final supermarketId = entry.key.toString();
        final categoryId = _extractCategoryId(entry.value);
        if (supermarketId.isEmpty || categoryId == null || categoryId.isEmpty) {
          continue;
        }
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
      return;
    }

    if (associationsData is List) {
      for (final item in associationsData) {
        if (item is Map) {
          final supermarketId = item['supermarketId'] ?? item['supermarket_id'];
          final categoryId = item['categoryId'] ?? item['category_id'];
          if (supermarketId is String && categoryId is String) {
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
      }
    }
  }

  String? _extractCategoryId(dynamic value) {
    if (value is String) return value;
    if (value is Map) {
      final categoryId = value['categoryId'] ?? value['category_id'];
      if (categoryId is String) return categoryId;
    }
    return null;
  }
}