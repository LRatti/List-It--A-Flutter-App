import 'package:app_code/models/product.dart';
import 'package:app_code/services/database/sqlite/manage_product.dart' as sqlite;
import 'package:app_code/services/database/firebase/manage_product.dart';

/// Database Manager for Products - Implements write-ahead pattern
/// SQLite operations are executed first (synchronously), 
/// Firebase operations follow in a non-blocking manner
class ProductDatabaseManager {
  final FirebaseProductManager _firebaseManager = FirebaseProductManager();

  /// Add a new product to both databases
  /// Write-ahead: SQLite first, then Firebase async
  Future<void> addProduct(Product product) async {
    // 1. Write to SQLite first (blocking)
    await sqlite.ManageProduct.addProduct(product);
    
    // 2. Write to Firebase in non-blocking manner
    _firebaseManager.setProduct(product).catchError((error) {
      print('Firebase sync error (addProduct): $error');
    });
  }

  /// Update an existing product in both databases
  /// Write-ahead: SQLite first, then Firebase async
  Future<void> updateProduct(Product product) async {
    // 1. Update SQLite first (blocking)
    await sqlite.ManageProduct.updateProduct(product);
    
    // 2. Update Firebase in non-blocking manner
    _firebaseManager.setProduct(product).catchError((error) {
      print('Firebase sync error (updateProduct): $error');
    });
  }

  /// Delete a product from both databases
  /// Write-ahead: SQLite first, then Firebase async
  Future<void> deleteProduct(String id) async {
    // 1. Delete from SQLite first (blocking)
    await sqlite.ManageProduct.deleteProduct(id);
    
    // 2. Delete from Firebase in non-blocking manner
    // Note: Firebase uses setProduct, so we need to mark as deleted or remove
    // For now, we'll skip Firebase delete as it doesn't have a dedicated delete method
    // This should be handled in a full sync implementation
  }

  /// Get product by ID - reads from SQLite only (source of truth)
  Future<Product?> getProductById(String id) async {
    return await sqlite.ManageProduct.getProductById(id);
  }

  /// Get product by name - reads from SQLite only (source of truth)
  Future<Product?> getProductByName(String name) async {
    return await sqlite.ManageProduct.getProductByName(name);
  }

  /// Get all products - reads from SQLite only (source of truth)
  Future<List<Product>> getAllProducts() async {
    return await sqlite.ManageProduct.getAllProducts();
  }

  // ========== Firebase-specific methods ==========
  
  /// Batch add multiple products (Firebase-specific feature)
  /// Write-ahead: SQLite first (one by one), then Firebase batch async
  Future<void> setAllProducts(List<Product> products) async {
    // 1. Write to SQLite first (blocking)
    for (var product in products) {
      await sqlite.ManageProduct.addProduct(product);
    }
    
    // 2. Batch write to Firebase in non-blocking manner
    _firebaseManager.setAllProducts(products).catchError((error) {
      print('Firebase sync error (setAllProducts): $error');
    });
  }

  /// Get visible products - Firebase-specific feature
  /// Since SQLite doesn't have this method, we query Firebase directly
  Future<List<Product>> getVisibleProducts() async {
    return await _firebaseManager.getVisibleProducts();
  }
}
