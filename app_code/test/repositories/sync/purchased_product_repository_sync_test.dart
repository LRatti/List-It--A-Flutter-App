import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/repositories/sync/purchased_product_repository_sync.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_category.dart';
import 'package:app_code/services/database/sqlite/manage_product.dart';
import 'package:app_code/services/database/sqlite/manage_purchased_product.dart';
import 'package:app_code/services/database/sqlite/manage_sync_box.dart';
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
    await db.delete('purchased_product');
    await db.delete('product');
    await db.delete('category');
    await db.delete('sync_box');
  });

  group('USER WRITE OPERATIONS - add -', () {
    late PurchasedProductRepositoryWithSync repository;

    setUp(() {
      repository = PurchasedProductRepositoryWithSync();
    });

    test('saves purchased product to database with correct data', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Apple');
      final category = Category(id: 'cat-1', name: 'Fruits');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-1',
        listId: 'list-1',
        product: product,
        category: category,
        price: 2.5,
        quantity: 3,
      );

      // Act
      await repository.add(purchasedProduct);

      // Assert
      final result = await ManagePurchasedProduct.getPurchasedProductById('pp-1');
      expect(result, isNotNull);
      expect(result!.id, 'pp-1');
      expect(result.listId, 'list-1');
      expect(result.price, 2.5);
      expect(result.quantity, 3);
      expect(result.isBought, false);
    });

    test('sets createdAt timestamp on add', () async {
      // Arrange
      final beforeAdd = DateTime.now();
      final product = Product(id: 'prod-2', name: 'Banana');
      final category = Category(id: 'cat-2', name: 'Fruits');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-2',
        listId: 'list-1',
        product: product,
        category: category,
      );

      // Act
      await repository.add(purchasedProduct);

      // Assert
      final result = await ManagePurchasedProduct.getPurchasedProductById('pp-2');
      expect(result, isNotNull);
      expect(result!.createdAt, isNotNull);
      expect(
        result.createdAt.isAfter(beforeAdd.subtract(Duration(seconds: 1))),
        true,
      );
    });

    test('sets lastModified timestamp equal to createdAt on add', () async {
      // Arrange
      final product = Product(id: 'prod-3', name: 'Orange');
      final category = Category(id: 'cat-3', name: 'Citrus');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-3',
        listId: 'list-1',
        product: product,
        category: category,
      );

      // Act
      await repository.add(purchasedProduct);

      // Assert
      final result = await ManagePurchasedProduct.getPurchasedProductById('pp-3');
      expect(result, isNotNull);
      expect(result!.lastModified, isNotNull);
      expect(result.lastModified, equals(result.createdAt));
    });

    test('creates sync_box entry with upsert operation', () async {
      // Arrange
      final product = Product(id: 'prod-4', name: 'Grape');
      final category = Category(id: 'cat-4', name: 'Fruits');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-4',
        listId: 'list-1',
        product: product,
        category: category,
      );

      // Act
      await repository.add(purchasedProduct);

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'pp-4',
        'purchased_product',
      );
      expect(syncEntry, isNotNull);
      expect(syncEntry!.entityId, 'pp-4');
      expect(syncEntry.entityType, 'purchased_product');
      expect(syncEntry.operation, SyncOperation.upsert);
    });

    test('sync_box entry has same timestamp as purchased product', () async {
      // Arrange
      final product = Product(id: 'prod-5', name: 'Watermelon');
      final category = Category(id: 'cat-5', name: 'Fruits');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-5',
        listId: 'list-1',
        product: product,
        category: category,
      );

      // Act
      await repository.add(purchasedProduct);

      // Assert
      final result =
          await ManagePurchasedProduct.getPurchasedProductById('pp-5');
      final syncEntry =
          await ManageSyncBox.getSyncEntry('pp-5', 'purchased_product');
      expect(result, isNotNull);
      expect(syncEntry, isNotNull);
      expect(
        syncEntry!.lastModified.millisecondsSinceEpoch,
        result!.lastModified!.millisecondsSinceEpoch,
      );
    });

    test('handles multiple purchased product additions', () async {
      // Arrange
      final product1 = Product(id: 'prod-1', name: 'Apple');
      final product2 = Product(id: 'prod-2', name: 'Banana');
      final product3 = Product(id: 'prod-3', name: 'Orange');
      final category = Category(id: 'cat-1', name: 'Fruits');

      // Act
      await repository.add(PurchasedProduct(
        id: 'pp-1',
        listId: 'list-1',
        product: product1,
        category: category,
      ));
      await repository.add(PurchasedProduct(
        id: 'pp-2',
        listId: 'list-1',
        product: product2,
        category: category,
      ));
      await repository.add(PurchasedProduct(
        id: 'pp-3',
        listId: 'list-1',
        product: product3,
        category: category,
      ));

      // Assert
      final syncEntries = await ManageSyncBox.getAllSyncEntries(
        entityType: 'purchased_product',
      );
      expect(syncEntries.length, 3);
      expect(
        syncEntries.map((s) => s.entityId).toList(),
        containsAll(['pp-1', 'pp-2', 'pp-3']),
      );
    });

    test('handles purchased product with isBought status', () async {
      // Arrange
      final product = Product(id: 'prod-6', name: 'Milk');
      final category = Category(id: 'cat-6', name: 'Dairy');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-6',
        listId: 'list-1',
        product: product,
        category: category,
        isBought: true,
      );

      // Act
      await repository.add(purchasedProduct);

      // Assert
      final result =
          await ManagePurchasedProduct.getPurchasedProductById('pp-6');
      expect(result, isNotNull);
      expect(result!.isBought, true);
    });

    test('marks isDeleted as false on add', () async {
      // Arrange
      final product = Product(id: 'prod-7', name: 'Eggs');
      final category = Category(id: 'cat-7', name: 'Dairy');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-7',
        listId: 'list-1',
        product: product,
        category: category,
      );

      // Act
      await repository.add(purchasedProduct);

      // Assert
      final result =
          await ManagePurchasedProduct.getPurchasedProductById('pp-7');
      expect(result, isNotNull);
      expect(result!.isDeleted, false);
    });
  });

  group('USER WRITE OPERATIONS - update -', () {
    late PurchasedProductRepositoryWithSync repository;

    setUp(() {
      repository = PurchasedProductRepositoryWithSync();
    });

    test('updates purchased product in database', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Apple');
      final category = Category(id: 'cat-1', name: 'Fruits');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-1',
        listId: 'list-1',
        product: product,
        category: category,
        quantity: 3,
      );
      await repository.add(purchasedProduct);

      // Act
      purchasedProduct.quantity = 5;
      await repository.update(purchasedProduct);

      // Assert
      final result =
          await ManagePurchasedProduct.getPurchasedProductById('pp-1');
      expect(result, isNotNull);
      expect(result!.quantity, 5);
    });

    test('generates monotonic timestamp on update', () async {
      // Arrange
      final product = Product(id: 'prod-2', name: 'Banana');
      final category = Category(id: 'cat-2', name: 'Fruits');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-2',
        listId: 'list-1',
        product: product,
        category: category,
      );
      await repository.add(purchasedProduct);
      final originalTimestamp = purchasedProduct.lastModified;

      // Wait to ensure different timestamp
      await Future.delayed(Duration(milliseconds: 2));

      // Act
      purchasedProduct.price = 3.5;
      await repository.update(purchasedProduct);

      // Assert
      final result =
          await ManagePurchasedProduct.getPurchasedProductById('pp-2');
      expect(result, isNotNull);
      expect(result!.lastModified, isNotNull);
      expect(
        result.lastModified!.isAfter(originalTimestamp!),
        true,
      );
    });

    test('creates sync_box entry with upsert operation on update', () async {
      // Arrange
      final product = Product(id: 'prod-3', name: 'Orange');
      final category = Category(id: 'cat-3', name: 'Citrus');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-3',
        listId: 'list-1',
        product: product,
        category: category,
      );
      await repository.add(purchasedProduct);

      // Clear sync box to verify update creates new entry
      await ManageSyncBox.clearAllSyncEntries();

      // Act
      purchasedProduct.quantity = 2;
      await repository.update(purchasedProduct);

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'pp-3',
        'purchased_product',
      );
      expect(syncEntry, isNotNull);
      expect(syncEntry!.operation, SyncOperation.upsert);
    });

    test('updates sync_box entry with newer timestamp', () async {
      // Arrange
      final product = Product(id: 'prod-4', name: 'Grape');
      final category = Category(id: 'cat-4', name: 'Fruits');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-4',
        listId: 'list-1',
        product: product,
        category: category,
      );
      await repository.add(purchasedProduct);
      final firstSyncEntry = await ManageSyncBox.getSyncEntry(
        'pp-4',
        'purchased_product',
      );

      await Future.delayed(Duration(milliseconds: 2));

      // Act
      purchasedProduct.price = 1.5;
      await repository.update(purchasedProduct);

      // Assert
      final secondSyncEntry = await ManageSyncBox.getSyncEntry(
        'pp-4',
        'purchased_product',
      );
      expect(secondSyncEntry, isNotNull);
      expect(
        secondSyncEntry!.lastModified.isAfter(firstSyncEntry!.lastModified),
        true,
      );
    });

    test('handles isBought status update', () async {
      // Arrange
      final product = Product(id: 'prod-5', name: 'Milk');
      final category = Category(id: 'cat-5', name: 'Dairy');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-5',
        listId: 'list-1',
        product: product,
        category: category,
        isBought: false,
      );
      await repository.add(purchasedProduct);

      // Act
      purchasedProduct.isBought = true;
      await repository.update(purchasedProduct);

      // Assert
      final result =
          await ManagePurchasedProduct.getPurchasedProductById('pp-5');
      expect(result, isNotNull);
      expect(result!.isBought, true);
    });

    test('updates price field', () async {
      // Arrange
      final product = Product(id: 'prod-6', name: 'Cheese');
      final category = Category(id: 'cat-6', name: 'Dairy');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-6',
        listId: 'list-1',
        product: product,
        category: category,
        price: 2.0,
      );
      await repository.add(purchasedProduct);

      // Act
      purchasedProduct.price = 4.5;
      await repository.update(purchasedProduct);

      // Assert
      final result =
          await ManagePurchasedProduct.getPurchasedProductById('pp-6');
      expect(result, isNotNull);
      expect(result!.price, 4.5);
    });

    test('multiple consecutive updates maintain monotonic timestamps', () async {
      // Arrange
      final product = Product(id: 'prod-7', name: 'Bread');
      final category = Category(id: 'cat-7', name: 'Bakery');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-7',
        listId: 'list-1',
        product: product,
        category: category,
      );
      await repository.add(purchasedProduct);
      final timestamps = <DateTime>[];

      // Act & Assert
      for (int i = 0; i < 3; i++) {
        purchasedProduct.quantity = i;
        await repository.update(purchasedProduct);

        final result =
            await ManagePurchasedProduct.getPurchasedProductById('pp-7');
        timestamps.add(result!.lastModified!);

        if (i > 0) {
          expect(timestamps[i].isAfter(timestamps[i - 1]), true);
        }
      }
    });
  });

  group('USER WRITE OPERATIONS - deleteById -', () {
    late PurchasedProductRepositoryWithSync repository;

    setUp(() {
      repository = PurchasedProductRepositoryWithSync();
    });

    test('soft deletes purchased product from database', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Apple');
      final category = Category(id: 'cat-1', name: 'Fruits');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-1',
        listId: 'list-1',
        product: product,
        category: category,
      );
      await repository.add(purchasedProduct);

      // Act
      await repository.deleteById('pp-1');

      // Assert - Check that soft delete was applied
      final db = await DatabaseHelper.database;
      final rows = await db.query(
        'purchased_product',
        where: 'id = ?',
        whereArgs: ['pp-1'],
      );
      expect(rows.length, 1);
      expect(rows.first['is_deleted'], 1);
    });

    test('creates sync_box entry with delete operation', () async {
      // Arrange
      final product = Product(id: 'prod-2', name: 'Banana');
      final category = Category(id: 'cat-2', name: 'Fruits');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-2',
        listId: 'list-1',
        product: product,
        category: category,
      );
      await repository.add(purchasedProduct);

      // Clear sync box
      await ManageSyncBox.clearAllSyncEntries();

      // Act
      await repository.deleteById('pp-2');

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'pp-2',
        'purchased_product',
      );
      expect(syncEntry, isNotNull);
      expect(syncEntry!.operation, SyncOperation.delete);
    });

    test('preserves timestamp on delete', () async {
      // Arrange
      final product = Product(id: 'prod-3', name: 'Orange');
      final category = Category(id: 'cat-3', name: 'Citrus');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-3',
        listId: 'list-1',
        product: product,
        category: category,
        lastModified: DateTime(2024, 1, 15, 10, 30, 45),
        createdAt: DateTime(2024, 1, 15, 10, 30, 45),
      );
      await ManagePurchasedProduct.addPurchasedProduct(purchasedProduct);

      // Act
      await repository.deleteById('pp-3');

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'pp-3',
        'purchased_product',
      );
      expect(syncEntry, isNotNull);
      expect(
        syncEntry!.lastModified.isAfter(DateTime(2024, 1, 15, 10, 30, 44)),
        true,
      );
    });

    test('deletion fails silently for non-existent purchased product',
        () async {
      // Arrange & Act & Assert
      expect(() => repository.deleteById('non-existent'), returnsNormally);
    });

    test('delete method delegates to deleteById', () async {
      // Arrange
      final product = Product(id: 'prod-4', name: 'Grape');
      final category = Category(id: 'cat-4', name: 'Fruits');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-4',
        listId: 'list-1',
        product: product,
        category: category,
      );
      await repository.add(purchasedProduct);

      // Act
      await repository.delete(purchasedProduct);

      // Assert
      final db = await DatabaseHelper.database;
      final rows = await db.query(
        'purchased_product',
        where: 'id = ?',
        whereArgs: ['pp-4'],
      );
      expect(rows.first['is_deleted'], 1);
    });
  });

  group('QUERY OPERATIONS - getById, getLocalData -', () {
    late PurchasedProductRepositoryWithSync repository;

    setUp(() {
      repository = PurchasedProductRepositoryWithSync();
    });

    test('getById returns correct purchased product', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Apple');
      final category = Category(id: 'cat-1', name: 'Fruits');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-1',
        listId: 'list-1',
        product: product,
        category: category,
        price: 2.5,
      );
      await repository.add(purchasedProduct);

      // Act
      final result = await repository.getById('pp-1');

      // Assert
      expect(result, isNotNull);
      expect(result!.id, 'pp-1');
      expect(result.listId, 'list-1');
      expect(result.price, 2.5);
    });

    test('getById returns null for non-existent purchased product', () async {
      // Act
      final result = await repository.getById('non-existent');

      // Assert
      expect(result, isNull);
    });

    test('getLocalData returns null for non-existent purchased product',
        () async {
      // Act
      final result = await repository.getLocalData('non-existent');

      // Assert
      expect(result, isNull);
    });

    test('getLocalData returns database format for existing purchased product',
        () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Apple');
      final category = Category(id: 'cat-1', name: 'Fruits');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-1',
        listId: 'list-1',
        product: product,
        category: category,
        price: 2.5,
        quantity: 3,
      );
      await repository.add(purchasedProduct);

      // Act
      final result = await repository.getLocalData('pp-1');

      // Assert
      expect(result, isNotNull);
      expect(result!['id'], 'pp-1');
      expect(result['list_id'], 'list-1');
      expect(result['price'], 2.5);
      expect(result['quantity'], 3);
    });

    test('getById preserves all purchased product properties', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Test Product');
      final category = Category(id: 'cat-1', name: 'Test Category');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-1',
        listId: 'list-1',
        product: product,
        category: category,
        price: 3.5,
        quantity: 2,
        isBought: true,
      );
      await repository.add(purchasedProduct);

      // Act
      final result = await repository.getById('pp-1');

      // Assert
      expect(result, isNotNull);
      expect(result!.listId, 'list-1');
      expect(result.price, 3.5);
      expect(result.quantity, 2);
      expect(result.isBought, true);
    });
  });

  group('REMOTE UPDATE OPERATIONS - applyRemoteUpdate -', () {
    late PurchasedProductRepositoryWithSync repository;

    setUp(() {
      repository = PurchasedProductRepositoryWithSync();
    });

    test('creates new purchased product from remote data', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Remote Product');
      final category = Category(id: 'cat-1', name: 'Remote Category');
      await ManageProduct.addProduct(product);
      await ManageCategory.addCategory(category);

      final remoteData = {
        'id': 'remote-pp-1',
        'listId': 'list-1',
        'productId': 'prod-1',
        'categoryId': 'cat-1',
        'price': 1.5,
        'quantity': 2,
        'createdAt': '2024-01-15T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result =
          await ManagePurchasedProduct.getPurchasedProductById('remote-pp-1');
      expect(result, isNotNull);
      expect(result!.listId, 'list-1');
      expect(result.price, 1.5);
      expect(result.quantity, 2);
    });

    test('updates existing purchased product from remote data', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Original Product');
      final category = Category(id: 'cat-1', name: 'Original Category');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-1',
        listId: 'list-1',
        product: product,
        category: category,
        price: 1.0,
        quantity: 1,
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManagePurchasedProduct.addPurchasedProduct(purchasedProduct);

      final remoteData = {
        'id': 'pp-1',
        'listId': 'list-1',
        'productId': 'prod-1',
        'categoryId': 'cat-1',
        'price': 2.5,
        'quantity': 3,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result =
          await ManagePurchasedProduct.getPurchasedProductById('pp-1');
      expect(result, isNotNull);
      expect(result!.price, 2.5);
      expect(result.quantity, 3);
    });

    test('does NOT create sync_box entry (silent update)', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Silent Update');
      final category = Category(id: 'cat-1', name: 'Remote Category');
      await ManageProduct.addProduct(product);
      await ManageCategory.addCategory(category);

      final remoteData = {
        'id': 'remote-pp-2',
        'listId': 'list-1',
        'productId': 'prod-1',
        'categoryId': 'cat-1',
        'price': 1.5,
        'createdAt': '2024-01-15T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'remote-pp-2',
        'purchased_product',
      );
      expect(syncEntry, isNull);
    });

    test('skips update if entity is dirty (has pending sync)', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Dirty Product');
      final category = Category(id: 'cat-1', name: 'Dirty Category');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-dirty',
        listId: 'list-1',
        product: product,
        category: category,
        price: 1.0,
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await repository.add(purchasedProduct);

      final remoteData = {
        'id': 'pp-dirty',
        'listId': 'list-1',
        'productId': 'prod-1',
        'categoryId': 'cat-1',
        'price': 5.0,
        'quantity': 10,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert - should keep local data
      final result =
          await ManagePurchasedProduct.getPurchasedProductById('pp-dirty');
      expect(result, isNotNull);
      expect(result!.price, 1.0);
    });

    test('Last-Write-Wins: remote wins if newer', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'LWW Product');
      final category = Category(id: 'cat-1', name: 'LWW Category');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-lww-1',
        listId: 'list-1',
        product: product,
        category: category,
        price: 1.0,
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManagePurchasedProduct.addPurchasedProduct(purchasedProduct);

      final remoteData = {
        'id': 'pp-lww-1',
        'listId': 'list-1',
        'productId': 'prod-1',
        'categoryId': 'cat-1',
        'price': 3.0,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T12:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result =
          await ManagePurchasedProduct.getPurchasedProductById('pp-lww-1');
      expect(result, isNotNull);
      expect(result!.price, 3.0);
    });

    test('Last-Write-Wins: local wins if newer', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'LWW Product Local');
      final category = Category(id: 'cat-1', name: 'LWW Category Local');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-lww-2',
        listId: 'list-1',
        product: product,
        category: category,
        price: 5.0,
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 3, 10, 0),
      );
      await ManagePurchasedProduct.addPurchasedProduct(purchasedProduct);

      final remoteData = {
        'id': 'pp-lww-2',
        'listId': 'list-1',
        'productId': 'prod-1',
        'categoryId': 'cat-1',
        'price': 1.0,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result =
          await ManagePurchasedProduct.getPurchasedProductById('pp-lww-2');
      expect(result, isNotNull);
      expect(result!.price, 5.0);
    });

    test('handles soft delete from remote (isDeleted=true)', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'To Delete');
      final category = Category(id: 'cat-1', name: 'Delete Category');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-delete-1',
        listId: 'list-1',
        product: product,
        category: category,
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManagePurchasedProduct.addPurchasedProduct(purchasedProduct);

      final remoteData = {
        'id': 'pp-delete-1',
        'isDeleted': true,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert - purchased product should be hard deleted
      final result =
          await ManagePurchasedProduct.getPurchasedProductById('pp-delete-1');
      expect(result, isNull);
    });

    test('handles soft delete with is_deleted=1', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Delete Via Flag');
      final category = Category(id: 'cat-1', name: 'Delete Category');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-delete-2',
        listId: 'list-1',
        product: product,
        category: category,
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManagePurchasedProduct.addPurchasedProduct(purchasedProduct);

      final remoteData = {
        'id': 'pp-delete-2',
        'is_deleted': 1,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result =
          await ManagePurchasedProduct.getPurchasedProductById('pp-delete-2');
      expect(result, isNull);
    });

    test('throws ArgumentError if id is missing', () async {
      // Arrange
      final remoteData = {
        'listId': 'list-1',
        'price': 1.5,
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
      final product = Product(id: 'prod-1', name: 'No Timestamp');
      final category = Category(id: 'cat-1', name: 'No Timestamp Cat');
      await ManageProduct.addProduct(product);
      await ManageCategory.addCategory(category);

      final remoteData = {
        'id': 'remote-no-timestamp',
        'listId': 'list-1',
        'productId': 'prod-1',
        'categoryId': 'cat-1',
        'price': 2.5,
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManagePurchasedProduct.getPurchasedProductById(
        'remote-no-timestamp',
      );
      expect(result, isNotNull);
      expect(result!.price, 2.5);
    });

    test('handles Firestore Timestamp format', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Firestore Product');
      final category = Category(id: 'cat-1', name: 'Firestore Category');
      await ManageProduct.addProduct(product);
      await ManageCategory.addCategory(category);

      final remoteData = {
        'id': 'remote-firestore',
        'listId': 'list-1',
        'productId': 'prod-1',
        'categoryId': 'cat-1',
        'price': 1.5,
        'lastModified': {
          '_seconds': 1705316400,
          '_nanoseconds': 0,
        },
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManagePurchasedProduct.getPurchasedProductById(
        'remote-firestore',
      );
      expect(result, isNotNull);
      expect(result!.price, 1.5);
    });

    test('handles malformed Firestore Timestamp gracefully', () async {
      // Arrange
      final product =
          Product(id: 'prod-1', name: 'Bad Timestamp Product');
      final category = Category(id: 'cat-1', name: 'Bad Timestamp Category');
      await ManageProduct.addProduct(product);
      await ManageCategory.addCategory(category);

      final remoteData = {
        'id': 'remote-bad-timestamp',
        'listId': 'list-1',
        'productId': 'prod-1',
        'categoryId': 'cat-1',
        'price': 2.0,
        'lastModified': {'_invalid': 'structure'},
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManagePurchasedProduct.getPurchasedProductById(
        'remote-bad-timestamp',
      );
      expect(result, isNotNull);
      expect(result!.price, 2.0);
    });

    test('handles camelCase to snake_case conversion', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Case Product');
      final category = Category(id: 'cat-1', name: 'Case Category');
      await ManageProduct.addProduct(product);
      await ManageCategory.addCategory(category);

      final remoteData = {
        'id': 'remote-case-1',
        'listId': 'list-1',
        'productId': 'prod-1',
        'categoryId': 'cat-1',
        'price': 3.5,
        'quantity': 5,
        'createdAt': '2024-01-15T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManagePurchasedProduct.getPurchasedProductById(
        'remote-case-1',
      );
      expect(result, isNotNull);
      expect(result!.price, 3.5);
      expect(result.quantity, 5);
    });

    test('upserts related product from remote data', () async {
      // Arrange
      // Product doesn't exist yet - it will be created from remote data
      final remoteData = {
        'id': 'remote-with-product',
        'listId': 'list-1',
        'productId': 'prod-new',
        'categoryId': 'cat-1',
        'price': 1.5,
        'product': {
          'id': 'prod-new',
          'name': 'New Product from Remote',
          'isVisible': true,
          'createdAt': '2024-01-15T10:00:00.000Z',
          'lastModified': '2024-01-15T10:00:00.000Z',
        },
        'category': {
          'id': 'cat-1',
          'name': 'Remote Category',
          'createdAt': '2024-01-15T10:00:00.000Z',
          'lastModified': '2024-01-15T10:00:00.000Z',
        },
        'createdAt': '2024-01-15T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final product = await ManageProduct.getProductById('prod-new');
      expect(product, isNotNull);
      expect(product!.getName(), 'New Product from Remote');

      final category = await ManageCategory.getCategoryById('cat-1');
      expect(category, isNotNull);
      expect(category!.getName(), 'Remote Category');
    });

    test('handles isDeleted boolean conversion', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Boolean Product');
      final category = Category(id: 'cat-1', name: 'Boolean Category');
      await ManageProduct.addProduct(product);
      await ManageCategory.addCategory(category);

      final remoteData = {
        'id': 'remote-bool-1',
        'listId': 'list-1',
        'productId': 'prod-1',
        'categoryId': 'cat-1',
        'price': 1.5,
        'isDeleted': false,
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManagePurchasedProduct.getPurchasedProductById(
        'remote-bool-1',
      );
      expect(result, isNotNull);
      expect(result!.price, 1.5);
    });

    test('handles zero price and quantity', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Free Product');
      final category = Category(id: 'cat-1', name: 'Free Category');
      await ManageProduct.addProduct(product);
      await ManageCategory.addCategory(category);

      final remoteData = {
        'id': 'remote-zero',
        'listId': 'list-1',
        'productId': 'prod-1',
        'categoryId': 'cat-1',
        'price': 0.0,
        'quantity': 0,
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result =
          await ManagePurchasedProduct.getPurchasedProductById('remote-zero');
      expect(result, isNotNull);
      expect(result!.price, 0.0);
      expect(result.quantity, 0);
    });
  });

  group('EDGE CASES - Timestamp Handling -', () {
    late PurchasedProductRepositoryWithSync repository;

    setUp(() {
      repository = PurchasedProductRepositoryWithSync();
    });

    test('handles string timestamp format ISO8601', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'ISO Product');
      final category = Category(id: 'cat-1', name: 'ISO Category');
      await ManageProduct.addProduct(product);
      await ManageCategory.addCategory(category);

      final remoteData = {
        'id': 'remote-iso-1',
        'listId': 'list-1',
        'productId': 'prod-1',
        'categoryId': 'cat-1',
        'price': 1.5,
        'createdAt': '2024-01-15T10:00:00.000Z',
        'lastModified': '2024-01-15T12:30:45.123Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result =
          await ManagePurchasedProduct.getPurchasedProductById('remote-iso-1');
      expect(result, isNotNull);
    });

    test('handles null timestamp gracefully', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Null Timestamp');
      final category = Category(id: 'cat-1', name: 'Null Category');
      await ManageProduct.addProduct(product);
      await ManageCategory.addCategory(category);

      final remoteData = {
        'id': 'remote-null-ts',
        'listId': 'list-1',
        'productId': 'prod-1',
        'categoryId': 'cat-1',
        'price': 2.0,
        'lastModified': null,
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManagePurchasedProduct.getPurchasedProductById(
        'remote-null-ts',
      );
      expect(result, isNotNull);
      expect(result!.price, 2.0);
    });

    test('handles invalid timestamp string gracefully', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Invalid Timestamp');
      final category = Category(id: 'cat-1', name: 'Invalid Category');
      await ManageProduct.addProduct(product);
      await ManageCategory.addCategory(category);

      final remoteData = {
        'id': 'remote-invalid-ts',
        'listId': 'list-1',
        'productId': 'prod-1',
        'categoryId': 'cat-1',
        'price': 3.0,
        'lastModified': 'not-a-valid-timestamp',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManagePurchasedProduct.getPurchasedProductById(
        'remote-invalid-ts',
      );
      expect(result, isNotNull);
    });

    test('handles last_modified field (snake_case)', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Snake Case Product');
      final category = Category(id: 'cat-1', name: 'Snake Case Category');
      await ManageProduct.addProduct(product);
      await ManageCategory.addCategory(category);

      final remoteData = {
        'id': 'remote-snake',
        'list_id': 'list-1',
        'product_id': 'prod-1',
        'category_id': 'cat-1',
        'price': 1.5,
        'last_modified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result =
          await ManagePurchasedProduct.getPurchasedProductById('remote-snake');
      expect(result, isNotNull);
    });
  });

  group('INTEGRATION TESTS - Complete Workflows -', () {
    late PurchasedProductRepositoryWithSync repository;

    setUp(() {
      repository = PurchasedProductRepositoryWithSync();
    });

    test('complete workflow: add, update, query, delete', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Test Product');
      final category = Category(id: 'cat-1', name: 'Test Category');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-integration-1',
        listId: 'list-1',
        product: product,
        category: category,
        price: 1.0,
        quantity: 1,
      );

      // Act 1: Add
      await repository.add(purchasedProduct);

      // Assert 1: Added
      var result = await repository.getById('pp-integration-1');
      expect(result, isNotNull);
      expect(result!.price, 1.0);

      var syncEntry = await ManageSyncBox.getSyncEntry(
        'pp-integration-1',
        'purchased_product',
      );
      expect(syncEntry!.operation, SyncOperation.upsert);

      // Act 2: Update
      purchasedProduct.price = 2.5;
      purchasedProduct.quantity = 3;
      await repository.update(purchasedProduct);

      // Assert 2: Updated
      result = await repository.getById('pp-integration-1');
      expect(result!.price, 2.5);
      expect(result.quantity, 3);

      // Act 3: Delete
      await repository.deleteById('pp-integration-1');

      // Assert 3: Deleted (soft delete)
      final db = await DatabaseHelper.database;
      final rows = await db.query(
        'purchased_product',
        where: 'id = ?',
        whereArgs: ['pp-integration-1'],
      );
      expect(rows.first['is_deleted'], 1);

      syncEntry = await ManageSyncBox.getSyncEntry(
        'pp-integration-1',
        'purchased_product',
      );
      expect(syncEntry!.operation, SyncOperation.delete);
    });

    test('local write followed by remote update respects Last-Write-Wins',
        () async {
      // Arrange: Create initial state
      final product = Product(id: 'prod-1', name: 'LWW Product');
      final category = Category(id: 'cat-1', name: 'LWW Category');
      final purchasedProduct = PurchasedProduct(
        id: 'pp-lww-workflow',
        listId: 'list-1',
        product: product,
        category: category,
        price: 1.0,
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await repository.add(purchasedProduct);

      // Act 1: Local update (makes item dirty)
      await Future.delayed(Duration(milliseconds: 10));
      purchasedProduct.price = 3.0;
      await repository.update(purchasedProduct);

      // Assert 1: Sync entry exists (dirty state)
      var syncEntry = await ManageSyncBox.getSyncEntry(
        'pp-lww-workflow',
        'purchased_product',
      );
      expect(syncEntry, isNotNull);

      // Act 2: Remote update arrives (older than local)
      final remoteData = {
        'id': 'pp-lww-workflow',
        'listId': 'list-1',
        'productId': 'prod-1',
        'categoryId': 'cat-1',
        'price': 0.5, // Older remote price
        'lastModified': '2024-01-01T10:00:00.000Z', // Older timestamp
      };
      await repository.applyRemoteUpdate(remoteData);

      // Assert 2: Local should win (not updated)
      var result = await repository.getById('pp-lww-workflow');
      expect(result!.price, 3.0);
    });

    test('multiple purchased products in same list', () async {
      // Arrange
      final product1 = Product(id: 'prod-1', name: 'Apple');
      final product2 = Product(id: 'prod-2', name: 'Banana');
      final category = Category(id: 'cat-1', name: 'Fruits');

      final pp1 = PurchasedProduct(
        id: 'pp-multi-1',
        listId: 'list-1',
        product: product1,
        category: category,
        price: 1.0,
      );
      final pp2 = PurchasedProduct(
        id: 'pp-multi-2',
        listId: 'list-1',
        product: product2,
        category: category,
        price: 2.0,
      );

      // Act
      await repository.add(pp1);
      await repository.add(pp2);

      // Assert
      var result1 = await repository.getById('pp-multi-1');
      var result2 = await repository.getById('pp-multi-2');
      expect(result1!.price, 1.0);
      expect(result2!.price, 2.0);

      var syncEntries = await ManageSyncBox.getAllSyncEntries(
        entityType: 'purchased_product',
      );
      expect(syncEntries.length, 2);
    });
  });
}
