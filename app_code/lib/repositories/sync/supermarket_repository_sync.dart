import 'package:app_code/models/category.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/repositories/sync/sync_repository.dart';
import 'package:app_code/repositories/sync/sync_repository_mixin.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_supermarket.dart';
import 'package:app_code/utils/monotonic_timestamp.dart';
import 'package:sqflite/sqflite.dart';

/// Supermarket repository with sync support
class SupermarketRepositoryWithSync
  with SyncRepositoryMixin
  implements SyncRepository {
  @override
  String getEntityType() => ENTITY_TYPE_SUPERMARKET;

  // ===== USER WRITES =====

  Future<void> add(Supermarket market) async {
    market.createdAt = DateTime.now();
    market.lastModified = market.createdAt;

    await ManageSupermarket.addSupermarket(market);

    await appendUpsertToSyncBox(
      market.id,
      getEntityType(),
      market.lastModified!,
    );
  }

  Future<void> update(Supermarket market) async {
    market.lastModified = MonotonicTimestamp.generateNext(
      previousTime: market.lastModified,
    );

    await ManageSupermarket.updateSupermarket(market);

    await appendUpsertToSyncBox(
      market.id,
      getEntityType(),
      market.lastModified!,
    );
  }

  Future<void> deleteById(String id) async {
    final local = await ManageSupermarket.getSupermarketById(id);

    await ManageSupermarket.deleteSupermarket(id);

    await appendDeleteToSyncBox(
      id,
      getEntityType(),
      local!.lastModified!,
    );
  }

  Future<Supermarket?> getById(String id) =>
      ManageSupermarket.getSupermarketById(id);

  Future<List<Supermarket>> getAll() => ManageSupermarket.getAllSupermarkets();

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
      await db.delete(
        'supermarket_category',
        where: 'supermarket_id = ?',
        whereArgs: [entityId],
      );
      await db.delete('supermarket', where: 'id = ?', whereArgs: [entityId]);
      return;
    }

    final cleanedData = _cleanFirebaseData(data);
    final exists = localData != null;

    if (exists) {
      await db.update(
        'supermarket',
        cleanedData,
        where: 'id = ?',
        whereArgs: [entityId],
      );
    } else {
      await db.insert(
        'supermarket',
        cleanedData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await _replaceCategories(db, entityId, data['categories'], data['categoryIds']);
  }

  @override
  Future<Map<String, dynamic>?> getLocalData(String id) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'supermarket',
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

    cleaned.remove('categories');
    cleaned.remove('categoryIds');

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

  Future<void> _replaceCategories(
    Database db,
    String supermarketId,
    dynamic categoriesData,
    dynamic categoryIdsData,
  ) async {
    final categoryIds = <String>[];

    if (categoryIdsData is List) {
      for (final id in categoryIdsData) {
        if (id is String) categoryIds.add(id);
      }
    } else if (categoriesData is List) {
      for (final item in categoriesData) {
        if (item is Map) {
          final id = item['id'];
          if (id is String) categoryIds.add(id);
          await _upsertCategory(db, item);
        }
      }
    }

    await db.delete(
      'supermarket_category',
      where: 'supermarket_id = ?',
      whereArgs: [supermarketId],
    );

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

  Future<void> _upsertCategory(Database db, Map<dynamic, dynamic> rawData) async {
    final data = _cleanCategoryData(rawData);
    if (data['id'] == null || data['name'] == null) return;

    await db.insert(
      'category',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Map<String, dynamic> _cleanCategoryData(Map<dynamic, dynamic> rawData) {
    final cleaned = <String, dynamic>{};

    if (rawData['id'] != null) cleaned['id'] = rawData['id'];
    if (rawData['name'] != null) cleaned['name'] = rawData['name'];

    if (rawData.containsKey('isDefault')) {
      cleaned['is_default'] = rawData['isDefault'] == true ? 1 : 0;
    } else if (rawData.containsKey('is_default')) {
      cleaned['is_default'] = rawData['is_default'] == true ? 1 : 0;
    } else {
      cleaned['is_default'] = 0;
    }

    if (rawData.containsKey('createdAt')) {
      final parsed = _parseTimestamp(rawData['createdAt']);
      cleaned['created_at'] = parsed?.toIso8601String() ?? DateTime.now().toIso8601String();
    } else if (rawData.containsKey('created_at')) {
      final parsed = _parseTimestamp(rawData['created_at']);
      cleaned['created_at'] = parsed?.toIso8601String() ?? DateTime.now().toIso8601String();
    } else {
      cleaned['created_at'] = DateTime.now().toIso8601String();
    }

    if (rawData.containsKey('lastModified')) {
      final parsed = _parseTimestamp(rawData['lastModified']);
      cleaned['last_modified'] = parsed?.toIso8601String() ?? DateTime.now().toIso8601String();
    } else if (rawData.containsKey('last_modified')) {
      final parsed = _parseTimestamp(rawData['last_modified']);
      cleaned['last_modified'] = parsed?.toIso8601String() ?? DateTime.now().toIso8601String();
    } else {
      cleaned['last_modified'] = DateTime.now().toIso8601String();
    }

    return cleaned;
  }
}