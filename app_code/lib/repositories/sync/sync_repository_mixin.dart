import 'package:app_code/models/sync/local_sync_entry.dart';
import 'package:app_code/models/sync/sync_operation.dart';
import 'package:app_code/services/database/sqlite/manage_sync_box.dart';
import 'package:app_code/utils/monotonic_timestamp.dart';

/// Mixin for repositories that support synchronization
/// Provides helper methods for managing sync_box entries and timestamps
mixin SyncRepositoryMixin {
  /// Append an upsert operation to the sync queue
  /// Uses the exact timestamp from the entity to avoid drift
  Future<void> appendUpsertToSyncBox(
    String entityId,
    String entityType,
    DateTime lastModified,
  ) async {
    final entry = LocalSyncEntry(
      entityId: entityId,
      entityType: entityType,
      operation: SyncOperation.upsert,
      lastModified: lastModified,
    );

    await ManageSyncBox.addOrUpdateSyncEntry(entry);
  }

  /// Append a delete operation to the sync queue
  /// Uses the exact timestamp from the entity to avoid drift
  Future<void> appendDeleteToSyncBox(
    String entityId,
    String entityType,
    DateTime lastModified,
  ) async {
    final entry = LocalSyncEntry(
      entityId: entityId,
      entityType: entityType,
      operation: SyncOperation.delete,
      lastModified: lastModified,
    );

    await ManageSyncBox.addOrUpdateSyncEntry(entry);
  }

  /// Check if an entity is dirty (has pending sync operations)
  Future<bool> isEntityDirty(String entityId, String entityType) async {
    return ManageSyncBox.isEntityDirty(entityId, entityType);
  }

  /// Clear sync entries for testing purposes
  Future<int> clearSyncEntriesForTesting() async {
    return ManageSyncBox.clearAllSyncEntries();
  }
}
