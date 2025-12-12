import 'package:app_code/models/product.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await getDatabasesPath();
    await deleteDatabase('$dbPath/shopping_app.db');
  });

  setUp(() async {
    final db = await DatabaseHelper.database;
    await db.delete('product');
  });

  test('adds and retrieves a product', () async {
    final product = Product(name: 'Apple');

    final inserted = await ManageProduct.addProduct(product);
    expect(inserted, greaterThan(0));

    final all = await ManageProduct.getAllProducts();
    expect(all.length, 1);
    expect(all.first.getName(), 'Apple');
  });

  test('finds product by name', () async {
    final product = Product(name: 'Bread');
    await ManageProduct.addProduct(product);

    final found = await ManageProduct.getProductByName('Bread');
    expect(found, isNotNull);
    expect(found!.id, product.id);
    expect(found.getName(), 'Bread');
  });

  test('updates an existing product', () async {
    final product = Product(name: 'Milk');
    await ManageProduct.addProduct(product);

    final updated = Product(id: product.id, name: 'Skim Milk');
    final count = await ManageProduct.updateProduct(updated);
    expect(count, 1);

    final retrieved = await ManageProduct.getProductById(product.id);
    expect(retrieved, isNotNull);
    expect(retrieved!.getName(), 'Skim Milk');
  });

  test('deletes a product', () async {
    final product = Product(name: 'Chips');
    await ManageProduct.addProduct(product);

    final deleted = await ManageProduct.deleteProduct(product.id);
    expect(deleted, 1);

    final remaining = await ManageProduct.getAllProducts();
    expect(remaining, isEmpty);
  });
}
