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
      'created_at': market.createdAt.toIso8601String(),
      'last_modified': market.lastModified?.toIso8601String() ?? DateTime.now().toIso8601String(),
    });

    for (final cat in market.getCategories()) {
      await db.insert('category', cat.toDatabase(),
          conflictAlgorithm: ConflictAlgorithm.replace);

      await db.insert('supermarket_category', {
        'supermarket_id': market.id,
        'category_id': cat.id,
        
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
      ''', [row['id']]);

      result.add(Supermarket(
        id: row['id'] as String,
        name: row['name'] as String,
        isVisible: row['is_visible'] == 1,
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

    for (final cat in market.getCategories()) {
      await db.insert('category', cat.toDatabase(),
          conflictAlgorithm: ConflictAlgorithm.ignore);

      await db.insert('supermarket_category', {
        'supermarket_id': market.id,
        'category_id': cat.id,
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
    ''', [id]);

    return Supermarket(
      id: rows.first['id'] as String,
      name: rows.first['name'] as String,
      lastModified: DateTime.tryParse(rows.first['last_modified'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(rows.first['created_at'] as String? ?? '') ?? DateTime.now(),
      isVisible: rows.first['is_visible'] == 1,
      categories: categories.map(Category.fromDatabase).toList(),
    );
  }
}
