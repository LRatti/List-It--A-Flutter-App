import 'package:sqflite/sqflite.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';

class ManageSupermarket {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create supermarket
  Future<void> addSupermarket(Supermarket market) async {
    final db = await _dbHelper.database;

    // insert supermarket
    await db.insert(
      'supermarket',
      {
        'id': market.id,
        'name': market.getName(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // insert categories and associations
    for (final cat in market.getCategories()) {
      await db.insert(
        'category',
        cat.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await db.insert(
        'supermarket_category',
        {
          'supermarket_id': market.id,
          'category_id': cat.id,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Delete supermarket
  Future<void> deleteSupermarket(String id) async {
    final db = await _dbHelper.database;

    await db.delete(
      'supermarket_category',
      where: 'supermarket_id = ?',
      whereArgs: [id],
    );

    await db.delete(
      'supermarket',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update supermarket (basic info + categories)
  Future<void> updateSupermarket(Supermarket market) async {
    final db = await _dbHelper.database;

    // update basic fields
    await db.update(
      'supermarket',
      {'name': market.getName()},
      where: 'id = ?',
      whereArgs: [market.id],
    );

    // remove old category associations
    await db.delete(
      'supermarket_category',
      where: 'supermarket_id = ?',
      whereArgs: [market.id],
    );

    // add categories and new associations
    for (final cat in market.getCategories()) {
      await db.insert(
        'category',
        cat.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await db.insert(
        'supermarket_category',
        {
          'supermarket_id': market.id,
          'category_id': cat.id,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Read supermarket + categories
  Future<Supermarket?> getSupermarketById(String id) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'supermarket',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;

    final data = result.first;

    final categories = await _getCategoriesForSupermarket(id);

    return Supermarket(
      id: data['id'] as String,
      name: data['name'] as String,
      categories: categories,
    );
  }

  // Read all supermarkets
  Future<List<Supermarket>> getAllSupermarkets() async {
    final db = await _dbHelper.database;

    final result = await db.query('supermarket');

    List<Supermarket> markets = [];

    for (final row in result) {
      final categories = await _getCategoriesForSupermarket(row['id'] as String);

      markets.add(
        Supermarket(
          id: row['id'] as String,
          name: row['name'] as String,
          categories: categories,
        ),
      );
    }

    return markets;
  }

  // Utility: load categories for supermarket
  Future<List<Category>> _getCategoriesForSupermarket(String id) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT category.*
      FROM category
      JOIN supermarket_category
        ON supermarket_category.category_id = category.id
      WHERE supermarket_category.supermarket_id = ?
    ''', [id]);

    return result.map((json) => Category.fromJson(json)).toList();
  }
}
