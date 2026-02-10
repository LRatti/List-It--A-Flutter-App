import 'package:sqflite/sqflite.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_purchased_product.dart';
import 'package:app_code/services/database/sqlite/manage_supermarket.dart';

/// Manages CRUD operations for ShoppingList entities in the SQLite database.
class ManageShoppingList {
  static Future<void> addShoppingList(ShoppingList list) async {
    final db = await DatabaseHelper.database;
    await db.insert(
      'shopping_list', 
      list.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace);

    // Add products linked to this list, if any
    final products = list.getProducts();
    if (products.isNotEmpty) {
      for (final item in products) {
        await ManagePurchasedProduct.addPurchasedProduct(item);
      }
    }
  }

  static Future<ShoppingList?> getShoppingListById(String id) async {
    final db = await DatabaseHelper.database;

    final rows =
        await db.query('shopping_list', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;

    final list = ShoppingList.fromDatabase(rows.first);

    final supermarketId = rows.first['supermarket_id'] as String?;
    if (supermarketId != null) {
      final supermarket = await ManageSupermarket.getSupermarketById(supermarketId);
      if (supermarket != null) list.setSupermarket(supermarket);
    }

    final products =
        await ManagePurchasedProduct.getPurchasedProductsByList(id);
    list.setPurchasedProducts(products);

    return list;
  }

  static Future<List<ShoppingList>> getAllShoppingLists() async {
    final db = await DatabaseHelper.database;
    final rows = await db.query('shopping_list');

    List<ShoppingList> result = [];

    for (final row in rows) {
      final list = ShoppingList.fromDatabase(row);

      final supermarketId = row['supermarket_id'] as String?;
      if (supermarketId != null) {
        final supermarket = await ManageSupermarket.getSupermarketById(supermarketId);
        if (supermarket != null) list.setSupermarket(supermarket);
      }

      final products =
          await ManagePurchasedProduct.getPurchasedProductsByList(list.id);
      list.setPurchasedProducts(products);

      result.add(list);
    }

    return result;
  }

  static Future<void> deleteShoppingList(ShoppingList list) async {
    final db = await DatabaseHelper.database;

    await db.delete(
      'purchased_product',
      where: 'list_id = ?',
      whereArgs: [list.id],
    );

    await db.delete(
      'shopping_list',
      where: 'id = ?',
      whereArgs: [list.id],
    );
  }

  static Future<void> updateShoppingList(ShoppingList list) async {
    final db = await DatabaseHelper.database;

    await db.update(
      'shopping_list',
      list.toDatabase(),
      where: 'id = ?',
      whereArgs: [list.id],
    );

    // Sync products for this list: update existing and add new
    final products = list.getProducts();
    if (products.isNotEmpty) {
      final existing = await ManagePurchasedProduct.getPurchasedProductsByList(list.id);
      final existingIds = existing.map((pp) => pp.id).toSet();

      for (final item in products) {
        if (existingIds.contains(item.id)) {
          await ManagePurchasedProduct.updatePurchasedProduct(item);
        } else {
          await ManagePurchasedProduct.addPurchasedProduct(item);
        }
      }
    }
  }
}
