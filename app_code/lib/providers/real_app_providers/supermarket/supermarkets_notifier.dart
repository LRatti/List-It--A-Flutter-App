import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/repositories/sync/supermarket_repository_sync.dart';
import 'package:app_code/services/database/sqlite/manage_supermarket.dart'
    as sqlite_supermarket;

/// Provides the supermarket repository implementation (injectable for testing).
final supermarketRepositoryProvider =
    Provider<SupermarketRepositoryWithSync>((ref) {
  return SupermarketRepositoryWithSync();
});

/// Interface for database operations (allows mocking in tests).
/// This wraps the static ManageSupermarket class for dependency injection.
abstract class SupermarketDatabaseManager {
  Future<Supermarket?> getFavoriteSupermarket();
  Future<void> setFavoriteSupermarket(String supermarketId);
  Future<void> clearFavoriteSupermarket(String supermarketId);
  Future<List<Category>> getSupermarketCategories(String supermarketId);
  Future<void> replaceCategoriesOrder(
    String supermarketId,
    List<Category> categories,
  );
}

/// Real implementation that delegates to ManageSupermarket static methods
class RealSupermarketDatabaseManager implements SupermarketDatabaseManager {
  @override
  Future<Supermarket?> getFavoriteSupermarket() =>
      sqlite_supermarket.ManageSupermarket.getFavoriteSupermarket();

  @override
  Future<void> setFavoriteSupermarket(String supermarketId) =>
      sqlite_supermarket.ManageSupermarket.setFavoriteSupermarket(supermarketId);

  @override
  Future<void> clearFavoriteSupermarket(String supermarketId) =>
      sqlite_supermarket.ManageSupermarket.clearFavoriteSupermarket(supermarketId);

  @override
  Future<List<Category>> getSupermarketCategories(String supermarketId) =>
      sqlite_supermarket.ManageSupermarket.getSupermarketCategories(supermarketId);

  @override
  Future<void> replaceCategoriesOrder(
    String supermarketId,
    List<Category> categories,
  ) =>
      sqlite_supermarket.ManageSupermarket.replaceCategoriesOrder(
        supermarketId,
        categories,
      );
}

/// Provides the database manager implementation (injectable for testing).
final supermarketDatabaseManagerProvider =
    Provider<SupermarketDatabaseManager>((ref) {
  return RealSupermarketDatabaseManager();
});

/// State notifier for managing supermarkets list
/// Uses sync-aware repository for automatic Firestore synchronization
class SupermarketsNotifier extends AsyncNotifier<List<Supermarket>> {
  @override
  Future<List<Supermarket>> build() async {
    final repository = ref.watch(supermarketRepositoryProvider);
    return await repository.getAll();
  }

  /// Add a new supermarket (will be synced to Firestore)
  Future<void> addSupermarket(Supermarket supermarket) async {
    final repository = ref.watch(supermarketRepositoryProvider);
    await repository.add(supermarket);
    ref.invalidateSelf();
  }

  /// Update an existing supermarket (will be synced to Firestore)
  Future<void> updateSupermarket(Supermarket supermarket) async {
    final repository = ref.watch(supermarketRepositoryProvider);
    await repository.update(supermarket);
    ref.invalidateSelf();
  }

  /// Delete a supermarket (mark as invisible, will be synced)
  /// 
  /// If the deleted supermarket was marked as favorite, automatically
  /// selects another visible supermarket as the new favorite to maintain
  /// the single-favorite constraint.
  Future<void> deleteSupermarket(String id) async {
    final repository = ref.watch(supermarketRepositoryProvider);
    final dbManager = ref.watch(supermarketDatabaseManagerProvider);
    // Check if this is the favorite supermarket
    final currentFavorite = await dbManager.getFavoriteSupermarket();
    final isFavorite = currentFavorite?.id == id;

    final supermarket = await repository.getById(id);
    if (supermarket != null) {
      supermarket.setVisibility(false);
      await repository.update(supermarket);
      
      // If the deleted supermarket was favorite, find a new favorite
      if (isFavorite) {
        await _ensureNewFavoriteAfterDeletion(id);
      }

      ref.invalidateSelf();
    }
  }

