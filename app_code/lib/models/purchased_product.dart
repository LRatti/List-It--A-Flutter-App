import 'package:app_code/models/product.dart';
import 'package:isar/isar.dart';

@collection
class PurchasedProduct {
  final String id;
  double price = 0.0;
  int quantity = 0;
  final Product _product;

  //TODO: generate random uuid for localId
  PurchasedProduct(
      {
        required this.id,
        this.price = 0.0,
        this.quantity = 0,
        required product,
      }
  ):  
    _product = product;


  factory PurchasedProduct.fromJson(Map<String, dynamic> json) {
    return PurchasedProduct(
      id: json['id'],
      price: json['price'],
      quantity: json['quantity'],
      product: json['product'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'price': price,
      'quantity': quantity,
      'product': _product
    };
  }

  double getTotalPrice() {
    return (price) * (quantity);
  }
}