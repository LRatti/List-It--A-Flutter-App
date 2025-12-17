import 'package:sqflite/sqflite.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';

class ManageCategory {
  static Future<void> addCategory(Category category) async {
    final db = await DatabaseHelper.database;
    await db.insert(
      'category', 
      category.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteCategory(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete('category', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updateCategory(Category category) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'category',
      category.toDatabase(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  static Future<List<Category>> getAllCategories() async {
    final db = await DatabaseHelper.database;
    final result = await db.query('category');
    return result.map(Category.fromDatabase).toList();
  }

  static Future<Category?> getCategoryById(String id) async {
    final db = await DatabaseHelper.database;
    final result =
        await db.query('category', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Category.fromDatabase(result.first);
  }

  static Future<Category?> getCategoryByName(String name) async {
    final db = await DatabaseHelper.database;
    final result =
        await db.query('category', where: 'name = ?', whereArgs: [name]);
    if (result.isEmpty) return null;
    return Category.fromDatabase(result.first);
  }
}
