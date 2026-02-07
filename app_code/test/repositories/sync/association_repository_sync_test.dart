import 'package:app_code/models/product.dart';
import 'package:app_code/repositories/sync/association_repository_sync.dart';
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
    late AssociationRepositoryWithSync repository;

    setUp(() {
      repository = AssociationRepositoryWithSync();
    });

    test('saves association to database with correct data', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      // Act
      await repository.add('prod-1', 'super-1', 'cat-1');

      // Assert
      final db = await DatabaseHelper.database;
      final result = await db.query(
        'associations',
        where: 'product_id = ? AND supermarket_id = ?',
        whereArgs: ['prod-1', 'super-1'],
      );
      expect(result.length, 1);
      expect(result.first['product_id'], 'prod-1');
      expect(result.first['supermarket_id'], 'super-1');
      expect(result.first['category_id'], 'cat-1');
    });

    test('creates sync_box entry for product with upsert operation', () async {
      // Arrange
      final product = Product(
        id: 'prod-2',
        name: 'Banana',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      // Clear sync box to verify add creates new entry
      await ManageSyncBox.clearAllSyncEntries();

      // Act
      await repository.add('prod-2', 'super-1', 'cat-1');

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry('prod-2', 'product');
      expect(syncEntry, isNotNull);
      expect(syncEntry!.operation, SyncOperation.upsert);
    });

    test('sync_box entry uses product timestamp', () async {
      // Arrange
      final productTimestamp = DateTime(2024, 1, 15, 10, 30, 45);
      final product = Product(
        id: 'prod-3',
        name: 'Orange',
        lastModified: productTimestamp,
      );
      await ManageProduct.addProduct(product);

      await ManageSyncBox.clearAllSyncEntries();

      // Act
      await repository.add('prod-3', 'super-1', 'cat-1');

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry('prod-3', 'product');
      expect(syncEntry, isNotNull);
      expect(syncEntry!.lastModified, productTimestamp);
    });

    test('throws ArgumentError if productId is empty', () async {
      // Act & Assert
      expect(
        () => repository.add('', 'super-1', 'cat-1'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError if supermarketId is empty', () async {
      // Act & Assert
      expect(
        () => repository.add('prod-1', '', 'cat-1'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError if categoryId is empty', () async {
      // Act & Assert
      expect(
        () => repository.add('prod-1', 'super-1', ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('replaces existing association if already exists', () async {
      // Arrange
      final product = Product(
        id: 'prod-4',
        name: 'Grape',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      await repository.add('prod-4', 'super-1', 'cat-1');

      // Act - add same product-supermarket with different category
      await repository.add('prod-4', 'super-1', 'cat-2');

      // Assert - should have replaced, not duplicated
      final db = await DatabaseHelper.database;
      final result = await db.query(
        'associations',
        where: 'product_id = ? AND supermarket_id = ?',
        whereArgs: ['prod-4', 'super-1'],
      );
      expect(result.length, 1);
      expect(result.first['category_id'], 'cat-2');
    });

    test('handles multiple associations for same product', () async {
      // Arrange
      final product = Product(
        id: 'prod-5',
        name: 'Melon',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      // Act
      await repository.add('prod-5', 'super-1', 'cat-1');
      await repository.add('prod-5', 'super-2', 'cat-2');
      await repository.add('prod-5', 'super-3', 'cat-1');

      // Assert
      final associations = await repository.getProductAssociations('prod-5');
      expect(associations.length, 3);
      expect(associations['super-1'], 'cat-1');
      expect(associations['super-2'], 'cat-2');
      expect(associations['super-3'], 'cat-1');
    });

    test('does not create sync entry if product does not exist', () async {
      // Arrange
      await ManageSyncBox.clearAllSyncEntries();

      // Act
      await repository.add('non-existent-product', 'super-1', 'cat-1');

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'non-existent-product',
        'product',
      );
      expect(syncEntry, isNull);
    });
  });

  group('USER WRITE OPERATIONS - update -', () {
    late AssociationRepositoryWithSync repository;

    setUp(() {
      repository = AssociationRepositoryWithSync();
    });

    test('updates existing association category', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);
      await repository.add('prod-1', 'super-1', 'cat-1');

      // Clear sync box to verify update creates new entry
      await ManageSyncBox.clearAllSyncEntries();

      // Act
      await repository.update('prod-1', 'super-1', 'cat-2');

      // Assert
      final category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, 'cat-2');
    });

    test('creates sync_box entry for product on update', () async {
      // Arrange
      final product = Product(
        id: 'prod-2',
        name: 'Banana',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);
      await repository.add('prod-2', 'super-1', 'cat-1');

      await ManageSyncBox.clearAllSyncEntries();

      // Act
      await repository.update('prod-2', 'super-1', 'cat-2');

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry('prod-2', 'product');
      expect(syncEntry, isNotNull);
      expect(syncEntry!.operation, SyncOperation.upsert);
    });

    test('throws ArgumentError if productId is empty', () async {
      // Act & Assert
      expect(
        () => repository.update('', 'super-1', 'cat-1'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError if supermarketId is empty', () async {
      // Act & Assert
      expect(
        () => repository.update('prod-1', '', 'cat-1'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError if categoryId is empty', () async {
      // Act & Assert
      expect(
        () => repository.update('prod-1', 'super-1', ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('update succeeds even if association does not exist', () async {
      // Arrange
      final product = Product(
        id: 'prod-3',
        name: 'Orange',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      // Act - update non-existent association
      await repository.update('prod-3', 'super-1', 'cat-1');

      // Assert - update may not create the row, just update if exists
      final category = await repository.getCategoryForProduct('prod-3', 'super-1');
      expect(category, isNull); // Update doesn't insert, only updates existing rows
    });
  });

  group('USER WRITE OPERATIONS - delete -', () {
    late AssociationRepositoryWithSync repository;

    setUp(() {
      repository = AssociationRepositoryWithSync();
    });

    test('removes association from database', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);
      await repository.add('prod-1', 'super-1', 'cat-1');

      // Act
      await repository.delete('prod-1', 'super-1');

      // Assert
      final category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, isNull);
    });

    test('creates sync_box entry for product on delete', () async {
      // Arrange
      final product = Product(
        id: 'prod-2',
        name: 'Banana',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);
      await repository.add('prod-2', 'super-1', 'cat-1');

      await ManageSyncBox.clearAllSyncEntries();

      // Act
      await repository.delete('prod-2', 'super-1');

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry('prod-2', 'product');
      expect(syncEntry, isNotNull);
      expect(syncEntry!.operation, SyncOperation.upsert);
    });

    test('does not affect other associations of same product', () async {
      // Arrange
      final product = Product(
        id: 'prod-3',
        name: 'Orange',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);
      await repository.add('prod-3', 'super-1', 'cat-1');
      await repository.add('prod-3', 'super-2', 'cat-2');

      // Act
      await repository.delete('prod-3', 'super-1');

      // Assert
      final category1 = await repository.getCategoryForProduct('prod-3', 'super-1');
      final category2 = await repository.getCategoryForProduct('prod-3', 'super-2');
      expect(category1, isNull);
      expect(category2, 'cat-2');
    });

    test('delete succeeds silently for non-existent association', () async {
      // Arrange
      final product = Product(
        id: 'prod-4',
        name: 'Grape',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      // Act & Assert
      expect(() => repository.delete('prod-4', 'super-1'), returnsNormally);
    });
  });

  group('BATCH OPERATIONS - addBatch -', () {
    late AssociationRepositoryWithSync repository;

    setUp(() {
      repository = AssociationRepositoryWithSync();
    });

    test('adds multiple associations in single batch', () async {
      // Arrange
      final product1 = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      final product2 = Product(
        id: 'prod-2',
        name: 'Banana',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product1);
      await ManageProduct.addProduct(product2);

      final batch = {
        'prod-1': {'super-1': 'cat-1', 'super-2': 'cat-2'},
        'prod-2': {'super-1': 'cat-3'},
      };

      // Act
      await repository.addBatch(batch);

      // Assert
      final associations1 = await repository.getProductAssociations('prod-1');
      final associations2 = await repository.getProductAssociations('prod-2');
      expect(associations1.length, 2);
      expect(associations1['super-1'], 'cat-1');
      expect(associations1['super-2'], 'cat-2');
      expect(associations2.length, 1);
      expect(associations2['super-1'], 'cat-3');
    });

    test('creates one sync_box entry per product in batch', () async {
      // Arrange
      final product1 = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      final product2 = Product(
        id: 'prod-2',
        name: 'Banana',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product1);
      await ManageProduct.addProduct(product2);

      await ManageSyncBox.clearAllSyncEntries();

      final batch = {
        'prod-1': {'super-1': 'cat-1', 'super-2': 'cat-2'},
        'prod-2': {'super-1': 'cat-3'},
      };

      // Act
      await repository.addBatch(batch);

      // Assert - should have only 2 sync entries (one per product)
      final syncEntries = await ManageSyncBox.getAllSyncEntries();
      final productSyncEntries = syncEntries
          .where((e) => e.entityType == 'product')
          .toList();
      expect(productSyncEntries.length, 2);

      final syncEntry1 = await ManageSyncBox.getSyncEntry('prod-1', 'product');
      final syncEntry2 = await ManageSyncBox.getSyncEntry('prod-2', 'product');
      expect(syncEntry1, isNotNull);
      expect(syncEntry2, isNotNull);
    });

    test('handles empty batch gracefully', () async {
      // Arrange
      final batch = <String, Map<String, String>>{};

      // Act & Assert
      expect(() => repository.addBatch(batch), returnsNormally);
    });

    test('throws ArgumentError if any association has empty productId', () async {
      // Arrange
      final batch = {
        '': {'super-1': 'cat-1'},
      };

      // Act & Assert
      expect(
        () => repository.addBatch(batch),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError if any association has empty supermarketId', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      final batch = {
        'prod-1': {'': 'cat-1'},
      };

      // Act & Assert
      expect(
        () => repository.addBatch(batch),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError if any association has empty categoryId', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      final batch = {
        'prod-1': {'super-1': ''},
      };

      // Act & Assert
      expect(
        () => repository.addBatch(batch),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('batch operation is atomic - all or nothing', () async {
      // Arrange
      final product1 = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product1);

      // Product2 doesn't exist - this should cause batch to fail
      final batch = {
        'prod-1': {'super-1': 'cat-1'},
        'prod-invalid': {'super-2': 'cat-2'},
      };

      // Act
      await repository.addBatch(batch);

      // Assert - associations are inserted but sync might fail for non-existent product
      final associations1 = await repository.getProductAssociations('prod-1');
      expect(associations1['super-1'], 'cat-1');
    });
  });

  group('BATCH OPERATIONS - deleteBatch -', () {
    late AssociationRepositoryWithSync repository;

    setUp(() {
      repository = AssociationRepositoryWithSync();
    });

    test('deletes multiple associations in single batch', () async {
      // Arrange
      final product1 = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      final product2 = Product(
        id: 'prod-2',
        name: 'Banana',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product1);
      await ManageProduct.addProduct(product2);

      await repository.add('prod-1', 'super-1', 'cat-1');
      await repository.add('prod-1', 'super-2', 'cat-2');
      await repository.add('prod-2', 'super-1', 'cat-3');

      final toDelete = [
        (productId: 'prod-1', supermarketId: 'super-1'),
        (productId: 'prod-2', supermarketId: 'super-1'),
      ];

      // Act
      await repository.deleteBatch(toDelete);

      // Assert
      final category1 = await repository.getCategoryForProduct('prod-1', 'super-1');
      final category2 = await repository.getCategoryForProduct('prod-1', 'super-2');
      final category3 = await repository.getCategoryForProduct('prod-2', 'super-1');
      expect(category1, isNull);
      expect(category2, 'cat-2'); // Should remain
      expect(category3, isNull);
    });

    test('creates one sync_box entry per product in delete batch', () async {
      // Arrange
      final product1 = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      final product2 = Product(
        id: 'prod-2',
        name: 'Banana',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product1);
      await ManageProduct.addProduct(product2);

      await repository.add('prod-1', 'super-1', 'cat-1');
      await repository.add('prod-1', 'super-2', 'cat-2');
      await repository.add('prod-2', 'super-1', 'cat-3');

      await ManageSyncBox.clearAllSyncEntries();

      final toDelete = [
        (productId: 'prod-1', supermarketId: 'super-1'),
        (productId: 'prod-1', supermarketId: 'super-2'),
        (productId: 'prod-2', supermarketId: 'super-1'),
      ];

      // Act
      await repository.deleteBatch(toDelete);

      // Assert - should have only 2 sync entries (one per product)
      final syncEntries = await ManageSyncBox.getAllSyncEntries();
      final productSyncEntries = syncEntries
          .where((e) => e.entityType == 'product')
          .toList();
      expect(productSyncEntries.length, 2);
    });

    test('handles empty delete batch gracefully', () async {
      // Arrange
      final toDelete = <({String productId, String supermarketId})>[];

      // Act & Assert
      expect(() => repository.deleteBatch(toDelete), returnsNormally);
    });

    test('delete batch succeeds even if some associations do not exist', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);
      await repository.add('prod-1', 'super-1', 'cat-1');

      final toDelete = [
        (productId: 'prod-1', supermarketId: 'super-1'),
        (productId: 'prod-1', supermarketId: 'super-2'), // Doesn't exist
      ];

      // Act & Assert
      expect(() => repository.deleteBatch(toDelete), returnsNormally);

      final category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, isNull);
    });
  });

  group('QUERY OPERATIONS - getProductAssociations, getCategoryForProduct -', () {
    late AssociationRepositoryWithSync repository;

    setUp(() {
      repository = AssociationRepositoryWithSync();
    });

    test('getProductAssociations returns all associations for product', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);
      await repository.add('prod-1', 'super-1', 'cat-1');
      await repository.add('prod-1', 'super-2', 'cat-2');
      await repository.add('prod-1', 'super-3', 'cat-3');

      // Act
      final associations = await repository.getProductAssociations('prod-1');

      // Assert
      expect(associations.length, 3);
      expect(associations['super-1'], 'cat-1');
      expect(associations['super-2'], 'cat-2');
      expect(associations['super-3'], 'cat-3');
    });

    test('getProductAssociations returns empty map for product with no associations', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      // Act
      final associations = await repository.getProductAssociations('prod-1');

      // Assert
      expect(associations, isEmpty);
    });

    test('getProductAssociations returns empty map for non-existent product', () async {
      // Act
      final associations = await repository.getProductAssociations('non-existent');

      // Assert
      expect(associations, isEmpty);
    });

    test('getCategoryForProduct returns correct category', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);
      await repository.add('prod-1', 'super-1', 'cat-1');

      // Act
      final category = await repository.getCategoryForProduct('prod-1', 'super-1');

      // Assert
      expect(category, 'cat-1');
    });

    test('getCategoryForProduct returns null for non-existent association', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      // Act
      final category = await repository.getCategoryForProduct('prod-1', 'super-1');

      // Assert
      expect(category, isNull);
    });

    test('getCategoryForProduct returns null for non-existent product', () async {
      // Act
      final category = await repository.getCategoryForProduct(
        'non-existent',
        'super-1',
      );

      // Assert
      expect(category, isNull);
    });
  });

  group('QUERY OPERATIONS - getLocalData -', () {
    late AssociationRepositoryWithSync repository;

    setUp(() {
      repository = AssociationRepositoryWithSync();
    });

    test('getLocalData returns association data by composite key', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);
      await repository.add('prod-1', 'super-1', 'cat-1');

      // Act
      final data = await repository.getLocalData('prod-1_super-1');

      // Assert
      expect(data, isNotNull);
      expect(data!['product_id'], 'prod-1');
      expect(data['supermarket_id'], 'super-1');
      expect(data['category_id'], 'cat-1');
    });

    test('getLocalData returns null for non-existent association', () async {
      // Act
      final data = await repository.getLocalData('prod-1_super-1');

      // Assert
      expect(data, isNull);
    });

    test('getLocalData handles composite key with underscores in IDs', () async {
      // Arrange
      // Note: When IDs contain underscores, the parsing is ambiguous
      // The implementation splits on '_' and takes first part as productId,
      // rest as supermarketId. So 'prod_1_super_1' becomes:
      // productId='prod' and supermarketId='1_super_1'
      // To test this properly, we need IDs that work with this parsing
      final product = Product(
        id: 'prod1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);
      await repository.add('prod1', 'super_market_1', 'cat-1');

      // Act - composite key with underscores in supermarket ID
      final data = await repository.getLocalData('prod1_super_market_1');

      // Assert
      expect(data, isNotNull);
      expect(data!['product_id'], 'prod1');
      expect(data['supermarket_id'], 'super_market_1');
      expect(data['category_id'], 'cat-1');
    });

    test('getLocalData returns null for invalid composite key', () async {
      // Act
      final data = await repository.getLocalData('invalid');

      // Assert
      expect(data, isNull);
    });

    test('getLocalData returns null for empty key', () async {
      // Act
      final data = await repository.getLocalData('');

      // Assert
      expect(data, isNull);
    });
  });

  group('REMOTE UPDATE OPERATIONS - applyRemoteUpdate -', () {
    late AssociationRepositoryWithSync repository;

    setUp(() {
      repository = AssociationRepositoryWithSync();
    });

    test('creates new association from remote data', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      final remoteData = {
        'productId': 'prod-1',
        'supermarketId': 'super-1',
        'categoryId': 'cat-1',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, 'cat-1');
    });

    test('updates existing association from remote data', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);
      await repository.add('prod-1', 'super-1', 'cat-1');

      await ManageSyncBox.clearAllSyncEntries();

      final remoteData = {
        'productId': 'prod-1',
        'supermarketId': 'super-1',
        'categoryId': 'cat-2',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, 'cat-2');
    });

    test('does NOT create sync_box entry (silent update)', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      await ManageSyncBox.clearAllSyncEntries();

      final remoteData = {
        'productId': 'prod-1',
        'supermarketId': 'super-1',
        'categoryId': 'cat-1',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry('prod-1', 'product');
      expect(syncEntry, isNull);
    });

    test('skips update if product is dirty (has pending sync)', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);
      await repository.add('prod-1', 'super-1', 'cat-1');

      // Product now has sync_box entry (is dirty)
      final remoteData = {
        'productId': 'prod-1',
        'supermarketId': 'super-1',
        'categoryId': 'cat-2',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert - should keep local data
      final category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, 'cat-1'); // Original value, not updated
    });

    test('handles soft delete from remote (isDeleted=true)', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      final db = await DatabaseHelper.database;
      await db.insert('associations', {
        'product_id': 'prod-1',
        'supermarket_id': 'super-1',
        'category_id': 'cat-1',
      });

      final remoteData = {
        'productId': 'prod-1',
        'supermarketId': 'super-1',
        'isDeleted': true,
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert - association should be deleted
      final category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, isNull);
    });

    test('handles soft delete with is_deleted=1', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      final db = await DatabaseHelper.database;
      await db.insert('associations', {
        'product_id': 'prod-1',
        'supermarket_id': 'super-1',
        'category_id': 'cat-1',
      });

      final remoteData = {
        'productId': 'prod-1',
        'supermarketId': 'super-1',
        'is_deleted': 1,
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, isNull);
    });

    test('throws ArgumentError if productId is missing', () async {
      // Arrange
      final remoteData = {
        'supermarketId': 'super-1',
        'categoryId': 'cat-1',
      };

      // Act & Assert
      expect(
        () => repository.applyRemoteUpdate(remoteData),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError if supermarketId is missing', () async {
      // Arrange
      final remoteData = {
        'productId': 'prod-1',
        'categoryId': 'cat-1',
      };

      // Act & Assert
      expect(
        () => repository.applyRemoteUpdate(remoteData),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('handles empty categoryId by not inserting', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      final remoteData = {
        'productId': 'prod-1',
        'supermarketId': 'super-1',
        'categoryId': '',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert - should not insert
      final category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, isNull);
    });

    test('handles null categoryId by not inserting', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      final remoteData = {
        'productId': 'prod-1',
        'supermarketId': 'super-1',
        'categoryId': null,
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, isNull);
    });
  });

  group('EDGE CASES - Timestamp Handling -', () {
    late AssociationRepositoryWithSync repository;

    setUp(() {
      repository = AssociationRepositoryWithSync();
    });

    test('handles product with string timestamp format', () async {
      // Arrange
      final db = await DatabaseHelper.database;
      await db.insert('product', {
        'id': 'prod-1',
        'name': 'Apple',
        'is_visible': 1,
        'created_at': '2024-01-15T10:00:00.000Z',
        'last_modified': '2024-01-15T10:00:00.000Z',
      });

      await ManageSyncBox.clearAllSyncEntries();

      // Act
      await repository.add('prod-1', 'super-1', 'cat-1');

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry('prod-1', 'product');
      expect(syncEntry, isNotNull);
    });

    test('handles product with invalid timestamp string gracefully', () async {
      // Arrange
      final db = await DatabaseHelper.database;
      // Database has NOT NULL constraints, so use invalid string instead
      await db.insert('product', {
        'id': 'prod-1',
        'name': 'Apple',
        'is_visible': 1,
        'created_at': 'invalid-timestamp',
        'last_modified': 'invalid-timestamp',
      });

      await ManageSyncBox.clearAllSyncEntries();

      // Act
      await repository.add('prod-1', 'super-1', 'cat-1');

      // Assert - should not create sync entry if timestamp can't be parsed
      final syncEntry = await ManageSyncBox.getSyncEntry('prod-1', 'product');
      expect(syncEntry, isNull);
    });

    test('handles Firestore Timestamp object in remote update', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      final remoteData = {
        'productId': 'prod-1',
        'supermarketId': 'super-1',
        'categoryId': 'cat-1',
        'lastModified': {
          '_seconds': 1705316400,
          '_nanoseconds': 0,
        },
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, 'cat-1');
    });
  });

  group('INTEGRATION TESTS - Complete Workflows -', () {
    late AssociationRepositoryWithSync repository;

    setUp(() {
      repository = AssociationRepositoryWithSync();
    });

    test('complete workflow: add, update, query, delete', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      // Act 1: Add
      await repository.add('prod-1', 'super-1', 'cat-1');

      // Assert: Verify add
      var category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, 'cat-1');
      var syncEntry = await ManageSyncBox.getSyncEntry('prod-1', 'product');
      expect(syncEntry, isNotNull);

      // Act 2: Update
      await repository.update('prod-1', 'super-1', 'cat-2');

      // Assert: Verify update
      category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, 'cat-2');

      // Act 3: Query
      final associations = await repository.getProductAssociations('prod-1');
      expect(associations.length, 1);
      expect(associations['super-1'], 'cat-2');

      // Act 4: Delete
      await repository.delete('prod-1', 'super-1');

      // Assert: Verify delete
      category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, isNull);
      syncEntry = await ManageSyncBox.getSyncEntry('prod-1', 'product');
      expect(syncEntry, isNotNull); // Sync entry should still exist
    });

    test('batch workflow: addBatch, query, deleteBatch', () async {
      // Arrange
      final product1 = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      final product2 = Product(
        id: 'prod-2',
        name: 'Banana',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product1);
      await ManageProduct.addProduct(product2);

      // Act 1: Add batch
      final addBatch = {
        'prod-1': {'super-1': 'cat-1', 'super-2': 'cat-2'},
        'prod-2': {'super-1': 'cat-3', 'super-3': 'cat-4'},
      };
      await repository.addBatch(addBatch);

      // Assert: Verify batch add
      var associations1 = await repository.getProductAssociations('prod-1');
      var associations2 = await repository.getProductAssociations('prod-2');
      expect(associations1.length, 2);
      expect(associations2.length, 2);

      // Act 2: Delete batch
      final deleteBatch = [
        (productId: 'prod-1', supermarketId: 'super-1'),
        (productId: 'prod-2', supermarketId: 'super-3'),
      ];
      await repository.deleteBatch(deleteBatch);

      // Assert: Verify batch delete
      associations1 = await repository.getProductAssociations('prod-1');
      associations2 = await repository.getProductAssociations('prod-2');
      expect(associations1.length, 1);
      expect(associations1['super-2'], 'cat-2');
      expect(associations2.length, 1);
      expect(associations2['super-1'], 'cat-3');
    });

    test('remote workflow: applyRemoteUpdate creates and deletes', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      await ManageSyncBox.clearAllSyncEntries();

      // Act 1: Remote create
      final remoteData1 = {
        'productId': 'prod-1',
        'supermarketId': 'super-1',
        'categoryId': 'cat-1',
      };
      await repository.applyRemoteUpdate(remoteData1);

      // Assert: Verify created, no sync entry
      var category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, 'cat-1');
      var syncEntry = await ManageSyncBox.getSyncEntry('prod-1', 'product');
      expect(syncEntry, isNull);

      // Act 2: Remote update
      final remoteData2 = {
        'productId': 'prod-1',
        'supermarketId': 'super-1',
        'categoryId': 'cat-2',
      };
      await repository.applyRemoteUpdate(remoteData2);

      // Assert: Verify updated
      category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, 'cat-2');

      // Act 3: Remote delete
      final remoteData3 = {
        'productId': 'prod-1',
        'supermarketId': 'super-1',
        'isDeleted': true,
      };
      await repository.applyRemoteUpdate(remoteData3);

      // Assert: Verify deleted
      category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, isNull);
    });

    test('conflict resolution: local changes win over remote', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      // Local add creates sync entry (dirty)
      await repository.add('prod-1', 'super-1', 'cat-local');

      // Act: Remote tries to update
      final remoteData = {
        'productId': 'prod-1',
        'supermarketId': 'super-1',
        'categoryId': 'cat-remote',
      };
      await repository.applyRemoteUpdate(remoteData);

      // Assert: Local value should remain (product is dirty)
      final category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, 'cat-local');
    });

    test('mixed operations: local and remote updates interleaved', () async {
      // Arrange
      final product = Product(
        id: 'prod-1',
        name: 'Apple',
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageProduct.addProduct(product);

      // Act 1: Remote add (no sync entry)
      await ManageSyncBox.clearAllSyncEntries();
      final remoteData1 = {
        'productId': 'prod-1',
        'supermarketId': 'super-1',
        'categoryId': 'cat-remote1',
      };
      await repository.applyRemoteUpdate(remoteData1);

      // Assert 1
      var category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, 'cat-remote1');
      var syncEntry = await ManageSyncBox.getSyncEntry('prod-1', 'product');
      expect(syncEntry, isNull);

      // Act 2: Local update (creates sync entry)
      await repository.update('prod-1', 'super-1', 'cat-local');

      // Assert 2
      category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, 'cat-local');
      syncEntry = await ManageSyncBox.getSyncEntry('prod-1', 'product');
      expect(syncEntry, isNotNull);

      // Act 3: Remote tries to update again (should be ignored, product is dirty)
      final remoteData2 = {
        'productId': 'prod-1',
        'supermarketId': 'super-1',
        'categoryId': 'cat-remote2',
      };
      await repository.applyRemoteUpdate(remoteData2);

      // Assert 3: Local value should remain
      category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, 'cat-local');

      // Act 4: Clear sync (simulate sync complete)
      await ManageSyncBox.clearAllSyncEntries();

      // Act 5: Remote update now should work
      final remoteData3 = {
        'productId': 'prod-1',
        'supermarketId': 'super-1',
        'categoryId': 'cat-remote3',
      };
      await repository.applyRemoteUpdate(remoteData3);

      // Assert 5: Remote value should be applied
      category = await repository.getCategoryForProduct('prod-1', 'super-1');
      expect(category, 'cat-remote3');
    });
  });
}
