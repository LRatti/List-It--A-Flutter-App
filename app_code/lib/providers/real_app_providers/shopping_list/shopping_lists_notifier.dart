import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/repositories/sync/shopping_list_repository_sync.dart';
import 'package:app_code/repositories/abstract/shopping_list_repository.dart';
import 'package:app_code/providers/real_app_providers/recipe/recipe_provider.dart';

/// Provides the current time (injectable for testability).
final currentDateTimeProvider = Provider<DateTime>((ref) => DateTime.now());

/// Provides the concrete repository implementation.
final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  return ShoppingListRepositoryWithSync();
});

/// Exposes a Riverpod AsyncNotifier that holds all shopping lists.
final shoppingListsProvider =
    AsyncNotifierProvider<ShoppingListsNotifier, List<ShoppingList>>(
      ShoppingListsNotifier.new,
    );

/// Provides a single shopping list by ID, fetching fresh data from the repository.
/// This ensures the shopping list always has the latest state from the database,
/// including any changes made in other screens (e.g., toggled products).
/// 
/// Uses .autoDispose to ensure the provider refetches data each time it's watched,
/// preventing stale cached data from being displayed after database updates.
final shoppingListProvider =
    FutureProvider.family.autoDispose<ShoppingList, String>((ref, id) async {
  final repository = ref.watch(shoppingListRepositoryProvider);
  final allLists = await repository.getAll();
  final list = allLists.firstWhere(
    (l) => l.id == id,
    orElse: () => throw Exception('Shopping list with ID $id not found'),
  );
  return list;
});

/// Manages shopping lists state and delegates persistence to the repository.
/// 
/// Design principles:
/// - build() is pure: loads data without mutations
/// - state updates are in-memory (no redundant repository.getAll() calls)
/// - repository is watched (reactive to provider overrides)
/// - time is injectable via currentDateTimeProvider for testability
/// - cleanup is explicit via cleanupExpiredLists() method
class ShoppingListsNotifier extends AsyncNotifier<List<ShoppingList>> {
  /// Loads all shopping lists from the repository.
  /// Side-effect free: only loads data, doesn't delete anything.
  /// Call cleanupExpiredLists() explicitly to remove expired trash items.
  @override
  Future<List<ShoppingList>> build() async {
    // Use ref.watch for repository (reactive to overrides)
    final repository = ref.watch(shoppingListRepositoryProvider);
    return repository.getAll();
  }

  /// Persists a new list and updates state in-memory (efficient).
  Future<void> addList(ShoppingList list) async {
    final repository = ref.watch(shoppingListRepositoryProvider);
    
    state = await AsyncValue.guard(() async {
      await repository.add(list);
      // Update in-memory: append new list
      final currentLists = state.value ?? [];
      return [...currentLists, list];
    });
  }

  /// Deletes a list from persistence and updates state in-memory.
  /// Automatically cancels related recipe searches.
  Future<void> deleteList(ShoppingList list) async {
    final repository = ref.watch(shoppingListRepositoryProvider);
    final backgroundRecipeNotifier = 
        ref.read(backgroundRecipeProvider.notifier);

    state = await AsyncValue.guard(() async {
      await repository.delete(list);
      // Cancel ongoing recipe search for this list
      await backgroundRecipeNotifier.cancelSearchForList(list.id);
      
      // Update in-memory: filter out deleted list by stable ID
      final currentLists = state.value ?? [];
      return currentLists.where((l) => l.id != list.id).toList();
    });
  }

  /// Updates a list in persistence and updates state in-memory.
  /// If list is moved to trash, automatically cancels recipe searches.
  Future<void> updateList(ShoppingList list) async {
    final repository = ref.watch(shoppingListRepositoryProvider);

    state = await AsyncValue.guard(() async {
      await repository.update(list);

      // If moved to trash, cancel recipe searches
      if (list.getIsInTheTrash()) {
        final backgroundRecipeNotifier =
            ref.read(backgroundRecipeProvider.notifier);
        await backgroundRecipeNotifier.cancelSearchForList(list.id);
      }

      // Update in-memory: replace updated list by stable ID
      final currentLists = state.value ?? [];
      return [
        for (final l in currentLists)
          if (l.id == list.id) list else l,
      ];
    });
  }

  /// Explicitly clean up lists that have been in trash for more than 30 days.
  /// This should be called explicitly (e.g., from UI initialization or a periodic timer).
  /// 
  /// Uses injectable time via [currentDateTimeProvider] for testability.
  /// Cancels recipe searches for all deleted lists.
  Future<void> cleanupExpiredLists() async {
    final repository = ref.watch(shoppingListRepositoryProvider);
    final now = ref.read(currentDateTimeProvider);
    final backgroundRecipeNotifier = ref.read(backgroundRecipeProvider.notifier);
    
    state = await AsyncValue.guard(() async {
      final currentLists = state.value ?? [];
      final expiredIds = <String>{};

      // Identify expired trash items by stable ID
      for (final list in currentLists) {
        if (list.getIsInTheTrash() && list.getDeletionTimestamp() != null) {
          final daysSinceDeletion = now.difference(list.getDeletionTimestamp()!).inDays;
          if (daysSinceDeletion >= 30) {
            expiredIds.add(list.id);
            // Delete from repository
            await repository.delete(list);
            // Cancel any ongoing recipe search
            await backgroundRecipeNotifier.cancelSearchForList(list.id);
          }
        }
      }

      // Update in-memory: filter out expired lists by stable ID
      return currentLists.where((l) => !expiredIds.contains(l.id)).toList();
    });
  }
}
