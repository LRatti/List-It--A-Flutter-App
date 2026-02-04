import 'package:app_code/models/category.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for products being categorized (in buffer zone)
class BufferProduct {
  final String name;
  final bool isLoading;
  final String? error;

  BufferProduct({required this.name, this.isLoading = true, this.error});

  BufferProduct copyWith({String? name, bool? isLoading, String? error}) {
    return BufferProduct(
      name: name ?? this.name,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// State class to hold the complete list detail screen state
/// This is the single source of truth for all UI state
class SelectedListState {
  final ShoppingList? list;
  final Supermarket? supermarket;
  final String listName;
  final List<PurchasedProduct> products;
  final Map<String, BufferProduct> bufferProducts;
  final bool hasChanges;
  final Category? uncategorizedFallback;

  SelectedListState({
    required this.list,
    required this.supermarket,
    required this.listName,
    required this.products,
    required this.bufferProducts,
    required this.hasChanges,
    this.uncategorizedFallback,
  });

  SelectedListState copyWith({
    ShoppingList? list,
    Supermarket? supermarket,
    String? listName,
    List<PurchasedProduct>? products,
    Map<String, BufferProduct>? bufferProducts,
    bool? hasChanges,
    Category? uncategorizedFallback,
  }) {
    return SelectedListState(
      list: list ?? this.list,
      supermarket: supermarket ?? this.supermarket,
      listName: listName ?? this.listName,
      products: products ?? this.products,
      bufferProducts: bufferProducts ?? this.bufferProducts,
      hasChanges: hasChanges ?? this.hasChanges,
      uncategorizedFallback: uncategorizedFallback ?? this.uncategorizedFallback,
    );
  }
}

/// Notifier to manage the currently selected shopping list and all its state
/// This is the single source of truth for the list detail screen
class SelectedListNotifier extends AsyncNotifier<SelectedListState> {
  @override
  Future<SelectedListState> build() async {
    // Initialize with no selected list
    return SelectedListState(
      list: null,
      supermarket: null,
      listName: '',
      products: [],
      bufferProducts: {},
      hasChanges: false,
    );
  }

  /// Select a shopping list and initialize its state
  Future<void> selectList(ShoppingList list) async {
    state = AsyncValue.data(
      SelectedListState(
        list: list,
        supermarket: list.getSupermarket(),
        listName: list.getName(),
        products: List.from(list.getProducts()),
        bufferProducts: {},
        hasChanges: false,
      ),
    );
  }

  /// Clear the selected shopping list
  Future<void> clearSelection() async {
    state = AsyncValue.data(
      SelectedListState(
        list: null,
        supermarket: null,
        listName: '',
        products: [],
        bufferProducts: {},
        hasChanges: false,
      ),
    );
  }

  /// Update list name
  void updateListName(String newName) {
    final currentState = state.value;
    if (currentState == null || currentState.listName == newName) return;

    state = AsyncValue.data(
      currentState.copyWith(
        listName: newName,
        hasChanges: true,
      ),
    );
  }

  /// Update selected supermarket
  void updateSupermarket(Supermarket? newSupermarket) {
    final currentState = state.value;
    if (currentState == null) return;

    final isNew = currentState.supermarket?.id != newSupermarket?.id;
    final isUpdated =
        currentState.supermarket?.id == newSupermarket?.id &&
        currentState.supermarket != newSupermarket;

    if (isNew || isUpdated) {
      state = AsyncValue.data(
        currentState.copyWith(
          supermarket: newSupermarket,
          hasChanges: isNew ? true : currentState.hasChanges,
        ),
      );
    }
  }

  /// Update products list
  void updateProducts(List<PurchasedProduct> products) {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(
      currentState.copyWith(
        products: List.from(products),
        hasChanges: true,
      ),
    );
  }

  /// Add a product to buffer zone
  void addToBuffer(String productName) {
    final currentState = state.value;
    if (currentState == null) return;

    final newBufferProducts = Map<String, BufferProduct>.from(
      currentState.bufferProducts,
    );
    newBufferProducts[productName] = BufferProduct(name: productName);

    state = AsyncValue.data(
      currentState.copyWith(bufferProducts: newBufferProducts),
    );
  }

  /// Update buffer product state
  void updateBufferProduct(
    String productName, {
    bool? isLoading,
    String? error,
  }) {
    final currentState = state.value;
    if (currentState == null ||
        !currentState.bufferProducts.containsKey(productName)) {
      return;
    }

    final newBufferProducts = Map<String, BufferProduct>.from(
      currentState.bufferProducts,
    );
    newBufferProducts[productName] = newBufferProducts[productName]!.copyWith(
      isLoading: isLoading,
      error: error,
    );

    state = AsyncValue.data(
      currentState.copyWith(bufferProducts: newBufferProducts),
    );
  }

  /// Remove product from buffer zone
  void removeFromBuffer(String productName) {
    final currentState = state.value;
    if (currentState == null) return;

    final newBufferProducts = Map<String, BufferProduct>.from(
      currentState.bufferProducts,
    );
    newBufferProducts.remove(productName);

    state = AsyncValue.data(
      currentState.copyWith(bufferProducts: newBufferProducts),
    );
  }

  /// Set uncategorized fallback category
  void setUncategorizedFallback(Category category) {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(
      currentState.copyWith(uncategorizedFallback: category),
    );
  }

  /// Mark that changes have been saved
  void markChangesSaved() {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(
      currentState.copyWith(hasChanges: false),
    );
  }

  /// Get the currently selected list ID (if any)
  String? getSelectedListId() {
    return state.value?.list?.id;
  }

  /// Check if a specific list is currently selected
  bool isSelected(String listId) {
    return state.value?.list?.id == listId;
  }

  /// Get the supermarket associated with the currently selected list
  Supermarket? getSelectedSupermarket() {
    return state.value?.supermarket;
  }
}

/// Provider for the selected list state.
final selectedListProvider =
    AsyncNotifierProvider<SelectedListNotifier, SelectedListState>(
  SelectedListNotifier.new,
);
