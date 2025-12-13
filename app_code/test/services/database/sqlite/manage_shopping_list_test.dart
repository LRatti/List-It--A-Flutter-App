import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
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
}
