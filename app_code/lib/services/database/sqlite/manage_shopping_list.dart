import 'package:app_code/models/shopping_list.dart';
import 'package:sqflite/sqflite.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';

class ManageShoppingList {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> addShoppingList(ShoppingList list) async {
    final db = await _dbHelper.database;

    await db.insert(
      'shopping_list',
      list.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteShoppingList(ShoppingList list) async {
    final db = await _dbHelper.database;

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

  Future<void> updateShoppingList(ShoppingList list) async {
    final db = await _dbHelper.database;

    await db.update(
      'shopping_list',
      list.toJson(),
      where: 'id = ?',
      whereArgs: [list.id],
    );
  }

  Future<List<ShoppingList>> getAllShoppingLists() async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps =
        await db.query('shopping_list');

    return maps.map((json) => ShoppingList.fromJson(json)).toList();
  }

  Future<ShoppingList?> getShoppingListById(String id) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'shopping_list',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return ShoppingList.fromJson(maps.first);
  }
}