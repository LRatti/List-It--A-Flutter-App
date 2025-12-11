
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/models/category.dart';
import 'package:sqflite/sqflite.dart';

class ManageCategory {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create
  static Future<int> addCategory(Category category) async {
    final db = await DatabaseHelper.database;
    return await db.insert(
      'category',
      category.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  // Delete
  static Future<int> deleteCategory(String categoryId) async {
    final db = await DatabaseHelper.database;
    return await db.delete(
      'category',
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  // Update
  static Future<int> updateCategory(Category category) async {
    final db = await DatabaseHelper.database;
    return await db.update(
      'category',
      category.toJson(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // Read all
  static Future<List<Category>> getAllCategories() async {
    final db = await DatabaseHelper.database;
    final result = await db.query('category');

    return result.map((row) => Category.fromJson(row)).toList();
  }
}