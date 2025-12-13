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
  
  PurchasedProduct({
    String? id,
    required this.listId,
    required this.product,
    required this.category,
    this.price = 0.0,
    this.quantity = 0,
  }) : this.id = id ?? Helper.generateId();

  factory PurchasedProduct.fromDatabase(Map<String, dynamic> json, Category category, Product product) {
    return PurchasedProduct(
      id: json['id'],
      listId: json['list_id'],
      category: category,
      product: product,
      price: json['price'],
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'list_id': listId,
      'product_id': product?.id,
      'category_id': category.id,
      'price': price,
      'quantity': quantity,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'list_id': listId,
      'product': product?.toJson(),
      'category': category.toJson(),
      'price': price,
      'quantity': quantity,
    };
  }

  set setProduct(Product product) {
    // ignore: unnecessary_this
    this.product = product;
  }
}