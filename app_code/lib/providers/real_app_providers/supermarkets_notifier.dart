import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/repositories/real_app_repo/database_manager_repository/manage_supermarket.dart';
import 'package:app_code/repositories/real_app_repo/database_manager_repository/manage_category.dart';
import 'package:app_code/repositories/sync/supermarket_repository_sync.dart';
import 'package:app_code/services/database/sqlite/manage_supermarket.dart'
    as sqlite_supermarket;

/// State notifier for managing supermarkets list
/// Uses sync-aware repository for automatic Firestore synchronization
class SupermarketsNotifier extends AsyncNotifier<List<Supermarket>> {
  late final SupermarketRepositoryWithSync _syncRepo =
      SupermarketRepositoryWithSync();

  @override
  Future<List<Supermarket>> build() async {
    return await _syncRepo.getAll();
  }

  /// Add a new supermarket (will be synced to Firestore)
  Future<void> addSupermarket(Supermarket supermarket) async {
    await _syncRepo.add(supermarket);
    ref.invalidateSelf();
  }

  /// Update an existing supermarket (will be synced to Firestore)
  Future<void> updateSupermarket(Supermarket supermarket) async {
    await _syncRepo.update(supermarket);
    ref.invalidateSelf();
  }

  /// Delete a supermarket (mark as invisible, will be synced)
  Future<void> deleteSupermarket(String id) async {
    final supermarket = await _syncRepo.getById(id);
    if (supermarket != null) {
      supermarket.setVisibility(false);
      await _syncRepo.update(supermarket);
      ref.invalidateSelf();
    }
  }

  /// Delete multiple supermarkets (mark as invisible instead of actually deleting)
  /// Returns the number of supermarkets successfully deleted
  Future<int> deleteSupermarkets(List<String> ids) async {
    int deletedCount = 0;

    for (final id in ids) {
      final supermarket = await _syncRepo.getById(id);
      if (supermarket != null) {
        supermarket.setVisibility(false);
        await _syncRepo.update(supermarket);
        deletedCount++;
      }
    }

    ref.invalidateSelf();
    return deletedCount;
  }

  /// Reorder categories in a supermarket (will be synced)
  Future<void> reorderCategories(
    String supermarketId,
    List<Category> categories,
  ) async {
    await sqlite_supermarket.ManageSupermarket.replaceCategoriesOrder(
      supermarketId,
      categories,
    );

    // Mark the supermarket as updated for sync
    final supermarket = await _syncRepo.getById(supermarketId);
    if (supermarket != null) {
      await _syncRepo.update(supermarket);
    }

    ref.invalidateSelf();
  }

  /// Add a category to a supermarket (will be synced)
  Future<void> addCategoryToSupermarket(
    String supermarketId,
    Category category,
  ) async {
    final supermarket = await _syncRepo.getById(supermarketId);
    if (supermarket != null) {
      final categories = supermarket.getCategories();
      categories.add(category);
      supermarket.setCategories(categories);
      await _syncRepo.update(supermarket);
      ref.invalidateSelf();
    }
  }

  /// Remove a category from a supermarket (will be synced)
  Future<void> removeCategoryFromSupermarket(
    String supermarketId,
    String categoryId,
  ) async {
    final supermarket = await _syncRepo.getById(supermarketId);
    if (supermarket != null) {
      final categories = supermarket.getCategories();
      categories.removeWhere((cat) => cat.id == categoryId);
      supermarket.setCategories(categories);
      await _syncRepo.update(supermarket);
      ref.invalidateSelf();
    }
  }

  /// Get a single supermarket by ID
  Future<Supermarket?> getSupermarketById(String id) async {
    return await _syncRepo.getById(id);
  }

  /// Get the last created supermarket (for initializing new ones)
  Future<Supermarket?> getLastCreatedSupermarket() async {
    final supermarkets = await _syncRepo.getAll();
    if (supermarkets.isEmpty) return null;
    // Sort by creation date, newest first
    supermarkets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return supermarkets.first;
  }
}

/// Provider for the supermarkets list
final supermarketsProvider =
    AsyncNotifierProvider<SupermarketsNotifier, List<Supermarket>>(
      () => SupermarketsNotifier(),
    );

/// Provider for getting a single supermarket by ID
final supermarketByIdProvider = FutureProvider.family<Supermarket?, String>((
  ref,
  id,
) async {
  final notifier = ref.watch(supermarketsProvider.notifier);
  return await notifier.getSupermarketById(id);
});

/// Provider for categories within a specific supermarket
final supermarketCategoriesProvider =
    FutureProvider.family<List<Category>, String>((ref, supermarketId) async {
      return await sqlite_supermarket
          .ManageSupermarket.getSupermarketCategories(supermarketId);
    });

/// Provider for tracking the last created supermarket configuration
final lastCreatedSupermarketProvider = FutureProvider<Supermarket?>((
  ref,
) async {
  final notifier = ref.watch(supermarketsProvider.notifier);
  return await notifier.getLastCreatedSupermarket();
});
