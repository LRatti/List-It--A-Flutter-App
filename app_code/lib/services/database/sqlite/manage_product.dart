import 'package:sqflite/sqflite.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';

class ManageProduct {
  // Create
  static Future<int> addProduct(Product product) async {
    final db = await DatabaseHelper.database;
    return await db.insert(
      'product',
      product.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Delete
  static Future<int> deleteProduct(String productId) async {
    final db = await DatabaseHelper.database;
    return await db.delete(
      'product',
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // Update
  static Future<int> updateProduct(Product product) async {
    final db = await DatabaseHelper.database;
    return await db.update(
      'product',
      product.toJson(),
      where: 'id = ?',
      whereArgs: [product.id],
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  // Read all
  static Future<List<Product>> getAllProducts() async {
    final db = await DatabaseHelper.database;
    final result = await db.query('product');
    return result.map((row) => Product.fromJson(row)).toList();
  }

  // Read by ID
  static Future<Product?> getProductById(String id) async {
    final db = await DatabaseHelper.database;
    final result = await db.query(
      'product',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    return Product.fromJson(result.first);
  }

  // Read by name
  static Future<Product?> getProductByName(String name) async {
    final db = await DatabaseHelper.database;
    final result = await db.query(
      'product',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (result.isEmpty) return null;
    return Product.fromJson(result.first);
  }
}
