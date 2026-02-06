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

Future<void> _insertShoppingList(String id, {String name = 'List'}) async {
  final db = await DatabaseHelper.database;
  await db.insert('shopping_list', {
    'id': id,
    'name': name,
    'created_at': DateTime(2024, 1, 1).toIso8601String(),
    'last_modified': DateTime(2024, 1, 1).toIso8601String(),
    'supermarket_id': null,
    'total_price': null,
    'image': null,
    'is_registered': 0,
    'is_in_the_trash': 0,
    'deletion_timestamp': null,
  });
}

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

  test('addPurchasedProduct persists product, category and purchase data',
      () async {
    await _insertShoppingList('list-1');

    final product = Product(id: 'prod-1', name: 'Apples');
    final category = Category(id: 'cat-1', name: 'Fruit');
    final purchased = PurchasedProduct(
      id: 'pp-1',
      listId: 'list-1',
      product: product,
      category: category,
      price: 2.5,
      quantity: 3,
    );

    await ManagePurchasedProduct.addPurchasedProduct(purchased);

    final fetched = await ManagePurchasedProduct.getPurchasedProductById('pp-1');
    expect(fetched, isNotNull);
    expect(fetched!.listId, 'list-1');
    expect(fetched.product.getName(), 'Apples');
    expect(fetched.category.getName(), 'Fruit');
    expect(fetched.price, 2.5);
    expect(fetched.quantity, 3);
  });

  test('getPurchasedProductById returns null when not found', () async {
    final missing = await ManagePurchasedProduct.getPurchasedProductById('none');
    expect(missing, isNull);
  });

  test('getPurchasedProductsByList filters by list id and returns empty when missing',
      () async {
    await _insertShoppingList('list-a');
    await _insertShoppingList('list-b');

    final productA = Product(id: 'prod-a', name: 'Milk');
    final categoryA = Category(id: 'cat-a', name: 'Dairy');
    final purchaseA = PurchasedProduct(
      id: 'pp-a',
      listId: 'list-a',
      product: productA,
      category: categoryA,
      price: 1.2,
      quantity: 2,
    );

    final productB = Product(id: 'prod-b', name: 'Bread');
    final categoryB = Category(id: 'cat-b', name: 'Bakery');
    final purchaseB = PurchasedProduct(
      id: 'pp-b',
      listId: 'list-b',
      product: productB,
      category: categoryB,
      price: 0.8,
      quantity: 1,
    );

    await ManagePurchasedProduct.addPurchasedProduct(purchaseA);
    await ManagePurchasedProduct.addPurchasedProduct(purchaseB);

    final listAItems =
        await ManagePurchasedProduct.getPurchasedProductsByList('list-a');
    final missingItems =
        await ManagePurchasedProduct.getPurchasedProductsByList('missing');

    expect(listAItems.map((p) => p.id).toList(), ['pp-a']);
    expect(missingItems, isEmpty);
  });

  test('updatePurchasedProduct updates price, quantity and linked entities',
      () async {
    await _insertShoppingList('list-up');

    final originalProduct = Product(id: 'prod-up', name: 'Old');
    final originalCategory = Category(id: 'cat-up', name: 'OldCat');
    final purchase = PurchasedProduct(
      id: 'pp-up',
      listId: 'list-up',
      product: originalProduct,
      category: originalCategory,
      price: 1.0,
      quantity: 1,
    );
    await ManagePurchasedProduct.addPurchasedProduct(purchase);

    final updated = PurchasedProduct(
      id: 'pp-up',
      listId: 'list-up',
      product: Product(id: 'prod-up', name: 'New', isVisible: false),
      category: Category(id: 'cat-up', name: 'Snacks'),
      price: 9.9,
      quantity: 5,
    );

    await ManagePurchasedProduct.updatePurchasedProduct(updated);

    final fetched = await ManagePurchasedProduct.getPurchasedProductById('pp-up');
    expect(fetched, isNotNull);
    expect(fetched!.product.getName(), 'New');
    expect(fetched.product.isVisible, isFalse);
    expect(fetched.category.getName(), 'Snacks');
    expect(fetched.price, 9.9);
    expect(fetched.quantity, 5);
  });

  test('getPurchasedProductByName matches by list and product name', () async {
    await _insertShoppingList('list-name');

    final product = Product(id: 'prod-name', name: 'Orange');
    final category = Category(id: 'cat-name', name: 'Fruit');
    final purchase = PurchasedProduct(
      id: 'pp-name',
      listId: 'list-name',
      product: product,
      category: category,
      price: 3.0,
      quantity: 4,
    );

    await ManagePurchasedProduct.addPurchasedProduct(purchase);

    final found = await ManagePurchasedProduct.getPurchasedProductByName(
      'list-name',
      'Orange',
    );
    final missing = await ManagePurchasedProduct.getPurchasedProductByName(
      'list-name',
      'Missing',
    );

    expect(found, isNotNull);
    expect(found!.id, 'pp-name');
    expect(missing, isNull);
  });

  test('deletePurchasedProduct removes rows', () async {
    await _insertShoppingList('list-del');

    final product = Product(id: 'prod-del', name: 'Item');
    final category = Category(id: 'cat-del', name: 'Shelf');
    final purchase = PurchasedProduct(
      id: 'pp-del',
      listId: 'list-del',
      product: product,
      category: category,
      price: 4.0,
      quantity: 2,
    );

    await ManagePurchasedProduct.addPurchasedProduct(purchase);

    await ManagePurchasedProduct.deletePurchasedProduct('pp-del');

    final afterDelete =
        await ManagePurchasedProduct.getPurchasedProductsByList('list-del');
    final single = await ManagePurchasedProduct.getPurchasedProductById('pp-del');

    expect(afterDelete, isEmpty);
    expect(single, isNull);
  });

  test('getPurchasedProductsByList loads product associations correctly', () async {
    await _insertShoppingList('list-assoc');

    // Create a supermarket and category
    final db = await DatabaseHelper.database;
    await db.insert('category', {
      'id': 'cat-dairy',
      'name': 'Dairy',
      'is_visible': 1,
      'created_at': DateTime.now().toIso8601String(),
      'last_modified': DateTime.now().toIso8601String(),
    });

    await db.insert('supermarket', {
      'id': 'sup-1',
      'name': 'Market 1',
      'is_visible': 1,
      'is_favorite': 0,
      'is_default': 0,
      'created_at': DateTime.now().toIso8601String(),
      'last_modified': DateTime.now().toIso8601String(),
    });

    // Add product with associations
    final product = Product(id: 'prod-milk', name: 'Milk');
    final category = Category(id: 'cat-dairy', name: 'Dairy');
    product.addAssociation('sup-1', 'cat-dairy');
    await ManageProduct.addProduct(product);

    final purchase = PurchasedProduct(
      id: 'pp-assoc',
      listId: 'list-assoc',
      product: product,
      category: category,
      price: 2.5,
      quantity: 1,
    );

    await ManagePurchasedProduct.addPurchasedProduct(purchase);

    final results = await ManagePurchasedProduct.getPurchasedProductsByList('list-assoc');

    expect(results, hasLength(1));
    final fetchedProduct = results.first.product;
    expect(fetchedProduct.associations['sup-1'], 'cat-dairy');
  });

  test('getPurchasedProductById loads product associations correctly', () async {
    await _insertShoppingList('list-single');

    final db = await DatabaseHelper.database;
    await db.insert('category', {
      'id': 'cat-meat',
      'name': 'Meat',
      'is_visible': 1,
      'created_at': DateTime.now().toIso8601String(),
      'last_modified': DateTime.now().toIso8601String(),
    });

    await db.insert('supermarket', {
      'id': 'sup-2',
      'name': 'Market 2',
      'is_visible': 1,
      'is_favorite': 0,
      'is_default': 0,
      'created_at': DateTime.now().toIso8601String(),
      'last_modified': DateTime.now().toIso8601String(),
    });

    final product = Product(id: 'prod-beef', name: 'Beef');
    final category = Category(id: 'cat-meat', name: 'Meat');
    product.addAssociation('sup-2', 'cat-meat');
    await ManageProduct.addProduct(product);

    final purchase = PurchasedProduct(
      id: 'pp-single-assoc',
      listId: 'list-single',
      product: product,
      category: category,
      price: 8.0,
      quantity: 1,
    );

    await ManagePurchasedProduct.addPurchasedProduct(purchase);

    final fetched = await ManagePurchasedProduct.getPurchasedProductById('pp-single-assoc');

    expect(fetched, isNotNull);
    expect(fetched!.product.associations['sup-2'], 'cat-meat');
  });

  test('getPurchasedProductByName loads product associations correctly', () async {
    await _insertShoppingList('list-by-name');

    final db = await DatabaseHelper.database;
    await db.insert('category', {
      'id': 'cat-bakery',
      'name': 'Bakery',
      'is_visible': 1,
      'created_at': DateTime.now().toIso8601String(),
      'last_modified': DateTime.now().toIso8601String(),
    });

    await db.insert('supermarket', {
      'id': 'sup-3',
      'name': 'Market 3',
      'is_visible': 1,
      'is_favorite': 0,
      'is_default': 0,
      'created_at': DateTime.now().toIso8601String(),
      'last_modified': DateTime.now().toIso8601String(),
    });

    final product = Product(id: 'prod-bread', name: 'Bread');
    final category = Category(id: 'cat-bakery', name: 'Bakery');
    product.addAssociation('sup-3', 'cat-bakery');
    await ManageProduct.addProduct(product);

    final purchase = PurchasedProduct(
      id: 'pp-bread',
      listId: 'list-by-name',
      product: product,
      category: category,
      price: 3.5,
      quantity: 2,
    );

    await ManagePurchasedProduct.addPurchasedProduct(purchase);

    final fetched = await ManagePurchasedProduct.getPurchasedProductByName('list-by-name', 'Bread');

    expect(fetched, isNotNull);
    expect(fetched!.product.associations['sup-3'], 'cat-bakery');
  });

  test('getPurchasedProductsByList excludes deleted items', () async {
    await _insertShoppingList('list-deleted');

    final product1 = Product(id: 'prod-1', name: 'Active');
    final product2 = Product(id: 'prod-2', name: 'Deleted');
    final category = Category(id: 'cat-1', name: 'Test');

    final purchase1 = PurchasedProduct(
      id: 'pp-active',
      listId: 'list-deleted',
      product: product1,
      category: category,
      price: 1.0,
      quantity: 1,
    );

    final purchase2 = PurchasedProduct(
      id: 'pp-deleted',
      listId: 'list-deleted',
      product: product2,
      category: category,
      price: 2.0,
      quantity: 1,
    );

    await ManagePurchasedProduct.addPurchasedProduct(purchase1);
    await ManagePurchasedProduct.addPurchasedProduct(purchase2);

    // Mark one as deleted
    final db = await DatabaseHelper.database;
    await db.update(
      'purchased_product',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: ['pp-deleted'],
    );

    final results = await ManagePurchasedProduct.getPurchasedProductsByList('list-deleted');

    expect(results, hasLength(1));
    expect(results.first.id, 'pp-active');
  });

  test('getPurchasedProductById returns null for deleted items', () async {
    await _insertShoppingList('list-del-check');

    final product = Product(id: 'prod-del', name: 'Item');
    final category = Category(id: 'cat-del', name: 'Cat');

    final purchase = PurchasedProduct(
      id: 'pp-del-check',
      listId: 'list-del-check',
      product: product,
      category: category,
      price: 1.0,
      quantity: 1,
    );

    await ManagePurchasedProduct.addPurchasedProduct(purchase);

    // Mark as deleted
    final db = await DatabaseHelper.database;
    await db.update(
      'purchased_product',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: ['pp-del-check'],
    );

    final result = await ManagePurchasedProduct.getPurchasedProductById('pp-del-check');

    expect(result, isNull);
  });

  test('getPurchasedProductByName returns null for deleted items', () async {
    await _insertShoppingList('list-name-del');

    final product = Product(id: 'prod-name-del', name: 'TestProduct');
    final category = Category(id: 'cat-name-del', name: 'TestCat');

    final purchase = PurchasedProduct(
      id: 'pp-name-del',
      listId: 'list-name-del',
      product: product,
      category: category,
      price: 1.0,
      quantity: 1,
    );

    await ManagePurchasedProduct.addPurchasedProduct(purchase);

    // Mark as deleted
    final db = await DatabaseHelper.database;
    await db.update(
      'purchased_product',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: ['pp-name-del'],
    );

    final result = await ManagePurchasedProduct.getPurchasedProductByName(
      'list-name-del',
      'TestProduct',
    );

    expect(result, isNull);
  });

  test('addPurchasedProduct replaces existing with same id', () async {
    await _insertShoppingList('list-replace');

    final product = Product(id: 'prod-replace', name: 'Item');
    final category = Category(id: 'cat-replace', name: 'Cat');

    final purchase1 = PurchasedProduct(
      id: 'pp-replace',
      listId: 'list-replace',
      product: product,
      category: category,
      price: 1.0,
      quantity: 1,
    );

    await ManagePurchasedProduct.addPurchasedProduct(purchase1);

    final purchase2 = PurchasedProduct(
      id: 'pp-replace',
      listId: 'list-replace',
      product: product,
      category: category,
      price: 5.0,
      quantity: 10,
    );

    await ManagePurchasedProduct.addPurchasedProduct(purchase2);

    final result = await ManagePurchasedProduct.getPurchasedProductById('pp-replace');

    expect(result, isNotNull);
    expect(result!.price, 5.0);
    expect(result.quantity, 10);
  });

  test('getPurchasedProductById handles multiple associations', () async {
    await _insertShoppingList('list-multi');

    final db = await DatabaseHelper.database;
    
    // Create multiple supermarkets and categories
    await db.insert('category', {
      'id': 'cat-fruit',
      'name': 'Fruit',
      'is_visible': 1,
      'created_at': DateTime.now().toIso8601String(),
      'last_modified': DateTime.now().toIso8601String(),
    });

    await db.insert('category', {
      'id': 'cat-organic',
      'name': 'Organic',
      'is_visible': 1,
      'created_at': DateTime.now().toIso8601String(),
      'last_modified': DateTime.now().toIso8601String(),
    });

    await db.insert('supermarket', {
      'id': 'sup-a',
      'name': 'Market A',
      'is_visible': 1,
      'is_favorite': 0,
      'is_default': 0,
      'created_at': DateTime.now().toIso8601String(),
      'last_modified': DateTime.now().toIso8601String(),
    });

    await db.insert('supermarket', {
      'id': 'sup-b',
      'name': 'Market B',
      'is_visible': 1,
      'is_favorite': 0,
      'is_default': 0,
      'created_at': DateTime.now().toIso8601String(),
      'last_modified': DateTime.now().toIso8601String(),
    });

    final product = Product(id: 'prod-apple', name: 'Apple');
    final category1 = Category(id: 'cat-fruit', name: 'Fruit');
    final category2 = Category(id: 'cat-organic', name: 'Organic');
    
    product.addAssociation('sup-a', 'cat-fruit');
    product.addAssociation('sup-b', 'cat-organic');
    
    await ManageProduct.addProduct(product);

    final purchase = PurchasedProduct(
      id: 'pp-multi',
      listId: 'list-multi',
      product: product,
      category: category1,
      price: 1.5,
      quantity: 3,
    );

    await ManagePurchasedProduct.addPurchasedProduct(purchase);

    final fetched = await ManagePurchasedProduct.getPurchasedProductById('pp-multi');

    expect(fetched, isNotNull);
    expect(fetched!.product.associations['sup-a'], 'cat-fruit');
    expect(fetched.product.associations['sup-b'], 'cat-organic');
  });
}
