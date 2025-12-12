import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_product.dart';
import 'package:app_code/services/database/sqlite/manage_purchased_product.dart';
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
    // Clear tables used in tests to avoid cross-test leakage.
    await db.delete('purchased_product');
    await db.delete('product');
    await db.delete('shopping_list');
  });

  test('adds and retrieves a purchased product by id', () async {
    // Create and insert a product first (FK requirement in queries).
    final product = Product(name: 'Pasta');
    await ManageProduct.addProduct(product);

    // Create purchased product linked to a list and product.
    final purchased = PurchasedProduct(
      listId: 'list-1',
      product: product,
      price: 1.99,
      quantity: 2,
    );

    final inserted = await ManagePurchasedProduct.addPurchasedProduct(purchased);
    expect(inserted, greaterThan(0));

    final fetched = await ManagePurchasedProduct.getPurchasedProductById(purchased.id);
    expect(fetched, isNotNull);
    expect(fetched!.product!.id, product.id);
    expect(fetched.product!.getName(), 'Pasta');
    expect(fetched.quantity, 2);
  });

  test('finds purchased product by name within a list', () async {
    final product = Product(name: 'Tomato Sauce');
    await ManageProduct.addProduct(product);

    final purchased = PurchasedProduct(
      listId: 'list-A',
      product: product,
      price: 2.50,
      quantity: 1,
    );
    await ManagePurchasedProduct.addPurchasedProduct(purchased);

    final found = await ManagePurchasedProduct.getPurchasedProductByName('list-A', 'Tomato Sauce');
    expect(found, isNotNull);
    expect(found!.id, purchased.id);
    expect(found.product!.id, product.id);
  });

  test('updates an existing purchased product', () async {
    final product = Product(name: 'Milk');
    await ManageProduct.addProduct(product);

    final purchased = PurchasedProduct(
      listId: 'list-B',
      product: product,
      price: 1.20,
      quantity: 1,
    );
    await ManagePurchasedProduct.addPurchasedProduct(purchased);

    // Update both purchased product values and the linked product (name change).
    final updatedProduct = Product(id: product.id, name: 'Skim Milk');
    final updated = PurchasedProduct(
      id: purchased.id,
      listId: purchased.listId,
      product: updatedProduct,
      price: 1.35,
      quantity: 3,
    );
    final count = await ManagePurchasedProduct.updatePurchasedProduct(updated);
    expect(count, 1);

    final fetched = await ManagePurchasedProduct.getPurchasedProductById(purchased.id);
    expect(fetched, isNotNull);
    expect(fetched!.price, 1.35);
    expect(fetched.quantity, 3);
    expect(fetched.product!.getName(), 'Skim Milk');

    // Product table should reflect the updated product.
    final storedProduct = await ManageProduct.getProductById(product.id);
    expect(storedProduct, isNotNull);
    expect(storedProduct!.getName(), 'Skim Milk');
  });

  test('lists purchased products by list id', () async {
    final product1 = Product(name: 'Apple');
    final product2 = Product(name: 'Banana');
    await ManageProduct.addProduct(product1);
    await ManageProduct.addProduct(product2);

    final p1 = PurchasedProduct(listId: 'list-X', product: product1, price: 0.50, quantity: 4);
    final p2 = PurchasedProduct(listId: 'list-X', product: product2, price: 0.30, quantity: 6);
    await ManagePurchasedProduct.addPurchasedProduct(p1);
    await ManagePurchasedProduct.addPurchasedProduct(p2);

    final items = await ManagePurchasedProduct.getPurchasedProductsByList('list-X');
    expect(items.length, 2);
    expect(items.map((e) => e.product!.getName()).toSet(), {'Apple', 'Banana'});
  });

  test('deletes a purchased product', () async {
    final product = Product(name: 'Chips');
    await ManageProduct.addProduct(product);

    final purchased = PurchasedProduct(listId: 'list-Z', product: product, price: 1.00, quantity: 2);
    await ManagePurchasedProduct.addPurchasedProduct(purchased);

    final deleted = await ManagePurchasedProduct.deletePurchasedProduct(purchased.id);
    expect(deleted, 1);

    final remaining = await ManagePurchasedProduct.getPurchasedProductsByList('list-Z');
    expect(remaining, isEmpty);

    // Ensure the linked product still exists and is not deleted.
    final stillThere = await ManageProduct.getProductById(product.id);
    expect(stillThere, isNotNull);
    expect(stillThere!.getName(), 'Chips');
  });
}
