/// Abstract base class for repositories that support synchronization
/// Implementations must handle both user writes and sync writes differently
abstract class SyncRepository {
  /// Apply a remote update received from Firestore
  /// This method implements the "Silent Update" logic:
  /// - Does NOT write to sync_box to avoid infinite loops
  /// - Checks if entity is dirty (exists in sync_box)
  /// - Compares timestamps for conflict resolution
  /// - Handles soft deletes
  Future<void> applyRemoteUpdate(Map<String, dynamic> data);

  /// Retrieve local data for a given entity ID
  /// Returns the entity as a map that can be compared with remote data
  Future<Map<String, dynamic>?> getLocalData(String id);

  /// Get the entity type identifier for this repository
  /// Used by the Sync Engine to route updates correctly
  String getEntityType();
}

/// Entity type constants
const String ENTITY_TYPE_SHOPPING_LIST = 'shopping_list';
const String ENTITY_TYPE_PRODUCT = 'product';
const String ENTITY_TYPE_PURCHASED_PRODUCT = 'purchased_product';
const String ENTITY_TYPE_CATEGORY = 'category';
const String ENTITY_TYPE_SUPERMARKET = 'supermarket';
const String ENTITY_TYPE_USER = 'user';
