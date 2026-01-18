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

  test('finds product by name', () async {
    final product = Product(name: 'Bread');
    await ManageProduct.addProduct(product);

    final found = await ManageProduct.getProductByName('Bread');
    expect(found, isNotNull);
    expect(found!.id, product.id);
    expect(found.getName(), 'Bread');
  });

  test('adds and retrieves a product', () async {
  final product = Product(name: 'Apple');

  await ManageProduct.addProduct(product);

  final all = await ManageProduct.getAllProducts();
  expect(all.length, 1);
  expect(all.first.getName(), 'Apple');
});

  test('updates an existing product', () async {
    final product = Product(name: 'Milk');
    await ManageProduct.addProduct(product);

    final updated = Product(id: product.id, name: 'Skim Milk');
    await ManageProduct.updateProduct(updated);

    final retrieved = await ManageProduct.getProductById(product.id);
    expect(retrieved, isNotNull);
    expect(retrieved!.getName(), 'Skim Milk');
  });

  test('deletes a product', () async {
    final product = Product(name: 'Chips');
    await ManageProduct.addProduct(product);

    await ManageProduct.deleteProduct(product.id);

    final remaining = await ManageProduct.getAllProducts();
    expect(remaining, isEmpty);
  });

  test('handles associations correctly', () async {
    final product = Product(
      name: 'Orange Juice',
      associations: {'supermarket1': 'category1'},
    );
    await ManageProduct.addProduct(product);

    final retrieved = await ManageProduct.getProductById(product.id);
    expect(retrieved, isNotNull);
    expect(retrieved!.associations.length, 1);
    expect(retrieved.associations['supermarket1'], 'category1');
  });

  test('returns null when product by id does not exist', () async {
    final result = await ManageProduct.getProductById('nonexistent-id');
    expect(result, isNull);
  });

  test('returns null when product by name does not exist', () async {
    final result = await ManageProduct.getProductByName('NonexistentProduct');
    expect(result, isNull);
  });

  test('handles product with multiple associations', () async {
    final product = Product(
      name: 'Multi Product',
      associations: {
        'supermarket1': 'category1',
        'supermarket2': 'category2',
        'supermarket3': 'category3',
      },
    );
    await ManageProduct.addProduct(product);

    final retrieved = await ManageProduct.getProductById(product.id);
    expect(retrieved, isNotNull);
    expect(retrieved!.associations.length, 3);
    expect(retrieved.associations['supermarket1'], 'category1');
    expect(retrieved.associations['supermarket2'], 'category2');
    expect(retrieved.associations['supermarket3'], 'category3');
  });

  test('handles product with no associations', () async {
    final product = Product(name: 'Simple Product');
    await ManageProduct.addProduct(product);

    final retrieved = await ManageProduct.getProductById(product.id);
    expect(retrieved, isNotNull);
    expect(retrieved!.associations, isEmpty);
  });

  test('updates product associations correctly', () async {
    final product = Product(
      name: 'Coffee',
      associations: {'super1': 'cat1'},
    );
    await ManageProduct.addProduct(product);

    final updated = Product(
      id: product.id,
      name: 'Coffee',
      associations: {'super2': 'cat2', 'super3': 'cat3'},
    );
    await ManageProduct.updateProduct(updated);

    final retrieved = await ManageProduct.getProductById(product.id);
    expect(retrieved, isNotNull);
    expect(retrieved!.associations.length, 2);
    expect(retrieved.associations['super2'], 'cat2');
    expect(retrieved.associations['super3'], 'cat3');
    expect(retrieved.associations.containsKey('super1'), false);
  });

  test('handles updating product removing all associations', () async {
    final product = Product(
      name: 'Tea',
      associations: {'super1': 'cat1', 'super2': 'cat2'},
    );
    await ManageProduct.addProduct(product);

    final updated = Product(
      id: product.id,
      name: 'Tea',
      associations: {},
    );
    await ManageProduct.updateProduct(updated);

    final retrieved = await ManageProduct.getProductById(product.id);
    expect(retrieved, isNotNull);
    expect(retrieved!.associations, isEmpty);
  });

  test('throws exception when adding invalid association with empty supermarket id', () async {
    final product = Product(
      name: 'Invalid Product',
      associations: {'': 'category1'},
    );

    expect(
      () => ManageProduct.addProduct(product),
      throwsException,
    );
  });

  test('throws exception when adding invalid association with empty category id', () async {
    final product = Product(
      name: 'Invalid Product',
      associations: {'supermarket1': ''},
    );

    expect(
      () => ManageProduct.addProduct(product),
      throwsException,
    );
  });

  test('throws exception when updating with invalid association', () async {
    final product = Product(name: 'Valid Product');
    await ManageProduct.addProduct(product);

    final updated = Product(
      id: product.id,
      name: 'Valid Product',
      associations: {'': 'category1'},
    );

    expect(
      () => ManageProduct.updateProduct(updated),
      throwsException,
    );
  });

  test('handles product visibility flag', () async {
    final product = Product(name: 'Visible Product', isVisible: true);
    await ManageProduct.addProduct(product);

    final retrieved = await ManageProduct.getProductById(product.id);
    expect(retrieved, isNotNull);
    expect(retrieved!.isVisible, true);

    final updated = Product(id: product.id, name: 'Visible Product', isVisible: false);
    await ManageProduct.updateProduct(updated);

    final retrievedUpdated = await ManageProduct.getProductById(product.id);
    expect(retrievedUpdated!.isVisible, false);
  });

  test('deletes product and its associations', () async {
    final db = await DatabaseHelper.database;
    final product = Product(
      name: 'Product to Delete',
      associations: {'super1': 'cat1', 'super2': 'cat2'},
    );
    await ManageProduct.addProduct(product);

    final associationsBefore = await db.query(
      'associations',
      where: 'product_id = ?',
      whereArgs: [product.id],
    );
    expect(associationsBefore.length, 2);

    await ManageProduct.deleteProduct(product.id);

    final associationsAfter = await db.query(
      'associations',
      where: 'product_id = ?',
      whereArgs: [product.id],
    );
    expect(associationsAfter, isEmpty);

    final productAfter = await ManageProduct.getProductById(product.id);
    expect(productAfter, isNull);
  });

  test('handles empty database when retrieving all products', () async {
    final all = await ManageProduct.getAllProducts();
    expect(all, isEmpty);
  });

  test('handles adding multiple products', () async {
    final p1 = Product(name: 'Product 1');
    final p2 = Product(name: 'Product 2');
    final p3 = Product(name: 'Product 3');

    await ManageProduct.addProduct(p1);
    await ManageProduct.addProduct(p2);
    await ManageProduct.addProduct(p3);

    final all = await ManageProduct.getAllProducts();
    expect(all.length, 3);
    expect(all.map((p) => p.getName()).toSet(), {'Product 1', 'Product 2', 'Product 3'});
  });

  test('replaces product with same id using replace conflict algorithm', () async {
    final p1 = Product(id: 'same-id', name: 'Original');
    final p2 = Product(id: 'same-id', name: 'Replaced');

    await ManageProduct.addProduct(p1);
    await ManageProduct.addProduct(p2);

    final all = await ManageProduct.getAllProducts();
    expect(all.length, 1);
    expect(all.first.getName(), 'Replaced');
  });

}
