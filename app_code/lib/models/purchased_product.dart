import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:isar/isar.dart';
import 'package:app_code/utils/helper.dart';

/// Represents a purchased product (item) in a shopping list
/// 
/// A PurchasedProduct is a specific instance of a Product added to a shopping list.
/// It maintains a reference to the Product object and tracks its quantity, price,
/// and category within the context of a specific supermarket.
/// 
/// IMPORTANT - Product Reference Management:
/// ===========================================
/// 
/// The [product] field holds a reference to a Product object. Multiple
/// PurchasedProduct instances can reference the same Product object.
/// 
/// When updating a purchased product's information:
/// - Quantity, price, category: Update directly on this PurchasedProduct
/// - Product name: NEVER use product.setName()
///   Instead: Update the [product] field to reference a different Product
/// 
/// Why? Because setName() modifies the shared Product object, affecting
/// all other PurchasedProducts that reference it across different lists.
/// 
/// Example Scenario:
/// -----------------
/// User has:
/// - List A (Supermarket X) with PurchasedProduct1 pointing to Product "Apple"
/// - List B (Supermarket X) with PurchasedProduct2 pointing to Product "Apple"
/// 
/// If the user renames PurchasedProduct1 to "Red Apple":
/// - WRONG: purchasedProduct1.product.setName("Red Apple")
///   Result: Both lists show "Red Apple" ❌
/// 
/// - RIGHT: purchasedProduct1.product = Product(name: "Red Apple")
///   Result: List A shows "Red Apple", List B still shows "Apple" ✅
@collection
class PurchasedProduct {

  final String id;
  final String listId;
  Product product;
  Category category;
  double price;
  int quantity;
  late DateTime? lastModified;
  late DateTime createdAt;
  bool isDeleted;
  
  PurchasedProduct({
    String? id,
    required this.listId,
    required this.product,
    required this.category,
    this.price = 0.0,
    this.quantity = 0,
    DateTime? lastModified,
    DateTime? createdAt,
    bool isDeleted = false,
  }) : this.id = id ?? Helper.generateId(),
        createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? (createdAt ?? DateTime.now()),
        isDeleted = isDeleted;

  factory PurchasedProduct.fromDatabase(Map<String, dynamic> json, Category category, Product product) {
    return PurchasedProduct(
      id: json['id'],
      listId: json['list_id'],
      category: category,
      product: product,
      price: json['price'],
      quantity: json['quantity'],
      lastModified: DateTime.tryParse(json['last_modified'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isDeleted: (json['is_deleted'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'list_id': listId,
      'product_id': product.id,
      'category_id': category.id,
      'price': price,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
      'last_modified': lastModified?.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory PurchasedProduct.fromJson(Map<String, dynamic> json) {
    return PurchasedProduct(
      id: json['id'],
      listId: json['list_id'],
      price: json['price'],
      category: json['category'] != null ? Category.fromJson(json['category']) : Category(id: '', name: 'Uncategorized'),
      quantity: json['quantity'],
      product: json['product'] != null ? Product.fromJson(json['product']) : Product(id: '', name: 'Unknown'),
      lastModified: DateTime.tryParse(json['lastModified'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'list_id': listId,
      'product': product.toJson(),
      'category': category.toJson(),
      'price': price,
      'quantity': quantity,
      'lastModified': lastModified?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  set setProduct(Product product) {
    // ignore: unnecessary_this
    this.product = product;
  }

  void setCategory(Category newCategory) {
    category = newCategory;
  }
}