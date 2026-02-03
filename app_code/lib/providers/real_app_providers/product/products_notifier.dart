import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/providers/real_app_providers/product/product_repositories_provider.dart';

/// Notifier for managing products
/// Handles add, update, and delete operations with automatic sync
class ProductsNotifier extends Notifier<Map<String, Product>> {
  @override
  Map<String, Product> build() {
    // Start with empty cache
    return {};
  }

  /// Add a new product (will be synced to Firestore)
  Future<void> addProduct(Product product) async {
    final repository = ref.watch(productRepositoryProvider);
    await repository.add(product);
    // Update local cache
    state = {...state, product.id: product};
  }

  /// Update an existing product (will be synced to Firestore)
  Future<void> updateProduct(Product product) async {
    final repository = ref.watch(productRepositoryProvider);
    await repository.update(product);
    // Update local cache
    state = {...state, product.id: product};
  }

  /// Delete a product by ID (will be synced to Firestore)
  Future<void> deleteProductById(String id) async {
    final repository = ref.watch(productRepositoryProvider);
    await repository.deleteById(id);
    // Update local cache
    final newState = {...state};
    newState.remove(id);
    state = newState;
  }

  /// Get a product by ID
  Future<Product?> getProductById(String id) async {
    final repository = ref.watch(productRepositoryProvider);
    return await repository.getById(id);
  }

  /// Cache a product in local state
  void cacheProduct(Product product) {
    state = {...state, product.id: product};
  }

  /// Get cached product by ID
  Product? getCachedProduct(String id) {
    return state[id];
  }
}

/// Provider for products management
final productsProvider =
    NotifierProvider<ProductsNotifier, Map<String, Product>>(
      () => ProductsNotifier(),
    );
