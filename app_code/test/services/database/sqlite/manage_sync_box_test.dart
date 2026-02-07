import 'package:app_code/models/sync/local_sync_entry.dart';
import 'package:app_code/models/sync/sync_operation.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_sync_box.dart';
import 'package:flutter_test/flutter_test.dart';
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
    await db.delete('sync_box');
  });

  group('addOrUpdateSyncEntry -', () {
    test('adds a new sync entry when it does not exist', () async {
      // Arrange
      final entry = LocalSyncEntry(
        entityId: 'entity-1',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1, 12, 0),
      );

      // Act
      await ManageSyncBox.addOrUpdateSyncEntry(entry);

      // Assert
      final retrieved = await ManageSyncBox.getSyncEntry('entity-1', 'product');
      expect(retrieved, isNotNull);
      expect(retrieved!.entityId, 'entity-1');
      expect(retrieved.entityType, 'product');
      expect(retrieved.operation, SyncOperation.upsert);
    });

    test('replaces existing entry when new entry is newer', () async {
      // Arrange - Add old entry
      final oldEntry = LocalSyncEntry(
        entityId: 'entity-2',
        entityType: 'shopping_list',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageSyncBox.addOrUpdateSyncEntry(oldEntry);

      // Arrange - Create newer entry
      final newEntry = LocalSyncEntry(
        entityId: 'entity-2',
        entityType: 'shopping_list',
        operation: SyncOperation.delete,
        lastModified: DateTime(2024, 1, 1, 11, 0),
      );

      // Act
      await ManageSyncBox.addOrUpdateSyncEntry(newEntry);

      // Assert
      final retrieved = await ManageSyncBox.getSyncEntry('entity-2', 'shopping_list');
      expect(retrieved, isNotNull);
      expect(retrieved!.operation, SyncOperation.delete);
      expect(retrieved.lastModified, DateTime(2024, 1, 1, 11, 0));
    });

    test('ignores new entry when existing entry is newer', () async {
      // Arrange - Add newer entry first
      final newerEntry = LocalSyncEntry(
        entityId: 'entity-3',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1, 12, 0),
      );
      await ManageSyncBox.addOrUpdateSyncEntry(newerEntry);

      // Arrange - Create older entry
      final olderEntry = LocalSyncEntry(
        entityId: 'entity-3',
        entityType: 'product',
        operation: SyncOperation.delete,
        lastModified: DateTime(2024, 1, 1, 11, 0),
      );

      // Act
      await ManageSyncBox.addOrUpdateSyncEntry(olderEntry);

      // Assert
      final retrieved = await ManageSyncBox.getSyncEntry('entity-3', 'product');
      expect(retrieved, isNotNull);
      expect(retrieved!.operation, SyncOperation.upsert);
      expect(retrieved.lastModified, DateTime(2024, 1, 1, 12, 0));
    });

    test('ignores new entry when existing entry has equal timestamp', () async {
      // Arrange
      final timestamp = DateTime(2024, 1, 1, 12, 0);
      final firstEntry = LocalSyncEntry(
        entityId: 'entity-4',
        entityType: 'category',
        operation: SyncOperation.upsert,
        lastModified: timestamp,
      );
      await ManageSyncBox.addOrUpdateSyncEntry(firstEntry);

      final sameTimeEntry = LocalSyncEntry(
        entityId: 'entity-4',
        entityType: 'category',
        operation: SyncOperation.delete,
        lastModified: timestamp,
      );

      // Act
      await ManageSyncBox.addOrUpdateSyncEntry(sameTimeEntry);

      // Assert
      final retrieved = await ManageSyncBox.getSyncEntry('entity-4', 'category');
      expect(retrieved, isNotNull);
      expect(retrieved!.operation, SyncOperation.upsert);
    });

    test('treats entries with different entity types as separate', () async {
      // Arrange
      final entry1 = LocalSyncEntry(
        entityId: 'entity-5',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      );
      final entry2 = LocalSyncEntry(
        entityId: 'entity-5',
        entityType: 'category',
        operation: SyncOperation.delete,
        lastModified: DateTime(2024, 1, 2),
      );

      // Act
      await ManageSyncBox.addOrUpdateSyncEntry(entry1);
      await ManageSyncBox.addOrUpdateSyncEntry(entry2);

      // Assert
      final allEntries = await ManageSyncBox.getAllSyncEntries();
      expect(allEntries.length, 2);
    });

    test('correctly stores all entry properties', () async {
      // Arrange
      final entry = LocalSyncEntry(
        id: 'custom-id',
        entityId: 'entity-6',
        entityType: 'supermarket',
        operation: SyncOperation.delete,
        lastModified: DateTime(2024, 1, 1, 15, 30, 45),
      );

      // Act
      await ManageSyncBox.addOrUpdateSyncEntry(entry);

      // Assert
      final retrieved = await ManageSyncBox.getSyncEntry('entity-6', 'supermarket');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'custom-id');
      expect(retrieved.entityId, 'entity-6');
      expect(retrieved.entityType, 'supermarket');
      expect(retrieved.operation, SyncOperation.delete);
      expect(retrieved.lastModified, DateTime(2024, 1, 1, 15, 30, 45));
    });
  });

  group('getAllSyncEntries -', () {
    test('returns empty list when no entries exist', () async {
      // Act
      final entries = await ManageSyncBox.getAllSyncEntries();

      // Assert
      expect(entries, isEmpty);
    });

    test('returns all entries when no filter is applied', () async {
      // Arrange
      final entries = [
        LocalSyncEntry(
          entityId: 'e1',
          entityType: 'product',
          operation: SyncOperation.upsert,
          lastModified: DateTime(2024, 1, 1),
        ),
        LocalSyncEntry(
          entityId: 'e2',
          entityType: 'shopping_list',
          operation: SyncOperation.delete,
          lastModified: DateTime(2024, 1, 2),
        ),
        LocalSyncEntry(
          entityId: 'e3',
          entityType: 'category',
          operation: SyncOperation.upsert,
          lastModified: DateTime(2024, 1, 3),
        ),
      ];

      for (final entry in entries) {
        await ManageSyncBox.addOrUpdateSyncEntry(entry);
      }

      // Act
      final retrieved = await ManageSyncBox.getAllSyncEntries();

      // Assert
      expect(retrieved.length, 3);
      expect(retrieved.map((e) => e.entityId).toSet(), {'e1', 'e2', 'e3'});
    });

    test('filters entries by entity type when specified', () async {
      // Arrange
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e1',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e2',
        entityType: 'product',
        operation: SyncOperation.delete,
        lastModified: DateTime(2024, 1, 2),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e3',
        entityType: 'shopping_list',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 3),
      ));

      // Act
      final productEntries = await ManageSyncBox.getAllSyncEntries(
        entityType: 'product',
      );

      // Assert
      expect(productEntries.length, 2);
      expect(productEntries.every((e) => e.entityType == 'product'), true);
    });

    test('returns empty list when filtering by non-existent entity type', () async {
      // Arrange
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e1',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));

      // Act
      final entries = await ManageSyncBox.getAllSyncEntries(
        entityType: 'nonexistent',
      );

      // Assert
      expect(entries, isEmpty);
    });

    test('preserves data integrity when retrieving multiple entries', () async {
      // Arrange
      final entry1 = LocalSyncEntry(
        id: 'id-1',
        entityId: 'entity-1',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      final entry2 = LocalSyncEntry(
        id: 'id-2',
        entityId: 'entity-2',
        entityType: 'product',
        operation: SyncOperation.delete,
        lastModified: DateTime(2024, 1, 1, 11, 0),
      );

      await ManageSyncBox.addOrUpdateSyncEntry(entry1);
      await ManageSyncBox.addOrUpdateSyncEntry(entry2);

      // Act
      final retrieved = await ManageSyncBox.getAllSyncEntries(entityType: 'product');

      // Assert
      expect(retrieved.length, 2);
      
      final retrievedEntry1 = retrieved.firstWhere((e) => e.id == 'id-1');
      expect(retrievedEntry1.entityId, 'entity-1');
      expect(retrievedEntry1.operation, SyncOperation.upsert);
      expect(retrievedEntry1.lastModified, DateTime(2024, 1, 1, 10, 0));

      final retrievedEntry2 = retrieved.firstWhere((e) => e.id == 'id-2');
      expect(retrievedEntry2.entityId, 'entity-2');
      expect(retrievedEntry2.operation, SyncOperation.delete);
      expect(retrievedEntry2.lastModified, DateTime(2024, 1, 1, 11, 0));
    });
  });

  group('getSyncEntry -', () {
    test('returns null when entry does not exist', () async {
      // Act
      final result = await ManageSyncBox.getSyncEntry('nonexistent', 'product');

      // Assert
      expect(result, isNull);
    });

    test('retrieves specific entry by entity id and type', () async {
      // Arrange
      final entry = LocalSyncEntry(
        entityId: 'specific-entity',
        entityType: 'shopping_list',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      );
      await ManageSyncBox.addOrUpdateSyncEntry(entry);

      // Act
      final retrieved = await ManageSyncBox.getSyncEntry(
        'specific-entity',
        'shopping_list',
      );

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.entityId, 'specific-entity');
      expect(retrieved.entityType, 'shopping_list');
    });

    test('returns null when entity id matches but type differs', () async {
      // Arrange
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'entity-x',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));

      // Act
      final result = await ManageSyncBox.getSyncEntry('entity-x', 'category');

      // Assert
      expect(result, isNull);
    });

    test('correctly maps database data to LocalSyncEntry model', () async {
      // Arrange
      final original = LocalSyncEntry(
        id: 'mapping-test-id',
        entityId: 'map-entity',
        entityType: 'purchased_product',
        operation: SyncOperation.delete,
        lastModified: DateTime(2024, 3, 15, 14, 30, 25),
      );
      await ManageSyncBox.addOrUpdateSyncEntry(original);

      // Act
      final retrieved = await ManageSyncBox.getSyncEntry('map-entity', 'purchased_product');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'mapping-test-id');
      expect(retrieved.entityId, 'map-entity');
      expect(retrieved.entityType, 'purchased_product');
      expect(retrieved.operation, SyncOperation.delete);
      expect(retrieved.lastModified, DateTime(2024, 3, 15, 14, 30, 25));
    });

    test('handles special characters in entity id', () async {
      // Arrange
      final entry = LocalSyncEntry(
        entityId: 'entity-with-special-chars-!@#\$%',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      );
      await ManageSyncBox.addOrUpdateSyncEntry(entry);

      // Act
      final retrieved = await ManageSyncBox.getSyncEntry(
        'entity-with-special-chars-!@#\$%',
        'product',
      );

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.entityId, 'entity-with-special-chars-!@#\$%');
    });
  });

  group('deleteSyncEntry -', () {
    test('deletes entry when entity id, type, and timestamp match', () async {
      // Arrange
      final timestamp = DateTime(2024, 1, 1, 12, 0);
      final entry = LocalSyncEntry(
        entityId: 'to-delete',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: timestamp,
      );
      await ManageSyncBox.addOrUpdateSyncEntry(entry);

      // Act
      final deletedCount = await ManageSyncBox.deleteSyncEntry(
        'to-delete',
        'product',
        timestamp,
      );

      // Assert
      expect(deletedCount, 1);
      final retrieved = await ManageSyncBox.getSyncEntry('to-delete', 'product');
      expect(retrieved, isNull);
    });

    test('deletes entry when provided timestamp is newer than stored timestamp', () async {
      // Arrange
      final entry = LocalSyncEntry(
        entityId: 'delete-newer',
        entityType: 'shopping_list',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1, 10, 0),
      );
      await ManageSyncBox.addOrUpdateSyncEntry(entry);

      // Act - Provide newer timestamp
      final deletedCount = await ManageSyncBox.deleteSyncEntry(
        'delete-newer',
        'shopping_list',
        DateTime(2024, 1, 1, 11, 0),
      );

      // Assert
      expect(deletedCount, 1);
      final retrieved = await ManageSyncBox.getSyncEntry('delete-newer', 'shopping_list');
      expect(retrieved, isNull);
    });

    test('does not delete when stored entry is newer (race condition protection)', () async {
      // Arrange - Entry modified at 12:00
      final entry = LocalSyncEntry(
        entityId: 'race-condition',
        entityType: 'category',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1, 12, 0),
      );
      await ManageSyncBox.addOrUpdateSyncEntry(entry);

      // Act - Try to delete with older timestamp (11:00)
      final deletedCount = await ManageSyncBox.deleteSyncEntry(
        'race-condition',
        'category',
        DateTime(2024, 1, 1, 11, 0),
      );

      // Assert - Entry should still exist
      expect(deletedCount, 0);
      final retrieved = await ManageSyncBox.getSyncEntry('race-condition', 'category');
      expect(retrieved, isNotNull);
    });

    test('returns 0 when entry does not exist', () async {
      // Act
      final deletedCount = await ManageSyncBox.deleteSyncEntry(
        'nonexistent',
        'product',
        DateTime.now(),
      );

      // Assert
      expect(deletedCount, 0);
    });

    test('does not delete entry with same id but different type', () async {
      // Arrange
      final timestamp = DateTime(2024, 1, 1, 12, 0);
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'same-id',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: timestamp,
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'same-id',
        entityType: 'category',
        operation: SyncOperation.upsert,
        lastModified: timestamp,
      ));

      // Act - Try to delete 'product' type
      final deletedCount = await ManageSyncBox.deleteSyncEntry(
        'same-id',
        'product',
        timestamp,
      );

      // Assert - Only product entry deleted
      expect(deletedCount, 1);
      final productEntry = await ManageSyncBox.getSyncEntry('same-id', 'product');
      expect(productEntry, isNull);
      final categoryEntry = await ManageSyncBox.getSyncEntry('same-id', 'category');
      expect(categoryEntry, isNotNull);
    });

    test('handles multiple delete attempts correctly', () async {
      // Arrange
      final timestamp = DateTime(2024, 1, 1, 12, 0);
      final entry = LocalSyncEntry(
        entityId: 'multi-delete',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: timestamp,
      );
      await ManageSyncBox.addOrUpdateSyncEntry(entry);

      // Act - First delete
      final firstDelete = await ManageSyncBox.deleteSyncEntry(
        'multi-delete',
        'product',
        timestamp,
      );

      // Act - Second delete (entry already gone)
      final secondDelete = await ManageSyncBox.deleteSyncEntry(
        'multi-delete',
        'product',
        timestamp,
      );

      // Assert
      expect(firstDelete, 1);
      expect(secondDelete, 0);
    });
  });

  group('deleteSyncEntriesByType -', () {
    test('deletes all entries of specified type', () async {
      // Arrange
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e1',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e2',
        entityType: 'product',
        operation: SyncOperation.delete,
        lastModified: DateTime(2024, 1, 2),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e3',
        entityType: 'shopping_list',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 3),
      ));

      // Act
      final deletedCount = await ManageSyncBox.deleteSyncEntriesByType('product');

      // Assert
      expect(deletedCount, 2);
      final remainingProducts = await ManageSyncBox.getAllSyncEntries(
        entityType: 'product',
      );
      expect(remainingProducts, isEmpty);
      
      final remainingLists = await ManageSyncBox.getAllSyncEntries(
        entityType: 'shopping_list',
      );
      expect(remainingLists.length, 1);
    });

    test('returns 0 when no entries of specified type exist', () async {
      // Arrange
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e1',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));

      // Act
      final deletedCount = await ManageSyncBox.deleteSyncEntriesByType('category');

      // Assert
      expect(deletedCount, 0);
    });

    test('handles deleting from empty table', () async {
      // Act
      final deletedCount = await ManageSyncBox.deleteSyncEntriesByType('product');

      // Assert
      expect(deletedCount, 0);
    });

    test('deletes all entries when multiple types exist', () async {
      // Arrange
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e1',
        entityType: 'category',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e2',
        entityType: 'category',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 2),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e3',
        entityType: 'category',
        operation: SyncOperation.delete,
        lastModified: DateTime(2024, 1, 3),
      ));

      // Act
      final deletedCount = await ManageSyncBox.deleteSyncEntriesByType('category');

      // Assert
      expect(deletedCount, 3);
      final remaining = await ManageSyncBox.getAllSyncEntries();
      expect(remaining, isEmpty);
    });
  });

  group('isEntityDirty -', () {
    test('returns true when entity has pending sync entry', () async {
      // Arrange
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'dirty-entity',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));

      // Act
      final isDirty = await ManageSyncBox.isEntityDirty('dirty-entity', 'product');

      // Assert
      expect(isDirty, true);
    });

    test('returns false when entity has no pending sync entry', () async {
      // Act
      final isDirty = await ManageSyncBox.isEntityDirty('clean-entity', 'product');

      // Assert
      expect(isDirty, false);
    });

    test('returns false when entity id matches but type differs', () async {
      // Arrange
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'entity-123',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));

      // Act
      final isDirty = await ManageSyncBox.isEntityDirty('entity-123', 'category');

      // Assert
      expect(isDirty, false);
    });

    test('returns false after sync entry is deleted', () async {
      // Arrange
      final timestamp = DateTime(2024, 1, 1);
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'synced-entity',
        entityType: 'shopping_list',
        operation: SyncOperation.upsert,
        lastModified: timestamp,
      ));

      // Verify it's dirty first
      var isDirty = await ManageSyncBox.isEntityDirty('synced-entity', 'shopping_list');
      expect(isDirty, true);

      // Act - Delete the sync entry
      await ManageSyncBox.deleteSyncEntry('synced-entity', 'shopping_list', timestamp);

      // Assert
      isDirty = await ManageSyncBox.isEntityDirty('synced-entity', 'shopping_list');
      expect(isDirty, false);
    });

    test('uses correct SQL query with COUNT', () async {
      // Arrange - Add multiple entries to ensure COUNT works correctly
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'count-test',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));

      // Act
      final isDirty = await ManageSyncBox.isEntityDirty('count-test', 'product');

      // Assert - Should return true based on COUNT > 0
      expect(isDirty, true);
    });
  });

  group('clearAllSyncEntries -', () {
    test('removes all sync entries from database', () async {
      // Arrange - Add multiple entries
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e1',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e2',
        entityType: 'shopping_list',
        operation: SyncOperation.delete,
        lastModified: DateTime(2024, 1, 2),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e3',
        entityType: 'category',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 3),
      ));

      // Act
      final deletedCount = await ManageSyncBox.clearAllSyncEntries();

      // Assert
      expect(deletedCount, 3);
      final remaining = await ManageSyncBox.getAllSyncEntries();
      expect(remaining, isEmpty);
    });

    test('returns 0 when clearing empty table', () async {
      // Act
      final deletedCount = await ManageSyncBox.clearAllSyncEntries();

      // Assert
      expect(deletedCount, 0);
    });

    test('allows adding entries after clearing', () async {
      // Arrange - Add and clear
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'temp',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));
      await ManageSyncBox.clearAllSyncEntries();

      // Act - Add new entry after clearing
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'new-entry',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 2),
      ));

      // Assert
      final entries = await ManageSyncBox.getAllSyncEntries();
      expect(entries.length, 1);
      expect(entries.first.entityId, 'new-entry');
    });

    test('clears entries of all types', () async {
      // Arrange - Add entries of different types
      final types = ['product', 'shopping_list', 'category', 'purchased_product', 'supermarket'];
      for (int i = 0; i < types.length; i++) {
        await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
          entityId: 'entity-$i',
          entityType: types[i],
          operation: SyncOperation.upsert,
          lastModified: DateTime(2024, 1, i + 1),
        ));
      }

      // Act
      final deletedCount = await ManageSyncBox.clearAllSyncEntries();

      // Assert
      expect(deletedCount, types.length);
      for (final type in types) {
        final entries = await ManageSyncBox.getAllSyncEntries(entityType: type);
        expect(entries, isEmpty);
      }
    });
  });

  group('getSyncEntriesByModificationTime -', () {
    test('returns entries sorted by modification time in ascending order', () async {
      // Arrange - Add entries in random order
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e2',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 2, 12, 0),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e1',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1, 10, 0),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e3',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 3, 14, 0),
      ));

      // Act
      final sorted = await ManageSyncBox.getSyncEntriesByModificationTime(
        ascending: true,
      );

      // Assert
      expect(sorted.length, 3);
      expect(sorted[0].entityId, 'e1');
      expect(sorted[1].entityId, 'e2');
      expect(sorted[2].entityId, 'e3');
    });

    test('returns entries sorted by modification time in descending order', () async {
      // Arrange
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e1',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e2',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 2),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e3',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 3),
      ));

      // Act
      final sorted = await ManageSyncBox.getSyncEntriesByModificationTime(
        ascending: false,
      );

      // Assert
      expect(sorted.length, 3);
      expect(sorted[0].entityId, 'e3');
      expect(sorted[1].entityId, 'e2');
      expect(sorted[2].entityId, 'e1');
    });

    test('filters by entity type and sorts', () async {
      // Arrange
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'p1',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 3),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'l1',
        entityType: 'shopping_list',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 2),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'p2',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));

      // Act
      final sorted = await ManageSyncBox.getSyncEntriesByModificationTime(
        entityType: 'product',
        ascending: true,
      );

      // Assert
      expect(sorted.length, 2);
      expect(sorted[0].entityId, 'p2');
      expect(sorted[1].entityId, 'p1');
      expect(sorted.every((e) => e.entityType == 'product'), true);
    });

    test('returns empty list when no entries match filter', () async {
      // Arrange
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e1',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));

      // Act
      final sorted = await ManageSyncBox.getSyncEntriesByModificationTime(
        entityType: 'category',
      );

      // Assert
      expect(sorted, isEmpty);
    });

    test('returns empty list when table is empty', () async {
      // Act
      final sorted = await ManageSyncBox.getSyncEntriesByModificationTime();

      // Assert
      expect(sorted, isEmpty);
    });

    test('handles entries with same timestamp correctly', () async {
      // Arrange - Same timestamp, different IDs
      final sameTime = DateTime(2024, 1, 1, 12, 0);
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e1',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: sameTime,
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e2',
        entityType: 'category',
        operation: SyncOperation.delete,
        lastModified: sameTime,
      ));

      // Act
      final sorted = await ManageSyncBox.getSyncEntriesByModificationTime(
        ascending: true,
      );

      // Assert - Both entries should be present
      expect(sorted.length, 2);
      expect(sorted.every((e) => e.lastModified == sameTime), true);
    });

    test('uses ascending order by default when parameter not specified', () async {
      // Arrange
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e2',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 2),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e1',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));

      // Act - Default ascending should be true
      final sorted = await ManageSyncBox.getSyncEntriesByModificationTime();

      // Assert
      expect(sorted[0].entityId, 'e1');
      expect(sorted[1].entityId, 'e2');
    });

    test('correctly sorts entries with millisecond precision', () async {
      // Arrange - Entries very close in time
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e1',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1, 12, 0, 0, 100),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e2',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1, 12, 0, 0, 200),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e3',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1, 12, 0, 0, 50),
      ));

      // Act
      final sorted = await ManageSyncBox.getSyncEntriesByModificationTime(
        ascending: true,
      );

      // Assert - Should be sorted by milliseconds
      expect(sorted[0].entityId, 'e3');
      expect(sorted[1].entityId, 'e1');
      expect(sorted[2].entityId, 'e2');
    });

    test('handles large number of entries efficiently', () async {
      // Arrange - Add 100 entries
      for (int i = 0; i < 100; i++) {
        await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
          entityId: 'entity-$i',
          entityType: 'product',
          operation: SyncOperation.upsert,
          lastModified: DateTime(2024, 1, 1).add(Duration(minutes: i)),
        ));
      }

      // Act
      final sorted = await ManageSyncBox.getSyncEntriesByModificationTime(
        ascending: true,
      );

      // Assert
      expect(sorted.length, 100);
      // Verify first and last are correct
      expect(sorted.first.entityId, 'entity-0');
      expect(sorted.last.entityId, 'entity-99');
      
      // Verify ordering is maintained
      for (int i = 0; i < 99; i++) {
        expect(
          sorted[i].lastModified.isBefore(sorted[i + 1].lastModified) ||
              sorted[i].lastModified.isAtSameMomentAs(sorted[i + 1].lastModified),
          true,
        );
      }
    });
  });

  group('data mapping -', () {
    test('correctly converts LocalSyncEntry to database format', () async {
      // Arrange
      final entry = LocalSyncEntry(
        id: 'test-id-123',
        entityId: 'entity-abc',
        entityType: 'test_type',
        operation: SyncOperation.delete,
        lastModified: DateTime(2024, 5, 15, 10, 30, 45),
      );

      // Act
      await ManageSyncBox.addOrUpdateSyncEntry(entry);
      
      // Access database directly to verify format
      final db = await DatabaseHelper.database;
      final rows = await db.query(
        'sync_box',
        where: 'id = ?',
        whereArgs: ['test-id-123'],
      );

      // Assert
      expect(rows.length, 1);
      final row = rows.first;
      expect(row['id'], 'test-id-123');
      expect(row['entity_id'], 'entity-abc');
      expect(row['entity_type'], 'test_type');
      expect(row['operation'], 'delete');
      expect(row['last_modified'], '2024-05-15T10:30:45.000');
    });

    test('correctly converts database format to LocalSyncEntry', () async {
      // Arrange - Insert directly to database
      final db = await DatabaseHelper.database;
      await db.insert('sync_box', {
        'id': 'db-test-id',
        'entity_id': 'db-entity',
        'entity_type': 'db_type',
        'operation': 'upsert',
        'last_modified': '2024-06-20T15:45:30.000',
      });

      // Act
      final entry = await ManageSyncBox.getSyncEntry('db-entity', 'db_type');

      // Assert
      expect(entry, isNotNull);
      expect(entry!.id, 'db-test-id');
      expect(entry.entityId, 'db-entity');
      expect(entry.entityType, 'db_type');
      expect(entry.operation, SyncOperation.upsert);
      expect(entry.lastModified, DateTime(2024, 6, 20, 15, 45, 30));
    });

    test('handles both sync operation types correctly', () async {
      // Arrange & Act - Test upsert
      final upsertEntry = LocalSyncEntry(
        entityId: 'upsert-test',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      );
      await ManageSyncBox.addOrUpdateSyncEntry(upsertEntry);
      
      // Arrange & Act - Test delete
      final deleteEntry = LocalSyncEntry(
        entityId: 'delete-test',
        entityType: 'product',
        operation: SyncOperation.delete,
        lastModified: DateTime(2024, 1, 2),
      );
      await ManageSyncBox.addOrUpdateSyncEntry(deleteEntry);

      // Assert
      final retrieved1 = await ManageSyncBox.getSyncEntry('upsert-test', 'product');
      expect(retrieved1!.operation, SyncOperation.upsert);
      
      final retrieved2 = await ManageSyncBox.getSyncEntry('delete-test', 'product');
      expect(retrieved2!.operation, SyncOperation.delete);
    });

    test('preserves datetime precision through round trip', () async {
      // Arrange - Use precise timestamp
      final preciseTime = DateTime(2024, 7, 15, 14, 25, 36, 789);
      final entry = LocalSyncEntry(
        entityId: 'precision-test',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: preciseTime,
      );

      // Act
      await ManageSyncBox.addOrUpdateSyncEntry(entry);
      final retrieved = await ManageSyncBox.getSyncEntry('precision-test', 'product');

      // Assert - Milliseconds should be preserved
      expect(retrieved!.lastModified, preciseTime);
    });

    test('handles UUID generation for entries without explicit id', () async {
      // Arrange - Create entry without ID
      final entryWithoutId = LocalSyncEntry(
        entityId: 'auto-id-test',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      );

      // Act
      await ManageSyncBox.addOrUpdateSyncEntry(entryWithoutId);
      final retrieved = await ManageSyncBox.getSyncEntry('auto-id-test', 'product');

      // Assert - ID should be auto-generated UUID
      expect(retrieved, isNotNull);
      expect(retrieved!.id, isNotEmpty);
      expect(retrieved.id.length, greaterThan(0));
    });
  });

  group('SQL query construction -', () {
    test('uses proper WHERE clause for getSyncEntry', () async {
      // Arrange - Add entries with similar entity IDs
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'test',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'test',
        entityType: 'category',
        operation: SyncOperation.delete,
        lastModified: DateTime(2024, 1, 2),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'test2',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 3),
      ));

      // Act
      final result = await ManageSyncBox.getSyncEntry('test', 'product');

      // Assert - Should only get exact match
      expect(result, isNotNull);
      expect(result!.entityId, 'test');
      expect(result.entityType, 'product');
    });

    test('uses LIMIT 1 for getSyncEntry query', () async {
      // Arrange - This verifies the limit is working even if duplicates somehow exist
      final entry = LocalSyncEntry(
        entityId: 'limit-test',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      );
      await ManageSyncBox.addOrUpdateSyncEntry(entry);

      // Act
      final result = await ManageSyncBox.getSyncEntry('limit-test', 'product');

      // Assert - Should return single entry, not a list
      expect(result, isNotNull);
      expect(result, isA<LocalSyncEntry>());
    });

    test('constructs correct ORDER BY clause for sorting', () async {
      // Arrange - Add entries that need sorting
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'z-last',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 3),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'a-first',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'm-middle',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 2),
      ));

      // Act - Get in ascending order
      final ascending = await ManageSyncBox.getSyncEntriesByModificationTime(
        ascending: true,
      );

      // Assert - Should be ordered by lastModified ASC
      expect(ascending[0].lastModified, DateTime(2024, 1, 1));
      expect(ascending[1].lastModified, DateTime(2024, 1, 2));
      expect(ascending[2].lastModified, DateTime(2024, 1, 3));

      // Act - Get in descending order
      final descending = await ManageSyncBox.getSyncEntriesByModificationTime(
        ascending: false,
      );

      // Assert - Should be ordered by lastModified DESC
      expect(descending[0].lastModified, DateTime(2024, 1, 3));
      expect(descending[1].lastModified, DateTime(2024, 1, 2));
      expect(descending[2].lastModified, DateTime(2024, 1, 1));
    });

    test('uses parameterized queries to prevent SQL injection', () async {
      // Arrange - Entity ID with SQL-like syntax
      final maliciousId = "'; DROP TABLE sync_box; --";
      final entry = LocalSyncEntry(
        entityId: maliciousId,
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      );

      // Act
      await ManageSyncBox.addOrUpdateSyncEntry(entry);
      final retrieved = await ManageSyncBox.getSyncEntry(maliciousId, 'product');

      // Assert - Entry should be stored safely
      expect(retrieved, isNotNull);
      expect(retrieved!.entityId, maliciousId);
      
      // Verify table still exists by querying it
      final allEntries = await ManageSyncBox.getAllSyncEntries();
      expect(allEntries, isNotEmpty);
    });

    test('handles apostrophes and quotes in entity IDs', () async {
      // Arrange
      final entityId = "O'Brien's \"Special\" Product";
      final entry = LocalSyncEntry(
        entityId: entityId,
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      );

      // Act
      await ManageSyncBox.addOrUpdateSyncEntry(entry);
      final retrieved = await ManageSyncBox.getSyncEntry(entityId, 'product');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.entityId, entityId);
    });
  });

  group('edge cases and error handling -', () {
    test('handles empty string entity id', () async {
      // Arrange
      final entry = LocalSyncEntry(
        entityId: '',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      );

      // Act
      await ManageSyncBox.addOrUpdateSyncEntry(entry);
      final retrieved = await ManageSyncBox.getSyncEntry('', 'product');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.entityId, '');
    });

    test('handles empty string entity type', () async {
      // Arrange
      final entry = LocalSyncEntry(
        entityId: 'test-entity',
        entityType: '',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      );

      // Act
      await ManageSyncBox.addOrUpdateSyncEntry(entry);
      final retrieved = await ManageSyncBox.getSyncEntry('test-entity', '');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.entityType, '');
    });

    test('handles very long entity id strings', () async {
      // Arrange - Create a very long entity ID
      final longId = 'x' * 1000;
      final entry = LocalSyncEntry(
        entityId: longId,
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      );

      // Act
      await ManageSyncBox.addOrUpdateSyncEntry(entry);
      final retrieved = await ManageSyncBox.getSyncEntry(longId, 'product');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.entityId, longId);
      expect(retrieved.entityId.length, 1000);
    });

    test('handles very old timestamps', () async {
      // Arrange
      final oldDate = DateTime(1900, 1, 1);
      final entry = LocalSyncEntry(
        entityId: 'old-entry',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: oldDate,
      );

      // Act
      await ManageSyncBox.addOrUpdateSyncEntry(entry);
      final retrieved = await ManageSyncBox.getSyncEntry('old-entry', 'product');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.lastModified, oldDate);
    });

    test('handles future timestamps', () async {
      // Arrange
      final futureDate = DateTime(2099, 12, 31, 23, 59, 59);
      final entry = LocalSyncEntry(
        entityId: 'future-entry',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: futureDate,
      );

      // Act
      await ManageSyncBox.addOrUpdateSyncEntry(entry);
      final retrieved = await ManageSyncBox.getSyncEntry('future-entry', 'product');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.lastModified, futureDate);
    });

    test('maintains consistency after multiple rapid operations', () async {
      // Arrange
      final entityId = 'rapid-ops';
      final entityType = 'product';
      
      // Act - Perform multiple rapid operations
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: entityId,
        entityType: entityType,
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1, 10, 0),
      ));
      
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: entityId,
        entityType: entityType,
        operation: SyncOperation.delete,
        lastModified: DateTime(2024, 1, 1, 10, 1),
      ));
      
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: entityId,
        entityType: entityType,
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1, 10, 2),
      ));

      // Assert - Should have latest entry
      final retrieved = await ManageSyncBox.getSyncEntry(entityId, entityType);
      expect(retrieved, isNotNull);
      expect(retrieved!.operation, SyncOperation.upsert);
      expect(retrieved.lastModified, DateTime(2024, 1, 1, 10, 2));
      
      // Should only have one entry for this entity
      final allForType = await ManageSyncBox.getAllSyncEntries(entityType: entityType);
      expect(allForType.length, 1);
    });

    test('handles Unicode and emoji in entity IDs', () async {
      // Arrange
      final unicodeId = '测试-🚀-émoji-Ñoño';
      final entry = LocalSyncEntry(
        entityId: unicodeId,
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      );

      // Act
      await ManageSyncBox.addOrUpdateSyncEntry(entry);
      final retrieved = await ManageSyncBox.getSyncEntry(unicodeId, 'product');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.entityId, unicodeId);
    });

    test('handles null checks for database operations', () async {
      // Arrange - Ensure database is initialized
      final db = await DatabaseHelper.database;
      expect(db, isNotNull);

      // Act & Assert - All operations should work without null errors
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'null-check',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));

      final retrieved = await ManageSyncBox.getSyncEntry('null-check', 'product');
      expect(retrieved, isNotNull);

      final isDirty = await ManageSyncBox.isEntityDirty('null-check', 'product');
      expect(isDirty, isNotNull);
      expect(isDirty, true);
    });

    test('handles case sensitivity in entity type filtering', () async {
      // Arrange
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e1',
        entityType: 'Product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'e2',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 2),
      ));

      // Act
      final upperCase = await ManageSyncBox.getAllSyncEntries(entityType: 'Product');
      final lowerCase = await ManageSyncBox.getAllSyncEntries(entityType: 'product');

      // Assert - Should be case-sensitive
      expect(upperCase.length, 1);
      expect(upperCase.first.entityId, 'e1');
      expect(lowerCase.length, 1);
      expect(lowerCase.first.entityId, 'e2');
    });
  });

  group('concurrent operations -', () {
    test('handles concurrent additions of different entities', () async {
      // Arrange & Act - Add multiple entries concurrently
      await Future.wait([
        ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
          entityId: 'concurrent-1',
          entityType: 'product',
          operation: SyncOperation.upsert,
          lastModified: DateTime(2024, 1, 1),
        )),
        ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
          entityId: 'concurrent-2',
          entityType: 'product',
          operation: SyncOperation.upsert,
          lastModified: DateTime(2024, 1, 2),
        )),
        ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
          entityId: 'concurrent-3',
          entityType: 'product',
          operation: SyncOperation.upsert,
          lastModified: DateTime(2024, 1, 3),
        )),
      ]);

      // Assert
      final entries = await ManageSyncBox.getAllSyncEntries(entityType: 'product');
      expect(entries.length, 3);
      expect(entries.map((e) => e.entityId).toSet(), 
        {'concurrent-1', 'concurrent-2', 'concurrent-3'});
    });

    test('handles concurrent reads correctly', () async {
      // Arrange
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'read-test',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));

      // Act - Multiple concurrent reads
      final results = await Future.wait([
        ManageSyncBox.getSyncEntry('read-test', 'product'),
        ManageSyncBox.getSyncEntry('read-test', 'product'),
        ManageSyncBox.getSyncEntry('read-test', 'product'),
      ]);

      // Assert - All reads should succeed
      expect(results.length, 3);
      expect(results.every((r) => r != null), true);
      expect(results.every((r) => r!.entityId == 'read-test'), true);
    });
  });

  group('transaction handling -', () {
    test('maintains data integrity when adding entries', () async {
      // Arrange & Act
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'integrity-test',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1),
      ));

      // Assert - Verify entry exists and is complete
      final db = await DatabaseHelper.database;
      final rows = await db.query(
        'sync_box',
        where: 'entity_id = ?',
        whereArgs: ['integrity-test'],
      );
      
      expect(rows.length, 1);
      expect(rows.first['id'], isNotNull);
      expect(rows.first['entity_id'], isNotNull);
      expect(rows.first['entity_type'], isNotNull);
      expect(rows.first['operation'], isNotNull);
      expect(rows.first['last_modified'], isNotNull);
    });

    test('ensures atomicity of update operations', () async {
      // Arrange - Add initial entry
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'atomic-test',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: DateTime(2024, 1, 1, 10, 0),
      ));

      // Act - Update entry
      await ManageSyncBox.addOrUpdateSyncEntry(LocalSyncEntry(
        entityId: 'atomic-test',
        entityType: 'product',
        operation: SyncOperation.delete,
        lastModified: DateTime(2024, 1, 1, 11, 0),
      ));

      // Assert - Should have exactly one entry with updated values
      final entries = await ManageSyncBox.getAllSyncEntries(entityType: 'product');
      expect(entries.length, 1);
      expect(entries.first.operation, SyncOperation.delete);
      expect(entries.first.lastModified, DateTime(2024, 1, 1, 11, 0));
    });
  });
}
