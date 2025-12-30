import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:isar/isar.dart';
import 'package:app_code/utils/helper.dart';

@collection
class PurchasedProduct {

  final String id;
  final String listId;
  Product product;
  Category category;
  double price;
  int quantity;
  late DateTime lastModified;
  bool isDeleted;
  
  PurchasedProduct({
    String? id,
    required this.listId,
    required this.product,
    required this.category,
    this.price = 0.0,
    this.quantity = 0,
    DateTime? lastModified,
    bool isDeleted = false,
  }) : this.id = id ?? Helper.generateId(),
        lastModified = lastModified ?? DateTime.now(),
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
      'last_modified': lastModified.toIso8601String(),
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
      'lastModified': lastModified.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  set setProduct(Product product) {
    // ignore: unnecessary_this
    this.product = product;
  }
}