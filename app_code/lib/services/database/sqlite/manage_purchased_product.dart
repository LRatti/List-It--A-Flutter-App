import 'package:sqflite/sqflite.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/models/product.dart';

class ManagePurchasedProduct {
  // Create
  static Future<int> addPurchasedProduct(PurchasedProduct purchasedProduct) async {
    final db = await DatabaseHelper.database;

    return await db.insert(
      'purchased_product',
      purchasedProduct.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Delete
  static Future<int> deletePurchasedProduct(String purchasedProductId) async {
    final db = await DatabaseHelper.database;

    return await db.delete(
      'purchased_product',
      where: 'id = ?',
      whereArgs: [purchasedProductId],
    );
  }

  // Update
  static Future<int> updatePurchasedProduct(PurchasedProduct purchasedProduct) async {
    final db = await DatabaseHelper.database;

    return await db.update(
      'purchased_product',
      purchasedProduct.toJson(),
      where: 'id = ?',
      whereArgs: [purchasedProduct.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Read all
  static Future<List<PurchasedProduct>> getAllPurchasedProducts() async {
    final db = await DatabaseHelper.database;

    final results = await db.rawQuery('''
      SELECT pp.*, p.name, p.category_id
      FROM purchased_product pp
      JOIN product p ON pp.product_id = p.id
    ''');

    return results.map((row) {
      final product = Product(
        id: row['product_id'] as String,
        name: row['name'],
        categoryId: row['category_id'] as int?,
      );

      return PurchasedProduct(
        id: row['id'] as String,
        listId: row['list_id'] as String,
        price: row['price'] as double,
        quantity: row['quantity'] as int,
        product: product,
      );
    }).toList();
  }

  // Read all purchased products in a specific list
  static Future<List<PurchasedProduct>> getPurchasedProductsByList(String listId) async {
    final db = await DatabaseHelper.database;
    final results = await db.rawQuery('''
      SELECT pp.*, p.name, p.category_id
      FROM purchased_product pp
      JOIN product p ON pp.product_id = p.id
      WHERE pp.list_id = ?
    ''', [listId]);

    return results.map((row) {
      final product = Product(
        id: row['product_id'] as String,
        name: row['name'],
        categoryId: row['category_id'] as int?,
      );

      return PurchasedProduct(
        id: row['id'] as String,
        listId: row['list_id'] as String,
        price: row['price'] as double,
        quantity: row['quantity'] as int,
        product: product,
      );
    }).toList();
  }

  // Read one by ID
  static Future<PurchasedProduct?> getPurchasedProductById(String id) async {
    final db = await DatabaseHelper.database;

    final result = await db.rawQuery('''
      SELECT pp.*, p.name, p.category_id
      FROM purchased_product pp
      JOIN product p ON pp.product_id = p.id
      WHERE pp.id = ?
    ''', [id]);

    if (result.isEmpty) return null;

    final row = result.first;

    final product = Product(
      id: row['product_id'] as String,
      name: row['name'],
      categoryId: row['category_id'] as int?,
    );

    return PurchasedProduct(
      id: row['id'] as String,
      listId: row['list_id'] as String,
      price: row['price'] as double,
      quantity: row['quantity'] as int,
      product: product,
    );
  }

  // Read by list ID and product name
  static Future<PurchasedProduct?> getPurchasedProductByName(
    String listId,
    String productName,
  ) async {
    final db = await DatabaseHelper.database;

    final result = await db.rawQuery('''
      SELECT pp.*, p.name, p.category_id
      FROM purchased_product pp
      JOIN product p ON pp.product_id = p.id
      WHERE pp.list_id = ? AND p.name = ?
    ''', [listId, productName]);

    if (result.isEmpty) return null;

    final row = result.first;

    final product = Product(
      id: row['product_id'] as String,
      name: row['name'],
      categoryId: row['category_id'] as int?,
    );

    return PurchasedProduct(
      id: row['id'] as String,
      listId: row['list_id'] as String,
      price: row['price'] as double,
      quantity: row['quantity'] as int,
      product: product,
    );
  }
}
