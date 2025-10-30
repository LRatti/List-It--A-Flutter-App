import 'package:app_code/models/product.dart';
import 'package:isar/isar.dart';

@collection
class PurchasedProduct {

  Id id = Isar.autoIncrement;
  double price = 0.0;
  int quantity = 0;
  Product? product;


  PurchasedProduct(
      {this.price = 0.0,
      this.quantity = 0,
      this.product});

  int getId() {
    return id;
  }

  double getPrice() {
    return price;
  }

  int getquantity() {
    return quantity;
  }

  void setPrice(double price) {
    this.price = price;
  }

  void setquantity(int quantity) {
    this.quantity = quantity;
  }

  factory PurchasedProduct.fromJson(Map<String, dynamic> json) {
    return PurchasedProduct(
      //id: json['id'],
      price: json['price'],
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'price': price,
      'quantity': quantity,
    };
  }

  double getTotalPrice() {
    return (price ?? 0.0) * (quantity ?? 0);
  }

  Product? getProduct() {
    return product;
  }


}