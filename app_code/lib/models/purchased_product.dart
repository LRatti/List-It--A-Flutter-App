import 'package:app_code/models/product.dart';
import 'package:isar/isar.dart';
import 'package:app_code/utils/helper.dart';

@collection
class PurchasedProduct {
  final String id;
  final String listId;
  double price;
  int quantity;
  final Product product;

  PurchasedProduct({
    String? id,
    required this.listId,
    required this.product,
    this.price = 0.0,
    this.quantity = 0,
  }) : this.id = id ?? Helper.generateId();

  factory PurchasedProduct.fromJson(Map<String, dynamic> json, Product product) {
    return PurchasedProduct(
      id: json['id'],
      listId: json['list_id'],
      product: product,
      price: json['price'],
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'list_id': listId,
      'product_id': product.id,
      'price': price,
      'quantity': quantity,
    };
  }

  double getTotalPrice() {
    return price * quantity;
  }
}