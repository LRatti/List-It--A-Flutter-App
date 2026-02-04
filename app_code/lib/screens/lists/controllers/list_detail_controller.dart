import 'package:app_code/providers/real_app_providers/shopping_list/selected_list_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/providers/real_app_providers/product/products_notifier.dart';
import 'package:app_code/providers/real_app_providers/purchased_products/purchased_products_notifier.dart';
import 'package:app_code/providers/real_app_providers/associations/associations_notifier.dart';
import 'package:app_code/services/database/sqlite/manage_product.dart';
import 'package:app_code/utils/uncategorized_category_utils.dart';
import 'package:app_code/screens/lists/controllers/purchased_product_update_handler.dart';
import 'package:app_code/providers/real_app_providers/supermarket/refreshed_supermarket_notifier.dart';

/// Controller that manages the logic for the list detail screen
/// All state is stored in selectedListProvider - this controller only contains business logic
/// and modifies the provider state, never holding its own state
class ListDetailController {
  final Ref _ref; // Riverpod ref for provider access
  final ShoppingList _originalList;
  final List<PurchasedProduct> _originalProducts; // Deep copy for comparison

  ListDetailController({
    required ShoppingList shoppingList,
    required Ref ref,
  })  : _ref = ref,
        _originalList = shoppingList,
        _originalProducts = List.from(shoppingList.getProducts() ?? []) {
    // Initialize listener to refreshedSupermarketNotifier
    _initializeRefreshedSupermarketListener();
  }

  // Getters that read from provider state
  SelectedListState get _state {
    final stateValue = _ref.read(selectedListProvider).value;
    if (stateValue == null) {
      throw StateError('Selected list state is not available');
    }
    return stateValue;
  }

  String get listName => _state.listName;
  Supermarket? get selectedSupermarket => _state.supermarket;
  List<PurchasedProduct> get products => _state.products;
  Map<String, BufferProduct> get bufferProducts => _state.bufferProducts;
  bool get hasChanges => _state.hasChanges;
  String get listId => _originalList.id;

  /// Initialize listener to refreshedSupermarketNotifier
  /// This allows the controller to automatically react to supermarket changes
  /// from the supermarket customization screen without UI-layer listeners
  void _initializeRefreshedSupermarketListener() {
    _ref.listen<AsyncValue<Supermarket?>>(
      refreshedSupermarketNotifier,
      (previous, next) {
        next.whenData((selectedSupermarket) {
          if (selectedSupermarket != null) {
            updateSupermarket(selectedSupermarket);
          }
        });
      },
    );
  }

  /// Update list name
  void updateListName(String newName) {
    _ref.read(selectedListProvider.notifier).updateListName(newName);
  }

  /// Update selected supermarket and recategorize products
  void updateSupermarket(Supermarket newSupermarket) {
    final currentSupermarket = _state.supermarket;
    final isNew = currentSupermarket?.id != newSupermarket.id;
    final isUpdated =
        currentSupermarket?.id == newSupermarket.id &&
        currentSupermarket != newSupermarket;

    if (isNew || isUpdated) {
      _ref.read(selectedListProvider.notifier).updateSupermarket(newSupermarket);
      
      if (isNew || isUpdated) {
        _recategorizeProductsForSupermarket(newSupermarket);
      }
    }
  }

  /// Clear selected supermarket and move all products to uncategorized
  /// When cleared:
  /// - Supermarket selection is removed (null)
  /// - All products moved to uncategorized category
  /// - Only uncategorized category is shown to the user
  Future<void> clearSupermarket({Category? uncategorized}) async {
    final fallback =
        uncategorized ??
        _state.uncategorizedFallback ??
        UncategorizedCategoryUtils.fallbackFrom(const []);

    _ref.read(selectedListProvider.notifier).setUncategorizedFallback(fallback);
    _ref.read(selectedListProvider.notifier).updateSupermarket(null);

    final products = List<PurchasedProduct>.from(_state.products);
    bool categoryChanged = false;

    for (var purchasedProduct in products) {
      if (purchasedProduct.category.id != fallback.id) {
        purchasedProduct.category = fallback;
        purchasedProduct.lastModified = DateTime.now();
        categoryChanged = true;
      }
    }

    if (categoryChanged) {
      _ref.read(selectedListProvider.notifier).updateProducts(products);
    }
  }

