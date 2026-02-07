import 'package:app_code/models/product.dart';
import 'package:app_code/repositories/sync/product_repository_sync.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_product.dart';
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
    await db.delete('product');
    await db.delete('associations');
    await db.delete('sync_box');
  });

  group('USER WRITE OPERATIONS - add -', () {
    late ProductRepositoryWithSync repository;

    setUp(() {
      repository = ProductRepositoryWithSync();
    });

    test('saves product to database with correct data', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        associations: {},
        isVisible: true,
      );

      // Act
      await repository.add(product);

      // Assert
      final result = await ManageProduct.getProductById('prod-1');
      expect(result, isNotNull);
      expect(result!.id, 'prod-1');
      expect(result.getName(), 'Apple');
      expect(result.isVisible, true);
    });

    test('sets createdAt timestamp on add', () async {
      // Arrange
      final beforeAdd = DateTime.now();
      final product = Product(
        id: 'prod-2',
        name: 'Banana',
      );

      // Act
      await repository.add(product);

      // Assert
      final result = await ManageProduct.getProductById('prod-2');
      expect(result, isNotNull);
      expect(result!.createdAt, isNotNull);
      expect(
        result.createdAt.isAfter(beforeAdd.subtract(Duration(seconds: 1))),
        true,
      );
    });

    test('sets lastModified timestamp equal to createdAt on add', () async {
      // Arrange
      final product = Product(
        id: 'prod-3',
        name: 'Orange',
      );

      // Act
      await repository.add(product);

      // Assert
      final result = await ManageProduct.getProductById('prod-3');
      expect(result, isNotNull);
      expect(result!.lastModified, isNotNull);
      expect(result.lastModified, equals(result.createdAt));
    });

    test('creates sync_box entry with upsert operation', () async {
      // Arrange
      final product = Product(
        id: 'prod-4',
        name: 'Grape',
      );

      // Act
      await repository.add(product);

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'prod-4',
        'product',
      );
      expect(syncEntry, isNotNull);
      expect(syncEntry!.entityId, 'prod-4');
      expect(syncEntry.entityType, 'product');
      expect(syncEntry.operation, SyncOperation.upsert);
    });

    test('sync_box entry has same timestamp as product', () async {
      // Arrange
      final product = Product(
        id: 'prod-5',
        name: 'Watermelon',
      );

      // Act
      await repository.add(product);

      // Assert
      final result = await ManageProduct.getProductById('prod-5');
      final syncEntry = await ManageSyncBox.getSyncEntry('prod-5', 'product');
      expect(result, isNotNull);
      expect(syncEntry, isNotNull);
      expect(
        syncEntry!.lastModified.millisecondsSinceEpoch,
        result!.lastModified!.millisecondsSinceEpoch,
      );
    });

    test('handles product with associations', () async {
      // Arrange
      final product = Product(
        id: 'prod-6',
        name: 'Milk',
        associations: {
          'super-1': 'dairy-cat',
          'super-2': 'drinks-cat',
        },
      );

      // Act
      await repository.add(product);

      // Assert
      final result = await ManageProduct.getProductById('prod-6');
      expect(result, isNotNull);
      expect(result!.associations.length, 2);
      expect(result.associations['super-1'], 'dairy-cat');
      expect(result.associations['super-2'], 'drinks-cat');
    });

    test('handles multiple product additions', () async {
      // Arrange
      final products = [
        Product(id: 'prod-a', name: 'Product A'),
        Product(id: 'prod-b', name: 'Product B'),
        Product(id: 'prod-c', name: 'Product C'),
      ];

      // Act
      for (var product in products) {
        await repository.add(product);
      }

      // Assert
      final allProducts = await ManageProduct.getAllProducts();
      expect(allProducts.length, 3);
      expect(
        allProducts.map((p) => p.id).toList(),
        containsAll(['prod-a', 'prod-b', 'prod-c']),
      );

      final syncEntries = await ManageSyncBox.getAllSyncEntries(
        entityType: 'product',
      );
      expect(syncEntries.length, 3);
    });
  });

  group('USER WRITE OPERATIONS - update -', () {
    late ProductRepositoryWithSync repository;

    setUp(() {
      repository = ProductRepositoryWithSync();
    });

    test('updates product in database', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Original Name');
      await repository.add(product);

      // Act
      product.setName('Updated Name');
      await repository.update(product);

      // Assert
      final result = await ManageProduct.getProductById('prod-1');
      expect(result, isNotNull);
      expect(result!.getName(), 'Updated Name');
    });

    test('generates monotonic timestamp on update', () async {
      // Arrange
      final product = Product(id: 'prod-2', name: 'Test Product');
      await repository.add(product);
      final originalTimestamp = product.lastModified;

      // Wait a tiny bit to ensure different timestamp
      await Future.delayed(Duration(milliseconds: 2));

      // Act
      product.setName('Modified Name');
      await repository.update(product);

      // Assert
      final result = await ManageProduct.getProductById('prod-2');
      expect(result, isNotNull);
      expect(result!.lastModified, isNotNull);
      expect(
        result.lastModified!.isAfter(originalTimestamp!),
        true,
      );
    });

    test('creates sync_box entry with upsert operation on update', () async {
      // Arrange
      final product = Product(id: 'prod-3', name: 'Test');
      await repository.add(product);

      // Clear sync box to verify update creates new entry
      await ManageSyncBox.clearAllSyncEntries();

      // Act
      product.setName('Updated Test');
      await repository.update(product);

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry('prod-3', 'product');
      expect(syncEntry, isNotNull);
      expect(syncEntry!.operation, SyncOperation.upsert);
    });

    test('updates sync_box entry with newer timestamp', () async {
      // Arrange
      final product = Product(id: 'prod-4', name: 'Test');
      await repository.add(product);
      final firstSyncEntry = await ManageSyncBox.getSyncEntry(
        'prod-4',
        'product',
      );

      await Future.delayed(Duration(milliseconds: 2));

      // Act
      product.setName('Updated');
      await repository.update(product);

      // Assert
      final secondSyncEntry = await ManageSyncBox.getSyncEntry(
        'prod-4',
        'product',
      );
      expect(secondSyncEntry, isNotNull);
      expect(
        secondSyncEntry!.lastModified.isAfter(firstSyncEntry!.lastModified),
        true,
      );
    });

    test('handles visibility updates', () async {
      // Arrange
      final product = Product(id: 'prod-5', name: 'Test', isVisible: true);
      await repository.add(product);

      // Act
      product.setVisibility(false);
      await repository.update(product);

      // Assert
      final result = await ManageProduct.getProductById('prod-5');
      expect(result, isNotNull);
      expect(result!.isVisible, false);
    });

    test('handles product associations update', () async {
      // Arrange
      final product = Product(
        id: 'prod-6',
        name: 'Test',
        associations: {'super-1': 'cat-1'},
      );
      await repository.add(product);

      // Act
      product.setAssociations({
        'super-1': 'cat-2',
        'super-2': 'cat-3',
      });
      await repository.update(product);

      // Assert
      final result = await ManageProduct.getProductById('prod-6');
      expect(result, isNotNull);
      expect(result!.associations.length, 2);
      expect(result.associations['super-1'], 'cat-2');
      expect(result.associations['super-2'], 'cat-3');
    });
  });

  group('USER WRITE OPERATIONS - deleteById -', () {
    late ProductRepositoryWithSync repository;

    setUp(() {
      repository = ProductRepositoryWithSync();
    });

    test('removes product from database', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'To Delete');
      await repository.add(product);

      // Act
      await repository.deleteById('prod-1');

      // Assert
      final result = await ManageProduct.getProductById('prod-1');
      expect(result, isNull);
    });

    test('creates sync_box entry with delete operation', () async {
      // Arrange
      final product = Product(id: 'prod-2', name: 'To Delete');
      await repository.add(product);

      // Clear sync box
      await ManageSyncBox.clearAllSyncEntries();

      // Act
      await repository.deleteById('prod-2');

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry('prod-2', 'product');
      expect(syncEntry, isNotNull);
      expect(syncEntry!.operation, SyncOperation.delete);
    });

    test('deletes associated associations entries', () async {
      // Arrange
      final db = await DatabaseHelper.database;
      final product = Product(
        id: 'prod-3',
        name: 'To Delete',
        associations: {
          'super-1': 'cat-1',
          'super-2': 'cat-2',
        },
      );
      await repository.add(product);

      // Act
      await repository.deleteById('prod-3');

      // Assert
      final associations = await db.query(
        'associations',
        where: 'product_id = ?',
        whereArgs: ['prod-3'],
      );
      expect(associations, isEmpty);
    });

    test('preserves lastModified timestamp in delete sync entry', () async {
      // Arrange
      final product = Product(id: 'prod-4', name: 'To Delete');
      await repository.add(product);
      final originalTimestamp = product.lastModified;

      // Clear sync box
      await ManageSyncBox.clearAllSyncEntries();

      // Act
      await repository.deleteById('prod-4');

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry('prod-4', 'product');
      expect(syncEntry, isNotNull);
      expect(
        syncEntry!.lastModified.millisecondsSinceEpoch,
        originalTimestamp!.millisecondsSinceEpoch,
      );
    });
  });

  group('REMOTE UPDATE OPERATIONS - applyRemoteUpdate -', () {
    late ProductRepositoryWithSync repository;

    setUp(() {
      repository = ProductRepositoryWithSync();
    });

    test('inserts new product from remote data', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-1',
        'name': 'Remote Product',
        'isVisible': true,
        'createdAt': '2024-01-15T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageProduct.getProductById('remote-1');
      expect(result, isNotNull);
      expect(result!.getName(), 'Remote Product');
      expect(result.isVisible, true);
    });

    test('updates existing product from remote data', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Original',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      final remoteData = {
        'id': 'prod-1',
        'name': 'Updated from Remote',
        'isVisible': false,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageProduct.getProductById('prod-1');
      expect(result, isNotNull);
      expect(result!.getName(), 'Updated from Remote');
      expect(result.isVisible, false);
    });

    test('does NOT create sync_box entry (silent update)', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-2',
        'name': 'Silent Update',
        'isVisible': true,
        'createdAt': '2024-01-15T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'remote-2',
        'product',
      );
      expect(syncEntry, isNull);
    });

    test('skips update if entity is dirty (has pending sync)', () async {
      // Arrange
      final product = Product(
        id: 'prod-dirty',
        name: 'Local Modified',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await repository.add(product);

      final remoteData = {
        'id': 'prod-dirty',
        'name': 'Remote Update',
        'isVisible': false,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert - should keep local data
      final result = await ManageProduct.getProductById('prod-dirty');
      expect(result, isNotNull);
      expect(result!.getName(), 'Local Modified');
    });

    test('Last-Write-Wins: remote wins if newer', () async {
      // Arrange
      final product = Product(
        id: 'prod-lww-1',
        name: 'Older Local',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      final remoteData = {
        'id': 'prod-lww-1',
        'name': 'Newer Remote',
        'isVisible': true,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T12:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageProduct.getProductById('prod-lww-1');
      expect(result, isNotNull);
      expect(result!.getName(), 'Newer Remote');
    });

    test('Last-Write-Wins: local wins if newer', () async {
      // Arrange
      final product = Product(
        id: 'prod-lww-2',
        name: 'Newer Local',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 3, 10, 0),
      );
      await ManageProduct.addProduct(product);

      final remoteData = {
        'id': 'prod-lww-2',
        'name': 'Older Remote',
        'isVisible': true,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageProduct.getProductById('prod-lww-2');
      expect(result, isNotNull);
      expect(result!.getName(), 'Newer Local');
    });

    test('handles soft delete from remote (isDeleted=true)', () async {
      // Arrange
      final product = Product(
        id: 'prod-delete-1',
        name: 'To Be Deleted',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      final remoteData = {
        'id': 'prod-delete-1',
        'name': 'To Be Deleted',
        'isDeleted': true,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert - product should be hard deleted
      final result = await ManageProduct.getProductById('prod-delete-1');
      expect(result, isNull);
    });

    test('handles soft delete with is_deleted=1', () async {
      // Arrange
      final product = Product(
        id: 'prod-delete-2',
        name: 'To Be Deleted',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      final remoteData = {
        'id': 'prod-delete-2',
        'name': 'To Be Deleted',
        'is_deleted': 1,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageProduct.getProductById('prod-delete-2');
      expect(result, isNull);
    });

    test('deletes associations on soft delete', () async {
      // Arrange
      final db = await DatabaseHelper.database;
      final product = Product(
        id: 'prod-delete-3',
        name: 'To Be Deleted',
        associations: {'super-1': 'cat-1'},
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      final remoteData = {
        'id': 'prod-delete-3',
        'isDeleted': true,
        'lastModified': '2024-01-02T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final associations = await db.query(
        'associations',
        where: 'product_id = ?',
        whereArgs: ['prod-delete-3'],
      );
      expect(associations, isEmpty);
    });

    test('throws ArgumentError if id is missing', () async {
      // Arrange
      final remoteData = {
        'name': 'No ID',
        'isVisible': true,
      };

      // Act & Assert
      expect(
        () => repository.applyRemoteUpdate(remoteData),
        throwsArgumentError,
      );
    });

    test('converts camelCase fields to snake_case', () async {
      // Arrange
      final remoteData = {
        'id': 'prod-convert',
        'name': 'Test',
        'isVisible': true,
        'createdAt': '2024-01-15T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final localData = await repository.getLocalData('prod-convert');
      expect(localData, isNotNull);
      expect(localData!['is_visible'], 1);
      expect(localData['created_at'], isNotNull);
      expect(localData['last_modified'], isNotNull);
    });

    test('handles product associations from remote data', () async {
      // Arrange
      final remoteData = {
        'id': 'prod-assoc-1',
        'name': 'Product with Associations',
        'isVisible': true,
        'createdAt': '2024-01-15T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
        'associations': {
          'super-1': 'cat-1',
          'super-2': 'cat-2',
        },
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageProduct.getProductById('prod-assoc-1');
      expect(result, isNotNull);
      expect(result!.associations.length, 2);
      expect(result.associations['super-1'], 'cat-1');
      expect(result.associations['super-2'], 'cat-2');
    });

    test('handles associations list format from remote', () async {
      // Arrange
      final remoteData = {
        'id': 'prod-assoc-list',
        'name': 'Test',
        'isVisible': true,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T10:00:00.000Z',
        'associations': [
          {'supermarketId': 'super-1', 'categoryId': 'cat-1'},
          {'supermarketId': 'super-2', 'categoryId': 'cat-2'},
        ],
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageProduct.getProductById('prod-assoc-list');
      expect(result, isNotNull);
      expect(result!.associations.length, 2);
      expect(result.associations['super-1'], 'cat-1');
      expect(result.associations['super-2'], 'cat-2');
    });
  });

  group('QUERY OPERATIONS -', () {
    late ProductRepositoryWithSync repository;

    setUp(() {
      repository = ProductRepositoryWithSync();
    });

    test('getById returns existing product', () async {
      // Arrange
      final product = Product(id: 'prod-1', name: 'Test Product');
      await repository.add(product);

      // Act
      final result = await repository.getById('prod-1');

      // Assert
      expect(result, isNotNull);
      expect(result!.id, 'prod-1');
      expect(result.getName(), 'Test Product');
    });

    test('getById returns null for non-existent product', () async {
      // Act
      final result = await repository.getById('non-existent');

      // Assert
      expect(result, isNull);
    });

    test('getAll returns all products', () async {
      // Arrange
      await repository.add(Product(id: 'prod-1', name: 'Product 1'));
      await repository.add(Product(id: 'prod-2', name: 'Product 2'));
      await repository.add(Product(id: 'prod-3', name: 'Product 3'));

      // Act
      final results = await repository.getAll();

      // Assert
      expect(results.length, 3);
      expect(
        results.map((p) => p.id).toList(),
        containsAll(['prod-1', 'prod-2', 'prod-3']),
      );
    });

    test('getAll returns empty list when no products exist', () async {
      // Act
      final results = await repository.getAll();

      // Assert
      expect(results, isEmpty);
    });

    test('getLocalData returns raw database row with product data', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Test',
        isVisible: true,
        associations: {'super-1': 'cat-1'},
      );
      await repository.add(product);

      // Act
      final localData = await repository.getLocalData('prod-1');

      // Assert
      expect(localData, isNotNull);
      expect(localData!['id'], 'prod-1');
      expect(localData['name'], 'Test');
      expect(localData['is_visible'], 1);
      expect(localData['created_at'], isNotNull);
      expect(localData['last_modified'], isNotNull);
    });

    test('getLocalData returns null for non-existent product', () async {
      // Act
      final localData = await repository.getLocalData('non-existent');

      // Assert
      expect(localData, isNull);
    });

    test('getLocalData includes associations', () async {
      // Arrange
      final product = Product(
        id: 'prod-assoc',
        name: 'Test',
        isVisible: true,
        associations: {
          'super-1': 'cat-1',
          'super-2': 'cat-2',
        },
      );
      await repository.add(product);

      // Act
      final localData = await repository.getLocalData('prod-assoc');

      // Assert
      expect(localData, isNotNull);
      expect(localData!['associations'], isNotNull);
      expect(localData['associations']['super-1'], 'cat-1');
      expect(localData['associations']['super-2'], 'cat-2');
    });

    test('getLocalData includes all database fields', () async {
      // Arrange
      final product = Product(
        id: 'prod-data',
        name: 'Complete Data',
        isVisible: false,
        createdAt: DateTime(2024, 1, 15, 10, 30),
        lastModified: DateTime(2024, 1, 15, 11, 30),
      );
      await ManageProduct.addProduct(product);

      // Act
      final localData = await repository.getLocalData('prod-data');

      // Assert
      expect(localData, isNotNull);
      expect(localData!.keys, contains('id'));
      expect(localData.keys, contains('name'));
      expect(localData.keys, contains('is_visible'));
      expect(localData.keys, contains('created_at'));
      expect(localData.keys, contains('last_modified'));
    });
  });

  group('EDGE CASES - Timestamp Parsing -', () {
    late ProductRepositoryWithSync repository;

    setUp(() {
      repository = ProductRepositoryWithSync();
    });

    test('handles ISO 8601 string timestamps', () async {
      // Arrange
      final remoteData = {
        'id': 'prod-iso',
        'name': 'ISO Timestamp',
        'isVisible': true,
        'createdAt': '2024-01-15T10:30:45.123Z',
        'lastModified': '2024-01-15T11:30:45.123Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageProduct.getProductById('prod-iso');
      expect(result, isNotNull);
      expect(result!.createdAt.year, 2024);
      expect(result.createdAt.month, 1);
      expect(result.createdAt.day, 15);
    });

    test('handles null timestamps with fallback defaults', () async {
      // Arrange
      final remoteData = {
        'id': 'prod-null-ts',
        'name': 'Null Timestamps',
        'isVisible': true,
        'createdAt': null,
        'lastModified': null,
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final localData = await repository.getLocalData('prod-null-ts');
      expect(localData, isNotNull);
      expect(localData!['created_at'], isNotNull);
      expect(localData['last_modified'], isNotNull);
    });

    test('handles missing timestamp fields', () async {
      // Arrange
      final remoteData = {
        'id': 'prod-missing-ts',
        'name': 'Missing Timestamps',
        'isVisible': true,
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final localData = await repository.getLocalData('prod-missing-ts');
      expect(localData, isNotNull);
      expect(localData!['created_at'], isNotNull);
      expect(localData['last_modified'], isNotNull);
    });

    test('handles Firestore Timestamp object with _seconds', () async {
      // Arrange
      final remoteData = {
        'id': 'prod-firestore',
        'name': 'Firestore Timestamp',
        'isVisible': true,
        'createdAt': {'_seconds': 1705315845},
        'lastModified': {'_seconds': 1705319445},
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageProduct.getProductById('prod-firestore');
      expect(result, isNotNull);
      expect(result!.createdAt.year, 2024);
    });

    test('handles invalid timestamp string gracefully', () async {
      // Arrange
      final remoteData = {
        'id': 'prod-invalid',
        'name': 'Invalid Timestamp',
        'isVisible': true,
        'createdAt': 'not-a-date',
        'lastModified': 'also-not-a-date',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert - should use fallback defaults
      final localData = await repository.getLocalData('prod-invalid');
      expect(localData, isNotNull);
      expect(localData!['created_at'], isNotNull);
      expect(localData['last_modified'], isNotNull);
    });
  });

  group('EDGE CASES - Data Conversion -', () {
    late ProductRepositoryWithSync repository;

    setUp(() {
      repository = ProductRepositoryWithSync();
    });

    test('converts boolean true to 1 for isVisible', () async {
      // Arrange
      final remoteData = {
        'id': 'prod-bool-1',
        'name': 'Boolean True',
        'isVisible': true,
        'createdAt': '2024-01-15T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final localData = await repository.getLocalData('prod-bool-1');
      expect(localData, isNotNull);
      expect(localData!['is_visible'], 1);
    });

    test('converts boolean false to 0 for isVisible', () async {
      // Arrange
      final remoteData = {
        'id': 'prod-bool-2',
        'name': 'Boolean False',
        'isVisible': false,
        'createdAt': '2024-01-15T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final localData = await repository.getLocalData('prod-bool-2');
      expect(localData, isNotNull);
      expect(localData!['is_visible'], 0);
    });

    test('handles is_visible as integer 1', () async {
      // Arrange
      final remoteData = {
        'id': 'prod-int-1',
        'name': 'Integer 1',
        'is_visible': 1,
        'createdAt': '2024-01-15T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final localData = await repository.getLocalData('prod-int-1');
      expect(localData, isNotNull);
      expect(localData!['is_visible'], 1);
    });

    test('handles is_visible as integer 0', () async {
      // Arrange
      final remoteData = {
        'id': 'prod-int-0',
        'name': 'Integer 0',
        'is_visible': 0,
        'createdAt': '2024-01-15T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final localData = await repository.getLocalData('prod-int-0');
      expect(localData, isNotNull);
      expect(localData!['is_visible'], 0);
    });
  });

  group('EDGE CASES - Empty and Missing Data -', () {
    late ProductRepositoryWithSync repository;

    setUp(() {
      repository = ProductRepositoryWithSync();
    });

    test('handles product with empty associations', () async {
      // Arrange
      final remoteData = {
        'id': 'prod-empty-assoc',
        'name': 'Empty Associations',
        'isVisible': true,
        'createdAt': '2024-01-15T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
        'associations': {},
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageProduct.getProductById('prod-empty-assoc');
      expect(result, isNotNull);
      expect(result!.associations, isEmpty);
    });

    test('handles product with null associations', () async {
      // Arrange
      final remoteData = {
        'id': 'prod-null-assoc',
        'name': 'Null Associations',
        'isVisible': true,
        'createdAt': '2024-01-15T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
        'associations': null,
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageProduct.getProductById('prod-null-assoc');
      expect(result, isNotNull);
      expect(result!.associations, isEmpty);
    });

    test('skips invalid associations (missing supermarketId)', () async {
      // Arrange
      final remoteData = {
        'id': 'prod-invalid-assoc',
        'name': 'Invalid Associations',
        'isVisible': true,
        'createdAt': '2024-01-15T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
        'associations': {
          '': 'cat-1',
          'super-1': '',
        },
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageProduct.getProductById('prod-invalid-assoc');
      expect(result, isNotNull);
      expect(result!.associations, isEmpty);
    });
  });
}
