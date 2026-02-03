import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/product/product_repositories_provider.dart';

/// State representing pending associations waiting to be persisted
/// Maps productId -> Map<supermarketId, categoryId>
typedef AssociationMap = Map<String, Map<String, String>>;

/// Notifier for managing product-category associations
/// Handles add, update, and batch operations with automatic sync
class AssociationsNotifier extends Notifier<AssociationMap> {
  @override
  AssociationMap build() {
    // Start with empty pending associations
    return {};
  }

  /// Mark an association change for persistence
  /// This tracks pending associations that will be saved when flushAssociations() is called
  void markAssociationChanged(
    String productId,
    String supermarketId,
    String categoryId,
  ) {
    if (!state.containsKey(productId)) {
      state = {...state, productId: {}};
    }
    final productAssocs = state[productId]!;
    productAssocs[supermarketId] = categoryId;
    state = {...state}; // Trigger rebuild
  }

  /// Get pending associations for a specific product
  Map<String, String>? getPendingAssociations(String productId) {
    return state[productId];
  }

  /// Check if there are any pending associations
  bool hasPendingAssociations() {
    return state.isNotEmpty;
  }

  /// Flush all pending associations to the database
  /// This persists all tracked associations and clears the pending state
  Future<void> flushAssociations() async {
    if (state.isEmpty) return;

    final repository = ref.watch(associationRepositoryProvider);
    try {
      // Persist all pending associations using batch operation
      await repository.addBatch(state);
      // Clear pending associations after successful save
      state = {};
    } catch (e) {
      rethrow;
    }
  }

  /// Clear pending associations without persisting
  /// Useful for rollback scenarios
  void clearPending() {
    state = {};
  }

  /// Clear pending associations for a specific product
  void clearPendingForProduct(String productId) {
    final newState = {...state};
    newState.remove(productId);
    state = newState;
  }
}

/// Provider for associations management
final associationsProvider = NotifierProvider<AssociationsNotifier, AssociationMap>(
  () => AssociationsNotifier(),
);
