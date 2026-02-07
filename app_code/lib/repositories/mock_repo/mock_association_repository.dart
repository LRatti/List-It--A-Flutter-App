import 'package:app_code/repositories/abstract/association_repository.dart';

/// In-memory implementation of AssociationRepository for testing.
/// Tracks method calls and provides simple association management.
class MockAssociationRepository implements AssociationRepository {
  // In-memory storage: productId -> (supermarketId -> categoryId)
  final Map<String, Map<String, String>> _associations = {};
  
  // Track method calls for testing verification
  final List<String> callLog = [];
  
  /// Add multiple associations in a batch
  Future<void> addBatch(
    Map<String, Map<String, String>> associationsByProduct,
  ) async {
    callLog.add('addBatch');
    
    for (final entry in associationsByProduct.entries) {
      final productId = entry.key;
      final associations = entry.value;
      
      if (!_associations.containsKey(productId)) {
        _associations[productId] = {};
      }
      
      _associations[productId]!.addAll(associations);
    }
  }
  
  /// Delete multiple associations in a batch
  Future<void> deleteBatch(
    List<({String productId, String supermarketId})> associationsToDelete,
  ) async {
    callLog.add('deleteBatch');
    
    for (final assoc in associationsToDelete) {
      _associations[assoc.productId]?.remove(assoc.supermarketId);
      
      // Clean up empty product entries
      if (_associations[assoc.productId]?.isEmpty ?? false) {
        _associations.remove(assoc.productId);
      }
    }
  }
  
  /// Add a single association
  Future<void> add(
    String productId,
    String supermarketId,
    String categoryId,
  ) async {
    callLog.add('add');
    
    if (productId.isEmpty || supermarketId.isEmpty || categoryId.isEmpty) {
      throw ArgumentError(
        'Invalid association: productId=$productId, '
        'supermarketId=$supermarketId, categoryId=$categoryId',
      );
    }
    
    if (!_associations.containsKey(productId)) {
      _associations[productId] = {};
    }
    
    _associations[productId]![supermarketId] = categoryId;
  }
  
  /// Update an association
  Future<void> update(
    String productId,
    String supermarketId,
    String categoryId,
  ) async {
    callLog.add('update');
    
    if (productId.isEmpty || supermarketId.isEmpty || categoryId.isEmpty) {
      throw ArgumentError(
        'Invalid association: productId=$productId, '
        'supermarketId=$supermarketId, categoryId=$categoryId',
      );
    }
    
    if (_associations.containsKey(productId)) {
      _associations[productId]![supermarketId] = categoryId;
    }
  }
  
  /// Delete a specific association
  Future<void> delete(
    String productId,
    String supermarketId,
  ) async {
    callLog.add('delete');
    
    _associations[productId]?.remove(supermarketId);
    
    // Clean up empty product entries
    if (_associations[productId]?.isEmpty ?? false) {
      _associations.remove(productId);
    }
  }
  
  /// Get all associations for a product
  Future<Map<String, String>> getProductAssociations(String productId) async {
    callLog.add('getProductAssociations');
    return Map.from(_associations[productId] ?? {});
  }
  
  /// Get category for a product in a specific supermarket
  Future<String?> getCategoryForProduct(
    String productId,
    String supermarketId,
  ) async {
    callLog.add('getCategoryForProduct');
    return _associations[productId]?[supermarketId];
  }
  
  /// Clear all associations (for testing)
  void clear() {
    _associations.clear();
    callLog.clear();
  }
  
  /// Get all associations (for testing verification)
  Map<String, Map<String, String>> getAll() {
    return _associations.map(
      (key, value) => MapEntry(key, Map<String, String>.from(value)),
    );
  }
}
