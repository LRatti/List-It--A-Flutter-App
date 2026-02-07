import 'package:app_code/models/sync/local_sync_entry.dart';
import 'package:app_code/models/sync/sync_operation.dart';
import 'package:app_code/repositories/sync/sync_repository_mixin.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_sync_box.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Test implementation of SyncRepositoryMixin for testing purposes
class TestSyncRepository with SyncRepositoryMixin {
  // Empty implementation - we only need the mixin methods
}

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
    // Clear sync_box table before each test
    final db = await DatabaseHelper.database;
    await db.delete('sync_box');
  });

  group('appendUpsertToSyncBox -', () {
    late TestSyncRepository repository;

    setUp(() {
      repository = TestSyncRepository();
    });

    test('creates new sync entry with upsert operation', () async {
      // Arrange
      final entityId = 'test-entity-1';
      final entityType = 'product';
      final timestamp = DateTime(2024, 1, 15, 10, 30);

      // Act
      await repository.appendUpsertToSyncBox(
        entityId,
        entityType,
        timestamp,
      );

      // Assert
      final entry = await ManageSyncBox.getSyncEntry(entityId, entityType);
      expect(entry, isNotNull);
      expect(entry!.entityId, entityId);
      expect(entry.entityType, entityType);
      expect(entry.operation, SyncOperation.upsert);
      expect(entry.lastModified, timestamp);
    });

    test('creates sync entry with correct timestamp', () async {
      // Arrange
      final entityId = 'test-entity-2';
      final entityType = 'shopping_list';
      final timestamp = DateTime(2024, 2, 20, 14, 45, 30);

      // Act
      await repository.appendUpsertToSyncBox(
        entityId,
        entityType,
        timestamp,
      );

      // Assert
      final entry = await ManageSyncBox.getSyncEntry(entityId, entityType);
      expect(entry, isNotNull);
      expect(entry!.lastModified, timestamp);
    });

    test('updates existing entry when new timestamp is newer', () async {
      // Arrange
      final entityId = 'test-entity-3';
      final entityType = 'category';
      final oldTimestamp = DateTime(2024, 1, 1, 10, 0);
      final newTimestamp = DateTime(2024, 1, 1, 11, 0);

      // Add initial entry
      await repository.appendUpsertToSyncBox(
        entityId,
        entityType,
        oldTimestamp,
      );

      // Act - Add newer entry
      await repository.appendUpsertToSyncBox(
        entityId,
        entityType,
        newTimestamp,
      );

      // Assert
      final entry = await ManageSyncBox.getSyncEntry(entityId, entityType);
      expect(entry, isNotNull);
      expect(entry!.lastModified, newTimestamp);
      expect(entry.operation, SyncOperation.upsert);
    });

    test('does not update existing entry when new timestamp is older', () async {
      // Arrange
      final entityId = 'test-entity-4';
      final entityType = 'product';
      final newerTimestamp = DateTime(2024, 1, 1, 12, 0);
      final olderTimestamp = DateTime(2024, 1, 1, 11, 0);

      // Add newer entry first
      await repository.appendUpsertToSyncBox(
        entityId,
        entityType,
        newerTimestamp,
      );

      // Act - Try to add older entry
      await repository.appendUpsertToSyncBox(
        entityId,
        entityType,
        olderTimestamp,
      );

      // Assert
      final entry = await ManageSyncBox.getSyncEntry(entityId, entityType);
      expect(entry, isNotNull);
      expect(entry!.lastModified, newerTimestamp);
    });

    test('handles multiple entities of same type', () async {
      // Arrange
      final entityType = 'product';
      final timestamp = DateTime(2024, 1, 1, 10, 0);

      // Act
      await repository.appendUpsertToSyncBox('entity-1', entityType, timestamp);
      await repository.appendUpsertToSyncBox('entity-2', entityType, timestamp);
      await repository.appendUpsertToSyncBox('entity-3', entityType, timestamp);

      // Assert
      final allEntries = await ManageSyncBox.getAllSyncEntries(
        entityType: entityType,
      );
      expect(allEntries.length, 3);
      expect(allEntries.map((e) => e.entityId).toList(),
          containsAll(['entity-1', 'entity-2', 'entity-3']));
    });

    test('handles different entity types with same ID', () async {
      // Arrange
      final entityId = 'same-id';
      final timestamp = DateTime(2024, 1, 1, 10, 0);

      // Act
      await repository.appendUpsertToSyncBox(entityId, 'product', timestamp);
      await repository.appendUpsertToSyncBox(
        entityId,
        'category',
        timestamp,
      );

      // Assert
      final productEntry = await ManageSyncBox.getSyncEntry(
        entityId,
        'product',
      );
      final categoryEntry = await ManageSyncBox.getSyncEntry(
        entityId,
        'category',
      );
      expect(productEntry, isNotNull);
      expect(categoryEntry, isNotNull);
      expect(productEntry!.entityType, 'product');
      expect(categoryEntry!.entityType, 'category');
    });

    test('preserves exact timestamp without drift', () async {
      // Arrange
      final entityId = 'timestamp-test';
      final entityType = 'product';
      // Use a precise timestamp with milliseconds
      final timestamp = DateTime(2024, 1, 15, 10, 30, 45, 123);

      // Act
      await repository.appendUpsertToSyncBox(
        entityId,
        entityType,
        timestamp,
      );

      // Assert
      final entry = await ManageSyncBox.getSyncEntry(entityId, entityType);
      expect(entry, isNotNull);
      expect(entry!.lastModified.millisecondsSinceEpoch,
          timestamp.millisecondsSinceEpoch);
    });
  });

  group('appendDeleteToSyncBox -', () {
    late TestSyncRepository repository;

    setUp(() {
      repository = TestSyncRepository();
    });

    test('creates new sync entry with delete operation', () async {
      // Arrange
      final entityId = 'delete-entity-1';
      final entityType = 'product';
      final timestamp = DateTime(2024, 1, 15, 10, 30);

      // Act
      await repository.appendDeleteToSyncBox(
        entityId,
        entityType,
        timestamp,
      );

      // Assert
      final entry = await ManageSyncBox.getSyncEntry(entityId, entityType);
      expect(entry, isNotNull);
      expect(entry!.entityId, entityId);
      expect(entry.entityType, entityType);
      expect(entry.operation, SyncOperation.delete);
      expect(entry.lastModified, timestamp);
    });

    test('replaces upsert operation with delete when newer', () async {
      // Arrange
      final entityId = 'entity-replace';
      final entityType = 'shopping_list';
      final upsertTimestamp = DateTime(2024, 1, 1, 10, 0);
      final deleteTimestamp = DateTime(2024, 1, 1, 11, 0);

      // Add upsert first
      await repository.appendUpsertToSyncBox(
        entityId,
        entityType,
        upsertTimestamp,
      );

      // Act - Add delete with newer timestamp
      await repository.appendDeleteToSyncBox(
        entityId,
        entityType,
        deleteTimestamp,
      );

      // Assert
      final entry = await ManageSyncBox.getSyncEntry(entityId, entityType);
      expect(entry, isNotNull);
      expect(entry!.operation, SyncOperation.delete);
      expect(entry.lastModified, deleteTimestamp);
    });

    test('does not replace delete with older upsert', () async {
      // Arrange
      final entityId = 'entity-no-replace';
      final entityType = 'category';
      final deleteTimestamp = DateTime(2024, 1, 1, 12, 0);
      final upsertTimestamp = DateTime(2024, 1, 1, 11, 0);

      // Add delete first
      await repository.appendDeleteToSyncBox(
        entityId,
        entityType,
        deleteTimestamp,
      );

      // Act - Try to add older upsert
      await repository.appendUpsertToSyncBox(
        entityId,
        entityType,
        upsertTimestamp,
      );

      // Assert
      final entry = await ManageSyncBox.getSyncEntry(entityId, entityType);
      expect(entry, isNotNull);
      expect(entry!.operation, SyncOperation.delete);
      expect(entry.lastModified, deleteTimestamp);
    });

    test('handles multiple delete operations', () async {
      // Arrange
      final entityType = 'product';
      final timestamp = DateTime(2024, 1, 1, 10, 0);

      // Act
      await repository.appendDeleteToSyncBox('del-1', entityType, timestamp);
      await repository.appendDeleteToSyncBox('del-2', entityType, timestamp);
      await repository.appendDeleteToSyncBox('del-3', entityType, timestamp);

      // Assert
      final allEntries = await ManageSyncBox.getAllSyncEntries(
        entityType: entityType,
      );
      expect(allEntries.length, 3);
      expect(
        allEntries.every((e) => e.operation == SyncOperation.delete),
        isTrue,
      );
    });

    test('creates delete entry with exact timestamp', () async {
      // Arrange
      final entityId = 'delete-timestamp-test';
      final entityType = 'supermarket';
      final timestamp = DateTime(2024, 2, 28, 23, 59, 59, 999);

      // Act
      await repository.appendDeleteToSyncBox(
        entityId,
        entityType,
        timestamp,
      );

      // Assert
      final entry = await ManageSyncBox.getSyncEntry(entityId, entityType);
      expect(entry, isNotNull);
      expect(entry!.lastModified.millisecondsSinceEpoch,
          timestamp.millisecondsSinceEpoch);
    });
  });

  group('isEntityDirty -', () {
    late TestSyncRepository repository;

    setUp(() {
      repository = TestSyncRepository();
    });

    test('returns false when no sync entry exists', () async {
      // Arrange
      final entityId = 'clean-entity';
      final entityType = 'product';

      // Act
      final isDirty = await repository.isEntityDirty(entityId, entityType);

      // Assert
      expect(isDirty, isFalse);
    });

    test('returns true when upsert sync entry exists', () async {
      // Arrange
      final entityId = 'dirty-entity-1';
      final entityType = 'product';
      final timestamp = DateTime(2024, 1, 1, 10, 0);

      await repository.appendUpsertToSyncBox(entityId, entityType, timestamp);

      // Act
      final isDirty = await repository.isEntityDirty(entityId, entityType);

      // Assert
      expect(isDirty, isTrue);
    });

    test('returns true when delete sync entry exists', () async {
      // Arrange
      final entityId = 'dirty-entity-2';
      final entityType = 'shopping_list';
      final timestamp = DateTime(2024, 1, 1, 10, 0);

      await repository.appendDeleteToSyncBox(entityId, entityType, timestamp);

      // Act
      final isDirty = await repository.isEntityDirty(entityId, entityType);

      // Assert
      expect(isDirty, isTrue);
    });

    test('checks correct entity by ID and type', () async {
      // Arrange
      final timestamp = DateTime(2024, 1, 1, 10, 0);
      await repository.appendUpsertToSyncBox('entity-1', 'product', timestamp);

      // Act - Check different entity
      final isDirty = await repository.isEntityDirty('entity-2', 'product');

      // Assert
      expect(isDirty, isFalse);
    });

    test('differentiates between entity types', () async {
      // Arrange
      final entityId = 'same-id';
      final timestamp = DateTime(2024, 1, 1, 10, 0);
      await repository.appendUpsertToSyncBox(entityId, 'product', timestamp);

      // Act - Check different type
      final isDirty = await repository.isEntityDirty(entityId, 'category');

      // Assert
      expect(isDirty, isFalse);
    });

    test('returns true for recently updated entry', () async {
      // Arrange
      final entityId = 'updated-entity';
      final entityType = 'product';
      final oldTimestamp = DateTime(2024, 1, 1, 10, 0);
      final newTimestamp = DateTime(2024, 1, 1, 11, 0);

      await repository.appendUpsertToSyncBox(
        entityId,
        entityType,
        oldTimestamp,
      );
      await repository.appendUpsertToSyncBox(
        entityId,
        entityType,
        newTimestamp,
      );

      // Act
      final isDirty = await repository.isEntityDirty(entityId, entityType);

      // Assert
      expect(isDirty, isTrue);
    });
  });

  group('clearSyncEntriesForTesting -', () {
    late TestSyncRepository repository;

    setUp(() {
      repository = TestSyncRepository();
    });

    test('clears all sync entries', () async {
      // Arrange - Add multiple entries
      final timestamp = DateTime(2024, 1, 1, 10, 0);
      await repository.appendUpsertToSyncBox('entity-1', 'product', timestamp);
      await repository.appendUpsertToSyncBox(
        'entity-2',
        'shopping_list',
        timestamp,
      );
      await repository.appendDeleteToSyncBox('entity-3', 'category', timestamp);

      // Act
      final deletedCount = await repository.clearSyncEntriesForTesting();

      // Assert
      expect(deletedCount, 3);
      final allEntries = await ManageSyncBox.getAllSyncEntries();
      expect(allEntries, isEmpty);
    });

    test('returns zero when no entries exist', () async {
      // Act
      final deletedCount = await repository.clearSyncEntriesForTesting();

      // Assert
      expect(deletedCount, 0);
    });

    test('clears entries of all types', () async {
      // Arrange
      final timestamp = DateTime(2024, 1, 1, 10, 0);
      final entityTypes = [
        'product',
        'shopping_list',
        'category',
        'supermarket',
        'purchased_product'
      ];

      for (var i = 0; i < entityTypes.length; i++) {
        await repository.appendUpsertToSyncBox(
          'entity-$i',
          entityTypes[i],
          timestamp,
        );
      }

      // Act
      await repository.clearSyncEntriesForTesting();

      // Assert
      for (var entityType in entityTypes) {
        final entries = await ManageSyncBox.getAllSyncEntries(
          entityType: entityType,
        );
        expect(entries, isEmpty);
      }
    });

    test('allows adding new entries after clearing', () async {
      // Arrange - Add and clear
      final timestamp = DateTime(2024, 1, 1, 10, 0);
      await repository.appendUpsertToSyncBox('entity-1', 'product', timestamp);
      await repository.clearSyncEntriesForTesting();

      // Act - Add new entry after clearing
      await repository.appendUpsertToSyncBox('entity-2', 'product', timestamp);

      // Assert
      final entry = await ManageSyncBox.getSyncEntry('entity-2', 'product');
      expect(entry, isNotNull);
      expect(entry!.entityId, 'entity-2');
    });
  });

  group('Integration tests -', () {
    late TestSyncRepository repository;

    setUp(() {
      repository = TestSyncRepository();
    });

    test('complete workflow: upsert -> check dirty -> delete -> check clean',
        () async {
      // Arrange
      final entityId = 'workflow-entity';
      final entityType = 'product';
      final upsertTime = DateTime(2024, 1, 1, 10, 0);
      final deleteTime = DateTime(2024, 1, 1, 11, 0);

      // Act & Assert - Add upsert
      await repository.appendUpsertToSyncBox(entityId, entityType, upsertTime);
      expect(await repository.isEntityDirty(entityId, entityType), isTrue);

      // Act & Assert - Delete entry
      await repository.appendDeleteToSyncBox(
        entityId,
        entityType,
        deleteTime,
      );
      expect(await repository.isEntityDirty(entityId, entityType), isTrue);

      final entry = await ManageSyncBox.getSyncEntry(entityId, entityType);
      expect(entry!.operation, SyncOperation.delete);

      // Clear
      await repository.clearSyncEntriesForTesting();
      expect(await repository.isEntityDirty(entityId, entityType), isFalse);
    });

    test('handles concurrent-like operations with monotonic timestamps',
        () async {
      // Arrange
      final entityId = 'concurrent-entity';
      final entityType = 'product';

      // Simulate rapid successive updates
      final timestamps = List.generate(
        10,
        (i) => DateTime(2024, 1, 1, 10, 0, i),
      );

      // Act - Add entries in order
      for (var timestamp in timestamps) {
        await repository.appendUpsertToSyncBox(
          entityId,
          entityType,
          timestamp,
        );
      }

      // Assert - Should have the latest timestamp
      final entry = await ManageSyncBox.getSyncEntry(entityId, entityType);
      expect(entry, isNotNull);
      expect(entry!.lastModified, timestamps.last);
    });

    test('handles out-of-order timestamps correctly', () async {
      // Arrange
      final entityId = 'out-of-order';
      final entityType = 'shopping_list';

      final timestamps = [
        DateTime(2024, 1, 1, 10, 5),
        DateTime(2024, 1, 1, 10, 2),
        DateTime(2024, 1, 1, 10, 8),
        DateTime(2024, 1, 1, 10, 3),
      ];

      // Act - Add in "random" order
      for (var timestamp in timestamps) {
        await repository.appendUpsertToSyncBox(
          entityId,
          entityType,
          timestamp,
        );
      }

      // Assert - Should keep the newest one
      final entry = await ManageSyncBox.getSyncEntry(entityId, entityType);
      expect(entry, isNotNull);
      expect(entry!.lastModified, DateTime(2024, 1, 1, 10, 8));
    });

    test('multiple repositories can use same mixin', () async {
      // Arrange
      final repo1 = TestSyncRepository();
      final repo2 = TestSyncRepository();
      final timestamp = DateTime(2024, 1, 1, 10, 0);

      // Act
      await repo1.appendUpsertToSyncBox('entity-1', 'product', timestamp);
      await repo2.appendUpsertToSyncBox('entity-2', 'category', timestamp);

      // Assert
      final isDirty1 = await repo1.isEntityDirty('entity-1', 'product');
      final isDirty2 = await repo2.isEntityDirty('entity-2', 'category');
      expect(isDirty1, isTrue);
      expect(isDirty2, isTrue);

      final allEntries = await ManageSyncBox.getAllSyncEntries();
      expect(allEntries.length, 2);
    });
  });

  group('Edge cases -', () {
    late TestSyncRepository repository;

    setUp(() {
      repository = TestSyncRepository();
    });

    test('handles very old timestamps', () async {
      // Arrange
      final entityId = 'old-entity';
      final entityType = 'product';
      final oldTimestamp = DateTime(1970, 1, 1);

      // Act
      await repository.appendUpsertToSyncBox(
        entityId,
        entityType,
        oldTimestamp,
      );

      // Assert
      final entry = await ManageSyncBox.getSyncEntry(entityId, entityType);
      expect(entry, isNotNull);
      expect(entry!.lastModified, oldTimestamp);
    });

    test('handles future timestamps', () async {
      // Arrange
      final entityId = 'future-entity';
      final entityType = 'product';
      final futureTimestamp = DateTime(2099, 12, 31, 23, 59, 59);

      // Act
      await repository.appendUpsertToSyncBox(
        entityId,
        entityType,
        futureTimestamp,
      );

      // Assert
      final entry = await ManageSyncBox.getSyncEntry(entityId, entityType);
      expect(entry, isNotNull);
      expect(entry!.lastModified, futureTimestamp);
    });

    test('handles special characters in entity IDs', () async {
      // Arrange
      final entityId = 'entity-with-special-chars-@#\$%^&*()';
      final entityType = 'product';
      final timestamp = DateTime(2024, 1, 1, 10, 0);

      // Act
      await repository.appendUpsertToSyncBox(
        entityId,
        entityType,
        timestamp,
      );

      // Assert
      final entry = await ManageSyncBox.getSyncEntry(entityId, entityType);
      expect(entry, isNotNull);
      expect(entry!.entityId, entityId);
    });

    test('handles very long entity IDs', () async {
      // Arrange
      final entityId = 'a' * 255; // Very long ID
      final entityType = 'product';
      final timestamp = DateTime(2024, 1, 1, 10, 0);

      // Act
      await repository.appendUpsertToSyncBox(
        entityId,
        entityType,
        timestamp,
      );

      // Assert
      final entry = await ManageSyncBox.getSyncEntry(entityId, entityType);
      expect(entry, isNotNull);
      expect(entry!.entityId.length, 255);
    });

    test('handles UTC and local time zones correctly', () async {
      // Arrange
      final entityId = 'timezone-entity';
      final entityType = 'product';
      final utcTime = DateTime.utc(2024, 1, 1, 10, 0);
      final localTime = DateTime(2024, 1, 1, 10, 0);

      // Act
      await repository.appendUpsertToSyncBox('utc', entityType, utcTime);
      await repository.appendUpsertToSyncBox('local', entityType, localTime);

      // Assert
      final utcEntry = await ManageSyncBox.getSyncEntry('utc', entityType);
      final localEntry = await ManageSyncBox.getSyncEntry('local', entityType);
      expect(utcEntry, isNotNull);
      expect(localEntry, isNotNull);
      // Both should be stored correctly
      expect(utcEntry!.lastModified.millisecondsSinceEpoch,
          utcTime.millisecondsSinceEpoch);
      expect(localEntry!.lastModified.millisecondsSinceEpoch,
          localTime.millisecondsSinceEpoch);
    });

    test('handles rapid successive operations', () async {
      // Arrange
      final entityId = 'rapid-entity';
      final entityType = 'product';
      final baseTime = DateTime(2024, 1, 1, 10, 0);

      // Act - Simulate very rapid updates
      for (var i = 0; i < 100; i++) {
        await repository.appendUpsertToSyncBox(
          entityId,
          entityType,
          baseTime.add(Duration(milliseconds: i)),
        );
      }

      // Assert - Should have the latest
      final entry = await ManageSyncBox.getSyncEntry(entityId, entityType);
      expect(entry, isNotNull);
      expect(
        entry!.lastModified,
        baseTime.add(Duration(milliseconds: 99)),
      );
    });

    test('handles empty entity type string', () async {
      // Arrange
      final entityId = 'entity-1';
      final entityType = '';
      final timestamp = DateTime(2024, 1, 1, 10, 0);

      // Act
      await repository.appendUpsertToSyncBox(
        entityId,
        entityType,
        timestamp,
      );

      // Assert
      final entry = await ManageSyncBox.getSyncEntry(entityId, entityType);
      expect(entry, isNotNull);
      expect(entry!.entityType, entityType);
    });
  });
}
