import 'package:app_code/models/shopping_list.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_list_notifier.g.dart';

/// AsyncNotifier to manage the currently selected shopping list across screens
@riverpod
class SelectedListNotifier extends _$SelectedListNotifier {
  @override
  Future<ShoppingList?> build() async {
    // Initialize with no selected list
    return null;
  }

  /// Select a shopping list
  Future<void> selectList(ShoppingList list) async {
    state = AsyncValue.data(list);
  }

  /// Clear the selected shopping list
  Future<void> clearSelection() async {
    state = const AsyncValue.data(null);
  }

  /// Update the selected shopping list with new data
  Future<void> updateSelectedList(ShoppingList updatedList) async {
    final currentList = state.value;
    if (currentList != null && currentList.id == updatedList.id) {
      state = AsyncValue.data(updatedList);
    }
  }

  /// Get the currently selected list ID (if any)
  String? getSelectedListId() {
    return state.value?.id;
  }

  /// Check if a specific list is currently selected
  bool isSelected(String listId) {
    return state.value?.id == listId;
  }
}
