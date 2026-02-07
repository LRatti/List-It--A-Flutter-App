import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/repositories/abstract/category_repository.dart';
import 'package:app_code/repositories/sync/category_repository_sync.dart';
import 'package:app_code/services/database/sqlite/manage_category.dart';
import 'package:app_code/utils/uncategorized_category_utils.dart';

/// Provides the category repository implementation (injectable for testing).
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryWithSync();
});

/// State notifier for managing categories
/// Uses sync-aware repository for automatic Firestore synchronization
class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final repository = ref.watch(categoryRepositoryProvider);
    return await repository.getAll();
  }

  /// Add a new category (will be synced to Firestore)
  Future<void> addCategory(Category category) async {
    final repository = ref.watch(categoryRepositoryProvider);
    await repository.add(category);
    ref.invalidateSelf();
  }

  /// Update an existing category (will be synced to Firestore)
  Future<void> updateCategory(Category category) async {
    final repository = ref.watch(categoryRepositoryProvider);
    await repository.update(category);
    ref.invalidateSelf();
  }

  /// Delete a category (mark as invisible instead of actually deleting)
  Future<void> deleteCategory(String id) async {
    final repository = ref.watch(categoryRepositoryProvider);
    final category = await repository.getById(id);
    if (category != null &&
        !UncategorizedCategoryUtils.isUncategorized(category)) {
      category.setVisibility(false);
      await repository.update(category);
      ref.invalidateSelf();
    }
  }

  /// Delete multiple categories (mark as invisible instead of actually deleting)
  /// Returns the number of categories successfully deleted
  Future<int> deleteCategories(List<String> ids) async {
    final repository = ref.watch(categoryRepositoryProvider);
    int deletedCount = 0;

    for (final id in ids) {
      final category = await repository.getById(id);
      if (category != null &&
          !UncategorizedCategoryUtils.isUncategorized(category)) {
        category.setVisibility(false);
        await repository.update(category);
        deletedCount++;
      }
    }

    ref.invalidateSelf();
    return deletedCount;
  }

  /// Get a category by ID
  Future<Category?> getCategoryById(String id) async {
    final repository = ref.watch(categoryRepositoryProvider);
    return await repository.getById(id);
  }

  /// Get a category by name
  Future<Category?> getCategoryByName(String name) async {
    return await ManageCategory.getCategoryByName(name);
  }

  /// Get all visible categories
  Future<List<Category>> getVisibleCategories() async {
    final repository = ref.watch(categoryRepositoryProvider);
    final all = await repository.getAll();
    return all.where((cat) => cat.isVisible).toList();
  }
}

/// Provider for all categories
final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Category>>(
      () => CategoriesNotifier(),
    );

/// Provider for getting a single category by ID
final categoryByIdProvider = FutureProvider.family<Category?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(categoriesProvider.notifier);
  return await notifier.getCategoryById(id);
});

/// Provider for getting a single category by name
final categoryByNameProvider = FutureProvider.family<Category?, String>((
  ref,
  name,
) async {
  final notifier = ref.watch(categoriesProvider.notifier);
  return await notifier.getCategoryByName(name);
});

/// Provider for all visible categories
final visibleCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final notifier = ref.watch(categoriesProvider.notifier);
  return await notifier.getVisibleCategories();
});
