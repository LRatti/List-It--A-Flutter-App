import 'package:sqflite/sqflite.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';

class ManageSupermarket {
  static Future<void> addSupermarket(Supermarket market) async {
    final db = await DatabaseHelper.database;

    await db.insert('supermarket', {
      'id': market.id,
      'name': market.getName(),
      'is_visible': market.isVisible ? 1 : 0,
      'is_favorite': market.isFavorite ? 1 : 0,
      'created_at': market.createdAt.toIso8601String(),
      'last_modified': market.lastModified?.toIso8601String() ?? DateTime.now().toIso8601String(),
    });

    final categories = market.getCategories();
    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      await db.insert('category', cat.toDatabase(),
          conflictAlgorithm: ConflictAlgorithm.replace);

      await db.insert('supermarket_category', {
        'supermarket_id': market.id,
        'category_id': cat.id,
        'order_index': i,
      },
      conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  static Future<List<Supermarket>> getAllSupermarkets() async {
    final db = await DatabaseHelper.database;
    final rows = await db.query('supermarket');

    List<Supermarket> result = [];

    for (final row in rows) {
      final categories = await db.rawQuery('''
        SELECT c.*
        FROM category c
        JOIN supermarket_category sc ON sc.category_id = c.id
        WHERE sc.supermarket_id = ?
        ORDER BY sc.order_index ASC
      ''', [row['id']]);

      result.add(Supermarket(
        id: row['id'] as String,
        name: row['name'] as String,
        isVisible: row['is_visible'] == 1,
        isFavorite: row['is_favorite'] == 1,
        lastModified: DateTime.tryParse(row['last_modified'] as String? ?? '') ?? DateTime.now(),
        createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
        categories: categories.map(Category.fromDatabase).toList(),
      ));
    }

    return result;
  }

  static Future<Supermarket?> getSupermarketByName(String name) async {
    final db = await DatabaseHelper.database;

    final rows =
        await db.query('supermarket', where: 'name = ?', whereArgs: [name]);
    if (rows.isEmpty) return null;

    return getSupermarketById(rows.first['id'] as String);
  }

  static Future<void> updateSupermarket(Supermarket market) async {
    final db = await DatabaseHelper.database;

    await db.update(
      'supermarket',
      {
        'name': market.getName(),
        'is_visible': market.isVisible ? 1 : 0,
        'is_favorite': market.isFavorite ? 1 : 0,
        'last_modified': market.lastModified?.toIso8601String() ?? DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [market.id],
    );

    await db.delete(
      'supermarket_category',
      where: 'supermarket_id = ?',
      whereArgs: [market.id],
    );

    final categories = market.getCategories();
    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      await db.insert('category', cat.toDatabase(),
          conflictAlgorithm: ConflictAlgorithm.ignore);

      await db.insert('supermarket_category', {
        'supermarket_id': market.id,
        'category_id': cat.id,
        'order_index': i,
      });
    }
  }

  static Future<void> deleteSupermarket(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete('supermarket_category',
        where: 'supermarket_id = ?', whereArgs: [id]);
    await db.delete('supermarket', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Supermarket?> getSupermarketById(String id) async {
    final db = await DatabaseHelper.database;

    final rows =
        await db.query('supermarket', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;

    final categories = await db.rawQuery('''
      SELECT c.*
      FROM category c
      JOIN supermarket_category sc ON sc.category_id = c.id
      WHERE sc.supermarket_id = ?
      ORDER BY sc.order_index ASC
    ''', [id]);

    return Supermarket(
      id: rows.first['id'] as String,
      name: rows.first['name'] as String,
      lastModified: DateTime.tryParse(rows.first['last_modified'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(rows.first['created_at'] as String? ?? '') ?? DateTime.now(),
      isVisible: rows.first['is_visible'] == 1,
      isFavorite: rows.first['is_favorite'] == 1,
      categories: categories.map(Category.fromDatabase).toList(),
    );
  }

  static Future<void> replaceCategoriesOrder(
    String supermarketId,
    List<Category> categories,
  ) async {
    final db = await DatabaseHelper.database;

    await db.transaction((txn) async {
      // Remove all existing category relations for the supermarket
      await txn.delete(
        'supermarket_category',
        where: 'supermarket_id = ?',
        whereArgs: [supermarketId],
      );

      // Reinsert categories with the new order
      for (int i = 0; i < categories.length; i++) {
        final category = categories[i];

        // Ensure category exists
        await txn.insert(
          'category',
          category.toDatabase(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        await txn.insert(
          'supermarket_category',
          {
            'supermarket_id': supermarketId,
            'category_id': category.id,
            'order_index': i,
          },
        );
      }
    });
  }



  /// Gets all categories of a supermarket ordered by position
  static Future<List<Category>> getSupermarketCategories(String supermarketId) async {
    final db = await DatabaseHelper.database;

    final categories = await db.rawQuery('''
      SELECT c.*
      FROM category c
      JOIN supermarket_category sc ON sc.category_id = c.id
      WHERE sc.supermarket_id = ?
      ORDER BY sc.order_index ASC
    ''', [supermarketId]);

    return categories.map(Category.fromDatabase).toList();
  }

  /// Adds a category to a supermarket at a specific position
  static Future<void> addCategoryToSupermarket(
    String supermarketId,
    Category category,
    int orderIndex,
  ) async {
    final db = await DatabaseHelper.database;

    // Insert or replace the category
    await db.insert('category', category.toDatabase(),
        conflictAlgorithm: ConflictAlgorithm.replace);

    // Insert the association with the order index
    await db.insert('supermarket_category', {
      'supermarket_id': supermarketId,
      'category_id': category.id,
      'order_index': orderIndex,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Reorders categories of a supermarket
  /// categoryOrderMap is a Map<categoryId, newOrderIndex>
  static Future<void> reorderCategories(
    String supermarketId,
    Map<String, int> categoryOrderMap,
  ) async {
    final db = await DatabaseHelper.database;

    for (final entry in categoryOrderMap.entries) {
      await db.update(
        'supermarket_category',
        {'order_index': entry.value},
        where: 'supermarket_id = ? AND category_id = ?',
        whereArgs: [supermarketId, entry.key],
      );
    }
  }

  /// Set a supermarket as favorite (unset any previous favorite)
  static Future<void> setFavoriteSupermarket(String supermarketId) async {
    final db = await DatabaseHelper.database;

    await db.transaction((txn) async {
      // Clear favorite from all supermarkets
      await txn.update(
        'supermarket',
        {'is_favorite': 0},
        where: 'is_favorite = ?',
        whereArgs: [1],
      );

      // Set the new favorite
      await txn.update(
        'supermarket',
        {'is_favorite': 1},
        where: 'id = ?',
        whereArgs: [supermarketId],
      );
    });
  }

  /// Clear favorite status from a specific supermarket
  static Future<void> clearFavoriteSupermarket(String supermarketId) async {
    final db = await DatabaseHelper.database;

    await db.update(
      'supermarket',
      {'is_favorite': 0},
      where: 'id = ?',
      whereArgs: [supermarketId],
    );
  }

  /// Get the current favorite supermarket
  static Future<Supermarket?> getFavoriteSupermarket() async {
    final db = await DatabaseHelper.database;

    final rows = await db.query(
      'supermarket',
      where: 'is_favorite = ?',
      whereArgs: [1],
    );

    if (rows.isEmpty) return null;

    final id = rows.first['id'] as String;
    return getSupermarketById(id);
  }
}
