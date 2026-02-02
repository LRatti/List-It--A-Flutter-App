import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/providers/real_app_providers/shopping_lists_notifier.dart';
import 'package:app_code/providers/real_app_providers/products_notifier.dart';
import 'package:app_code/providers/real_app_providers/purchased_products_notifier.dart';
import 'package:app_code/providers/real_app_providers/associations_notifier.dart';
import 'package:app_code/services/database/sqlite/manage_product.dart';
import 'package:app_code/utils/uncategorized_category_utils.dart';
import 'package:flutter/foundation.dart' hide Category;

/// State for products being categorized (in buffer zone)
class BufferProduct {
  final String name;
  final bool isLoading;
  final String? error;

  BufferProduct({
    required this.name,
    this.isLoading = true,
    this.error,
  });

  BufferProduct copyWith({
    String? name,
    bool? isLoading,
    String? error,
  }) {
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
  })  : _originalList = shoppingList,
        _ref = ref,
        _listName = shoppingList.getName(),
        _selectedSupermarket = initialSupermarket ?? shoppingList.getSupermarket(),
        _products = List.from(initialProducts ?? shoppingList.getProducts() ?? []),
        _originalProducts = List.from(initialProducts ?? shoppingList.getProducts() ?? []);

  // Getters
  String get listName => _listName;
  Supermarket? get selectedSupermarket => _selectedSupermarket;
  List<PurchasedProduct> get products => List.unmodifiable(_products);
  Map<String, BufferProduct> get bufferProducts => Map.unmodifiable(_bufferProducts);
  bool get hasChanges => _hasChanges;
  String get listId => _originalList.id;

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
    final isUpdated = _selectedSupermarket?.id == newSupermarket.id && 
        _selectedSupermarket != newSupermarket;
    
    if (isNew || isUpdated) {
      _selectedSupermarket = newSupermarket;
      _uncategorizedFallback = null;
      _recategorizeProductsForSupermarket();
      if (isNew) {
        _hasChanges = true;
      }
      notifyListeners();
    }
  }

  /// Clear selected supermarket and move all products to uncategorized
  Future<void> clearSupermarket({Category? uncategorized}) async {
    final fallback = uncategorized ?? _uncategorizedFallback ??
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
  void updateBufferProduct(String productName, {bool? isLoading, String? error}) {
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
      final fallback = _uncategorizedFallback ??
          UncategorizedCategoryUtils.fallbackFrom(const []);
      _uncategorizedFallback = fallback;

      return {
        fallback: List.unmodifiable(_products),
      };
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
  void _markAssociationChanged(String productId, String supermarketId, String categoryId) {
    final associationsNotifier = _ref.read(associationsProvider.notifier);
    associationsNotifier.markAssociationChanged(productId, supermarketId, categoryId);
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
      final purchasedProductsNotifier = _ref.read(purchasedProductsProvider.notifier);
      
      for (var purchasedProduct in _products) {
        final product = purchasedProduct.product;
        
        // Check if product with this name exists
        final existingProduct = await ManageProduct.getProductByName(product.getName());
        
        if (existingProduct != null && existingProduct.id != product.id) {
          // Product name matches existing product - use existing product reference
          purchasedProduct.product = existingProduct;
        } else if (existingProduct == null) {
          // New product - ensure it exists in database via provider
          final check = await productsNotifier.getProductById(product.id);
          if (check == null) {
            await productsNotifier.addProduct(product);
          } else {
            // Update existing product
            await productsNotifier.updateProduct(product);
          }
        } else {
          // Same product, just update via provider
          await productsNotifier.updateProduct(product);
        }

        // 3. Save/update purchased product via provider
        final existingPurchased = await purchasedProductsNotifier.getPurchasedProductById(purchasedProduct.id);
        if (existingPurchased == null) {
          await purchasedProductsNotifier.addPurchasedProduct(purchasedProduct);
        } else {
          await purchasedProductsNotifier.updatePurchasedProduct(purchasedProduct);
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
