import 'package:sqflite/sqflite.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_product.dart';
import 'package:app_code/services/database/sqlite/manage_category.dart';

class ManagePurchasedProduct {
  static Future<void> addPurchasedProduct(PurchasedProduct item) async {
  final db = await DatabaseHelper.database;

  await ManageProduct.addProduct(item.product);
  await ManageCategory.addCategory(item.category);

  await db.insert(
    'purchased_product',
    item.toDatabase(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

  static Future<List<PurchasedProduct>> getPurchasedProductsByList(
      String listId) async {
    final db = await DatabaseHelper.database;

    final rows = await db.rawQuery('''
      SELECT pp.*, p.id AS p_id, p.name AS p_name, p.is_visible AS p_visible, 
             c.id AS c_id, c.name AS c_name
      FROM purchased_product pp
      JOIN product p ON p.id = pp.product_id
      JOIN category c ON c.id = pp.category_id
      WHERE pp.list_id = ?
    ''', [listId]);

    return rows.map((row) {
      final product = Product.fromDatabase(
        {'id': row['p_id'], 'name': row['p_name'], 'is_visible': row['p_visible']},
        associations: {}, // o passare categorie se vuoi caricarle
      );
      final category = Category.fromDatabase({'id': row['c_id'], 'name': row['c_name']});
      return PurchasedProduct.fromDatabase(row, category, product);
    }).toList();
  }

  static Future<PurchasedProduct?> getPurchasedProductById(String id) async {
    final db = await DatabaseHelper.database;

    final rows = await db.rawQuery('''
      SELECT pp.*, p.id AS p_id, p.name AS p_name, p.is_visible AS p_visible, 
             c.id AS c_id, c.name AS c_name
      FROM purchased_product pp
      JOIN product p ON p.id = pp.product_id
      JOIN category c ON c.id = pp.category_id
      WHERE pp.id = ?
    ''', [id]);

    if (rows.isEmpty) return null;

    final row = rows.first;
    final product = Product.fromDatabase(
      {'id': row['p_id'], 'name': row['p_name'], 'is_visible': row['p_visible']},
      associations: {},
    );
    final category = Category.fromDatabase({'id': row['c_id'], 'name': row['c_name']});
    return PurchasedProduct.fromDatabase(row, category, product);
  }

  static Future<void> deletePurchasedProduct(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete('purchased_product', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updatePurchasedProduct(PurchasedProduct item) async {
    final db = await DatabaseHelper.database;

    await ManageProduct.updateProduct(item.product);
    await ManageCategory.updateCategory(item.category);

    await db.update(
      'purchased_product',
      item.toDatabase(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  static Future<PurchasedProduct?> getPurchasedProductByName(
      String listId, String productName) async {
    final db = await DatabaseHelper.database;

    final rows = await db.rawQuery('''
      SELECT pp.*, p.id AS p_id, p.name AS p_name, p.is_visible AS p_visible, 
             c.id AS c_id, c.name AS c_name
      FROM purchased_product pp
      JOIN product p ON p.id = pp.product_id
      JOIN category c ON c.id = pp.category_id
      WHERE pp.list_id = ? AND p.name = ?
    ''', [listId, productName]);

    if (rows.isEmpty) return null;

    final row = rows.first;
    final product = Product.fromDatabase(
      {'id': row['p_id'], 'name': row['p_name'], 'is_visible': row['p_visible']},
      associations: {},
    );
    final category = Category.fromDatabase({'id': row['c_id'], 'name': row['c_name']});
    return PurchasedProduct.fromDatabase(row, category, product);
  }
}
