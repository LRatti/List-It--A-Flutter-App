import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/repositories/sync/category_repository_sync.dart';
import 'package:app_code/services/database/sqlite/manage_category.dart';

/// State notifier for managing categories
/// Uses sync-aware repository for automatic Firestore synchronization
class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  late final CategoryRepositoryWithSync _syncRepo =
      CategoryRepositoryWithSync();

  @override
  Future<List<Category>> build() async {
    return await _syncRepo.getAll();
  }

  /// Add a new category (will be synced to Firestore)
  Future<void> addCategory(Category category) async {
    await _syncRepo.add(category);
    ref.invalidateSelf();
  }

  /// Update an existing category (will be synced to Firestore)
  Future<void> updateCategory(Category category) async {
    await _syncRepo.update(category);
    ref.invalidateSelf();
  }

  /// Delete a category (mark as invisible instead of actually deleting)
  Future<void> deleteCategory(String id) async {
    final category = await _syncRepo.getById(id);
    if (category != null) {
      category.setVisibility(false);
      await _syncRepo.update(category);
      ref.invalidateSelf();
    }
  }

  /// Delete multiple categories (mark as invisible instead of actually deleting)
  /// Returns the number of categories successfully deleted
  Future<int> deleteCategories(List<String> ids) async {
    int deletedCount = 0;

    for (final id in ids) {
      final category = await _syncRepo.getById(id);
      if (category != null) {
        category.setVisibility(false);
        await _syncRepo.update(category);
        deletedCount++;
      }
    }

    ref.invalidateSelf();
    return deletedCount;
  }

  /// Get a category by ID
  Future<Category?> getCategoryById(String id) async {
    return await _syncRepo.getById(id);
  }

  /// Get a category by name
  Future<Category?> getCategoryByName(String name) async {
    return await ManageCategory.getCategoryByName(name);
  }

  /// Get all visible categories
  Future<List<Category>> getVisibleCategories() async {
    final all = await _syncRepo.getAll();
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
