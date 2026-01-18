import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_shopping_list.dart';
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
    await db.delete('shopping_list');
    await db.delete('purchased_product');
    await db.delete('supermarket');
  });

  test('adds and retrieves a shopping list by id', () async {
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Super Market',
    );

    final shoppingList = ShoppingList(
      id: 'list1',
      name: 'Grocery Shopping',
      createdAt: DateTime.now(),
      supermarket: supermarket,
      totalPrice: 50.0,
      isRegistered: false,
    );

    await ManageShoppingList.addShoppingList(shoppingList);

    final fetched = await ManageShoppingList.getShoppingListById('list1');
    expect(fetched, isNotNull);
    expect(fetched!.id, 'list1');
    expect(fetched.getName(), 'Grocery Shopping');
    expect(fetched.getTotalPrice(), 50.0);
  });

  test('retrieves all shopping lists', () async {
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Super Market',
    );

    final list1 = ShoppingList(
      id: 'list1',
      name: 'Weekly Shopping',
      createdAt: DateTime.now(),
      supermarket: supermarket,
      totalPrice: 50.0,
      isRegistered: false,
    );

    final list2 = ShoppingList(
      id: 'list2',
      name: 'Daily Shopping',
      createdAt: DateTime.now(),
      supermarket: supermarket,
      totalPrice: 30.0,
      isRegistered: false,
    );

    await ManageShoppingList.addShoppingList(list1);
    await ManageShoppingList.addShoppingList(list2);

    final all = await ManageShoppingList.getAllShoppingLists();
    expect(all.length, 2);
    expect(all.map((l) => l.id).toSet(), {'list1', 'list2'});
  });

  test('updates an existing shopping list', () async {
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Super Market',
    );

    final shoppingList = ShoppingList(
      id: 'list1',
      name: 'Original Name',
      createdAt: DateTime.now(),
      supermarket: supermarket,
      totalPrice: 50.0,
      isRegistered: false,
    );

    await ManageShoppingList.addShoppingList(shoppingList);

    shoppingList.setName('Updated Name');
    shoppingList.setTotalPrice(75.0);

    await ManageShoppingList.updateShoppingList(shoppingList);

    final updated = await ManageShoppingList.getShoppingListById('list1');
    expect(updated, isNotNull);
    expect(updated!.getName(), 'Updated Name');
    expect(updated.getTotalPrice(), 75.0);
  });

  test('deletes a shopping list', () async {
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Super Market',
    );

    final shoppingList = ShoppingList(
      id: 'list1',
      name: 'Shopping List',
      createdAt: DateTime.now(),
      supermarket: supermarket,
      totalPrice: 50.0,
      isRegistered: false,
    );

    await ManageShoppingList.addShoppingList(shoppingList);

    await ManageShoppingList.deleteShoppingList(shoppingList);

    final remaining = await ManageShoppingList.getAllShoppingLists();
    expect(remaining, isEmpty);
  });

  test('deletes purchased products when list is deleted', () async {
    final db = await DatabaseHelper.database;

    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Super Market',
    );

    final shoppingList = ShoppingList(
      id: 'list1',
      name: 'Shopping List',
      createdAt: DateTime.now(),
      supermarket: supermarket,
      isRegistered: false,
    );

    await ManageShoppingList.addShoppingList(shoppingList);

    // Add a purchased product manually
    await db.insert(
      'purchased_product',
      {
        'id': 'prod1',
        'product_id': 'p1',
        'list_id': 'list1',
        'price': 10.0,
        'quantity': 2,
        'category_id': 'c1',
      },
    );

    final productsBeforeDelete = await db.query(
      'purchased_product',
      where: 'list_id = ?',
      whereArgs: ['list1'],
    );
    expect(productsBeforeDelete.length, 1);

    await ManageShoppingList.deleteShoppingList(shoppingList);

    final productsAfterDelete = await db.query(
      'purchased_product',
      where: 'list_id = ?',
      whereArgs: ['list1'],
    );
    expect(productsAfterDelete, isEmpty);
  });

  test('handles replacing a shopping list with same id', () async {
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Super Market',
    );

    final list1 = ShoppingList(
      id: 'list1',
      name: 'Original Name',
      createdAt: DateTime.now(),
      supermarket: supermarket,
      totalPrice: 50.0,
      isRegistered: false,
    );

    final list2 = ShoppingList(
      id: 'list1',
      name: 'Replaced Name',
      createdAt: DateTime.now(),
      supermarket: supermarket,
      totalPrice: 75.0,
      isRegistered: false,
    );

    await ManageShoppingList.addShoppingList(list1);
    await ManageShoppingList.addShoppingList(list2);

    final all = await ManageShoppingList.getAllShoppingLists();
    expect(all.length, 1);
    expect(all.first.getName(), 'Replaced Name');
    expect(all.first.getTotalPrice(), 75.0);
  });

  test('returns null when shopping list does not exist', () async {
    final result = await ManageShoppingList.getShoppingListById('nonexistent');
    expect(result, isNull);
  });

  test('handles empty database when retrieving all shopping lists', () async {
    final all = await ManageShoppingList.getAllShoppingLists();
    expect(all, isEmpty);
  });

  test('handles shopping list with zero total price', () async {
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Super Market',
    );

    final shoppingList = ShoppingList(
      id: 'list1',
      name: 'Empty List',
      createdAt: DateTime.now(),
      supermarket: supermarket,
      totalPrice: 0.0,
      isRegistered: false,
    );

    await ManageShoppingList.addShoppingList(shoppingList);

    final fetched = await ManageShoppingList.getShoppingListById('list1');
    expect(fetched, isNotNull);
    expect(fetched!.getTotalPrice(), 0.0);
  });

  test('handles shopping list with null total price', () async {
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Super Market',
    );

    final shoppingList = ShoppingList(
      id: 'list1',
      name: 'No Price List',
      createdAt: DateTime.now(),
      supermarket: supermarket,
      totalPrice: null,
      isRegistered: false,
    );

    await ManageShoppingList.addShoppingList(shoppingList);

    final fetched = await ManageShoppingList.getShoppingListById('list1');
    expect(fetched, isNotNull);
    expect(fetched!.getTotalPrice(), 0.0);
  });

  test('handles shopping list with isInTheTrash flag', () async {
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Super Market',
    );

    final shoppingList = ShoppingList(
      id: 'list1',
      name: 'Trashed List',
      createdAt: DateTime.now(),
      supermarket: supermarket,
      isRegistered: false,
      isInTheTrash: true,
    );

    await ManageShoppingList.addShoppingList(shoppingList);

    final fetched = await ManageShoppingList.getShoppingListById('list1');
    expect(fetched, isNotNull);
    expect(fetched!.getIsInTheTrash(), true);
  });

  test('handles shopping list with deletion timestamp', () async {
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Super Market',
    );

    final deletionTime = DateTime.now();
    final shoppingList = ShoppingList(
      id: 'list1',
      name: 'Deleted List',
      createdAt: DateTime.now(),
      supermarket: supermarket,
      isRegistered: false,
      isInTheTrash: true,
      deletionTimestamp: deletionTime,
    );

    await ManageShoppingList.addShoppingList(shoppingList);

    final fetched = await ManageShoppingList.getShoppingListById('list1');
    expect(fetched, isNotNull);
    expect(fetched!.getDeletionTimestamp(), isNotNull);
  });

  test('handles shopping list with image path', () async {
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Super Market',
    );

    final shoppingList = ShoppingList(
      id: 'list1',
      name: 'List with Image',
      createdAt: DateTime.now(),
      supermarket: supermarket,
      image: '/path/to/image.jpg',
      isRegistered: false,
    );

    await ManageShoppingList.addShoppingList(shoppingList);

    final fetched = await ManageShoppingList.getShoppingListById('list1');
    expect(fetched, isNotNull);
    expect(fetched!.image, '/path/to/image.jpg');
  });

  test('handles shopping list registered flag', () async {
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Super Market',
    );

    final shoppingList = ShoppingList(
      id: 'list1',
      name: 'Registered List',
      createdAt: DateTime.now(),
      supermarket: supermarket,
      isRegistered: true,
    );

    await ManageShoppingList.addShoppingList(shoppingList);

    final fetched = await ManageShoppingList.getShoppingListById('list1');
    expect(fetched, isNotNull);
    expect(fetched!.getIsRegistered(), true);
  });

  test('updates shopping list with purchased products', () async {
    final db = await DatabaseHelper.database;
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Super Market',
    );

    final shoppingList = ShoppingList(
      id: 'list1',
      name: 'Shopping List',
      createdAt: DateTime.now(),
      supermarket: supermarket,
      isRegistered: false,
    );

    await ManageShoppingList.addShoppingList(shoppingList);

    // Manually add a purchased product
    await db.insert('product', {
      'id': 'prod1',
      'name': 'Product 1',
      'is_visible': 1,
    });
    await db.insert('category', {
      'id': 'cat1',
      'name': 'Category 1',
      'is_default': 0,
    });
    await db.insert('purchased_product', {
      'id': 'pp1',
      'list_id': 'list1',
      'product_id': 'prod1',
      'category_id': 'cat1',
      'price': 5.0,
      'quantity': 2,
    });

    final product2 = Product(id: 'prod2', name: 'Product 2');
    final category2 = Category(id: 'cat2', name: 'Category 2');

    shoppingList.addProduct(product2, category2);
    shoppingList.registerProduct(product2.getName(), 3.0, 1);
    await ManageShoppingList.updateShoppingList(shoppingList);

    final updated = await ManageShoppingList.getShoppingListById('list1');
    expect(updated, isNotNull);
    expect(updated!.getProducts().length, 2);
  });

  test('handles supermarket without id when retrieving', () async {
    final db = await DatabaseHelper.database;

    // Insert shopping list without supermarket_id
    await db.insert('shopping_list', {
      'id': 'list1',
      'name': 'List Without Supermarket',
      'created_at': DateTime.now().toIso8601String(),
      'supermarket_id': '',
      'is_registered': 0,
      'is_in_the_trash': 0,
    });

    final fetched = await ManageShoppingList.getShoppingListById('list1');
    expect(fetched, isNotNull);
    expect(fetched!.getName(), 'List Without Supermarket');
  });

  test('handles updating shopping list name and price only', () async {
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Super Market',
    );

    final shoppingList = ShoppingList(
      id: 'list1',
      name: 'Original Name',
      createdAt: DateTime.now(),
      supermarket: supermarket,
      totalPrice: 50.0,
      isRegistered: false,
    );

    await ManageShoppingList.addShoppingList(shoppingList);

    shoppingList.setName('New Name');
    shoppingList.setTotalPrice(100.0);

    await ManageShoppingList.updateShoppingList(shoppingList);

    final updated = await ManageShoppingList.getShoppingListById('list1');
    expect(updated, isNotNull);
    expect(updated!.getName(), 'New Name');
    expect(updated.getTotalPrice(), 100.0);
  });

  test('handles updating shopping list image', () async {
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Super Market',
    );

    final shoppingList = ShoppingList(
      id: 'list1',
      name: 'List',
      createdAt: DateTime.now(),
      supermarket: supermarket,
      image: '/old/path.jpg',
      isRegistered: false,
    );

    await ManageShoppingList.addShoppingList(shoppingList);

    shoppingList.setImage('/new/path.jpg');
    await ManageShoppingList.updateShoppingList(shoppingList);

    final updated = await ManageShoppingList.getShoppingListById('list1');
    expect(updated, isNotNull);
    expect(updated!.image, '/new/path.jpg');
  });

  test('handles updating shopping list trash status', () async {
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Super Market',
    );

    final shoppingList = ShoppingList(
      id: 'list1',
      name: 'List',
      createdAt: DateTime.now(),
      supermarket: supermarket,
      isRegistered: false,
      isInTheTrash: false,
    );

    await ManageShoppingList.addShoppingList(shoppingList);

    shoppingList.setIsInTheTrash(true);
    shoppingList.setDeletionTimestamp(DateTime.now());
    await ManageShoppingList.updateShoppingList(shoppingList);

    final updated = await ManageShoppingList.getShoppingListById('list1');
    expect(updated, isNotNull);
    expect(updated!.getIsInTheTrash(), true);
    expect(updated.getDeletionTimestamp(), isNotNull);
  });
}
