import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/repositories/sync/shopping_list_repository_sync.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_shopping_list.dart';
import 'package:app_code/services/database/sqlite/manage_sync_box.dart';
import 'package:app_code/services/database/sqlite/manage_purchased_product.dart';
import 'package:app_code/services/database/sqlite/manage_supermarket.dart';
import 'package:app_code/models/sync/sync_operation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    // Initialize sqflite_ffi for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Clean up any existing database
    final dbPath = await getDatabasesPath();
    await deleteDatabase('$dbPath/shopping_app.db');
  });

  setUp(() async {
    // Clear tables before each test
    final db = await DatabaseHelper.database;
    await db.delete('shopping_list');
    await db.delete('purchased_product');
    await db.delete('supermarket');
    await db.delete('sync_box');
  });

  group('USER WRITE OPERATIONS - add -', () {
    late ShoppingListRepositoryWithSync repository;

    setUp(() {
      repository = ShoppingListRepositoryWithSync();
    });

    test('saves shopping list to database with correct data', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-1',
        name: 'Weekly Groceries',
        createdAt: DateTime(2024, 1, 15, 10, 0),
      );

      // Act
      await repository.add(list);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('list-1');
      expect(result, isNotNull);
      expect(result!.id, 'list-1');
      expect(result.getName(), 'Weekly Groceries');
      expect(result.isDeleted, false);
    });

    test('sets lastModified timestamp equal to createdAt on add', () async {
      // Arrange
      final createdTime = DateTime(2024, 1, 15, 10, 30, 45);
      final list = ShoppingList(
        id: 'list-2',
        name: 'Shopping',
        createdAt: createdTime,
      );

      // Act
      await repository.add(list);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('list-2');
      expect(result, isNotNull);
      expect(result!.lastModified, equals(result.createdAt));
    });

    test('creates sync_box entry with upsert operation', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-3',
        name: 'Test List',
        createdAt: DateTime.now(),
      );

      // Act
      await repository.add(list);

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'list-3',
        'shopping_list',
      );
      expect(syncEntry, isNotNull);
      expect(syncEntry!.entityId, 'list-3');
      expect(syncEntry.entityType, 'shopping_list');
      expect(syncEntry.operation, SyncOperation.upsert);
    });

    test('sync_box entry has same timestamp as shopping list', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-4',
        name: 'Test List',
        createdAt: DateTime(2024, 1, 15, 10, 0),
      );

      // Act
      await repository.add(list);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('list-4');
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'list-4',
        'shopping_list',
      );
      expect(syncEntry, isNotNull);
      expect(syncEntry!.lastModified, equals(result!.lastModified));
    });

    test('saves shopping list with supermarket', () async {
      // Arrange
      final supermarket = Supermarket(id: 'super-1', name: 'Carrefour');
      await ManageSupermarket.addSupermarket(supermarket);

      final list = ShoppingList(
        id: 'list-5',
        name: 'Weekly Groceries',
        createdAt: DateTime.now(),
        supermarket: supermarket,
      );

      // Act
      await repository.add(list);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('list-5');
      expect(result, isNotNull);
      expect(result!.getSupermarket(), isNotNull);
      expect(result.getSupermarket()!.id, 'super-1');
    });

    test('saves shopping list with products', () async {
      // Arrange
      final category = Category(id: 'cat-1', name: 'Fruits');
      final product1 = Product(id: 'prod-1', name: 'Apple');
      final product2 = Product(id: 'prod-2', name: 'Banana');

      final purchasedProduct1 = PurchasedProduct(
        listId: 'list-6',
        product: product1,
        category: category,
        quantity: 5,
      );
      final purchasedProduct2 = PurchasedProduct(
        listId: 'list-6',
        product: product2,
        category: category,
        quantity: 3,
      );

      final list = ShoppingList(
        id: 'list-6',
        name: 'Fruits',
        createdAt: DateTime.now(),
        products: [purchasedProduct1, purchasedProduct2],
      );

      // Act
      await repository.add(list);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('list-6');
      expect(result, isNotNull);
      expect(result!.getProducts().length, 2);
    });

    test('handles multiple shopping list additions', () async {
      // Arrange & Act
      for (int i = 1; i <= 3; i++) {
        final list = ShoppingList(
          id: 'list-$i',
          name: 'List $i',
          createdAt: DateTime.now(),
        );
        await repository.add(list);
      }

      // Assert
      final allLists = await ManageShoppingList.getAllShoppingLists();
      expect(allLists.length, 3);
      expect(
        allLists.map((l) => l.id).toList(),
        containsAll(['list-1', 'list-2', 'list-3']),
      );

      final syncEntries = await ManageSyncBox.getAllSyncEntries(
        entityType: 'shopping_list',
      );
      expect(syncEntries.length, 3);
    });

    test('handles isRegistered flag on add', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-registered',
        name: 'Registered List',
        createdAt: DateTime.now(),
        isRegistered: true,
      );

      // Act
      await repository.add(list);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('list-registered');
      expect(result, isNotNull);
      expect(result!.getIsRegistered(), true);
    });

    test('handles isInTheTrash flag on add', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-trash',
        name: 'Trashed List',
        createdAt: DateTime.now(),
        isInTheTrash: true,
      );

      // Act
      await repository.add(list);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('list-trash');
      expect(result, isNotNull);
      expect(result!.getIsInTheTrash(), true);
    });
  });

  group('USER WRITE OPERATIONS - update -', () {
    late ShoppingListRepositoryWithSync repository;

    setUp(() {
      repository = ShoppingListRepositoryWithSync();
    });

    test('updates shopping list in database', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-1',
        name: 'Original Name',
        createdAt: DateTime.now(),
      );
      await repository.add(list);

      // Act
      list.setName('Updated Name');
      await repository.update(list);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('list-1');
      expect(result, isNotNull);
      expect(result!.getName(), 'Updated Name');
    });

    test('generates monotonic timestamp on update', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-2',
        name: 'Test List',
        createdAt: DateTime.now(),
      );
      await repository.add(list);
      final originalTimestamp = list.lastModified;

      // Wait a bit to ensure different timestamp
      await Future.delayed(Duration(milliseconds: 2));

      // Act
      list.setName('Modified Name');
      await repository.update(list);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('list-2');
      expect(result, isNotNull);
      expect(result!.lastModified, isNotNull);
      expect(
        result.lastModified!.isAfter(originalTimestamp!),
        true,
      );
    });

    test('creates sync_box entry with upsert operation on update', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-3',
        name: 'Test',
        createdAt: DateTime.now(),
      );
      await repository.add(list);

      // Clear sync box to verify update creates new entry
      await ManageSyncBox.clearAllSyncEntries();

      // Act
      list.setName('Updated Test');
      await repository.update(list);

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry('list-3', 'shopping_list');
      expect(syncEntry, isNotNull);
      expect(syncEntry!.operation, SyncOperation.upsert);
    });

    test('updates sync_box entry with newer timestamp', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-4',
        name: 'Test',
        createdAt: DateTime.now(),
      );
      await repository.add(list);
      final firstSyncEntry = await ManageSyncBox.getSyncEntry(
        'list-4',
        'shopping_list',
      );

      await Future.delayed(Duration(milliseconds: 2));

      // Act
      list.setName('Updated');
      await repository.update(list);

      // Assert
      final secondSyncEntry = await ManageSyncBox.getSyncEntry(
        'list-4',
        'shopping_list',
      );
      expect(secondSyncEntry, isNotNull);
      expect(
        secondSyncEntry!.lastModified.isAfter(firstSyncEntry!.lastModified),
        true,
      );
    });

    test('updates supermarket association', () async {
      // Arrange
      final supermarket1 = Supermarket(id: 'super-1', name: 'Carrefour');
      final supermarket2 = Supermarket(id: 'super-2', name: 'Conad');
      await ManageSupermarket.addSupermarket(supermarket1);
      await ManageSupermarket.addSupermarket(supermarket2);

      final list = ShoppingList(
        id: 'list-5',
        name: 'Test',
        createdAt: DateTime.now(),
        supermarket: supermarket1,
      );
      await repository.add(list);

      // Act
      list.setSupermarket(supermarket2);
      await repository.update(list);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('list-5');
      expect(result, isNotNull);
      expect(result!.getSupermarket()!.id, 'super-2');
    });

    test('updates products in shopping list', () async {
      // Arrange
      final category = Category(id: 'cat-1', name: 'Fruits');
      final product1 = Product(id: 'prod-1', name: 'Apple');
      final purchasedProduct1 = PurchasedProduct(
        listId: 'list-6',
        product: product1,
        category: category,
        quantity: 5,
      );

      final list = ShoppingList(
        id: 'list-6',
        name: 'Test',
        createdAt: DateTime.now(),
        products: [purchasedProduct1],
      );
      await repository.add(list);

      final product2 = Product(id: 'prod-2', name: 'Banana');
      final purchasedProduct2 = PurchasedProduct(
        listId: 'list-6',
        product: product2,
        category: category,
        quantity: 3,
      );

      // Act
      list.setPurchasedProducts([purchasedProduct1, purchasedProduct2]);
      await repository.update(list);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('list-6');
      expect(result, isNotNull);
      expect(result!.getProducts().length, 2);
    });

    test('multiple consecutive updates maintain monotonic timestamps', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-7',
        name: 'Test',
        createdAt: DateTime.now(),
      );
      await repository.add(list);
      final timestamps = <DateTime>[];

      // Act & Assert
      for (int i = 0; i < 3; i++) {
        list.setName('Update $i');
        await repository.update(list);

        final result = await ManageShoppingList.getShoppingListById('list-7');
        timestamps.add(result!.lastModified!);

        if (i > 0) {
          expect(timestamps[i].isAfter(timestamps[i - 1]), true);
        }
      }
    });

    test('handles isInTheTrash flag updates', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-8',
        name: 'Test',
        createdAt: DateTime.now(),
        isInTheTrash: false,
      );
      await repository.add(list);

      // Act
      list.setIsInTheTrash(true);
      await repository.update(list);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('list-8');
      expect(result, isNotNull);
      expect(result!.getIsInTheTrash(), true);
    });
  });

  group('USER WRITE OPERATIONS - delete -', () {
    late ShoppingListRepositoryWithSync repository;

    setUp(() {
      repository = ShoppingListRepositoryWithSync();
    });

    test('marks shopping list as deleted (soft delete)', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-1',
        name: 'To Delete',
        createdAt: DateTime.now(),
      );
      await repository.add(list);

      // Act
      await repository.delete(list);

      // Assert
      final db = await DatabaseHelper.database;
      final rows = await db.query(
        'shopping_list',
        where: 'id = ?',
        whereArgs: ['list-1'],
      );
      expect(rows.isNotEmpty, true);
      expect(rows.first['is_deleted'], 1);
    });

    test('creates sync_box entry with delete operation', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-2',
        name: 'To Delete',
        createdAt: DateTime.now(),
      );
      await repository.add(list);

      // Clear sync box
      await ManageSyncBox.clearAllSyncEntries();

      // Act
      await repository.delete(list);

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'list-2',
        'shopping_list',
      );
      expect(syncEntry, isNotNull);
      expect(syncEntry!.operation, SyncOperation.delete);
    });

    test('updates timestamp on delete', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-3',
        name: 'To Delete',
        createdAt: DateTime(2024, 1, 1, 10, 0),
      );
      await repository.add(list);
      final originalTimestamp = list.lastModified;

      await Future.delayed(Duration(milliseconds: 2));

      // Act
      await repository.delete(list);

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'list-3',
        'shopping_list',
      );
      expect(syncEntry, isNotNull);
      expect(syncEntry!.lastModified.isAfter(originalTimestamp!), true);
    });

    test('cascade deletes all purchased products', () async {
      // Arrange
      final category = Category(id: 'cat-1', name: 'Fruits');
      final product1 = Product(id: 'prod-1', name: 'Apple');
      final product2 = Product(id: 'prod-2', name: 'Banana');

      final purchasedProduct1 = PurchasedProduct(
        listId: 'list-4',
        product: product1,
        category: category,
        quantity: 5,
      );
      final purchasedProduct2 = PurchasedProduct(
        listId: 'list-4',
        product: product2,
        category: category,
        quantity: 3,
      );

      final list = ShoppingList(
        id: 'list-4',
        name: 'To Delete',
        createdAt: DateTime.now(),
        products: [purchasedProduct1, purchasedProduct2],
      );
      await repository.add(list);

      // Act
      await repository.delete(list);

      // Assert
      final db = await DatabaseHelper.database;
      final productRows = await db.query(
        'purchased_product',
        where: 'list_id = ? AND is_deleted = 1',
        whereArgs: ['list-4'],
      );
      expect(productRows.length, 2);
    });

    test('creates sync_box entries for deleted products', () async {
      // Arrange
      final category = Category(id: 'cat-1', name: 'Fruits');
      final product1 = Product(id: 'prod-1', name: 'Apple');
      final purchasedProduct1 = PurchasedProduct(
        id: 'pp-1',
        listId: 'list-5',
        product: product1,
        category: category,
        quantity: 5,
      );

      final list = ShoppingList(
        id: 'list-5',
        name: 'To Delete',
        createdAt: DateTime.now(),
        products: [purchasedProduct1],
      );
      await repository.add(list);

      // Clear sync box to only track delete operations
      await ManageSyncBox.clearAllSyncEntries();

      // Act
      await repository.delete(list);

      // Assert
      final listSyncEntry = await ManageSyncBox.getSyncEntry(
        'list-5',
        'shopping_list',
      );
      expect(listSyncEntry, isNotNull);
      expect(listSyncEntry!.operation, SyncOperation.delete);

      final productSyncEntry = await ManageSyncBox.getSyncEntry(
        'pp-1',
        'purchased_product',
      );
      expect(productSyncEntry, isNotNull);
      expect(productSyncEntry!.operation, SyncOperation.delete);
    });

    test('handles deletion of shopping list without products', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-6',
        name: 'Empty List',
        createdAt: DateTime.now(),
      );
      await repository.add(list);

      // Clear sync box to only track delete operation
      await ManageSyncBox.clearAllSyncEntries();

      // Act
      await repository.delete(list);

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'list-6',
        'shopping_list',
      );
      expect(syncEntry, isNotNull);
      expect(syncEntry!.operation, SyncOperation.delete);
    });
  });

  group('QUERY OPERATIONS - getById, getAll -', () {
    late ShoppingListRepositoryWithSync repository;

    setUp(() {
      repository = ShoppingListRepositoryWithSync();
    });

    test('getById returns correct shopping list', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-1',
        name: 'Weekly Groceries',
        createdAt: DateTime.now(),
      );
      await repository.add(list);

      // Act
      final result = await repository.getById('list-1');

      // Assert
      expect(result, isNotNull);
      expect(result!.id, 'list-1');
      expect(result.getName(), 'Weekly Groceries');
    });

    test('getById returns null for non-existent shopping list', () async {
      // Act
      final result = await repository.getById('non-existent');

      // Assert
      expect(result, isNull);
    });

    test('getById excludes soft-deleted lists', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-deleted',
        name: 'Deleted List',
        createdAt: DateTime.now(),
      );
      await repository.add(list);
      await repository.delete(list);

      // Act
      final result = await repository.getById('list-deleted');

      // Assert
      expect(result, isNull);
    });

    test('getAll returns all shopping lists', () async {
      // Arrange
      final lists = [
        ShoppingList(id: 'list-1', name: 'List 1', createdAt: DateTime.now()),
        ShoppingList(id: 'list-2', name: 'List 2', createdAt: DateTime.now()),
        ShoppingList(id: 'list-3', name: 'List 3', createdAt: DateTime.now()),
      ];
      for (var l in lists) {
        await repository.add(l);
      }

      // Act
      final result = await repository.getAll();

      // Assert
      expect(result.length, 3);
      expect(
        result.map((l) => l.id).toList(),
        containsAll(['list-1', 'list-2', 'list-3']),
      );
    });

    test('getAll returns empty list when no shopping lists exist', () async {
      // Act
      final result = await repository.getAll();

      // Assert
      expect(result, isEmpty);
    });

    test('getAll excludes soft-deleted lists', () async {
      // Arrange
      final list1 = ShoppingList(id: 'list-1', name: 'List 1', createdAt: DateTime.now());
      final list2 = ShoppingList(id: 'list-2', name: 'List 2', createdAt: DateTime.now());
      await repository.add(list1);
      await repository.add(list2);
      await repository.delete(list1);

      // Act
      final result = await repository.getAll();

      // Assert
      expect(result.length, 1);
      expect(result.first.id, 'list-2');
    });

    test('getById preserves all shopping list properties', () async {
      // Arrange
      final supermarket = Supermarket(id: 'super-1', name: 'Carrefour');
      await ManageSupermarket.addSupermarket(supermarket);

      final category = Category(id: 'cat-1', name: 'Fruits');
      final product1 = Product(id: 'prod-1', name: 'Apple');
      final purchasedProduct1 = PurchasedProduct(
        listId: 'list-1',
        product: product1,
        category: category,
        quantity: 2,
        price: 50.25,
      );

      final list = ShoppingList(
        id: 'list-1',
        name: 'Test List',
        createdAt: DateTime.now(),
        supermarket: supermarket,
        products: [purchasedProduct1],
        isRegistered: true,
        isInTheTrash: false,
      );
      await repository.add(list);

      // Act
      final result = await repository.getById('list-1');

      // Assert
      expect(result, isNotNull);
      expect(result!.getName(), 'Test List');
      expect(result.getSupermarket()!.id, 'super-1');
      expect(result.getTotalPrice(), 50.25);
      expect(result.getIsRegistered(), true);
      expect(result.getIsInTheTrash(), false);
    });

    test('getById includes products', () async {
      // Arrange
      final category = Category(id: 'cat-1', name: 'Fruits');
      final product1 = Product(id: 'prod-1', name: 'Apple');
      final product2 = Product(id: 'prod-2', name: 'Banana');

      final purchasedProduct1 = PurchasedProduct(
        listId: 'list-1',
        product: product1,
        category: category,
        quantity: 5,
      );
      final purchasedProduct2 = PurchasedProduct(
        listId: 'list-1',
        product: product2,
        category: category,
        quantity: 3,
      );

      final list = ShoppingList(
        id: 'list-1',
        name: 'Fruits',
        createdAt: DateTime.now(),
        products: [purchasedProduct1, purchasedProduct2],
      );
      await repository.add(list);

      // Act
      final result = await repository.getById('list-1');

      // Assert
      expect(result, isNotNull);
      expect(result!.getProducts().length, 2);
    });
  });

  group('QUERY OPERATIONS - getLocalData -', () {
    late ShoppingListRepositoryWithSync repository;

    setUp(() {
      repository = ShoppingListRepositoryWithSync();
    });

    test('getLocalData returns null for non-existent shopping list', () async {
      // Act
      final result = await repository.getLocalData('non-existent');

      // Assert
      expect(result, isNull);
    });

    test('getLocalData returns database format for existing shopping list', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-1',
        name: 'Test List',
        createdAt: DateTime.now(),
        isRegistered: true,
      );
      await repository.add(list);

      // Act
      final result = await repository.getLocalData('list-1');

      // Assert
      expect(result, isNotNull);
      expect(result!['id'], 'list-1');
      expect(result['name'], 'Test List');
      expect(result['is_registered'], 1);
    });

    test('getLocalData includes soft-deleted shopping lists', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-deleted',
        name: 'Deleted List',
        createdAt: DateTime.now(),
      );
      await repository.add(list);
      await repository.delete(list);

      // Act
      final result = await repository.getLocalData('list-deleted');

      // Assert
      expect(result, isNotNull);
      expect(result!['id'], 'list-deleted');
      expect(result['is_deleted'], 1);
    });

    test('getLocalData used for LWW conflict resolution', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-lww-test',
        name: 'Local List',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 2, 10, 0),
      );
      await ManageShoppingList.addShoppingList(list);

      final remoteData = {
        'id': 'list-lww-test',
        'name': 'Remote List',
        'lastModified': '2024-01-01T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert - local should win
      final result = await ManageShoppingList.getShoppingListById('list-lww-test');
      expect(result!.getName(), 'Local List');
    });
  });

  group('REMOTE UPDATE OPERATIONS - applyRemoteUpdate -', () {
    late ShoppingListRepositoryWithSync repository;

    setUp(() {
      repository = ShoppingListRepositoryWithSync();
    });

    test('creates new shopping list from remote data', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-1',
        'name': 'Remote List',
        'isRegistered': false,
        'isInTheTrash': false,
        'createdAt': '2024-01-15T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('remote-1');
      expect(result, isNotNull);
      expect(result!.getName(), 'Remote List');
    });

    test('updates existing shopping list from remote data', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-1',
        name: 'Original Name',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageShoppingList.addShoppingList(list);

      final remoteData = {
        'id': 'list-1',
        'name': 'Updated from Remote',
        'isRegistered': true,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('list-1');
      expect(result, isNotNull);
      expect(result!.getName(), 'Updated from Remote');
      expect(result.getIsRegistered(), true);
    });

    test('does NOT create sync_box entry (silent update)', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-2',
        'name': 'Silent Update',
        'createdAt': '2024-01-15T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'remote-2',
        'shopping_list',
      );
      expect(syncEntry, isNull);
    });

    test('skips update if entity is dirty (has pending sync)', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-dirty',
        name: 'Local Modified',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await repository.add(list);

      final remoteData = {
        'id': 'list-dirty',
        'name': 'Remote Update',
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert - should keep local data
      final result = await ManageShoppingList.getShoppingListById('list-dirty');
      expect(result, isNotNull);
      expect(result!.getName(), 'Local Modified');
    });

    test('Last-Write-Wins: remote wins if newer', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-lww-1',
        name: 'Older Local',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageShoppingList.addShoppingList(list);

      final remoteData = {
        'id': 'list-lww-1',
        'name': 'Newer Remote',
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T12:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('list-lww-1');
      expect(result, isNotNull);
      expect(result!.getName(), 'Newer Remote');
    });

    test('Last-Write-Wins: local wins if newer', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-lww-2',
        name: 'Newer Local',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 3, 10, 0),
      );
      await ManageShoppingList.addShoppingList(list);

      final remoteData = {
        'id': 'list-lww-2',
        'name': 'Older Remote',
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('list-lww-2');
      expect(result, isNotNull);
      expect(result!.getName(), 'Newer Local');
    });

    test('handles soft delete from remote (isDeleted=true)', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-delete-1',
        name: 'To Be Deleted',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageShoppingList.addShoppingList(list);

      final remoteData = {
        'id': 'list-delete-1',
        'name': 'To Be Deleted',
        'isDeleted': true,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert - shopping list should be hard deleted
      final result = await ManageShoppingList.getShoppingListById('list-delete-1');
      expect(result, isNull);
    });

    test('handles soft delete with is_deleted=1', () async {
      // Arrange
      final list = ShoppingList(
        id: 'list-delete-2',
        name: 'To Be Deleted',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageShoppingList.addShoppingList(list);

      final remoteData = {
        'id': 'list-delete-2',
        'name': 'To Be Deleted',
        'is_deleted': 1,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('list-delete-2');
      expect(result, isNull);
    });

    test('deletes purchased_products on soft delete', () async {
      // Arrange
      final category = Category(id: 'cat-1', name: 'Fruits');
      final product = Product(id: 'prod-1', name: 'Apple');
      final purchasedProduct = PurchasedProduct(
        listId: 'list-delete-3',
        product: product,
        category: category,
        quantity: 5,
      );

      final list = ShoppingList(
        id: 'list-delete-3',
        name: 'To Be Deleted',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
        products: [purchasedProduct],
      );
      await ManageShoppingList.addShoppingList(list);

      final remoteData = {
        'id': 'list-delete-3',
        'isDeleted': true,
        'lastModified': '2024-01-02T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final db = await DatabaseHelper.database;
      final productRows = await db.query(
        'purchased_product',
        where: 'list_id = ?',
        whereArgs: ['list-delete-3'],
      );
      expect(productRows, isEmpty);
    });

    test('throws ArgumentError if id is missing', () async {
      // Arrange
      final remoteData = {
        'name': 'No ID',
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act & Assert
      expect(
        () => repository.applyRemoteUpdate(remoteData),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('handles missing lastModified with default', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-no-timestamp',
        'name': 'List Without Timestamp',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageShoppingList.getShoppingListById(
        'remote-no-timestamp',
      );
      expect(result, isNotNull);
      expect(result!.getName(), 'List Without Timestamp');
    });

    test('handles Firestore Timestamp format', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-firestore',
        'name': 'Firestore List',
        'lastModified': {
          '_seconds': 1705316400,
          '_nanoseconds': 0,
        },
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('remote-firestore');
      expect(result, isNotNull);
      expect(result!.getName(), 'Firestore List');
    });

    test('handles malformed Firestore Timestamp gracefully', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-bad-timestamp',
        'name': 'List With Bad Timestamp',
        'lastModified': {'_invalid': 'structure'},
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageShoppingList.getShoppingListById(
        'remote-bad-timestamp',
      );
      expect(result, isNotNull);
      expect(result!.getName(), 'List With Bad Timestamp');
    });

    test('converts Firebase boolean format correctly', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-bool-1',
        'name': 'Boolean Test',
        'isRegistered': true,
        'isInTheTrash': false,
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('remote-bool-1');
      expect(result, isNotNull);
      expect(result!.getIsRegistered(), true);
      expect(result.getIsInTheTrash(), false);
    });

    test('handles supermarketId update', () async {
      // Arrange
      final supermarket = Supermarket(id: 'super-1', name: 'Carrefour');
      await ManageSupermarket.addSupermarket(supermarket);

      final remoteData = {
        'id': 'remote-super',
        'name': 'List With Supermarket',
        'supermarketId': 'super-1',
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('remote-super');
      expect(result, isNotNull);
      expect(result!.getSupermarket(), isNotNull);
      expect(result.getSupermarket()!.id, 'super-1');
    });

    test('handles totalPrice update', () async {
      // Arrange
      final category = Category(id: 'cat-1', name: 'Fruits');
      final product = Product(id: 'prod-1', name: 'Apple');
      final purchasedProduct = PurchasedProduct(
        listId: 'remote-price',
        product: product,
        category: category,
        quantity: 3,
        price: 50.25,
      );

      final remoteData = {
        'id': 'remote-price',
        'name': 'List With Price',
        'totalPrice': 150.75,
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Manually add product since products are synced separately
      final db = await DatabaseHelper.database;
      await db.insert('purchased_product', purchasedProduct.toDatabase());

      // Assert
      final result = await ManageShoppingList.getShoppingListById('remote-price');
      expect(result, isNotNull);
      // totalPrice is computed from products, not stored value
      expect(result!.getTotalPrice(), 50.25);
    });
  });

  group('EDGE CASES - Timestamp Handling -', () {
    late ShoppingListRepositoryWithSync repository;

    setUp(() {
      repository = ShoppingListRepositoryWithSync();
    });

    test('handles string timestamp format ISO8601', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-iso-1',
        'name': 'ISO Timestamp',
        'lastModified': '2024-01-15T10:30:45.000Z',
        'createdAt': '2024-01-15T09:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('remote-iso-1');
      expect(result, isNotNull);
    });

    test('handles null timestamp gracefully', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-null-ts',
        'name': 'Null Timestamp',
        'lastModified': null,
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('remote-null-ts');
      expect(result, isNotNull);
      expect(result!.getName(), 'Null Timestamp');
    });

    test('handles invalid timestamp string gracefully', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-invalid-ts',
        'name': 'Invalid Timestamp',
        'lastModified': 'not-a-valid-timestamp',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('remote-invalid-ts');
      expect(result, isNotNull);
    });

    test('handles last_modified field (snake_case)', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-snake',
        'name': 'Snake Case',
        'last_modified': '2024-01-15T10:00:00.000Z',
        'created_at': '2024-01-15T09:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('remote-snake');
      expect(result, isNotNull);
    });

    test('handles deletionTimestamp field', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-deletion-ts',
        'name': 'With Deletion Timestamp',
        'deletionTimestamp': '2024-01-16T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageShoppingList.getShoppingListById('remote-deletion-ts');
      expect(result, isNotNull);
    });
  });

  group('INTEGRATION TESTS - Complete Workflows -', () {
    late ShoppingListRepositoryWithSync repository;

    setUp(() {
      repository = ShoppingListRepositoryWithSync();
    });

    test('complete workflow: add, update, query, delete', () async {
      // Add
      final list = ShoppingList(
        id: 'workflow-1',
        name: 'Shopping List',
        createdAt: DateTime.now(),
      );
      await repository.add(list);

      final addResult = await repository.getById('workflow-1');
      expect(addResult, isNotNull);
      expect(addResult!.getName(), 'Shopping List');

      // Update
      list.setName('Updated Shopping List');
      await repository.update(list);

      final updateResult = await repository.getById('workflow-1');
      expect(updateResult, isNotNull);
      expect(updateResult!.getName(), 'Updated Shopping List');

      // Delete
      await repository.delete(list);

      final deleteResult = await repository.getById('workflow-1');
      expect(deleteResult, isNull);
    });

    test('sync workflow: local add, remote update, LWW resolution', () async {
      // Local add
      final list = ShoppingList(
        id: 'sync-1',
        name: 'Local List',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await repository.add(list);

      // Clear sync to simulate sync completion
      await ManageSyncBox.clearAllSyncEntries();

      // Remote update (newer)
      final remoteData = {
        'id': 'sync-1',
        'name': 'Remote Update',
        'lastModified': '2024-01-02T10:00:00.000Z',
      };
      await repository.applyRemoteUpdate(remoteData);

      // Verify remote update applied
      final result = await repository.getById('sync-1');
      expect(result, isNotNull);
      expect(result!.getName(), 'Remote Update');
    });

    test('sync workflow: remote soft delete propagates to local', () async {
      // Add list locally
      final list = ShoppingList(
        id: 'sync-delete-1',
        name: 'To Delete',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await repository.add(list);

      // Clear sync box
      await ManageSyncBox.clearAllSyncEntries();

      // Remote sends soft delete
      final remoteData = {
        'id': 'sync-delete-1',
        'isDeleted': true,
        'lastModified': '2024-01-02T10:00:00.000Z',
      };
      await repository.applyRemoteUpdate(remoteData);

      // Verify local hard delete
      final result = await repository.getById('sync-delete-1');
      expect(result, isNull);

      // Verify no sync box entry created
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'sync-delete-1',
        'shopping_list',
      );
      expect(syncEntry, isNull);
    });

    test('complex workflow with products and supermarket', () async {
      // Setup supermarket
      final supermarket = Supermarket(id: 'super-1', name: 'Carrefour');
      await ManageSupermarket.addSupermarket(supermarket);

      // Setup products
      final category = Category(id: 'cat-1', name: 'Fruits');
      final product1 = Product(id: 'prod-1', name: 'Apple');
      final product2 = Product(id: 'prod-2', name: 'Banana');

      final purchasedProduct1 = PurchasedProduct(
        listId: 'complex-1',
        product: product1,
        category: category,
        quantity: 5,
      );
      final purchasedProduct2 = PurchasedProduct(
        listId: 'complex-1',
        product: product2,
        category: category,
        quantity: 3,
      );

      // Add list with all relationships
      final list = ShoppingList(
        id: 'complex-1',
        name: 'Complex List',
        createdAt: DateTime.now(),
        supermarket: supermarket,
        products: [purchasedProduct1, purchasedProduct2],
      );
      await repository.add(list);

      // Verify
      final result = await repository.getById('complex-1');
      expect(result, isNotNull);
      expect(result!.getSupermarket()!.id, 'super-1');
      expect(result.getProducts().length, 2);

      // Update
      list.setName('Updated Complex List');
      await repository.update(list);

      final updateResult = await repository.getById('complex-1');
      expect(updateResult!.getName(), 'Updated Complex List');

      // Delete (cascade)
      await repository.delete(list);

      final deleteResult = await repository.getById('complex-1');
      expect(deleteResult, isNull);
    });
  });
}
