import 'package:sqflite/sqflite.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';

class ManageProduct {
  static Future<void> addProduct(Product product) async {
    final db = await DatabaseHelper.database;

    // Inserisci il prodotto nella tabella principale
    await db.insert(
      'product', 
      product.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace);

    // Inserisci le categorie nella tabella product_category
    for (final catId in product.categoryIds) {
      await db.insert(
        'product_category',
        {
          'product_id': product.id,
          'category_id': catId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<void> updateProduct(Product product) async {
    final db = await DatabaseHelper.database;

    await db.update(
      'product',
      product.toDatabase(),
      where: 'id = ?',
      whereArgs: [product.id],
    );

    // Aggiorna le categorie
    await db.delete(
      'product_category',
      where: 'product_id = ?',
      whereArgs: [product.id],
    );

    for (final catId in product.categoryIds) {
      await db.insert(
        'product_category',
        {
          'product_id': product.id,
          'category_id': catId,
        },
      );
    }
  }

  static Future<void> deleteProduct(String id) async {
    final db = await DatabaseHelper.database;
    await db.delete('product_category', where: 'product_id = ?', whereArgs: [id]);
    await db.delete('product', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Product?> getProductById(String id) async {
    final db = await DatabaseHelper.database;

    final productRows = await db.query('product', where: 'id = ?', whereArgs: [id]);
    if (productRows.isEmpty) return null;

    final categoryRows = await db.query(
      'product_category',
      where: 'product_id = ?',
      whereArgs: [id],
    );
    final categoryIds = categoryRows.map((e) => e['category_id'] as String).toList();

    // Passa le categorie come parametro a fromDatabase
    return Product.fromDatabase(productRows.first, categoryIds: categoryIds);
  }

  static Future<List<Product>> getAllProducts() async {
    final db = await DatabaseHelper.database;
    final productRows = await db.query('product');

    List<Product> result = [];

    for (final row in productRows) {
      final categoryRows = await db.query(
        'product_category',
        where: 'product_id = ?',
        whereArgs: [row['id']],
      );
      final categoryIds = categoryRows.map((e) => e['category_id'] as String).toList();

      final product = Product.fromDatabase(row, categoryIds: categoryIds);
      result.add(product);
    }

    return result;
  }

  static Future<Product?> getProductByName(String name) async {
    final db = await DatabaseHelper.database;

    final rows = await db.query('product', where: 'name = ?', whereArgs: [name]);
    if (rows.isEmpty) return null;

    final productId = rows.first['id'] as String;
    final categoryRows = await db.query(
      'product_category',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    final categoryIds = categoryRows.map((e) => e['category_id'] as String).toList();

    return Product.fromDatabase(rows.first, categoryIds: categoryIds);
  }
}
