import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:flutter/material.dart';
import 'package:app_code/utils/helper.dart';

class ShoppingList {
 
  final String id;
  String _name;
  final DateTime? createdAt;
  Supermarket _supermarket;
  double? _totalPrice;
  Image? image;
  List<PurchasedProduct>? products;
  bool _isRegistered = false;

  ShoppingList(
      {String? id,
      required name,
      required this.createdAt,
      supermarket,
      totalPrice,
      this.image,
      this.products,
      isRegistered,
  }) :  _name = name,
        _totalPrice = totalPrice,
        _supermarket = supermarket,
        _isRegistered = isRegistered,
        this.id = id ?? Helper.generateId();

  String getName() {
    return this._name;
  }

  DateTime? getCreatedAt() {
    return createdAt;
  }

  Supermarket? getSupermarket() {
    return this._supermarket;
  }

  double getTotalPrice() {
    return this._totalPrice ?? 0.0;
  }

  List<PurchasedProduct> getProducts() {
    return products ?? [];
  }

  bool getIsRegistered() {
    return _isRegistered;
  }

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'],
      name: json['name'],
      //WARN: can be null from import check date.
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      totalPrice: json['total_price'],
      isRegistered: json['is_registered'] ?? false,
      // image and products deserialization can be added here if needed
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': _name,
      'created_at': createdAt?.toIso8601String(),
      'supermarket': _supermarket.id,
      'total_price': _totalPrice,
      'is_registered': _isRegistered,
      // image and products serialization can be added here if needed
    };
  }

  void addProduct(Product product) {
    PurchasedProduct purchasedProduct = PurchasedProduct(
      id: product.id,
      price: 0.0,
      quantity: 1,
      product: product, 
      listId: id,
    );
    products ??= [];
    products!.add(purchasedProduct);
  }

  void setPurchasedProducts(List<PurchasedProduct> products) {
    this.products = products;
  }

  void removeProduct(PurchasedProduct product) {
    products?.remove(product);
  }

  void removeProductById(String productId) {
    products?.removeWhere((product) => product.id == productId);
  }

  void removeAllProducts() {
    products?.clear();
  }
  
  void setName(String newName) {
    this._name = newName;
  }

  void setSupermarket(Supermarket supermarket) {
    this._supermarket = supermarket;
  }

  void setTotalPrice(double totalPrice) {
    this._totalPrice = totalPrice;
  }

  void computeTotalPrice() {
    _totalPrice = products?.fold(0, (sum, product) => sum! + (product.getTotalPrice())) ?? 0.0;
  } 

  void setImage(Image image) {
    this.image = image;
  }

  void setIsRegistered(bool isRegistered) {
    _isRegistered = isRegistered;
  }
}