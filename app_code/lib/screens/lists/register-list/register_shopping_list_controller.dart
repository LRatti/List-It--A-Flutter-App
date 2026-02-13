import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/receipt_match.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/real_app_providers/purchased_products/purchased_products_notifier.dart';
import 'package:app_code/providers/real_app_providers/receipt/receipt_processing_provider.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';

/// Controller that manages state for register_shopping_list_screen
/// This screen allows users to register (archive) a shopping list by filling in
/// quantity and price for each purchased product that was marked as bought.
/// 
/// State Management:
/// - Tracks modifications to quantity and price for bought products
/// - Defers all persistence until explicit save/register action
/// - Manages navigation back to previous screen or history screen
class RegisterShoppingListController extends ChangeNotifier {
  final ShoppingList _originalList;
  final Ref _ref;

  // In-memory state for modifications
  Map<String, int> _quantityUpdates = {}; // productId -> quantity
  Map<String, double> _priceUpdates = {}; // productId -> price
  bool _hasChanges = false;

  RegisterShoppingListController({
    required ShoppingList shoppingList,
    required Ref ref,
  }) : _originalList = shoppingList,
       _ref = ref;

  // Getters
  String get listId => _originalList.id;
  String get listName => _originalList.getName();
  ShoppingList get shoppingList => _originalList;
  bool get hasChanges => _hasChanges;

  /// Get all bought products from the list
  List<PurchasedProduct> getBoughtProducts() {
    return (_originalList.getProducts())
        .where((pp) => pp.isBought)
        .toList();
  }

  /// Get quantity for a product (from updates or original)
  int getQuantity(String productId) {
    return _quantityUpdates[productId] ?? 
           (_originalList.getProducts().firstWhere(
             (pp) => pp.id == productId,
             orElse: () => PurchasedProduct(
               listId: listId,
               product: null as dynamic,
               category: null as dynamic,
               quantity: 0,
             ),
           ).quantity);
  }

  /// Get price for a product (from updates or original)
  double getPrice(String productId) {
    return _priceUpdates[productId] ?? 
           (_originalList.getProducts().firstWhere(
             (pp) => pp.id == productId,
             orElse: () => PurchasedProduct(
               listId: listId,
               product: null as dynamic,
               category: null as dynamic,
               price: 0.0,
             ),
           ).price);
  }

  /// Update quantity for a product
  void updateQuantity(String productId, int quantity) {
    if (quantity < 0) return;

    _quantityUpdates[productId] = quantity;
      _hasChanges = true;
      notifyListeners();
    
    // if (boughtProduct != null && quantity != (boughtProduct as PurchasedProduct).quantity) {
    //   _quantityUpdates[productId] = quantity;
    //   _hasChanges = true;
    //   notifyListeners();
    // } else if (boughtProduct == null && _quantityUpdates.containsKey(productId)) {
    //   // If no original product found, track the update
    //   _quantityUpdates[productId] = quantity;
    //   _hasChanges = true;
    //   notifyListeners();
    // }
  }

  /// Update price for a product
  void updatePrice(String productId, double price) {
    if (price < 0) return;

     _priceUpdates[productId] = price;
      _hasChanges = true;
      notifyListeners();


    // Variable can't be null. The correct code has been reported above.
    // if (boughtProduct != null && price != (boughtProduct as PurchasedProduct).price) {
    //   _priceUpdates[productId] = price;
    //   _hasChanges = true;
    //   notifyListeners();
    // } else if (boughtProduct == null && _priceUpdates.containsKey(productId)) {
    //   _priceUpdates[productId] = price;
    //   _hasChanges = true;
    //   notifyListeners();
    // }
  }

  /// Persist all changes (quantity and price) to the database
  /// This is called when back button, check button, or pencil button are pressed
  Future<void> persistChanges() async {
    _ref.watch(shoppingListRepositoryProvider);
    final purchasedProductsNotifier = 
        _ref.read(purchasedProductsProvider.notifier);
    
    final boughtProducts = getBoughtProducts();
    
    // Update each bought product with the new quantity/price values
    for (final product in boughtProducts) {
      // Only update if there are changes for this product
      if (_quantityUpdates.containsKey(product.id) ||
          _priceUpdates.containsKey(product.id)) {
        product.quantity = _quantityUpdates[product.id] ?? product.quantity;
        product.price = _priceUpdates[product.id] ?? product.price;
        product.lastModified = DateTime.now();
        
        // Persist to repository
        await purchasedProductsNotifier.updatePurchasedProduct(product);
      }
    }
  }

