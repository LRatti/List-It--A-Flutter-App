import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_category.dart';
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
    await db.delete('category');
    await db.delete('shopping_list');
  });

  test('adds and retrieves a purchased product by id', () async {
    final product = Product(name: 'Pasta');
    await ManageProduct.addProduct(product);

    final category = Category(name: 'Pantry');

    final purchased = PurchasedProduct(
      listId: 'list-1',
      product: product,
      category: category,
      price: 1.99,
      quantity: 2,
    );

    await ManagePurchasedProduct.addPurchasedProduct(purchased);

    final fetched =
        await ManagePurchasedProduct.getPurchasedProductById(purchased.id);
    expect(fetched, isNotNull);
    expect(fetched!.product.id, product.id);
    expect(fetched.product.getName(), 'Pasta');
    expect(fetched.quantity, 2);
  });


  test('finds purchased product by name within a list', () async {
    final product = Product(name: 'Tomato Sauce');
    await ManageProduct.addProduct(product);

    final category = Category(name: 'Sauces');

    final purchased = PurchasedProduct(
      listId: 'list-A',
      product: product,
      category: category,
      price: 2.50,
      quantity: 1,
    );
    await ManagePurchasedProduct.addPurchasedProduct(purchased);

    final found = await ManagePurchasedProduct.getPurchasedProductByName(
        'list-A', 'Tomato Sauce');
    expect(found, isNotNull);
    expect(found!.id, purchased.id);
    expect(found.product.id, product.id);
});


  test('updates an existing purchased product', () async {
    final product = Product(name: 'Milk');
    await ManageProduct.addProduct(product);

    final category = Category(name: 'Dairy');

    final purchased = PurchasedProduct(
      listId: 'list-B',
      product: product,
      category: category,
      price: 1.20,
      quantity: 1,
    );
    await ManagePurchasedProduct.addPurchasedProduct(purchased);

    final updatedProduct = Product(id: product.id, name: 'Skim Milk');
    final updated = PurchasedProduct(
      id: purchased.id,
      listId: purchased.listId,
      product: updatedProduct,
      category: category,
      price: 1.35,
      quantity: 3,
    );

    await ManagePurchasedProduct.updatePurchasedProduct(updated);

    final fetched =
        await ManagePurchasedProduct.getPurchasedProductById(purchased.id);
    expect(fetched, isNotNull);
    expect(fetched!.price, 1.35);
    expect(fetched.quantity, 3);
    expect(fetched.product.getName(), 'Skim Milk');

    final storedProduct =
        await ManageProduct.getProductById(product.id);
    expect(storedProduct, isNotNull);
    expect(storedProduct!.getName(), 'Skim Milk');
  });


  test('lists purchased products by list id', () async {
    final product1 = Product(name: 'Apple');
    final product2 = Product(name: 'Banana');
    await ManageProduct.addProduct(product1);
    await ManageProduct.addProduct(product2);

    final category = Category(name: 'Fruits');

    final p1 = PurchasedProduct(
        listId: 'list-X',
        product: product1,
        category: category,
        price: 0.50,
        quantity: 4);
    final p2 = PurchasedProduct(
        listId: 'list-X',
        product: product2,
        category: category,
        price: 0.30,
        quantity: 6);

    await ManagePurchasedProduct.addPurchasedProduct(p1);
    await ManagePurchasedProduct.addPurchasedProduct(p2);

    final items =
        await ManagePurchasedProduct.getPurchasedProductsByList('list-X');
    expect(items.length, 2);
    expect(items.map((e) => e.product.getName()).toSet(),
        {'Apple', 'Banana'});
  });


  test('deletes a purchased product', () async {
    final product = Product(name: 'Chips');
    await ManageProduct.addProduct(product);

    final category = Category(name: 'Snacks');

    final purchased = PurchasedProduct(
        listId: 'list-Z',
        product: product,
        category: category,
        price: 1.00,
        quantity: 2);

    await ManagePurchasedProduct.addPurchasedProduct(purchased);
    await ManagePurchasedProduct.deletePurchasedProduct(purchased.id);

    final remaining =
        await ManagePurchasedProduct.getPurchasedProductsByList('list-Z');
    expect(remaining, isEmpty);

    final stillThere =
        await ManageProduct.getProductById(product.id);
    expect(stillThere, isNotNull);
    expect(stillThere!.getName(), 'Chips');
  });

  test('returns null when purchased product by id does not exist', () async {
    final result = await ManagePurchasedProduct.getPurchasedProductById('nonexistent-id');
    expect(result, isNull);
  });

  test('returns null when purchased product by name does not exist', () async {
    final result = await ManagePurchasedProduct.getPurchasedProductByName(
        'list-A', 'NonexistentProduct');
    expect(result, isNull);
  });

  test('returns empty list when no purchased products for given list id', () async {
    final items = await ManagePurchasedProduct.getPurchasedProductsByList('nonexistent-list');
    expect(items, isEmpty);
  });

  test('handles adding purchased product with zero price', () async {
    final product = Product(name: 'Free Sample');
    await ManageProduct.addProduct(product);

    final category = Category(name: 'Samples');

    final purchased = PurchasedProduct(
      listId: 'list-free',
      product: product,
      category: category,
      price: 0.0,
      quantity: 1,
    );

    await ManagePurchasedProduct.addPurchasedProduct(purchased);

    final fetched = await ManagePurchasedProduct.getPurchasedProductById(purchased.id);
    expect(fetched, isNotNull);
    expect(fetched!.price, 0.0);
  });

  test('handles adding purchased product with large quantity', () async {
    final product = Product(name: 'Bulk Rice');
    await ManageProduct.addProduct(product);

    final category = Category(name: 'Grains');

    final purchased = PurchasedProduct(
      listId: 'list-bulk',
      product: product,
      category: category,
      price: 25.99,
      quantity: 100,
    );

    await ManagePurchasedProduct.addPurchasedProduct(purchased);

    final fetched = await ManagePurchasedProduct.getPurchasedProductById(purchased.id);
    expect(fetched, isNotNull);
    expect(fetched!.quantity, 100);
  });

  test('handles multiple purchased products with same product in different lists', () async {
    final product = Product(name: 'Bread');
    await ManageProduct.addProduct(product);

    final category = Category(name: 'Bakery');

    final purchased1 = PurchasedProduct(
      listId: 'list-1',
      product: product,
      category: category,
      price: 2.50,
      quantity: 1,
    );

    final purchased2 = PurchasedProduct(
      listId: 'list-2',
      product: product,
      category: category,
      price: 2.50,
      quantity: 2,
    );

    await ManagePurchasedProduct.addPurchasedProduct(purchased1);
    await ManagePurchasedProduct.addPurchasedProduct(purchased2);

    final list1Items = await ManagePurchasedProduct.getPurchasedProductsByList('list-1');
    final list2Items = await ManagePurchasedProduct.getPurchasedProductsByList('list-2');

    expect(list1Items.length, 1);
    expect(list2Items.length, 1);
    expect(list1Items.first.quantity, 1);
    expect(list2Items.first.quantity, 2);
  });

  test('handles purchased product with decimal price', () async {
    final product = Product(name: 'Gum');
    await ManageProduct.addProduct(product);

    final category = Category(name: 'Candy');

    final purchased = PurchasedProduct(
      listId: 'list-decimal',
      product: product,
      category: category,
      price: 1.99,
      quantity: 1,
    );

    await ManagePurchasedProduct.addPurchasedProduct(purchased);

    final fetched = await ManagePurchasedProduct.getPurchasedProductById(purchased.id);
    expect(fetched, isNotNull);
    expect(fetched!.price, 1.99);
  });

  test('addPurchasedProduct adds product and category if not exist', () async {
    final product = Product(name: 'New Product');
    final category = Category(name: 'New Category');

    final purchased = PurchasedProduct(
      listId: 'list-new',
      product: product,
      category: category,
      price: 5.00,
      quantity: 1,
    );

    await ManagePurchasedProduct.addPurchasedProduct(purchased);

    final retrievedProduct = await ManageProduct.getProductById(product.id);
    expect(retrievedProduct, isNotNull);
    expect(retrievedProduct!.getName(), 'New Product');

    final retrievedCategory = await ManageCategory.getCategoryById(category.id);
    expect(retrievedCategory, isNotNull);
    expect(retrievedCategory!.getName(), 'New Category');

    final retrievedPurchased = await ManagePurchasedProduct.getPurchasedProductById(purchased.id);
    expect(retrievedPurchased, isNotNull);
  });

  test('updatePurchasedProduct updates product and category', () async {
    final product = Product(name: 'Original Product');
    final category = Category(name: 'Original Category');

    final purchased = PurchasedProduct(
      listId: 'list-update',
      product: product,
      category: category,
      price: 5.00,
      quantity: 1,
    );
    await ManagePurchasedProduct.addPurchasedProduct(purchased);

    final updatedProduct = Product(id: product.id, name: 'Updated Product');
    final updatedCategory = Category(id: category.id, name: 'Updated Category');

    final updatedPurchased = PurchasedProduct(
      id: purchased.id,
      listId: purchased.listId,
      product: updatedProduct,
      category: updatedCategory,
      price: 7.50,
      quantity: 3,
    );

    await ManagePurchasedProduct.updatePurchasedProduct(updatedPurchased);

    final retrievedProduct = await ManageProduct.getProductById(product.id);
    expect(retrievedProduct!.getName(), 'Updated Product');

    final retrievedCategory = await ManageCategory.getCategoryById(category.id);
    expect(retrievedCategory!.getName(), 'Updated Category');

    final retrievedPurchased = await ManagePurchasedProduct.getPurchasedProductById(purchased.id);
    expect(retrievedPurchased!.price, 7.50);
    expect(retrievedPurchased.quantity, 3);
  });

  test('replaces purchased product with same id using replace conflict algorithm', () async {
    final product = Product(name: 'Product');
    await ManageProduct.addProduct(product);

    final category = Category(name: 'Category');

    final p1 = PurchasedProduct(
      id: 'same-id',
      listId: 'list-replace',
      product: product,
      category: category,
      price: 5.00,
      quantity: 1,
    );

    final p2 = PurchasedProduct(
      id: 'same-id',
      listId: 'list-replace',
      product: product,
      category: category,
      price: 10.00,
      quantity: 2,
    );

    await ManagePurchasedProduct.addPurchasedProduct(p1);
    await ManagePurchasedProduct.addPurchasedProduct(p2);

    final items = await ManagePurchasedProduct.getPurchasedProductsByList('list-replace');
    expect(items.length, 1);
    expect(items.first.price, 10.00);
    expect(items.first.quantity, 2);
  });

}
