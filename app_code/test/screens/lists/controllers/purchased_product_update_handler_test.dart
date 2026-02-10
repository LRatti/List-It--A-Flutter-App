import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/screens/lists/controllers/purchased_product_update_handler.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<void> clearDb() async {
    final db = await DatabaseHelper.database;
    await db.delete('associations');
    await db.delete('product');
  }

  Category createCategory() => Category(id: 'cat-1', name: 'Category');

  Product createProduct(
    String name, {
    String? id,
    Map<String, String>? associations,
  }) {
    return Product(
      id: id,
      name: name,
      associations: associations,
    );
  }

  PurchasedProduct createPurchasedProduct(Product product) {
    return PurchasedProduct(
      listId: 'list-1',
      product: product,
      category: createCategory(),
      quantity: 1,
      price: 0.0,
    );
  }

  setUp(() async {
    await clearDb();
  });

  test('returns same product when name unchanged', () async {
    final product = createProduct('Apple');
    final purchased = createPurchasedProduct(product);

    final updated = await PurchasedProductUpdateHandler.updateProductName(
      purchased,
      'Apple',
    );

    expect(identical(updated, purchased), isTrue);
    expect(identical(updated.product, product), isTrue);
  });

  test('reuses existing product when name matches', () async {
    final existing = createProduct(
      'Milk',
      id: 'prod-milk',
      associations: {'sm-1': 'cat-1'},
    );
    await ManageProduct.addProduct(existing);

    final purchased = createPurchasedProduct(createProduct('Old'));

    final updated = await PurchasedProductUpdateHandler.updateProductName(
      purchased,
      'Milk',
    );

    expect(updated.product.id, existing.id);
    expect(updated.product.getName(), 'Milk');
    expect(updated.product.associations, existing.associations);
  });

  test('creates new product and copies associations when missing', () async {
    final original = createProduct(
      'Old',
      associations: {'sm-1': 'cat-1'},
    );
    final purchased = createPurchasedProduct(original);

    final updated = await PurchasedProductUpdateHandler.updateProductName(
      purchased,
      'New Name',
    );

    expect(updated.product.getName(), 'New Name');
    expect(updated.product.id, isNot(original.id));
    expect(updated.product.associations, original.associations);
  });

  test('wouldCreateDuplicate detects name clash with different id', () async {
    final existing = createProduct('Bread', id: 'prod-bread');
    await ManageProduct.addProduct(existing);

    final duplicate = await PurchasedProductUpdateHandler.wouldCreateDuplicate(
      'Bread',
      'other-id',
    );
    final sameId = await PurchasedProductUpdateHandler.wouldCreateDuplicate(
      'Bread',
      'prod-bread',
    );

    expect(duplicate, isTrue);
    expect(sameId, isFalse);
  });
}
