import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/providers/real_app_providers/product_repositories_provider.dart';

/// Notifier for managing purchased products for a specific shopping list
/// Handles add, update, and delete operations with automatic sync
class PurchasedProductsNotifier
    extends Notifier<Map<String, PurchasedProduct>> {
  @override
  Map<String, PurchasedProduct> build() {
    // Start with empty cache
    return {};
  }

  /// Add a new purchased product (will be synced to Firestore)
  Future<void> addPurchasedProduct(PurchasedProduct product) async {
    final repository = ref.watch(purchasedProductRepositoryProvider);
    await repository.add(product);
    // Update local cache
    state = {...state, product.id: product};
  }

  /// Update an existing purchased product (will be synced to Firestore)
  Future<void> updatePurchasedProduct(PurchasedProduct product) async {
    final repository = ref.watch(purchasedProductRepositoryProvider);
    await repository.update(product);
    // Update local cache
    state = {...state, product.id: product};
  }

  /// Delete a purchased product by ID (will be synced to Firestore)
  Future<void> deletePurchasedProductById(String id) async {
    final repository = ref.watch(purchasedProductRepositoryProvider);
    await repository.deleteById(id);
    // Update local cache
    final newState = {...state};
    newState.remove(id);
    state = newState;
  }

  /// Get a purchased product by ID
  Future<PurchasedProduct?> getPurchasedProductById(String id) async {
    final repository = ref.watch(purchasedProductRepositoryProvider);
    return await repository.getById(id);
  }

  /// Cache a purchased product in local state
  void cachePurchasedProduct(PurchasedProduct product) {
    state = {...state, product.id: product};
  }

  /// Get cached purchased product by ID
  PurchasedProduct? getCachedPurchasedProduct(String id) {
    return state[id];
  }

  /// Remove from cache without deleting from database
  void removeCachedProduct(String id) {
    final newState = {...state};
    newState.remove(id);
    state = newState;
  }
}

/// Provider for purchased products management
final purchasedProductsProvider =
    NotifierProvider<PurchasedProductsNotifier, Map<String, PurchasedProduct>>(
      () => PurchasedProductsNotifier(),
    );
