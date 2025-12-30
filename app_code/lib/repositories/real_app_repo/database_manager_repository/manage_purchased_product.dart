import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/services/database/sqlite/manage_purchased_product.dart' as sqlite;
import 'package:app_code/services/database/firebase/manage_purchased_product.dart';

/// Database Manager for Purchased Products - Implements write-ahead pattern
/// SQLite operations are executed first (synchronously),
/// Firebase operations follow in a non-blocking manner
class PurchasedProductDatabaseManager {
  final FirebasePurchasedProductManager _firebaseManager = FirebasePurchasedProductManager();

  /// Add a new purchased product to both databases
  /// Write-ahead: SQLite first, then Firebase async
  Future<void> addPurchasedProduct(PurchasedProduct purchasedProduct) async {
    // 1. Write to SQLite first (blocking)
    await sqlite.ManagePurchasedProduct.addPurchasedProduct(purchasedProduct);
    
    // 2. Write to Firebase in non-blocking manner
    _firebaseManager.setPurchasedProduct(purchasedProduct).catchError((error) {
      print('Firebase sync error (addPurchasedProduct): $error');
    });
  }

  /// Update an existing purchased product in both databases
  /// Write-ahead: SQLite first, then Firebase async
  Future<void> updatePurchasedProduct(PurchasedProduct purchasedProduct) async {
    // 1. Update SQLite first (blocking)
    await sqlite.ManagePurchasedProduct.updatePurchasedProduct(purchasedProduct);
    
    // 2. Update Firebase in non-blocking manner
    _firebaseManager.setPurchasedProduct(purchasedProduct).catchError((error) {
      print('Firebase sync error (updatePurchasedProduct): $error');
    });
  }

  /// Delete a purchased product from both databases
  /// Write-ahead: SQLite first, then Firebase async
  Future<void> deletePurchasedProduct(String id, PurchasedProduct purchasedProduct) async {
    // 1. Delete from SQLite first (blocking)
    await sqlite.ManagePurchasedProduct.deletePurchasedProduct(id);
    
    // 2. Delete from Firebase in non-blocking manner
    _firebaseManager.deletePurchasedProduct(purchasedProduct).catchError((error) {
      print('Firebase sync error (deletePurchasedProduct): $error');
    });
  }

  /// Get purchased product by ID - reads from SQLite only (source of truth)
  Future<PurchasedProduct?> getPurchasedProductById(String id) async {
    return await sqlite.ManagePurchasedProduct.getPurchasedProductById(id);
  }

  /// Get purchased product by name - reads from SQLite only (source of truth)
  Future<PurchasedProduct?> getPurchasedProductByName(String shoppingListId, String name) async {
    return await sqlite.ManagePurchasedProduct.getPurchasedProductByName(shoppingListId, name);
  }

  /// Get purchased products by shopping list - reads from SQLite only (source of truth)
  Future<List<PurchasedProduct>> getPurchasedProductsByList(String shoppingListId) async {
    return await sqlite.ManagePurchasedProduct.getPurchasedProductsByList(shoppingListId);
  }

  // ========== Firebase-specific methods ==========
  
  /// Batch add multiple purchased products (Firebase-specific feature)
  /// Write-ahead: SQLite first (one by one), then Firebase batch async
  Future<void> setAllPurchasedProducts(List<PurchasedProduct> purchasedProducts) async {
    // 1. Write to SQLite first (blocking)
    for (var purchasedProduct in purchasedProducts) {
      await sqlite.ManagePurchasedProduct.addPurchasedProduct(purchasedProduct);
    }
    
    // 2. Batch write to Firebase in non-blocking manner
    _firebaseManager.setAllPurchasedProducts(purchasedProducts).catchError((error) {
      print('Firebase sync error (setAllPurchasedProducts): $error');
    });
  }

  /// Get purchased products by list from Firebase (alternative implementation)
  /// This uses Firebase's method signature which differs from SQLite
  Future<List<PurchasedProduct>> getPurchasedProductByListFromFirebase(String listId) async {
    return await _firebaseManager.getPurchasedProductByList(listId);
  }

  /// Get purchased product by ID from Firebase (alternative implementation)
  /// This uses Firebase's method signature which requires both listId and productId
  Future<PurchasedProduct?> getPurchasedProductByIdFromFirebase(String listId, String purchasedProductId) async {
    return await _firebaseManager.getPurchasedProductById(listId, purchasedProductId);
  }
}