  /// Recategorize all products when supermarket changes
  void _recategorizeProductsForSupermarket(Supermarket supermarket) {
    final supermarketId = supermarket.id;
    final categories = supermarket.getCategories();
    final uncategorized = UncategorizedCategoryUtils.fallbackFrom(categories);
    final products = List<PurchasedProduct>.from(_state.products);

    for (var purchasedProduct in products) {
      final product = purchasedProduct.product;

      // Check if product has association with this supermarket
      if (product.associations.containsKey(supermarketId)) {
        final categoryId = product.associations[supermarketId]!;
        final category = categories.firstWhere(
          (cat) => cat.id == categoryId,
          orElse: () => uncategorized,
        );
        purchasedProduct.category = category;
      } else {
        // No association, place in uncategorized
        purchasedProduct.category = uncategorized;
      }
    }

    _ref.read(selectedListProvider.notifier).updateProducts(products);
  }

  /// Add a product to buffer zone (while categorizing)
  void addToBuffer(String productName) {
    _ref.read(selectedListProvider.notifier).addToBuffer(productName);
  }

  /// Update buffer product state
  void updateBufferProduct(
    String productName, {
    bool? isLoading,
    String? error,
  }) {
    _ref.read(selectedListProvider.notifier).updateBufferProduct(
      productName,
      isLoading: isLoading,
      error: error,
    );
  }

  /// Remove product from buffer zone
  void removeFromBuffer(String productName) {
    _ref.read(selectedListProvider.notifier).removeFromBuffer(productName);
  }

  /// Search for existing product by name
  Future<Product?> searchExistingProduct(String productName) async {
    return await ManageProduct.getProductByName(productName);
  }

  /// Add a product to the list with the specified category
  /// Returns the added PurchasedProduct
  PurchasedProduct addProduct(Product product, Category category) {
    final products = List<PurchasedProduct>.from(_state.products);
    
    final purchasedProduct = PurchasedProduct(
      listId: _originalList.id,
      product: product,
      category: category,
      quantity: 1,
      price: 0.0,
    );

    // Find the first product with the same category to insert before it
    // This places new products at the top of their category
    final firstIndexInCategory = products.indexWhere(
      (p) => p.category.id == category.id,
    );

    if (firstIndexInCategory != -1) {
      // Insert at the beginning of the category
      products.insert(firstIndexInCategory, purchasedProduct);
    } else {
      // No products in this category yet, add at the end
      products.add(purchasedProduct);
    }

    // Track the association if we have a selected supermarket
    // This ensures new product categorizations are persisted and synced
    if (_state.supermarket != null) {
      _markAssociationChanged(
        product.id,
        _state.supermarket!.id,
        category.id,
      );
    }

    _ref.read(selectedListProvider.notifier).updateProducts(products);

    return purchasedProduct;
  }

  /// Remove a product from the list
  void removeProduct(PurchasedProduct product) {
    final products = List<PurchasedProduct>.from(_state.products);
    products.removeWhere((p) => p.id == product.id);
    _ref.read(selectedListProvider.notifier).updateProducts(products);
  }

  /// Update a product in the list
  void updateProduct(PurchasedProduct updatedProduct) {
    final products = List<PurchasedProduct>.from(_state.products);
    final index = products.indexWhere((p) => p.id == updatedProduct.id);
    if (index != -1) {
      products[index] = updatedProduct;
      _ref.read(selectedListProvider.notifier).updateProducts(products);
    }
  }

