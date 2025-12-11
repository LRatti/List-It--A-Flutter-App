import 'package:app_code/models/shopping_list.dart';
import 'package:sqflite/sqflite.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_purchased_product.dart';
import 'package:app_code/services/database/sqlite/manage_supermarket.dart';

class ManageShoppingList {
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
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<ShoppingList>> getAllShoppingLists() async {
    final db = await DatabaseHelper.database;

    final List<Map<String, dynamic>> maps =
        await db.query('shopping_list');

    final lists = await Future.wait(
      maps.map(_hydrateShoppingListFromRow),
    );

    return lists;
  }

  static Future<ShoppingList?> getShoppingListById(String id) async {
    final db = await DatabaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'shopping_list',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return _hydrateShoppingListFromRow(maps.first);
  }

  static Future<ShoppingList> _hydrateShoppingListFromRow(
    Map<String, dynamic> row,
  ) async {
    final supermarketId = row['supermarket'] as String?;
    final supermarket = supermarketId != null
        ? await ManageSupermarket.getSupermarketById(supermarketId)
        : null;

    final products = await ManagePurchasedProduct
        .getPurchasedProductsByList(row['id'] as String);

    final list = ShoppingList.fromJson(row);

    if (supermarket != null) {
      list.setSupermarket(supermarket);
    }

    if (products.isNotEmpty){
      list.setPurchasedProducts(products);
    }

    return list;
  }
}