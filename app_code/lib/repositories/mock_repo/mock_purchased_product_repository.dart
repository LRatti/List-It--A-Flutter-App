import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/repositories/sync/purchased_product_repository_sync.dart';

/// In-memory implementation used only for tests.
/// It behaves like a real repository but without persistence.
/// Implements the same interface as PurchasedProductRepositoryWithSync for testing.
class MockPurchasedProductRepository
    implements PurchasedProductRepositoryWithSync {
  final List<PurchasedProduct> _products = [];

  // Track all method calls for verification
  int addCallCount = 0;
  int updateCallCount = 0;
  int deleteByIdCallCount = 0;
  int getByIdCallCount = 0;

  Future<List<PurchasedProduct>> getAll() async {
    return List.from(_products);
  }

  Future<void> add(PurchasedProduct product) async {
    addCallCount++;
    _products.add(product);
  }

  Future<void> update(PurchasedProduct product) async {
    updateCallCount++;
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
    }
  }

  Future<void> deleteById(String id) async {
    deleteByIdCallCount++;
    _products.removeWhere((p) => p.id == id);
  }

  /// Delete a purchased product (convenience method)
  Future<void> delete(PurchasedProduct item) async {
    await deleteById(item.id);
  }

  Future<PurchasedProduct?> getById(String id) async {
    getByIdCallCount++;
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

  /// Reset call counters
  void resetCounters() {
    addCallCount = 0;
    updateCallCount = 0;
    deleteByIdCallCount = 0;
    getByIdCallCount = 0;
  }

  // Default implementations of abstract methods (not used in these tests)
  @override
  String getEntityType() => 'purchased_product';

  @override
  Future<void> applyRemoteUpdate(Map<String, dynamic> data) async {}

  Future<void> applyRemoteDelete(Map<String, dynamic> data) async {}

  @override
  Future<Map<String, dynamic>?> getLocalData(String entityId) async => null;

  @override
  Future<bool> isEntityDirty(String entityId, String entityType) async =>
      false;

  
  Future<List<Map<String, dynamic>>> getRemoteDeletes(String sinceTimestamp) async =>
      [];

  
  Future<List<Map<String, dynamic>>> getRemoteUpserts(String sinceTimestamp) async =>
      [];

  @override
  Future<void> appendUpsertToSyncBox(
    String entityId,
    String entityType,
    DateTime timestamp,
  ) async {}

  @override
  Future<void> appendDeleteToSyncBox(
    String entityId,
    String entityType,
    DateTime timestamp,
  ) async {}

  
  Future<void> clearSyncBox() async {}

  @override
  Future<int> clearSyncEntriesForTesting() async => 0;
}
