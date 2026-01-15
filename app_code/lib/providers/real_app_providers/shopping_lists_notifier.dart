import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/repositories/real_app_repo/shopping_list_repository_db.dart';
import 'package:app_code/repositories/abstract/shopping_list_repository.dart';

/// Exposes a Riverpod AsyncNotifier that holds all shopping lists.
final shoppingListsProvider =
    AsyncNotifierProvider<ShoppingListsNotifier, List<ShoppingList>>(
  ShoppingListsNotifier.new,
);

/// Provides the concrete repository implementation (SQLite here).
// TODO: use manage_database instead of direct SQLite access
final shoppingListRepositoryProvider =
    Provider<ShoppingListRepository>((ref) {
  return ShoppingListRepositoryDb();
});

/// Manages shopping lists state and delegates persistence to the repository.
class ShoppingListsNotifier extends AsyncNotifier<List<ShoppingList>> {
  
  late final ShoppingListRepository  _repository;

  /// Initializes the repository and loads all shopping lists.
  /// Automatically deletes any lists in trash that have exceeded 30 days.
  @override
  Future<List<ShoppingList>> build() async {
    _repository = ref.read(shoppingListRepositoryProvider);
    final allLists = await _repository.getAll();
    
    // Check for lists that should be auto-deleted (in trash for 30+ days)
    final now = DateTime.now();
    final listsToDelete = <ShoppingList>[];
    
    for (final list in allLists) {
      if (list.getIsInTheTrash() && list.getDeletionTimestamp() != null) {
        final daysSinceDeletion = now.difference(list.getDeletionTimestamp()!).inDays;
        if (daysSinceDeletion >= 30) {
          listsToDelete.add(list);
        }
      }
    }
    
    // Delete any expired lists
    for (final list in listsToDelete) {
      await _repository.delete(list);
    }
    
    // Return the filtered list (without the deleted ones)
    return allLists.where((l) => !listsToDelete.contains(l)).toList();
  }

  /// Persists a new list, then appends it to the in-memory state.
  Future<void> addList(ShoppingList list) async {
    await _repository.add(list);
    state = AsyncData([...state.value ?? [], list]);
  }

  /// Deletes a list from persistence and removes it from state.
  Future<void> deleteList(ShoppingList list) async {
    await _repository.delete(list);
    state = AsyncData(
      state.value!.where((l) => l.id != list.id).toList(),
    );
  }

  /// Updates a list in persistence and replaces it in state.
  Future<void> updateList(ShoppingList list) async {
    await _repository.update(list);
    state = AsyncData([
      for (final l in state.value!)
        if (l.id == list.id) list else l
    ]);
  }
}
