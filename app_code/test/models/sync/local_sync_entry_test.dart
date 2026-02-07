import 'package:app_code/models/sync/local_sync_entry.dart';
import 'package:app_code/models/sync/sync_operation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalSyncEntry', () {
    final fixedTime = DateTime(2024, 1, 2, 3, 4, 5);

    test('generates id when not provided', () {
      final entry1 = LocalSyncEntry(
        entityId: 'entity1',
        entityType: 'product',
        operation: SyncOperation.upsert,
        lastModified: fixedTime,
      );
      final entry2 = LocalSyncEntry(
        entityId: 'entity2',
        entityType: 'product',
        operation: SyncOperation.delete,
        lastModified: fixedTime,
      );

      expect(entry1.id.isNotEmpty, true);
      expect(entry2.id.isNotEmpty, true);
      expect(entry1.id, isNot(entry2.id));
    });

    test('keeps provided id', () {
      final entry = LocalSyncEntry(
        id: 'custom-id',
        entityId: 'entity1',
        entityType: 'shopping_list',
        operation: SyncOperation.upsert,
        lastModified: fixedTime,
      );

      expect(entry.id, 'custom-id');
    });

    test('toDatabase returns expected map', () {
      final entry = LocalSyncEntry(
        id: 'sync1',
        entityId: 'entity1',
        entityType: 'product',
        operation: SyncOperation.delete,
        lastModified: fixedTime,
      );

      final db = entry.toDatabase();

      expect(db['id'], 'sync1');
      expect(db['entity_id'], 'entity1');
      expect(db['entity_type'], 'product');
      expect(db['operation'], 'delete');
      expect(db['last_modified'], fixedTime.toIso8601String());
    });

    test('fromDatabase parses expected values', () {
      final db = {
        'id': 'sync2',
        'entity_id': 'entity2',
        'entity_type': 'purchased_product',
        'operation': 'upsert',
        'last_modified': fixedTime.toIso8601String(),
      };

      final entry = LocalSyncEntry.fromDatabase(db);

      expect(entry.id, 'sync2');
      expect(entry.entityId, 'entity2');
      expect(entry.entityType, 'purchased_product');
      expect(entry.operation, SyncOperation.upsert);
      expect(entry.lastModified, fixedTime);
    });

    test('toDatabase and fromDatabase roundtrip', () {
      final entry = LocalSyncEntry(
        id: 'sync3',
        entityId: 'entity3',
        entityType: 'shopping_list',
        operation: SyncOperation.upsert,
        lastModified: fixedTime,
      );

      final restored = LocalSyncEntry.fromDatabase(entry.toDatabase());

      expect(restored.id, 'sync3');
      expect(restored.entityId, 'entity3');
      expect(restored.entityType, 'shopping_list');
      expect(restored.operation, SyncOperation.upsert);
      expect(restored.lastModified, fixedTime);
    });

    test('toString includes key fields', () {
      final entry = LocalSyncEntry(
        id: 'sync4',
        entityId: 'entity4',
        entityType: 'product',
        operation: SyncOperation.delete,
        lastModified: fixedTime,
      );

      final text = entry.toString();

      expect(text, contains('LocalSyncEntry'));
      expect(text, contains('sync4'));
      expect(text, contains('entity4'));
      expect(text, contains('product'));
      expect(text, contains('delete'));
    });
  });
}
