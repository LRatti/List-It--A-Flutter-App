import 'package:sqflite/sqflite.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';

class ManageProduct {
  static Future<void> addProduct(Product product) async {
  final db = await DatabaseHelper.database;

  await db.insert(
    'product',
    product.toDatabase(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  for (final entry in product.associations.entries) {
    final supermarketId = entry.key;
    final categoryId = entry.value;

    if (supermarketId.isEmpty || categoryId.isEmpty) {
      throw Exception(
        'Invalid association for product ${product.id}: '
        'supermarketId=$supermarketId, categoryId=$categoryId',
      );
    }

    await db.insert(
      'associations',
      {
        'product_id': product.id,
        'supermarket_id': supermarketId,
        'category_id': categoryId,
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

    // Remove old associations
    await db.delete(
      'associations',
      where: 'product_id = ?',
      whereArgs: [product.id],
    );

    // Insert new associations (product + supermarket + category)
    for (final entry in product.associations.entries) {
      final supermarketId = entry.key;
      final categoryId = entry.value;

      if (supermarketId.isEmpty || categoryId.isEmpty) {
        throw Exception(
          'Invalid association for product ${product.id}',
        );
      }

      await db.insert(
        'associations',
        {
          'product_id': product.id,
          'supermarket_id': supermarketId,
          'category_id': categoryId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<void> deleteProduct(String id) async {
  final db = await DatabaseHelper.database;

  await db.delete(
    'associations',
    where: 'product_id = ?',
    whereArgs: [id],
  );

  await db.delete(
    'product',
    where: 'id = ?',
    whereArgs: [id],
  );
}

  static Future<Product?> getProductById(String id) async {
    final db = await DatabaseHelper.database;

    final productRows = await db.query('product', where: 'id = ?', whereArgs: [id]);
    if (productRows.isEmpty) return null;

    final categoryRows = await db.query(
      'associations',
      where: 'product_id = ?',
      whereArgs: [id],
    );
    final categoryIds = categoryRows.map((e) => e['category_id'] as String).toList();

    return Product.fromDatabase(productRows.first, categoryIds: categoryIds);
  }

  static Future<List<Product>> getAllProducts() async {
    final db = await DatabaseHelper.database;
    final productRows = await db.query('product');

    List<Product> result = [];

    for (final row in productRows) {
      final categoryRows = await db.query(
        'associations',
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
      'associations',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    final categoryIds = categoryRows.map((e) => e['category_id'] as String).toList();

    return Product.fromDatabase(rows.first, categoryIds: categoryIds);
  }
}
