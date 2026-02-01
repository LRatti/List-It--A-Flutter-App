import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/repositories/sync/association_repository_sync.dart';
import 'package:app_code/repositories/sync/product_repository_sync.dart';
import 'package:app_code/repositories/sync/purchased_product_repository_sync.dart';
import 'package:app_code/repositories/sync/shopping_list_repository_sync.dart';
import 'package:app_code/services/database/sqlite/manage_product.dart';
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
class ListDetailController extends ChangeNotifier {
  final ShoppingList _originalList;
  final ProductRepositoryWithSync _productRepo = ProductRepositoryWithSync();
  final PurchasedProductRepositoryWithSync _purchasedProductRepo =
      PurchasedProductRepositoryWithSync();
  final ShoppingListRepositoryWithSync _listRepo =
      ShoppingListRepositoryWithSync();
  final AssociationRepositoryWithSync _associationRepo =
      AssociationRepositoryWithSync();

  // In-memory state
  String _listName;
  Supermarket? _selectedSupermarket;
  List<PurchasedProduct> _products = [];
  final List<PurchasedProduct> _originalProducts; // Deep copy for comparison
  final Map<String, BufferProduct> _bufferProducts = {};
  
  // Track changes
  bool _hasChanges = false;

  ListDetailController({
    required ShoppingList shoppingList,
    Supermarket? initialSupermarket,
    List<PurchasedProduct>? initialProducts,
  })  : _originalList = shoppingList,
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
    if (_selectedSupermarket?.id != newSupermarket.id) {
      _selectedSupermarket = newSupermarket;
      _recategorizeProductsForSupermarket();
      _hasChanges = true;
      notifyListeners();
    }
  }

  /// Recategorize all products when supermarket changes
  void _recategorizeProductsForSupermarket() {
    if (_selectedSupermarket == null) return;

    final supermarketId = _selectedSupermarket!.id;
    final categories = _selectedSupermarket!.getCategories();
    final uncategorized = categories.firstWhere(
      (cat) => cat.getName().toLowerCase() == 'uncategorized',
      orElse: () => Category(name: 'uncategorized'),
    );

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

    _products.add(purchasedProduct);
    
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
      _products[index].category = newCategory;
      
      // Update product association for current supermarket
      if (_selectedSupermarket != null) {
        _products[index].product.addAssociation(
          _selectedSupermarket!.id,
          newCategory.id,
        );
        
        // Mark association change for persistence
        _markAssociationChanged(
          _products[index].product.id,
          _selectedSupermarket!.id,
          newCategory.id,
        );
      }
      
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
  Map<Category, List<PurchasedProduct>> getProductsByCategory() {
    if (_selectedSupermarket == null) {
      return {};
    }

    final categories = _selectedSupermarket!.getCategories();
    final Map<Category, List<PurchasedProduct>> grouped = {};

    // Initialize with uncategorized first
    final uncategorized = categories.firstWhere(
      (cat) => cat.getName().toLowerCase() == 'uncategorized',
      orElse: () => Category(name: 'uncategorized'),
    );
    grouped[uncategorized] = [];

    // Initialize all other categories in order
    for (var category in categories) {
      if (category.getName().toLowerCase() != 'uncategorized') {
        grouped[category] = [];
      }
    }

    // Distribute products into categories
    for (var product in _products) {
      final category = product.category;
      if (grouped.containsKey(category)) {
        grouped[category]!.add(product);
      } else {
        // Fallback to uncategorized if category not found
        grouped[uncategorized]!.add(product);
      }
    }

    return grouped;
  }

  // Track association changes that need to be persisted
  final Map<String, Map<String, String>> _pendingAssociations = {};
  
  // Track association deletions that need to be persisted
  final List<({String productId, String supermarketId})> _pendingAssociationDeletions = [];

  /// Mark an association change for persistence
  void _markAssociationChanged(String productId, String supermarketId, String categoryId) {
    if (!_pendingAssociations.containsKey(productId)) {
      _pendingAssociations[productId] = {};
    }
    _pendingAssociations[productId]![supermarketId] = categoryId;
  }

  /// Mark an association for deletion
  void _markAssociationDeleted(String productId, String supermarketId) {
    _pendingAssociationDeletions.add(
      (productId: productId, supermarketId: supermarketId),
    );
  }

  /// Remove an association between a product and a supermarket
  /// This is exposed for UI-triggered association removal
  Future<void> removeAssociation(String productId, String supermarketId) async {
    // Find the product in the current list
    final productIndex = _products.indexWhere((p) => p.product.id == productId);
    
    if (productIndex != -1) {
      final product = _products[productIndex].product;
      
      // Remove from in-memory associations map
      product.associations.remove(supermarketId);
      
      // If this is the current supermarket, move product to uncategorized
      if (_selectedSupermarket?.id == supermarketId) {
        final uncategorized = _selectedSupermarket!.getCategories().firstWhere(
          (cat) => cat.getName().toLowerCase() == 'uncategorized',
          orElse: () => Category(name: 'uncategorized'),
        );
        _products[productIndex].category = uncategorized;
      }
      
      // Mark for deletion
      _markAssociationDeleted(productId, supermarketId);
      
      _hasChanges = true;
      notifyListeners();
    }
  }

  /// Save all changes to database (called on screen exit)
  Future<void> save() async {
    if (!_hasChanges) return;

    try {
      // 1. Update shopping list name and supermarket
      _originalList.setName(_listName);
      if (_selectedSupermarket != null) {
        _originalList.setSupermarket(_selectedSupermarket!);
      }

      await _listRepo.update(_originalList);

      // 2. Handle products - process name changes and create/update products
      for (var purchasedProduct in _products) {
        final product = purchasedProduct.product;
        
        // Check if product with this name exists
        final existingProduct = await ManageProduct.getProductByName(product.getName());
        
        if (existingProduct != null && existingProduct.id != product.id) {
          // Product name matches existing product - use existing product reference
          purchasedProduct.product = existingProduct;
        } else if (existingProduct == null) {
          // New product - ensure it exists in database
          final check = await _productRepo.getById(product.id);
          if (check == null) {
            await _productRepo.add(product);
          } else {
            // Update existing product
            await _productRepo.update(product);
          }
        } else {
          // Same product, just update
          await _productRepo.update(product);
        }

        // 3. Save/update purchased product
        final existingPurchased = await _purchasedProductRepo.getById(purchasedProduct.id);
        if (existingPurchased == null) {
          await _purchasedProductRepo.add(purchasedProduct);
        } else {
          await _purchasedProductRepo.update(purchasedProduct);
        }
      }

      // 4. Handle deleted products (compare with original list)
      final originalProductIds = _originalProducts.map((p) => p.id).toSet();
      final currentProductIds = _products.map((p) => p.id).toSet();
      final deletedIds = originalProductIds.difference(currentProductIds);
      
      for (var deletedId in deletedIds) {
        await _purchasedProductRepo.deleteById(deletedId);
      }

      // 5. Persist all pending association changes using BATCH OPERATION
      // This ensures associations are saved to the associations table
      // and will be synced to Firestore by the sync-engine
      // Using batch operation creates only ONE sync_box entry per product
      // instead of one entry per association (performance optimization)
      if (_pendingAssociations.isNotEmpty) {
        await _associationRepo.addBatch(_pendingAssociations);
      }
      
      // 6. Persist all pending association deletions using BATCH OPERATION
      if (_pendingAssociationDeletions.isNotEmpty) {
        await _associationRepo.deleteBatch(_pendingAssociationDeletions);
      }
      
      // Clear pending changes after save
      _pendingAssociations.clear();
      _pendingAssociationDeletions.clear();

      _hasChanges = false;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete the shopping list (move to trash)
  Future<void> deleteList() async {
    _originalList.setIsInTheTrash(true);
    await _listRepo.update(_originalList);
  }

  @override
  void dispose() {
    _bufferProducts.clear();
    super.dispose();
  }
}
