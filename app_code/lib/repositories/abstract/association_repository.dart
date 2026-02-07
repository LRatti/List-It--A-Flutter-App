/// Abstract interface for association repositories
/// Manages the mapping between products, supermarkets, and categories
abstract class AssociationRepository {
  /// Add multiple associations in a batch
  Future<void> addBatch(
    Map<String, Map<String, String>> associationsByProduct,
  );

  /// Delete multiple associations in a batch
  Future<void> deleteBatch(
    List<({String productId, String supermarketId})> associationsToDelete,
  );

  /// Add a single association
  Future<void> add(
    String productId,
    String supermarketId,
    String categoryId,
  );

  /// Update an existing association
  Future<void> update(
    String productId,
    String supermarketId,
    String categoryId,
  );

  /// Delete a specific association
  Future<void> delete(
    String productId,
    String supermarketId,
  );

  /// Get all associations for a specific product
  Future<Map<String, String>> getProductAssociations(String productId);

  /// Get the category for a product in a specific supermarket
  Future<String?> getCategoryForProduct(
    String productId,
    String supermarketId,
  );
}
