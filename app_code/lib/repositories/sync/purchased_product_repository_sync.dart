import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/repositories/sync/sync_repository.dart';
import 'package:app_code/repositories/sync/sync_repository_mixin.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_category.dart';
import 'package:app_code/services/database/sqlite/manage_product.dart';
import 'package:app_code/services/database/sqlite/manage_purchased_product.dart';
import 'package:app_code/utils/monotonic_timestamp.dart';
import 'package:sqflite/sqflite.dart';

/// PurchasedProduct repository with sync support
class PurchasedProductRepositoryWithSync
  with SyncRepositoryMixin
  implements SyncRepository {
  @override
  String getEntityType() => ENTITY_TYPE_PURCHASED_PRODUCT;

  // ===== USER WRITES =====

  Future<void> add(PurchasedProduct item) async {
    item.createdAt = DateTime.now();
    item.lastModified = item.createdAt;
    item.isDeleted = false;

    await ManagePurchasedProduct.addPurchasedProduct(item);

    await appendUpsertToSyncBox(
      item.id,
      getEntityType(),
      item.lastModified!,
    );
  }

  Future<void> update(PurchasedProduct item) async {
    item.lastModified = MonotonicTimestamp.generateNext(
      previousTime: item.lastModified,
    );

    await ManagePurchasedProduct.updatePurchasedProduct(item);

    await appendUpsertToSyncBox(
      item.id,
      getEntityType(),
      item.lastModified!,
    );
  }

  Future<void> deleteById(String id) async {
    final local = await ManagePurchasedProduct.getPurchasedProductById(id);
    if (local != null) {
      final db = await DatabaseHelper.database;
      final newLastModified = MonotonicTimestamp.generateNext(
        previousTime: local.lastModified,
      );

      await db.update(
        'purchased_product',
        {
          'is_deleted': 1,
          'last_modified': newLastModified.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      // Use the NEW timestamp for the sync entry
      await appendDeleteToSyncBox(
        id,
        getEntityType(),
        newLastModified,
      );
    }
  }

  /// Delete a purchased product (convenience method)
  Future<void> delete(PurchasedProduct item) async {
    await deleteById(item.id);
  }

  Future<PurchasedProduct?> getById(String id) =>
      ManagePurchasedProduct.getPurchasedProductById(id);

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
      await db.delete('purchased_product', where: 'id = ?', whereArgs: [entityId]);
      return;
    }

    await _upsertRelatedEntities(data);

    final cleanedData = _cleanFirebaseData(data);
    final exists = localData != null;

    if (exists) {
      await db.update(
        'purchased_product',
        cleanedData,
        where: 'id = ?',
        whereArgs: [entityId],
      );
    } else {
      await db.insert(
        'purchased_product',
        cleanedData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> getLocalData(String id) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'purchased_product',
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

    if (cleaned.containsKey('listId')) {
      cleaned['list_id'] = cleaned['listId'];
      cleaned.remove('listId');
    }

    if (cleaned.containsKey('productId')) {
      cleaned['product_id'] = cleaned['productId'];
      cleaned.remove('productId');
    }

    if (cleaned.containsKey('categoryId')) {
      cleaned['category_id'] = cleaned['categoryId'];
      cleaned.remove('categoryId');
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

    if (cleaned.containsKey('isDeleted')) {
      cleaned['is_deleted'] = cleaned['isDeleted'] == true ? 1 : 0;
      cleaned.remove('isDeleted');
    }

    cleaned.remove('product');
    cleaned.remove('category');

    cleaned.putIfAbsent('price', () => 0.0);
    cleaned.putIfAbsent('quantity', () => 0);
    
    // Ensure required fields have default values if missing
    if (!cleaned.containsKey('created_at') || cleaned['created_at'] == null) {
      cleaned['created_at'] = DateTime.now().toIso8601String();
    }
    if (!cleaned.containsKey('last_modified') || cleaned['last_modified'] == null) {
      cleaned['last_modified'] = DateTime.now().toIso8601String();
    }
    if (!cleaned.containsKey('is_deleted') || cleaned['is_deleted'] == null) {
      cleaned['is_deleted'] = 0;
    }

    return cleaned;
  }

  Future<void> _upsertRelatedEntities(Map<String, dynamic> data) async {
    final productData = data['product'];
    final categoryData = data['category'];

    if (productData is Map) {
      final product = _productFromData(productData);
      if (product != null) {
        final existing = await ManageProduct.getProductById(product.id);
        if (existing == null) {
          await ManageProduct.addProduct(product);
        } else {
          await ManageProduct.updateProduct(product);
        }
      }
    }

    if (categoryData is Map) {
      final category = _categoryFromData(categoryData);
      if (category != null) {
        final existing = await ManageCategory.getCategoryById(category.id);
        if (existing == null) {
          await ManageCategory.addCategory(category);
        } else {
          await ManageCategory.updateCategory(category);
        }
      }
    }
  }

  Product? _productFromData(Map<dynamic, dynamic> data) {
    final id = data['id'];
    final name = data['name'];
    if (id is! String || name is! String) return null;

    return Product(
      id: id,
      name: name,
      isVisible: data['isVisible'] ?? data['is_visible'] ?? true,
      lastModified: _parseTimestamp(data['lastModified'] ?? data['last_modified']) ??
          DateTime.now(),
      createdAt: _parseTimestamp(data['createdAt'] ?? data['created_at']) ?? DateTime.now(),
    );
  }

  Category? _categoryFromData(Map<dynamic, dynamic> data) {
    final id = data['id'];
    final name = data['name'];
    if (id is! String || name is! String) return null;

    return Category(
      id: id,
      name: name,
      lastModified: _parseTimestamp(data['lastModified'] ?? data['last_modified']) ??
          DateTime.now(),
      createdAt: _parseTimestamp(data['createdAt'] ?? data['created_at']) ?? DateTime.now(),
    );
  }
}