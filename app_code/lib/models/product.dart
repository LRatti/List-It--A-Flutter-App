import 'package:app_code/utils/helper.dart';

/// Represents a unique product in the system
/// 
/// A Product is a global entity that can be referenced by multiple PurchasedProduct
/// instances across different shopping lists. It maintains a unique ID and name,
/// along with category associations for each supermarket.
/// 
/// CRITICAL DESIGN NOTE - Product References and Updates:
/// =====================================================
/// 
/// Products are shared references across PurchasedProduct instances. This means
/// multiple PurchasedProduct objects can point to the same Product instance.
/// 
/// When updating a product's name:
/// - NEVER directly modify the Product object with setName() if it may be
///   referenced by multiple PurchasedProduct instances
/// - Instead, update the PurchasedProduct's product REFERENCE to point to
///   a different Product (either new or existing)
/// 
/// Example of the Bug:
/// -------------------
/// List A has PurchasedProduct1 -> Product (id=P1, name="Apple")
/// List B has PurchasedProduct2 -> Product (id=P1, name="Apple") [SAME OBJECT!]
/// 
/// If you do: purchasedProduct1.product.setName("Red Apple")
/// Result: Both products become "Red Apple" because they reference the same object
/// 
/// Correct Approach:
/// -----------------
/// When updating a purchased product's name:
/// 1. Find or create a Product with the new name
/// 2. Update the PurchasedProduct to reference this new Product
/// 3. The original Product remains unchanged
/// 
/// See: PurchasedProductUpdateHandler for the correct implementation
class Product {
  final String id;
  String _name;
  Map<String, String> associations; // supermarketId -> categoryId
  bool isVisible;
  late DateTime? lastModified;
  late DateTime createdAt;

  Product({
    String? id,
    required String name,
    Map<String, String>? associations,
    bool isVisible = true,
    DateTime? lastModified,
    DateTime? createdAt,
    bool isDeleted = false,
  })  : id = id ?? Helper.generateId(),
        _name = name,
        associations = associations ?? {},
        isVisible = isVisible,
        createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? (createdAt ?? DateTime.now());

  String getName() {
    return _name;
  }

  void setName(String name) {
    _name = name;
  }

  void setAssociations(Map<String, String> associations) {
    this.associations = associations;
  }

  void setVisibility(bool visibility) {
    isVisible = visibility;
  }

  void addAssociation(String supermarketId, String categoryId) {
    associations[supermarketId] = categoryId;
  }

  factory Product.fromDatabase(
    Map<String, dynamic> json, {
    Map<String, String>? associations,
  }) {
    return Product(
      id: json['id'],
      name: json['name'],
      isVisible: (json['is_visible'] ?? 1) == 1,
      associations: associations,
      lastModified: DateTime.tryParse(json['last_modified'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'name': _name,
      'is_visible': isVisible ? 1 : 0,
      'last_modified': lastModified?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      associations: Map<String, String>.from(json['associations'] ?? {}),
      isVisible: json['isVisible'] ?? true,
      lastModified: DateTime.tryParse(json['lastModified'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': _name,
      'associations': associations,
      'isVisible': isVisible,
      'lastModified': lastModified?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
