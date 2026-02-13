import 'package:app_code/models/category.dart';
import 'package:app_code/repositories/abstract/category_repository.dart';
import 'package:app_code/repositories/sync/sync_repository.dart';
import 'package:app_code/repositories/sync/sync_repository_mixin.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_category.dart';
import 'package:app_code/utils/monotonic_timestamp.dart';
import 'package:sqflite/sqflite.dart';

/// Category repository with sync support
class CategoryRepositoryWithSync 
  with SyncRepositoryMixin
  implements SyncRepository, CategoryRepository {
  @override
  String getEntityType() => ENTITY_TYPE_CATEGORY;

  // ===== USER WRITES =====

  Future<void> add(Category category) async {
    category.createdAt = DateTime.now();
    category.lastModified = category.createdAt;
    // bool isPresent = await ManageCategory.getCategoryByName(category.getName()) != null;

    // if (isPresent) {
    //   return;
    // }

    await ManageCategory.addCategory(category);


    await appendUpsertToSyncBox(
      category.id,
      getEntityType(),
      category.lastModified!,
    );
  }

  Future<void> update(Category category) async {
    category.lastModified = MonotonicTimestamp.generateNext(
      previousTime: category.lastModified,
    );

    await ManageCategory.updateCategory(category);

    await appendUpsertToSyncBox(
      category.id,
      getEntityType(),
      category.lastModified!,
    );
  }

  Future<void> deleteById(String id) async {
    final local = await ManageCategory.getCategoryById(id);

    await ManageCategory.deleteCategory(id);

    final db = await DatabaseHelper.database;
    await db.delete(
      'supermarket_category',
      where: 'category_id = ?',
      whereArgs: [id],
    );

    await appendDeleteToSyncBox(
      id,
      getEntityType(),
      local!.lastModified!,
    );
  }

  Future<Category?> getById(String id) => ManageCategory.getCategoryById(id);

  Future<List<Category>> getAll() => ManageCategory.getAllCategories();

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
        where: 'category_id = ?',
        whereArgs: [entityId],
      );
      await db.delete('category', where: 'id = ?', whereArgs: [entityId]);
      return;
    }

    final cleanedData = _cleanFirebaseData(data);
    final exists = localData != null;

    if (exists) {
      await db.update(
        'category',
        cleanedData,
        where: 'id = ?',
        whereArgs: [entityId],
      );
    } else {
      await db.insert(
        'category',
        cleanedData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> getLocalData(String id) async {
    final db = await DatabaseHelper.database;
    final rows = await db.query(
      'category',
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

    if (cleaned.containsKey('isDefault')) {
      cleaned['is_default'] = cleaned['isDefault'] == true ? 1 : 0;
      cleaned.remove('isDefault');
    }

    if (cleaned.containsKey('isVisible')) {
      cleaned['is_visible'] = cleaned['isVisible'] == true ? 1 : 0;
      cleaned.remove('isVisible');
    } else if (cleaned.containsKey('is_visible')) {
      final value = cleaned['is_visible'];
      cleaned['is_visible'] = value == true || value == 1 ? 1 : 0;
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
    if (!cleaned.containsKey('is_visible') || cleaned['is_visible'] == null) {
      cleaned['is_visible'] = 1;
    }
    if (!cleaned.containsKey('created_at') || cleaned['created_at'] == null) {
      cleaned['created_at'] = DateTime.now().toIso8601String();
    }
    if (!cleaned.containsKey('last_modified') || cleaned['last_modified'] == null) {
      cleaned['last_modified'] = DateTime.now().toIso8601String();
    }

    return cleaned;
  }
}