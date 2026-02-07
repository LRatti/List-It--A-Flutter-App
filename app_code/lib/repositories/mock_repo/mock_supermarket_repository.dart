import 'package:app_code/models/supermarket.dart';
import 'package:app_code/repositories/sync/supermarket_repository_sync.dart';

/// In-memory implementation of SupermarketRepositoryWithSync used for testing.
/// It behaves like a real repository but without persistence or sync.
/// Provides spy functionality to track method calls.
class MockSupermarketRepository extends SupermarketRepositoryWithSync {
  final List<Supermarket> _supermarkets = [];

  // Spy tracking for method calls
  int addCallCount = 0;
  int updateCallCount = 0;
  int deleteCallCount = 0;
  int getByIdCallCount = 0;
  int getAllCallCount = 0;

  @override
  Future<List<Supermarket>> getAll() async {
    getAllCallCount++;
    return List.from(_supermarkets);
  }

  @override
  Future<void> add(Supermarket supermarket) async {
    addCallCount++;
    if (!_supermarkets.any((s) => s.id == supermarket.id)) {
      _supermarkets.add(supermarket);
    }
  }

  @override
  Future<void> update(Supermarket supermarket) async {
    updateCallCount++;
    final index = _supermarkets.indexWhere((s) => s.id == supermarket.id);
    if (index != -1) {
      _supermarkets[index] = supermarket;
    }
  }

  @override
  Future<void> deleteById(String id) async {
    deleteCallCount++;
    _supermarkets.removeWhere((s) => s.id == id);
  }

  @override
  Future<Supermarket?> getById(String id) async {
    getByIdCallCount++;
    try {
      return _supermarkets.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear all supermarkets and reset spy counters
  void clear() {
    _supermarkets.clear();
    resetSpies();
  }

  /// Reset all spy counters
  void resetSpies() {
    addCallCount = 0;
    updateCallCount = 0;
    deleteCallCount = 0;
    getByIdCallCount = 0;
    getAllCallCount = 0;
  }

  /// Verify specific method was called
  void verifyAddCalled(int times) {
    assert(addCallCount == times, 'add() called $addCallCount times, expected $times');
  }

  void verifyUpdateCalled(int times) {
    assert(updateCallCount == times, 'update() called $updateCallCount times, expected $times');
  }

  void verifyDeleteCalled(int times) {
    assert(deleteCallCount == times, 'deleteById() called $deleteCallCount times, expected $times');
  }

  void verifyGetByIdCalled(int times) {
    assert(getByIdCallCount == times, 'getById() called $getByIdCallCount times, expected $times');
  }

  void verifyGetAllCalled(int times) {
    assert(getAllCallCount == times, 'getAll() called $getAllCallCount times, expected $times');
  }
}
