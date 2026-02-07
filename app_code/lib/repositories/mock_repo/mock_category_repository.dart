import 'package:app_code/models/category.dart';
import 'package:app_code/repositories/abstract/category_repository.dart';

/// In-memory implementation used only for widget tests.
/// It behaves like a real repository but without persistence.
/// Implements the same interface as CategoryRepositoryWithSync for testing.
class MockCategoryRepository implements CategoryRepository {
  final List<Category> _categories = [];

  @override
  Future<List<Category>> getAll() async {
    return List.from(_categories);
  }

  @override
  Future<void> add(Category category) async {
    _categories.add(category);
  }

  @override
  Future<void> update(Category category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
    }
  }

  @override
  Future<void> deleteById(String id) async {
    _categories.removeWhere((c) => c.id == id);
  }

  @override
  Future<Category?> getById(String id) async {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear all categories (useful for testing)
  void clear() {
    _categories.clear();
  }
}
