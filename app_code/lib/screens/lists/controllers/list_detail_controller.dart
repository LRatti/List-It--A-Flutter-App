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
import 'package:flutter/foundation.dart' hide Category;

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

/// Controller that manages in-memory state for list detail screen
/// All changes are deferred to persistence layer until save() is called
///
/// This controller uses Riverpod providers for all persistence operations,
/// ensuring consistency with the app's architecture.
class ListDetailController extends ChangeNotifier {
  final ShoppingList _originalList;
  final Ref _ref; // Riverpod ref for provider access

  // In-memory state
  String _listName;
  Supermarket? _selectedSupermarket;
  Category? _uncategorizedFallback;
  List<PurchasedProduct> _products = [];
  final List<PurchasedProduct> _originalProducts; // Deep copy for comparison
  final Map<String, BufferProduct> _bufferProducts = {};

  // Track changes
  bool _hasChanges = false;

  ListDetailController({
    required ShoppingList shoppingList,
    required Ref ref,
    Supermarket? initialSupermarket,
    List<PurchasedProduct>? initialProducts,
  }) : _originalList = shoppingList,
       _ref = ref,
       _listName = shoppingList.getName(),
       _selectedSupermarket =
           initialSupermarket ?? shoppingList.getSupermarket(),
       _products = List.from(
         initialProducts ?? shoppingList.getProducts() ?? [],
       ),
       _originalProducts = List.from(
         initialProducts ?? shoppingList.getProducts() ?? [],
       ) {
    // Initialize listener to refreshedSupermarketNotifier
    _initializeRefreshedSupermarketListener();
  }

