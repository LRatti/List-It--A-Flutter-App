import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class to hold both shopping list and its associated supermarket
class SelectedListState {
  final ShoppingList? list;
  final Supermarket? supermarket;

  SelectedListState({
    required this.list,
    required this.supermarket,
  });

  SelectedListState copyWith({
    ShoppingList? list,
    Supermarket? supermarket,
  }) {
    return SelectedListState(
      list: list ?? this.list,
      supermarket: supermarket ?? this.supermarket,
    );
  }
}

/// Notifier to manage the currently selected shopping list and its supermarket across screens
class SelectedListNotifier extends AsyncNotifier<SelectedListState> {
  @override
  Future<SelectedListState> build() async {
    // Initialize with no selected list and no supermarket
    return SelectedListState(list: null, supermarket: null);
  }

  /// Select a shopping list (preserves current supermarket if list is same)
  Future<void> selectList(ShoppingList list) async {
    final currentState = state.value;
    // If selecting the same list, preserve the supermarket
    final supermarket = currentState?.list?.id == list.id
        ? currentState?.supermarket
        : list.getSupermarket();
    state = AsyncValue.data(
      SelectedListState(list: list, supermarket: supermarket),
    );
  }

  /// Clear the selected shopping list
  Future<void> clearSelection() async {
    state = AsyncValue.data(
      SelectedListState(list: null, supermarket: null),
    );
  }

  /// Update the selected shopping list with new data
  Future<void> updateSelectedList(ShoppingList updatedList) async {
    final currentState = state.value;
    if (currentState?.list != null &&
        currentState!.list!.id == updatedList.id) {
      state = AsyncValue.data(
        SelectedListState(
          list: updatedList,
          supermarket: currentState.supermarket,
        ),
      );
    }
  }

  /// Get the currently selected list ID (if any)
  String? getSelectedListId() {
    return state.value?.list?.id;
  }

  /// Check if a specific list is currently selected
  bool isSelected(String listId) {
    return state.value?.list?.id == listId;
  }

  /// Update the supermarket for the currently selected list
  Future<void> updateSelectedSupermarket(Supermarket? supermarket) async {
    final currentState = state.value;
    if (currentState?.list != null) {
      state = AsyncValue.data(
        SelectedListState(
          list: currentState!.list,
          supermarket: supermarket,
        ),
      );
    }
  }

  /// Get the supermarket associated with the currently selected list
  Supermarket? getSelectedSupermarket() {
    return state.value?.supermarket;
  }

  /// Set supermarket info when navigating to customization
  /// This allows the supermarket customization screen to know which list it's working for
  Future<void> setSupermarketBeingCustomized(Supermarket? supermarket) async {
    final currentState = state.value;
    state = AsyncValue.data(
      SelectedListState(
        list: currentState?.list,
        supermarket: supermarket,
      ),
    );
  }
}

/// Provider for the selected list state.
final selectedListProvider =
    AsyncNotifierProvider<SelectedListNotifier, SelectedListState>(
  SelectedListNotifier.new,
);
