    import 'package:app_code/models/sync/sync_operation.dart';
import 'package:uuid/uuid.dart';

/// Represents a pending synchronization entry in the local sync queue.
/// Used to track changes that need to be synchronized to Firestore.
class LocalSyncEntry {
  /// Unique identifier for this sync entry
  final String id;

  /// The ID of the entity being synchronized
  final String entityId;

  /// The type of entity (e.g., 'shopping_list', 'product', 'purchased_product')
  final String entityType;

  /// The type of operation to perform (upsert or delete)
  final SyncOperation operation;

  /// Timestamp of the last modification on the local device
  /// This is used for last-write-wins conflict resolution
  final DateTime lastModified;

  LocalSyncEntry({
    String? id,
    required this.entityId,
    required this.entityType,
    required this.operation,
    required this.lastModified,
  }) : id = id ?? const Uuid().v4();

  /// Convert LocalSyncEntry to database map format
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'entity_id': entityId,
      'entity_type': entityType,
      'operation': operation.toDb(),
      'last_modified': lastModified.toIso8601String(),
    };
  }

  /// Create LocalSyncEntry from database map
  factory LocalSyncEntry.fromDatabase(Map<String, dynamic> data) {
    return LocalSyncEntry(
      id: data['id'] as String,
      entityId: data['entity_id'] as String,
      entityType: data['entity_type'] as String,
      operation: SyncOperation.fromDb(data['operation'] as String),
      lastModified: DateTime.parse(data['last_modified'] as String),
    );
  }

  @override
  String toString() =>
      'LocalSyncEntry(id: $id, entityId: $entityId, entityType: $entityType, '
      'operation: $operation, lastModified: $lastModified)';
}