  /// Delete multiple supermarkets (mark as invisible instead of actually deleting)
  /// Returns the number of supermarkets successfully deleted
  /// 
  /// If one of the deleted supermarkets was marked as favorite, automatically
  /// selects another visible supermarket as the new favorite.
  Future<int> deleteSupermarkets(List<String> ids) async {
    final repository = ref.watch(supermarketRepositoryProvider);
    final dbManager = ref.watch(supermarketDatabaseManagerProvider);
    int deletedCount = 0;

    // Check if the favorite is being deleted
    final currentFavorite = await dbManager.getFavoriteSupermarket();
    bool favoriteBeinDeleted = currentFavorite != null && ids.contains(currentFavorite.id);

    for (final id in ids) {
      final supermarket = await repository.getById(id);
      if (supermarket != null) {
        supermarket.setVisibility(false);
        await repository.update(supermarket);
        deletedCount++;
      }
    }

    // If the favorite was deleted, find a new favorite
    if (favoriteBeinDeleted) {
      await _ensureNewFavoriteAfterDeletion(currentFavorite.id);
    }

    ref.invalidateSelf();
    return deletedCount;
  }

  /// Helper method to ensure a new favorite is selected after the current one is deleted
  /// 
  /// This maintains the invariant that exactly one supermarket is always favorite.
  Future<void> _ensureNewFavoriteAfterDeletion(String deletedSupermarketId) async {
    final repository = ref.watch(supermarketRepositoryProvider);
    // Get all remaining visible supermarkets
    final allSupermarkets = await repository.getAll();
    final remainingVisible = allSupermarkets
        .where((s) => s.isVisible && s.id != deletedSupermarketId)
        .toList();

    if (remainingVisible.isEmpty) {
      // No supermarkets left, this shouldn't happen in normal operation
      print('⚠️ No visible supermarkets remaining after deletion');
      return;
    }

    // Set the first remaining visible supermarket as favorite
    await setFavoriteSupermarket(remainingVisible.first.id);
  }

  /// Reorder categories in a supermarket (will be synced)
  Future<void> reorderCategories(
    String supermarketId,
    List<Category> categories,
  ) async {
    final repository = ref.watch(supermarketRepositoryProvider);
    final dbManager = ref.watch(supermarketDatabaseManagerProvider);
    await dbManager.replaceCategoriesOrder(supermarketId, categories);

    // Mark the supermarket as updated for sync
    final supermarket = await repository.getById(supermarketId);
    if (supermarket != null) {
      await repository.update(supermarket);
    }

    ref.invalidateSelf();
  }

  /// Add a category to a supermarket (will be synced)
  Future<void> addCategoryToSupermarket(
    String supermarketId,
    Category category,
  ) async {
    final repository = ref.watch(supermarketRepositoryProvider);
    final supermarket = await repository.getById(supermarketId);
    if (supermarket != null) {
      final categories = supermarket.getCategories();
      categories.add(category);
      supermarket.setCategories(categories);
      await repository.update(supermarket);
      ref.invalidateSelf();
    }
  }

  /// Remove a category from a supermarket (will be synced)
  Future<void> removeCategoryFromSupermarket(
    String supermarketId,
    String categoryId,
  ) async {
    final repository = ref.watch(supermarketRepositoryProvider);
    final supermarket = await repository.getById(supermarketId);
    if (supermarket != null) {
      final categories = supermarket.getCategories();
      categories.removeWhere((cat) => cat.id == categoryId);
      supermarket.setCategories(categories);
      await repository.update(supermarket);
      ref.invalidateSelf();
    }
  }

  /// Get a single supermarket by ID
  Future<Supermarket?> getSupermarketById(String id) async {
    final repository = ref.watch(supermarketRepositoryProvider);
    return await repository.getById(id);
  }

  /// Get the last created supermarket (for initializing new ones)
  Future<Supermarket?> getLastCreatedSupermarket() async {
    final repository = ref.watch(supermarketRepositoryProvider);
    final supermarkets = await repository.getAll();
    if (supermarkets.isEmpty) return null;
    // Sort by creation date, newest first
    supermarkets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return supermarkets.first;
  }

