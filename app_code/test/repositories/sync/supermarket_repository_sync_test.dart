import 'package:app_code/models/category.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/repositories/sync/supermarket_repository_sync.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_supermarket.dart';
import 'package:app_code/services/database/sqlite/manage_sync_box.dart';
import 'package:app_code/services/database/sqlite/manage_category.dart';
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
    await db.delete('supermarket_category');
    await db.delete('supermarket');
    await db.delete('category');
    await db.delete('sync_box');
  });

  group('USER WRITE OPERATIONS - add -', () {
    late SupermarketRepositoryWithSync repository;

    setUp(() {
      repository = SupermarketRepositoryWithSync();
    });

    test('saves supermarket to database with correct data', () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-1',
        name: 'Carrefour',
        isVisible: true,
        isFavorite: false,
      );

      // Act
      await repository.add(supermarket);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('super-1');
      expect(result, isNotNull);
      expect(result!.id, 'super-1');
      expect(result.getName(), 'Carrefour');
      expect(result.isVisible, true);
      expect(result.isFavorite, false);
    });

    test('sets createdAt timestamp on add', () async {
      // Arrange
      final beforeAdd = DateTime.now();
      final supermarket = Supermarket(
        id: 'super-2',
        name: 'Tesco',
      );

      // Act
      await repository.add(supermarket);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('super-2');
      expect(result, isNotNull);
      expect(result!.createdAt, isNotNull);
      expect(
        result.createdAt.isAfter(beforeAdd.subtract(Duration(seconds: 1))),
        true,
      );
    });

    test('sets lastModified timestamp equal to createdAt on add', () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-3',
        name: 'Sainsbury',
      );

      // Act
      await repository.add(supermarket);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('super-3');
      expect(result, isNotNull);
      expect(result!.lastModified, isNotNull);
      expect(result.lastModified, equals(result.createdAt));
    });

    test('creates sync_box entry with upsert operation', () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-4',
        name: 'Lidl',
      );

      // Act
      await repository.add(supermarket);

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'super-4',
        'supermarket',
      );
      expect(syncEntry, isNotNull);
      expect(syncEntry!.entityId, 'super-4');
      expect(syncEntry.entityType, 'supermarket');
      expect(syncEntry.operation, SyncOperation.upsert);
    });

    test('sync_box entry has same timestamp as supermarket', () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-5',
        name: 'Aldi',
      );

      // Act
      await repository.add(supermarket);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('super-5');
      final syncEntry = await ManageSyncBox.getSyncEntry('super-5', 'supermarket');
      expect(result, isNotNull);
      expect(syncEntry, isNotNull);
      expect(
        syncEntry!.lastModified.millisecondsSinceEpoch,
        result!.lastModified!.millisecondsSinceEpoch,
      );
    });

    test('does NOT create sync_box entry for default supermarkets', () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-default',
        name: 'Default Market',
        isDefault: true,
      );

      // Act
      await repository.add(supermarket);

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'super-default',
        'supermarket',
      );
      expect(syncEntry, isNull);
    });

    test('saves supermarket with categories', () async {
      // Arrange
      final category1 = Category(id: 'cat-1', name: 'Fruits');
      final category2 = Category(id: 'cat-2', name: 'Vegetables');
      final supermarket = Supermarket(
        id: 'super-with-cats',
        name: 'Market With Categories',
        categories: [category1, category2],
      );

      // Act
      await repository.add(supermarket);

      // Assert
      final result = await ManageSupermarket.getSupermarketById(
        'super-with-cats',
      );
      expect(result, isNotNull);
      expect(result!.getCategories().length, 2);
      expect(result.getCategories()[0].id, 'cat-1');
      expect(result.getCategories()[1].id, 'cat-2');
    });

    test('handles multiple supermarket additions', () async {
      // Arrange
      final supermarkets = [
        Supermarket(id: 'super-a', name: 'Market A'),
        Supermarket(id: 'super-b', name: 'Market B'),
        Supermarket(id: 'super-c', name: 'Market C'),
      ];

      // Act
      for (var supermarket in supermarkets) {
        await repository.add(supermarket);
      }

      // Assert
      final allSupermarkets = await ManageSupermarket.getAllSupermarkets();
      expect(allSupermarkets.length, 3);
      expect(
        allSupermarkets.map((s) => s.id).toList(),
        containsAll(['super-a', 'super-b', 'super-c']),
      );

      final syncEntries = await ManageSyncBox.getAllSyncEntries(
        entityType: 'supermarket',
      );
      expect(syncEntries.length, 3);
    });

    test('handles visibility settings on add', () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-visible',
        name: 'Visible Market',
        isVisible: false,
      );

      // Act
      await repository.add(supermarket);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('super-visible');
      expect(result, isNotNull);
      expect(result!.isVisible, false);
    });

    test('handles favorite settings on add', () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-favorite',
        name: 'Favorite Market',
        isFavorite: true,
      );

      // Act
      await repository.add(supermarket);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('super-favorite');
      expect(result, isNotNull);
      expect(result!.isFavorite, true);
    });
  });

  group('USER WRITE OPERATIONS - update -', () {
    late SupermarketRepositoryWithSync repository;

    setUp(() {
      repository = SupermarketRepositoryWithSync();
    });

    test('updates supermarket in database', () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-1',
        name: 'Original Name',
      );
      await repository.add(supermarket);

      // Act
      supermarket.setName('Updated Name');
      await repository.update(supermarket);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('super-1');
      expect(result, isNotNull);
      expect(result!.getName(), 'Updated Name');
    });

    test('generates monotonic timestamp on update', () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-2',
        name: 'Test Supermarket',
      );
      await repository.add(supermarket);
      final originalTimestamp = supermarket.lastModified;

      // Wait a bit to ensure different timestamp
      await Future.delayed(Duration(milliseconds: 2));

      // Act
      supermarket.setName('Modified Name');
      await repository.update(supermarket);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('super-2');
      expect(result, isNotNull);
      expect(result!.lastModified, isNotNull);
      expect(
        result.lastModified!.isAfter(originalTimestamp!),
        true,
      );
    });

    test('creates sync_box entry with upsert operation on update', () async {
      // Arrange
      final supermarket = Supermarket(id: 'super-3', name: 'Test');
      await repository.add(supermarket);

      // Clear sync box to verify update creates new entry
      await ManageSyncBox.clearAllSyncEntries();

      // Act
      supermarket.setName('Updated Test');
      await repository.update(supermarket);

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry('super-3', 'supermarket');
      expect(syncEntry, isNotNull);
      expect(syncEntry!.operation, SyncOperation.upsert);
    });

    test('updates sync_box entry with newer timestamp', () async {
      // Arrange
      final supermarket = Supermarket(id: 'super-4', name: 'Test');
      await repository.add(supermarket);
      final firstSyncEntry = await ManageSyncBox.getSyncEntry(
        'super-4',
        'supermarket',
      );

      await Future.delayed(Duration(milliseconds: 2));

      // Act
      supermarket.setName('Updated');
      await repository.update(supermarket);

      // Assert
      final secondSyncEntry = await ManageSyncBox.getSyncEntry(
        'super-4',
        'supermarket',
      );
      expect(secondSyncEntry, isNotNull);
      expect(
        secondSyncEntry!.lastModified.isAfter(firstSyncEntry!.lastModified),
        true,
      );
    });

    test('handles visibility updates', () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-5',
        name: 'Test',
        isVisible: true,
      );
      await repository.add(supermarket);

      // Act
      supermarket.setVisibility(false);
      await repository.update(supermarket);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('super-5');
      expect(result, isNotNull);
      expect(result!.isVisible, false);
    });

    test('updates supermarket categories', () async {
      // Arrange
      final cat1 = Category(id: 'cat-1', name: 'Fruits');
      final supermarket = Supermarket(
        id: 'super-6',
        name: 'Test',
        categories: [cat1],
      );
      await repository.add(supermarket);

      final cat2 = Category(id: 'cat-2', name: 'Vegetables');
      cat1.setVisibility(false);

      // Act
      supermarket.setCategories([cat2, cat1]);
      await repository.update(supermarket);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('super-6');
      expect(result, isNotNull);
      expect(result!.getCategories().length, 2);
    });

    test('multiple consecutive updates maintain monotonic timestamps', () async {
      // Arrange
      final supermarket = Supermarket(id: 'super-7', name: 'Test');
      await repository.add(supermarket);
      final timestamps = <DateTime>[];

      // Act & Assert
      for (int i = 0; i < 3; i++) {
        supermarket.setName('Update $i');
        await repository.update(supermarket);

        final result = await ManageSupermarket.getSupermarketById('super-7');
        timestamps.add(result!.lastModified!);

        if (i > 0) {
          expect(timestamps[i].isAfter(timestamps[i - 1]), true);
        }
      }
    });
  });

  group('USER WRITE OPERATIONS - deleteById -', () {
    late SupermarketRepositoryWithSync repository;

    setUp(() {
      repository = SupermarketRepositoryWithSync();
    });

    test('removes supermarket from database', () async {
      // Arrange
      final supermarket = Supermarket(id: 'super-1', name: 'To Delete');
      await repository.add(supermarket);

      // Act
      await repository.deleteById('super-1');

      // Assert
      final result = await ManageSupermarket.getSupermarketById('super-1');
      expect(result, isNull);
    });

    test('creates sync_box entry with delete operation', () async {
      // Arrange
      final supermarket = Supermarket(id: 'super-2', name: 'To Delete');
      await repository.add(supermarket);

      // Clear sync box
      await ManageSyncBox.clearAllSyncEntries();

      // Act
      await repository.deleteById('super-2');

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'super-2',
        'supermarket',
      );
      expect(syncEntry, isNotNull);
      expect(syncEntry!.operation, SyncOperation.delete);
    });

    test('preserves timestamp on delete', () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-3',
        name: 'To Delete',
        lastModified: DateTime(2024, 1, 15, 10, 30, 45),
      );
      await ManageSupermarket.addSupermarket(supermarket);

      // Act
      await repository.deleteById('super-3');

      // Assert
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'super-3',
        'supermarket',
      );
      expect(syncEntry, isNotNull);
      expect(syncEntry!.lastModified, DateTime(2024, 1, 15, 10, 30, 45));
    });

    test('deletes related supermarket_category entries', () async {
      // Arrange
      final db = await DatabaseHelper.database;
      final supermarket = Supermarket(id: 'super-4', name: 'To Delete');
      await repository.add(supermarket);

      await db.insert('supermarket_category', {
        'supermarket_id': 'super-4',
        'category_id': 'cat-1',
        'order_index': 0,
      });

      // Act
      await repository.deleteById('super-4');

      // Assert
      final associations = await db.query(
        'supermarket_category',
        where: 'supermarket_id = ?',
        whereArgs: ['super-4'],
      );
      expect(associations, isEmpty);
    });

    test('handles deletion of supermarket with multiple categories', () async {
      // Arrange
      final db = await DatabaseHelper.database;
      final cat1 = Category(id: 'cat-1', name: 'Fruits');
      final cat2 = Category(id: 'cat-2', name: 'Vegetables');
      final supermarket = Supermarket(
        id: 'super-5',
        name: 'To Delete',
        categories: [cat1, cat2],
      );
      await repository.add(supermarket);

      // Act
      await repository.deleteById('super-5');

      // Assert
      final associations = await db.query(
        'supermarket_category',
        where: 'supermarket_id = ?',
        whereArgs: ['super-5'],
      );
      expect(associations, isEmpty);

      final result = await ManageSupermarket.getSupermarketById('super-5');
      expect(result, isNull);
    });

    test('deletion throws error for non-existent supermarket', () async {
      // Arrange & Act & Assert
      expect(
        () => repository.deleteById('non-existent'),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('QUERY OPERATIONS - getById, getAll -', () {
    late SupermarketRepositoryWithSync repository;

    setUp(() {
      repository = SupermarketRepositoryWithSync();
    });

    test('getById returns correct supermarket', () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-1',
        name: 'Carrefour',
        isFavorite: true,
      );
      await repository.add(supermarket);

      // Act
      final result = await repository.getById('super-1');

      // Assert
      expect(result, isNotNull);
      expect(result!.id, 'super-1');
      expect(result.getName(), 'Carrefour');
      expect(result.isFavorite, true);
    });

    test('getById returns null for non-existent supermarket', () async {
      // Act
      final result = await repository.getById('non-existent');

      // Assert
      expect(result, isNull);
    });

    test('getAll returns all supermarkets', () async {
      // Arrange
      final supermarkets = [
        Supermarket(id: 'super-1', name: 'Market 1'),
        Supermarket(id: 'super-2', name: 'Market 2'),
        Supermarket(id: 'super-3', name: 'Market 3'),
      ];
      for (var s in supermarkets) {
        await repository.add(s);
      }

      // Act
      final result = await repository.getAll();

      // Assert
      expect(result.length, 3);
      expect(
        result.map((s) => s.id).toList(),
        containsAll(['super-1', 'super-2', 'super-3']),
      );
    });

    test('getAll returns empty list when no supermarkets exist', () async {
      // Act
      final result = await repository.getAll();

      // Assert
      expect(result, isEmpty);
    });

    test('getById preserves all supermarket properties', () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-1',
        name: 'Test Market',
        isVisible: false,
        isFavorite: true,
        isDefault: false,
      );
      await repository.add(supermarket);

      // Act
      final result = await repository.getById('super-1');

      // Assert
      expect(result, isNotNull);
      expect(result!.getName(), 'Test Market');
      expect(result.isVisible, false);
      expect(result.isFavorite, true);
      expect(result.isDefault, false);
    });

    test('getById includes categories', () async {
      // Arrange
      final cat1 = Category(id: 'cat-1', name: 'Fruits');
      final cat2 = Category(id: 'cat-2', name: 'Vegetables');
      final supermarket = Supermarket(
        id: 'super-1',
        name: 'Market',
        categories: [cat1, cat2],
      );
      await repository.add(supermarket);

      // Act
      final result = await repository.getById('super-1');

      // Assert
      expect(result, isNotNull);
      expect(result!.getCategories().length, 2);
      expect(result.getCategories()[0].id, 'cat-1');
      expect(result.getCategories()[1].id, 'cat-2');
    });
  });

  group('REMOTE UPDATE OPERATIONS - applyRemoteUpdate -', () {
    late SupermarketRepositoryWithSync repository;

    setUp(() {
      repository = SupermarketRepositoryWithSync();
    });

    test('creates new supermarket from remote data', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-1',
        'name': 'Remote Market',
        'isVisible': true,
        'isFavorite': false,
        'createdAt': '2024-01-15T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('remote-1');
      expect(result, isNotNull);
      expect(result!.getName(), 'Remote Market');
      expect(result.isVisible, true);
    });

    test('updates existing supermarket from remote data', () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-1',
        name: 'Original Name',
        isVisible: true,
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageSupermarket.addSupermarket(supermarket);

      final remoteData = {
        'id': 'super-1',
        'name': 'Updated from Remote',
        'isVisible': false,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('super-1');
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
        'supermarket',
      );
      expect(syncEntry, isNull);
    });

    test('skips update if entity is dirty (has pending sync)', () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-dirty',
        name: 'Local Modified',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await repository.add(supermarket);

      final remoteData = {
        'id': 'super-dirty',
        'name': 'Remote Update',
        'isVisible': false,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert - should keep local data
      final result = await ManageSupermarket.getSupermarketById('super-dirty');
      expect(result, isNotNull);
      expect(result!.getName(), 'Local Modified');
    });

    test('Last-Write-Wins: remote wins if newer', () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-lww-1',
        name: 'Older Local',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageSupermarket.addSupermarket(supermarket);

      final remoteData = {
        'id': 'super-lww-1',
        'name': 'Newer Remote',
        'isVisible': true,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T12:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('super-lww-1');
      expect(result, isNotNull);
      expect(result!.getName(), 'Newer Remote');
    });

    test('Last-Write-Wins: local wins if newer', () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-lww-2',
        name: 'Newer Local',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 3, 10, 0),
      );
      await ManageSupermarket.addSupermarket(supermarket);

      final remoteData = {
        'id': 'super-lww-2',
        'name': 'Older Remote',
        'isVisible': true,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('super-lww-2');
      expect(result, isNotNull);
      expect(result!.getName(), 'Newer Local');
    });

    test('handles soft delete from remote (isDeleted=true)', () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-delete-1',
        name: 'To Be Deleted',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageSupermarket.addSupermarket(supermarket);

      final remoteData = {
        'id': 'super-delete-1',
        'name': 'To Be Deleted',
        'isDeleted': true,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert - supermarket should be hard deleted
      final result = await ManageSupermarket.getSupermarketById('super-delete-1');
      expect(result, isNull);
    });

    test('handles soft delete with is_deleted=1', () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-delete-2',
        name: 'To Be Deleted',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageSupermarket.addSupermarket(supermarket);

      final remoteData = {
        'id': 'super-delete-2',
        'name': 'To Be Deleted',
        'is_deleted': 1,
        'createdAt': '2024-01-01T10:00:00.000Z',
        'lastModified': '2024-01-02T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('super-delete-2');
      expect(result, isNull);
    });

    test('deletes supermarket_category on soft delete', () async {
      // Arrange
      final db = await DatabaseHelper.database;
      final supermarket = Supermarket(
        id: 'super-delete-3',
        name: 'To Be Deleted',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageSupermarket.addSupermarket(supermarket);

      await db.insert('supermarket_category', {
        'supermarket_id': 'super-delete-3',
        'category_id': 'cat-1',
        'order_index': 0,
      });

      final remoteData = {
        'id': 'super-delete-3',
        'isDeleted': true,
        'lastModified': '2024-01-02T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final associations = await db.query(
        'supermarket_category',
        where: 'supermarket_id = ?',
        whereArgs: ['super-delete-3'],
      );
      expect(associations, isEmpty);
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
        'name': 'Market Without Timestamp',
        'isVisible': true,
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageSupermarket.getSupermarketById(
        'remote-no-timestamp',
      );
      expect(result, isNotNull);
      expect(result!.getName(), 'Market Without Timestamp');
    });

    test('handles Firestore Timestamp format', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-firestore',
        'name': 'Firestore Market',
        'isVisible': true,
        'lastModified': {
          '_seconds': 1705316400,
          '_nanoseconds': 0,
        },
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('remote-firestore');
      expect(result, isNotNull);
      expect(result!.getName(), 'Firestore Market');
    });

    test('handles malformed Firestore Timestamp gracefully', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-bad-timestamp',
        'name': 'Market With Bad Timestamp',
        'isVisible': true,
        'lastModified': {'_invalid': 'structure'},
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageSupermarket.getSupermarketById(
        'remote-bad-timestamp',
      );
      expect(result, isNotNull);
      expect(result!.getName(), 'Market With Bad Timestamp');
    });

    test('converts Firebase boolean format correctly', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-bool-1',
        'name': 'Boolean Test',
        'isVisible': true,
        'isFavorite': false,
        'isDefault': false,
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('remote-bool-1');
      expect(result, isNotNull);
      expect(result!.isVisible, true);
      expect(result.isFavorite, false);
    });

    test('handles empty categoryIds', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-no-cats',
        'name': 'No Categories',
        'isVisible': true,
        'categoryIds': [],
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('remote-no-cats');
      expect(result, isNotNull);
      expect(result!.getCategories(), isEmpty);
    });

    test('handles categoryIds update', () async {
      // Arrange
      final cat1 = Category(id: 'cat-1', name: 'Fruits');
      final cat2 = Category(id: 'cat-2', name: 'Vegetables');
      await ManageCategory.addCategory(cat1);
      await ManageCategory.addCategory(cat2);

      final remoteData = {
        'id': 'remote-cats',
        'name': 'Market With Categories',
        'isVisible': true,
        'categoryIds': ['cat-1', 'cat-2'],
        'lastModified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('remote-cats');
      expect(result, isNotNull);
      expect(result!.getCategories().length, 2);
    });

    test('replaces old categories with new ones', () async {
      // Arrange
      final cat1 = Category(id: 'cat-1', name: 'Fruits');
      final cat2 = Category(id: 'cat-2', name: 'Vegetables');
      final cat3 = Category(id: 'cat-3', name: 'Dairy');

      final supermarket = Supermarket(
        id: 'super-1',
        name: 'Market',
        categories: [cat1, cat2],
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageSupermarket.addSupermarket(supermarket);

      await ManageCategory.addCategory(cat3);

      final remoteData = {
        'id': 'super-1',
        'name': 'Market',
        'isVisible': true,
        'categoryIds': ['cat-3'],
        'lastModified': '2024-01-15T11:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('super-1');
      expect(result, isNotNull);
      expect(result!.getCategories().length, 1);
      expect(result.getCategories()[0].id, 'cat-3');
    });
  });

  group('REMOTE UPDATE OPERATIONS - applyRemoteUpdate with getLocalData -', () {
    late SupermarketRepositoryWithSync repository;

    setUp(() {
      repository = SupermarketRepositoryWithSync();
    });

    test('getLocalData returns null for non-existent supermarket', () async {
      // Act
      final result = await repository.getLocalData('non-existent');

      // Assert
      expect(result, isNull);
    });

    test('getLocalData returns database format for existing supermarket',
        () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-1',
        name: 'Test Market',
        isVisible: true,
        isFavorite: false,
      );
      await repository.add(supermarket);

      // Act
      final result = await repository.getLocalData('super-1');

      // Assert
      expect(result, isNotNull);
      expect(result!['id'], 'super-1');
      expect(result['name'], 'Test Market');
      expect(result['is_visible'], 1);
      expect(result['is_favorite'], 0);
    });

    test('uses getLocalData to check for LWW conflict', () async {
      // Arrange
      final supermarket = Supermarket(
        id: 'super-lww-test',
        name: 'Local Market',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 2, 10, 0),
      );
      await ManageSupermarket.addSupermarket(supermarket);

      final remoteData = {
        'id': 'super-lww-test',
        'name': 'Remote Market',
        'lastModified': '2024-01-01T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert - local should win
      final result = await ManageSupermarket.getSupermarketById(
        'super-lww-test',
      );
      expect(result!.getName(), 'Local Market');
    });
  });

  group('EDGE CASES - Timestamp Handling -', () {
    late SupermarketRepositoryWithSync repository;

    setUp(() {
      repository = SupermarketRepositoryWithSync();
    });

    test('handles string timestamp format ISO8601', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-iso-1',
        'name': 'ISO Timestamp Market',
        'isVisible': true,
        'lastModified': '2024-01-15T10:30:45.123Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('remote-iso-1');
      expect(result, isNotNull);
    });

    test('handles null timestamp gracefully', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-null-ts',
        'name': 'Null Timestamp',
        'isVisible': true,
        'lastModified': null,
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('remote-null-ts');
      expect(result, isNotNull);
      expect(result!.getName(), 'Null Timestamp');
    });

    test('handles invalid timestamp string gracefully', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-invalid-ts',
        'name': 'Invalid Timestamp',
        'isVisible': true,
        'lastModified': 'not-a-valid-date',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('remote-invalid-ts');
      expect(result, isNotNull);
    });

    test('handles last_modified field (snake_case)', () async {
      // Arrange
      final remoteData = {
        'id': 'remote-snake',
        'name': 'Snake Case',
        'is_visible': 1,
        'last_modified': '2024-01-15T10:00:00.000Z',
      };

      // Act
      await repository.applyRemoteUpdate(remoteData);

      // Assert
      final result = await ManageSupermarket.getSupermarketById('remote-snake');
      expect(result, isNotNull);
    });
  });

  group('INTEGRATION TESTS - Complete Workflows -', () {
    late SupermarketRepositoryWithSync repository;

    setUp(() {
      repository = SupermarketRepositoryWithSync();
    });

    test('complete workflow: add, update, query, delete', () async {
      // Arrange & Act - Add
      final supermarket = Supermarket(
        id: 'super-workflow',
        name: 'Workflow Market',
        isFavorite: false,
      );
      await repository.add(supermarket);

      // Assert Add
      var result = await repository.getById('super-workflow');
      expect(result, isNotNull);
      expect(result!.getName(), 'Workflow Market');

      // Act - Update
      supermarket.setName('Updated Workflow');
      supermarket.isFavorite = true;
      await repository.update(supermarket);

      // Assert Update
      result = await repository.getById('super-workflow');
      expect(result!.getName(), 'Updated Workflow');
      expect(result.isFavorite, true);

      // Act - Delete
      await repository.deleteById('super-workflow');

      // Assert Delete
      result = await repository.getById('super-workflow');
      expect(result, isNull);
    });

    test('sync conflict resolution: local change wins against stale remote',
        () async {
      // Arrange - Create local with timestamp 2024-01-01
      final supermarket = Supermarket(
        id: 'super-conflict',
        name: 'Original',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageSupermarket.addSupermarket(supermarket);

      // Act - User updates locally (2024-01-03)
      supermarket.setName('Locally Updated');
      await repository.update(supermarket);

      // Act - Remote tries to apply stale update (2024-01-02)
      final staleRemote = {
        'id': 'super-conflict',
        'name': 'Stale Remote',
        'lastModified': '2024-01-02T10:00:00.000Z',
      };
      await repository.applyRemoteUpdate(staleRemote);

      // Assert - Local change should be preserved
      final result = await repository.getById('super-conflict');
      expect(result!.getName(), 'Locally Updated');

      // Assert - Sync box should have local upsert
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'super-conflict',
        'supermarket',
      );
      expect(syncEntry, isNotNull);
      expect(syncEntry!.operation, SyncOperation.upsert);
    });

    test('sync conflict resolution: newer remote wins', () async {
      // Arrange - Create local with old timestamp
      final supermarket = Supermarket(
        id: 'super-newer-remote',
        name: 'Old Local',
        createdAt: DateTime(2024, 1, 1, 10, 0),
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageSupermarket.addSupermarket(supermarket);

      // Act - Remote sends newer update
      final newerRemote = {
        'id': 'super-newer-remote',
        'name': 'Newer Remote',
        'lastModified': '2024-01-05T10:00:00.000Z',
      };
      await repository.applyRemoteUpdate(newerRemote);

      // Assert - Remote should win
      final result = await repository.getById('super-newer-remote');
      expect(result!.getName(), 'Newer Remote');

      // Assert - No sync entry since it's a remote silent update
      final syncEntry = await ManageSyncBox.getSyncEntry(
        'super-newer-remote',
        'supermarket',
      );
      expect(syncEntry, isNull);
    });

    test('multiple markets with categories sync correctly', () async {
      // Arrange
      final categories = [
        Category(id: 'cat-1', name: 'Fruits'),
        Category(id: 'cat-2', name: 'Vegetables'),
      ];
      for (var cat in categories) {
        await ManageCategory.addCategory(cat);
      }

      final markets = [
        Supermarket(
          id: 'market-1',
          name: 'Carrefour',
          categories: [categories[0]],
        ),
        Supermarket(
          id: 'market-2',
          name: 'Aldi',
          categories: [categories[1]],
        ),
      ];

      // Act
      for (var market in markets) {
        await repository.add(market);
      }

      final allMarkets = await repository.getAll();

      // Assert
      expect(allMarkets.length, 2);
      expect(allMarkets[0].getCategories().length, 1);
      expect(allMarkets[1].getCategories().length, 1);

      final syncEntries = await ManageSyncBox.getAllSyncEntries(
        entityType: 'supermarket',
      );
      expect(syncEntries.length, 2);
    });
  });
}
