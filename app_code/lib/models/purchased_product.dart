import 'package:app_code/models/product.dart';
import 'package:isar/isar.dart';
import 'package:app_code/utils/helper.dart';

@collection
class PurchasedProduct {
  final String id;
  final String listId;
  double price;
  int quantity;
  Product? product;

  PurchasedProduct({
    String? id,
    required this.listId,
    this.product,
    this.price = 0.0,
    this.quantity = 0,
  }) : this.id = id ?? Helper.generateId();

  factory PurchasedProduct.fromDatabase(Map<String, dynamic> json) {
    return PurchasedProduct(
      id: json['id'],
      listId: json['list_id'],
      price: json['price'],
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'list_id': listId,
      'product_id': product?.id,
      'price': price,
      'quantity': quantity,
    };
  }

  factory PurchasedProduct.fromJson(Map<String, dynamic> json) {
    return PurchasedProduct(
      id: json['id'],
      listId: json['list_id'],
      price: json['price'],
      quantity: json['quantity'],
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'list_id': listId,
      'product': product?.toJson(),
      'price': price,
      'quantity': quantity,
    };
  }

  set setProduct(Product product) {
    // ignore: unnecessary_this
    this.product = product;
  }
}