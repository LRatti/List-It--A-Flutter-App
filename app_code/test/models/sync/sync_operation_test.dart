import 'package:app_code/models/sync/sync_operation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncOperation', () {
    test('toDb returns enum name', () {
      expect(SyncOperation.upsert.toDb(), 'upsert');
      expect(SyncOperation.delete.toDb(), 'delete');
    });

    test('fromDb returns matching enum', () {
      expect(SyncOperation.fromDb('upsert'), SyncOperation.upsert);
      expect(SyncOperation.fromDb('delete'), SyncOperation.delete);
    });

    test('fromDb falls back to upsert for unknown values', () {
      expect(SyncOperation.fromDb('unknown'), SyncOperation.upsert);
      expect(SyncOperation.fromDb(''), SyncOperation.upsert);
    });
  });
}