  // Getters
  String get listName => _listName;
  Supermarket? get selectedSupermarket => _selectedSupermarket;
  List<PurchasedProduct> get products => List.unmodifiable(_products);
  Map<String, BufferProduct> get bufferProducts =>
      Map.unmodifiable(_bufferProducts);
  bool get hasChanges => _hasChanges;
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
    if (_listName != newName) {
      _listName = newName;
      _hasChanges = true;
      notifyListeners();
    }
  }

  /// Update selected supermarket and recategorize products
  void updateSupermarket(Supermarket newSupermarket) {
    final isNew = _selectedSupermarket?.id != newSupermarket.id;
    final isUpdated =
        _selectedSupermarket?.id == newSupermarket.id &&
        _selectedSupermarket != newSupermarket;

    if (isNew || isUpdated) {
      _selectedSupermarket = newSupermarket;
      _uncategorizedFallback = null;
      _recategorizeProductsForSupermarket();
      if (isNew) {
        _hasChanges = true;
      }
      notifyListeners();
      // Update notifier with selected supermarket
      // _ref
      //     .read(selectedListProvider.notifier)
      //     .updateSelectedSupermarket(newSupermarket);
    }
  }

  /// Clear selected supermarket and move all products to uncategorized
  Future<void> clearSupermarket({Category? uncategorized}) async {
    final fallback =
        uncategorized ??
        _uncategorizedFallback ??
        UncategorizedCategoryUtils.fallbackFrom(const []);

    final selectionChanged = _selectedSupermarket != null;
    bool categoryChanged = false;

    _selectedSupermarket = null;
    _uncategorizedFallback = fallback;

    for (var purchasedProduct in _products) {
      if (purchasedProduct.category.id != fallback.id) {
        purchasedProduct.category = fallback;
        purchasedProduct.lastModified = DateTime.now();
        categoryChanged = true;
      }
    }

    if (selectionChanged || categoryChanged) {
      _hasChanges = true;
      notifyListeners();
    }
  }

  /// Recategorize all products when supermarket changes
  void _recategorizeProductsForSupermarket() {
    if (_selectedSupermarket == null) return;

    final supermarketId = _selectedSupermarket!.id;
    final categories = _selectedSupermarket!.getCategories();
    final uncategorized = UncategorizedCategoryUtils.fallbackFrom(categories);

    for (var purchasedProduct in _products) {
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
  }

  /// Add a product to buffer zone (while categorizing)
  void addToBuffer(String productName) {
    _bufferProducts[productName] = BufferProduct(name: productName);
    notifyListeners();
  }

  /// Update buffer product state
  void updateBufferProduct(
    String productName, {
    bool? isLoading,
    String? error,
  }) {
    if (_bufferProducts.containsKey(productName)) {
      _bufferProducts[productName] = _bufferProducts[productName]!.copyWith(
        isLoading: isLoading,
        error: error,
      );
      notifyListeners();
    }
  }

  /// Remove product from buffer zone
  void removeFromBuffer(String productName) {
    _bufferProducts.remove(productName);
    notifyListeners();
  }

  /// Search for existing product by name
  Future<Product?> searchExistingProduct(String productName) async {
    return await ManageProduct.getProductByName(productName);
  }

  /// Add a product to the list with the specified category
  /// Returns the added PurchasedProduct
  PurchasedProduct addProduct(Product product, Category category) {
    final purchasedProduct = PurchasedProduct(
      listId: _originalList.id,
      product: product,
      category: category,
      quantity: 1,
      price: 0.0,
    );

    // Find the first product with the same category to insert before it
    // This places new products at the top of their category
    final firstIndexInCategory = _products.indexWhere(
      (p) => p.category.id == category.id,
    );

    if (firstIndexInCategory != -1) {
      // Insert at the beginning of the category
      _products.insert(firstIndexInCategory, purchasedProduct);
    } else {
      // No products in this category yet, add at the end
      _products.add(purchasedProduct);
    }

    // Track the association if we have a selected supermarket
    // This ensures new product categorizations are persisted and synced
    if (_selectedSupermarket != null) {
      _markAssociationChanged(
        product.id,
        _selectedSupermarket!.id,
        category.id,
      );
    }

    _hasChanges = true;
    notifyListeners();

    return purchasedProduct;
  }

  /// Remove a product from the list
  void removeProduct(PurchasedProduct product) {
    _products.removeWhere((p) => p.id == product.id);
    _hasChanges = true;
    notifyListeners();
  }

  /// Update a product in the list
  void updateProduct(PurchasedProduct updatedProduct) {
    final index = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (index != -1) {
      _products[index] = updatedProduct;
      _hasChanges = true;
      notifyListeners();
    }
  }

  /// Toggle the bought status of a purchased product
  /// This updates the isBought flag and marks the product as modified
  void toggleProductBought(PurchasedProduct product, bool isBought) {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      // Update the isBought flag
      _products[index].isBought = isBought;
      // Mark as modified for persistence
      _products[index].lastModified = DateTime.now();
      _hasChanges = true;
      notifyListeners();
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
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      // Update the purchased product's category
      _products[index].category = newCategory;

      // CRITICAL FIX: Update the category reference on the product parameter as well
      // This ensures the PurchasedProduct model holds the correct category
      product.category = newCategory;

      // Update product association for current supermarket
      if (_selectedSupermarket != null) {
        _products[index].product.addAssociation(
          _selectedSupermarket!.id,
          newCategory.id,
        );

        // Mark association change for persistence
        // This saves to the associations table and syncs to Firestore
        _markAssociationChanged(
          _products[index].product.id,
          _selectedSupermarket!.id,
          newCategory.id,
        );
      }

      // CRITICAL FIX: Update the PurchasedProduct's lastModified timestamp
      // This ensures the purchased_product row will be updated in the database
      // with the new category_id when save() is called
      _products[index].lastModified = DateTime.now();

      _hasChanges = true;
      notifyListeners();
    }
  }

  /// Reorder products within the same category
  void reorderProducts(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final product = _products.removeAt(oldIndex);
    _products.insert(newIndex, product);
    _hasChanges = true;
    notifyListeners();
  }

  /// Get products grouped by category for the current supermarket
  ///
  /// NEW BEHAVIOR: Always returns ALL categories from the selected supermarket,
  /// even if they have no products. This allows users to see all available
  /// categories upfront and drag products to any category.
  ///
  /// CRITICAL: Categories are matched by ID (not object reference) to handle
  /// the case where the same category is loaded as different object instances.
  Map<Category, List<PurchasedProduct>> getProductsByCategory() {
    if (_selectedSupermarket == null) {
      final fallback =
          _uncategorizedFallback ??
          UncategorizedCategoryUtils.fallbackFrom(const []);
      _uncategorizedFallback = fallback;

      return {fallback: List.unmodifiable(_products)};
    }

    final categories = _selectedSupermarket!.getCategories();
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
    for (var product in _products) {
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
    if (!_hasChanges) return;

    try {
      // 1. Update shopping list name and supermarket using provider
      _originalList.setName(_listName);
      _originalList.setSupermarket(_selectedSupermarket);

      final listNotifier = _ref.read(shoppingListsProvider.notifier);
      await listNotifier.updateList(_originalList);

      // 2. Handle products - process name changes and create/update products
      final productsNotifier = _ref.read(productsProvider.notifier);
      final purchasedProductsNotifier = _ref.read(
        purchasedProductsProvider.notifier,
      );

      for (var purchasedProduct in _products) {
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
      final currentProductIds = _products.map((p) => p.id).toSet();
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

      _hasChanges = false;
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

  @override
  void dispose() {
    _bufferProducts.clear();
    super.dispose();
  }
}