  /// Get the last edited supermarket (for initializing new ones)
  Future<Supermarket?> getLastEditedSupermarket() async {
    final repository = ref.watch(supermarketRepositoryProvider);
    final dbManager = ref.watch(supermarketDatabaseManagerProvider);
    final supermarkets = await repository.getAll();
    final visible = supermarkets.where((s) => s.isVisible).toList();
    if (visible.isEmpty) return null;

    visible.sort((a, b) {
      final aModified = a.lastModified ?? a.createdAt;
      final bModified = b.lastModified ?? b.createdAt;
      return bModified.compareTo(aModified);
    });

    final lastEdited = visible.first;

    // Ensure categories are hydrated from SQLite (avoids empty template after cold start)
    if (lastEdited.getCategories().isEmpty) {
      final categories = await dbManager.getSupermarketCategories(lastEdited.id);
      if (categories.isNotEmpty) {
        lastEdited.setCategories(categories);
      }
    }

    return lastEdited;
  }

  /// Set a supermarket as favorite (will unset any previous favorite)
  Future<void> setFavoriteSupermarket(String supermarketId) async {
    final repository = ref.watch(supermarketRepositoryProvider);
    final dbManager = ref.watch(supermarketDatabaseManagerProvider);
    // Capture the previous favorite before updating local DB
    final previousFavorite = await dbManager.getFavoriteSupermarket();

    // Update in database (clears previous favorite and sets new one)
    await dbManager.setFavoriteSupermarket(supermarketId);

    // Update previous favorite in sync (if different)
    if (previousFavorite != null && previousFavorite.id != supermarketId) {
      final previous = await repository.getById(previousFavorite.id);
      if (previous != null) {
        previous.isFavorite = false;
        await repository.update(previous);
      }
    }

    // Update new favorite in sync
    final supermarket = await repository.getById(supermarketId);
    if (supermarket != null) {
      supermarket.isFavorite = true;
      await repository.update(supermarket);
    }

    ref.invalidateSelf();
  }

  /// Clear favorite status from a supermarket
  /// 
  /// NOTE: This method will NOT clear the favorite if it's the only one.
  /// The app enforces the constraint that exactly one supermarket must be favorite.
  /// If you need to change the favorite, use setFavoriteSupermarket() instead.
  /// 
  /// Returns false if the clear operation was prevented due to the single-favorite constraint.
  /// Returns true if the clear operation was successful.
  Future<bool> clearFavoriteSupermarket(String supermarketId) async {
    final repository = ref.watch(supermarketRepositoryProvider);
    final dbManager = ref.watch(supermarketDatabaseManagerProvider);
    // Check if this is the only favorite
    final currentFavorite = await dbManager.getFavoriteSupermarket();
    if (currentFavorite != null && currentFavorite.id == supermarketId) {
      // This is the current favorite, check if there are other supermarkets to become favorite
      final allVisible = (await repository.getAll()).where((s) => s.isVisible).toList();
      
      if (allVisible.length <= 1) {
        // This is the only supermarket, can't clear favorite
        print('⚠️ Cannot clear favorite from the only supermarket. Use setFavoriteSupermarket() to change it.');
        return false;
      }
      
      // There are other supermarkets, automatically set the first one as favorite
      final nextFavorite = allVisible.firstWhere((s) => s.id != supermarketId);
      await setFavoriteSupermarket(nextFavorite.id);
      return true;
    }

    // Not the current favorite, just clear it
    await dbManager.clearFavoriteSupermarket(supermarketId);

    // Get the supermarket and mark it as updated for sync
    final supermarket = await repository.getById(supermarketId);
    if (supermarket != null) {
      supermarket.isFavorite = false;
      await repository.update(supermarket);
    }

    ref.invalidateSelf();
    return true;
  }

  /// Get the current favorite supermarket
  Future<Supermarket?> getFavoriteSupermarket() async {
    final dbManager = ref.watch(supermarketDatabaseManagerProvider);
    return await dbManager.getFavoriteSupermarket();
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

/// Provider for tracking the favorite supermarket
final favoriteSupermarketProvider = FutureProvider<Supermarket?>((
  ref,
) async {
  final notifier = ref.watch(supermarketsProvider.notifier);
  return await notifier.getFavoriteSupermarket();
});

/// Provider for tracking the last edited supermarket configuration
final lastEditedSupermarketProvider = FutureProvider<Supermarket?>((
  ref,
) async {
  final notifier = ref.watch(supermarketsProvider.notifier);
  return await notifier.getLastEditedSupermarket();
});
