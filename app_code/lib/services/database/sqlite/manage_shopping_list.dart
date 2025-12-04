import 'package:app_code/models/shopping_list.dart';
import 'package:sqflite/sqflite.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';

class ManageShoppingList {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static Future<void> addShoppingList(ShoppingList list) async {
    final db = await DatabaseHelper.database;

    await db.insert(
      'shopping_list',
      list.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteShoppingList(ShoppingList list) async {
    final db = await DatabaseHelper.database;

    await db.delete(
      'shopping_list',
      where: 'id = ?',
      whereArgs: [list.id],
    );

    // delete purchased products related to list
    await db.delete(
      'purchased_product',
      where: 'list_id = ?',
      whereArgs: [list.id],
    );
  }

  static Future<void> updateShoppingList(ShoppingList list) async {
    final db = await DatabaseHelper.database;

    await db.update(
      'shopping_list',
      list.toJson(),
      where: 'id = ?',
      whereArgs: [list.id],
    );
  }

  static Future<List<ShoppingList>> getAllShoppingLists() async {
    final db = await DatabaseHelper.database;

    final List<Map<String, dynamic>> maps =
        await db.query('shopping_list');

    return maps.map((json) => ShoppingList.fromJson(json)).toList();
  }

  static Future<ShoppingList?> getShoppingListById(String id) async {
    final db = await DatabaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'shopping_list',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return ShoppingList.fromJson(maps.first);
  }
}