  /// Toggle the bought status of a purchased product
  /// This updates the isBought flag and marks the product as modified
  void toggleProductBought(PurchasedProduct product, bool isBought) {
    final products = List<PurchasedProduct>.from(_state.products);
    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      // Update the isBought flag
      products[index].isBought = isBought;
      // Mark as modified for persistence
      products[index].lastModified = DateTime.now();
      _ref.read(selectedListProvider.notifier).updateProducts(products);
    }
  }

  // Update a purchased product's name with proper product reference handling
  ///
  /// This method implements the following logic:
  ///
  /// 1. Check if a product with [newName] already exists in the database
  /// 2. If it exists:
  ///    - Update the purchased product to reference the existing product
  ///    - Preserve all associations and metadata
  /// 3. If it doesn't exist:
  ///    - Create a new product with [newName]
  ///    - Copy relevant associations from the old product if applicable
  ///    - Update the purchased product to reference the new product
  ///
  /// This ensures that renaming a purchased product in one list does not
  /// affect purchased products in other lists, even if they originally had
  /// the same name.
  ///
  /// Parameters:
  /// - [purchasedProduct]: The purchased product to update
  /// - [newName]: The new name for the product
  ///
  /// Returns: The updated [PurchasedProduct] with the new product reference
  static Future<PurchasedProduct> updateProductName(
    PurchasedProduct purchasedProduct,
    String newName,
  ) async {
    // Validation: Skip update if name hasn't changed
    if (purchasedProduct.product.getName() == newName) {
      return purchasedProduct;
    }

    // 1. Look up existing product with the new name
    final existingProduct = await ManageProduct.getProductByName(newName);

    if (existingProduct != null) {
      // Case 1: Product with new name exists - reuse it
      // This handles the scenario where the user renames to match an existing product
      purchasedProduct.product = existingProduct;
    } else {
      // Case 2: Product with new name doesn't exist - create new product
      // This is the common case where we're creating a truly new product
      final newProduct = Product(
        name: newName,
        // Copy associations from the old product if they exist
        // This preserves category mappings in the supermarket
        associations: Map<String, String>.from(
          purchasedProduct.product.associations,
        ),
      );

      purchasedProduct.product = newProduct;
    }

    // Update the timestamp to reflect the modification
    purchasedProduct.lastModified = DateTime.now();

    return purchasedProduct;
  }

  /// Check if a product update would create a duplicate reference
  ///
  /// In some cases, renaming a product might result in it having the same
  /// name as another product. This method helps detect such scenarios.
  ///
  /// Returns: true if the new name matches an existing product
  static Future<bool> wouldCreateDuplicate(
    String newName,
    String currentProductId,
  ) async {
    final existingProduct = await ManageProduct.getProductByName(newName);
    return existingProduct != null && existingProduct.id != currentProductId;
  }

  /// Update a purchased product's name with proper product reference handling
  ///
  /// This method implements the fix for the product update bug. When a user
  /// renames a purchased product, this method ensures that:
  /// 1. A new product is created if the name is unique
  /// 2. An existing product is referenced if one with that name exists
  /// 3. The original product is NOT modified, preventing cascading updates
  ///
  /// The key difference from direct product.setName():
  /// - Direct modification: changes the shared Product object, affecting all references
  /// - This method: updates the product REFERENCE, keeping other products intact
  ///
  /// Example:
  /// - List A has PurchasedProduct1 -> Product "Apple"
  /// - List B has PurchasedProduct2 -> Product "Apple" (same object reference!)
  /// - User renames PurchasedProduct1 to "Red Apple"
  /// - OLD BUG: Both products become "Red Apple" because they share the same object
  /// - NEW FIX: PurchasedProduct1 -> Product "Red Apple" (new product)
  ///           PurchasedProduct2 -> Product "Apple" (unchanged)
  Future<void> updatePurchasedProductName(
    PurchasedProduct purchasedProduct,
    String newName,
  ) async {
    // Use the handler to safely update the product reference
    final updatedProduct = await updateProductName(purchasedProduct, newName);

    // Update the in-memory state with the new product reference
    updateProduct(updatedProduct);
  }

  /// Move product to a different category (drag and drop)
  void moveProductToCategory(PurchasedProduct product, Category newCategory) {
    final products = List<PurchasedProduct>.from(_state.products);
    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      // Update the purchased product's category
      products[index].category = newCategory;

      // CRITICAL FIX: Update the category reference on the product parameter as well
      // This ensures the PurchasedProduct model holds the correct category
      product.category = newCategory;

      // Update product association for current supermarket
      if (_state.supermarket != null) {
        products[index].product.addAssociation(
          _state.supermarket!.id,
          newCategory.id,
        );

        // Mark association change for persistence
        // This saves to the associations table and syncs to Firestore
        _markAssociationChanged(
          products[index].product.id,
          _state.supermarket!.id,
          newCategory.id,
        );
      }

      // CRITICAL FIX: Update the PurchasedProduct's lastModified timestamp
      // This ensures the purchased_product row will be updated in the database
      // with the new category_id when save() is called
      products[index].lastModified = DateTime.now();

      _ref.read(selectedListProvider.notifier).updateProducts(products);
    }
  }

  /// Reorder products within the same category
  void reorderProducts(int oldIndex, int newIndex) {
    final products = List<PurchasedProduct>.from(_state.products);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final product = products.removeAt(oldIndex);
    products.insert(newIndex, product);
    _ref.read(selectedListProvider.notifier).updateProducts(products);
  }

  /// Get products grouped by category for the current supermarket
  ///
  /// When no supermarket is selected:
  /// - Returns only the uncategorized category
  /// - All products are grouped under it
  ///
  /// When a supermarket is selected:
  /// - Returns ALL categories from that supermarket (even empty ones)
  /// - This allows users to see all available categories for drag-and-drop
  ///
  /// CRITICAL: Categories are matched by ID (not object reference) to handle
  /// the case where the same category is loaded as different object instances.
  Map<Category, List<PurchasedProduct>> getProductsByCategory() {
    final products = _state.products;
    final supermarket = _state.supermarket;
    
    // When no supermarket is selected, only show uncategorized category
    if (supermarket == null) {
      final fallback =
          _state.uncategorizedFallback ??
          UncategorizedCategoryUtils.fallbackFrom(const []);

      return {fallback: List.unmodifiable(products)};
    }

    final categories = supermarket.getCategories();
    final Map<Category, List<PurchasedProduct>> grouped = {};

    // Initialize ALL categories with empty lists (even if they have no products)
    // This ensures all category headers are displayed, allowing users to
    // drag products to any category
    for (var category in categories) {
      grouped[category] = [];
    }

    // Distribute products into their respective categories
    // CRITICAL FIX: Match by category ID instead of object reference
    // This handles the case where product.category is a different instance
    // than the category in the supermarket's categories list
    for (var product in products) {
      final productCategoryId = product.category.id;

      // Find matching category in supermarket's categories by ID
      final matchingCategory = categories.firstWhere(
        (cat) => cat.id == productCategoryId,
        orElse: () {
          // Category not found in supermarket - use uncategorized
          return UncategorizedCategoryUtils.fallbackFrom(categories);
        },
      );

      // Add product to the matching category
      if (grouped.containsKey(matchingCategory)) {
        grouped[matchingCategory]!.add(product);
      } else {
        // This shouldn't happen since we initialized all categories,
        // but handle it gracefully
        grouped[matchingCategory] = [product];
      }
    }

    return grouped;
  }

  /// Mark an association change for persistence
  /// Uses the associations provider to track pending changes
  void _markAssociationChanged(
    String productId,
    String supermarketId,
    String categoryId,
  ) {
    final associationsNotifier = _ref.read(associationsProvider.notifier);
    associationsNotifier.markAssociationChanged(
      productId,
      supermarketId,
      categoryId,
    );
  }

  /// Save all changes to database (called on screen exit)
  /// Uses Riverpod providers for all persistence operations
  Future<void> save() async {
    if (!_state.hasChanges) return;

    try {
      final products = _state.products;
      
      // 1. Update shopping list name and supermarket using provider
      _originalList.setName(_state.listName);
      _originalList.setSupermarket(_state.supermarket);

      final listNotifier = _ref.read(shoppingListsProvider.notifier);
      await listNotifier.updateList(_originalList);

      // 2. Handle products - process name changes and create/update products
      final productsNotifier = _ref.read(productsProvider.notifier);
      final purchasedProductsNotifier = _ref.read(
        purchasedProductsProvider.notifier,
      );

      for (var purchasedProduct in products) {
        final product = purchasedProduct.product;

        // Check if product with this name exists
        final existingProduct = await ManageProduct.getProductByName(
          product.getName(),
        );

        if (existingProduct != null) {
          // Product name matches existing product - use existing product reference
          purchasedProduct.product = existingProduct;
        } else {
          // New product
          await productsNotifier.addProduct(product);
        }

        // 3. Save/update purchased product via provider
        final existingPurchased = await purchasedProductsNotifier
            .getPurchasedProductById(purchasedProduct.id);
        if (existingPurchased == null) {
          await purchasedProductsNotifier.addPurchasedProduct(purchasedProduct);
        } else {
          await purchasedProductsNotifier.updatePurchasedProduct(
            purchasedProduct,
          );
        }
      }

      // 4. Handle deleted products (compare with original list)
      final originalProductIds = _originalProducts.map((p) => p.id).toSet();
      final currentProductIds = products.map((p) => p.id).toSet();
      final deletedIds = originalProductIds.difference(currentProductIds);

      for (var deletedId in deletedIds) {
        await purchasedProductsNotifier.deletePurchasedProductById(deletedId);
      }

      // 5. Persist all pending association changes using provider's batch operation
      // This ensures associations are saved to the associations table
      // and will be synced to Firestore by the sync-engine
      // Using batch operation creates only ONE sync_box entry per product
      // instead of one entry per association (performance optimization)
      final associationsNotifier = _ref.read(associationsProvider.notifier);
      if (associationsNotifier.hasPendingAssociations()) {
        await associationsNotifier.flushAssociations();
      }

      _ref.read(selectedListProvider.notifier).markChangesSaved();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete the shopping list (move to trash) using provider
  Future<void> deleteList() async {
    _originalList.setIsInTheTrash(true);
    final listNotifier = _ref.read(shoppingListsProvider.notifier);
    await listNotifier.updateList(_originalList);
  }
}
