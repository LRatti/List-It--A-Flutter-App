import 'package:app_code/models/product.dart';
import 'package:app_code/repositories/abstract/product_repository.dart';

/// In-memory implementation used only for tests.
/// It behaves like a real repository but without persistence.
/// Implements the same interface as ProductRepositoryWithSync for testing.
class MockProductRepository implements ProductRepository {
  final List<Product> _products = [];

  Future<List<Product>> getAll() async {
    return List.from(_products);
  }

  Future<void> add(Product product) async {
    _products.add(product);
  }

  Future<void> update(Product product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
    }
  }

  Future<void> deleteById(String id) async {
    _products.removeWhere((p) => p.id == id);
  }

  Future<Product?> getById(String id) async {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear all products (useful for testing)
  void clear() {
    _products.clear();
  }
}