  /// Apply receipt matches (quantity/price) and persist updates.
  Future<List<ReceiptMatch>> applyReceiptFromImage(File imageFile) async {
    final boughtProducts = getBoughtProducts();
    if (boughtProducts.isEmpty) {
      return [];
    }

    final ocrService = _ref.read(receiptOcrServiceProvider);
    final receiptText = await ocrService.extractText(imageFile);

    if (receiptText.trim().isEmpty) {
      throw Exception('No readable text found in the receipt image.');
    }

    final geminiRepository = _ref.read(receiptGeminiRepositoryProvider);
    final matches = await geminiRepository.extractReceiptMatches(
      receiptText: receiptText,
      purchasedProducts: boughtProducts,
    );

    if (matches.isEmpty) {
      return [];
    }

    final purchasedProductsNotifier =
        _ref.read(purchasedProductsProvider.notifier);

    final boughtById = {
      for (final product in boughtProducts) product.id: product,
    };
    final boughtByName = {
      for (final product in boughtProducts)
        _normalizeName(product.product.getName()): product,
    };

    final applied = <ReceiptMatch>[];

    for (final match in matches) {
      final product = match.productId != null
          ? boughtById[match.productId!]
          : boughtByName[_normalizeName(match.productName ?? '')];

      if (product == null) continue;

      var changed = false;

      if (match.quantity >= 0 && match.quantity != product.quantity) {
        product.quantity = match.quantity;
        _quantityUpdates[product.id] = match.quantity;
        changed = true;
      }

      if (match.price >= 0 && match.price != product.price) {
        product.price = match.price;
        _priceUpdates[product.id] = match.price;
        changed = true;
      }

      if (changed) {
        product.lastModified = DateTime.now();
        await purchasedProductsNotifier.updatePurchasedProduct(product);
        applied.add(match);
      }
    }

    _hasChanges = _quantityUpdates.isNotEmpty || _priceUpdates.isNotEmpty;
    notifyListeners();

    return applied;
  }

  String _normalizeName(String name) {
    return name.toLowerCase().trim();
  }

  /// Register the shopping list (set is_registered to true)
  /// Also auto-fills quantity=1 for any bought products without quantity
  Future<void> registerList() async {
    final repository = _ref.watch(shoppingListRepositoryProvider);
    
    // First persist quantity/price changes
    await persistChanges();
    
    // Auto-fill quantity=1 for bought products without quantity
    final boughtProducts = getBoughtProducts();
    for (final product in boughtProducts) {
      if (product.quantity == 0) {
        product.quantity = 1;
        product.lastModified = DateTime.now();
        final purchasedProductsNotifier = 
            _ref.read(purchasedProductsProvider.notifier);
        await purchasedProductsNotifier.updatePurchasedProduct(product);
      }
    }
    
    // Update the list to mark as registered
    _originalList.setIsRegistered(true);
    _originalList.lastModified = DateTime.now();
    
    // Persist the list changes
    await repository.update(_originalList);
    
    // Update the provider state
    final notifier = _ref.read(shoppingListsProvider.notifier);
    await notifier.updateList(_originalList);
  }

  /// Unregister the shopping list (set is_registered to false)
  /// Called when pencil button opens list_detail_screen to allow further editing
  Future<void> unregisterList() async {
    final repository = _ref.watch(shoppingListRepositoryProvider);
    
    // First persist any pending changes
    await persistChanges();
    
    // Update the list to mark as not registered
    _originalList.setIsRegistered(false);
    _originalList.lastModified = DateTime.now();
    
    // Persist the list changes
    await repository.update(_originalList);
    
    // Update the provider state
    final notifier = _ref.read(shoppingListsProvider.notifier);
    await notifier.updateList(_originalList);
  }
}
