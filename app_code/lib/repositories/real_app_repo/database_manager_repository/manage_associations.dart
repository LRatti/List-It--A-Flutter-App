import 'package:app_code/services/database/firebase/manage_associations.dart';

/// Database Manager for Associations - Firebase-only feature
/// 
/// Note: SQLite handles associations differently (embedded in product management),
/// so this manager only wraps Firebase's dedicated association management.
/// In SQLite, associations are managed through the ManageProduct class.
///
/// For write operations, you should use the ProductDatabaseManager which handles
/// associations in both SQLite and Firebase properly.
class AssociationDatabaseManager {
  final FirebaseManageAssociations _firebaseManager = FirebaseManageAssociations();

  // ========== Firebase-only methods ==========
  
  /// Set an association between product, supermarket, and category
  /// This is a Firebase-specific feature for managing associations separately
  Future<void> setAssociation(String productId, String supermarketId, String categoryId) async {
    return await _firebaseManager.setAssociation(productId, supermarketId, categoryId);
  }

  /// Delete a specific association between a product and supermarket
  Future<void> deleteAssociation(String productId, String supermarketId) async {
    return await _firebaseManager.deleteAssociation(productId, supermarketId);
  }

  /// Delete all associations for a specific product
  Future<void> deleteProductAssociations(String productId) async {
    return await _firebaseManager.deleteProductAssociations(productId);
  }

  /// Get all associations for a specific product
  /// Returns a map of supermarketId -> categoryId
  Future<Map<String, String>> getProductAssociations(String productId) async {
    return await _firebaseManager.getProductAssociations(productId);
  }

  /// Get all products associated with a specific supermarket
  /// Returns a list of product IDs
  Future<List<String>> getProductsBySupermarket(String supermarketId) async {
    return await _firebaseManager.getProductsBySupermarket(supermarketId);
  }

  /// Get all products in a specific category within a supermarket
  /// Returns a list of product IDs
  Future<List<String>> getProductsByCategory(String supermarketId, String categoryId) async {
    return await _firebaseManager.getProductsByCategory(supermarketId, categoryId);
  }

  /// Get the category for a specific product in a specific supermarket
  /// Returns the category ID or null if not found
  Future<String?> getCategoryForProduct(String productId, String supermarketId) async {
    return await _firebaseManager.getCategoryForProduct(productId, supermarketId);
  }

  /// Get all categories associated with a product across all supermarkets
  /// Returns a list of category IDs
  Future<List<String>> getCategoriesByProduct(String productId) async {
    return await _firebaseManager.getCategoriesByProduct(productId);
  }
}
