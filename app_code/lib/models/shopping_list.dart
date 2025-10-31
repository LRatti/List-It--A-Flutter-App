import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:flutter/material.dart';

class ShoppingList {
 
  final int id;
  String? name;
  DateTime? createdAt;
  Supermarket? supermarket;
  final int userId;
  double? totalPrice;
  Image? image;
  List<PurchasedProduct>? products;
  bool isRegistered = false;

  ShoppingList(
      {required this.id,
      this.name,
      this.createdAt,
      this.supermarket,
      required this.userId,
      this.totalPrice,
      this.image,
      this.products,
      this.isRegistered = false});

  int getId() {
    return id;
  }

  String getName() {
    return name ?? '';
  }

  DateTime getCreatedAt() {
    return createdAt ?? DateTime.now();
  }

  Supermarket? getSupermarket() {
    return supermarket;
  }

  int getUserId() {
    return userId;
  }

  double getTotalPrice() {
    return totalPrice ?? 0.0;
  }

  List<PurchasedProduct> getProducts() {
    return products ?? [];
  }

  bool getIsRegistered() {
    return isRegistered;
  }

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
      supermarket: json['supermarket'] != null
          ? Supermarket.fromJson(json['supermarket'])
          : null,
      userId: json['user_id'],
      totalPrice: json['total_price'],
      isRegistered: json['is_registered'] ?? false,
      // image and products deserialization can be added here if needed
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt?.toIso8601String(),
      'supermarket': supermarket?.toJson(),
      'user_id': userId,
      'total_price': totalPrice,
      'is_registered': isRegistered,
      // image and products serialization can be added here if needed
    };
  }

  void addProduct(Product product) {
    PurchasedProduct purchasedProduct = PurchasedProduct(
      price: 0.0,
      quantity: 1,
      product: product,
    );
    products ??= [];
    products!.add(purchasedProduct);
  }

  void removeProduct(PurchasedProduct product) {
    products?.remove(product);
  }

  void removeProductById(int productId) {
    products?.removeWhere((product) => product.id == productId);
  }
  
  void setName(String name) {
    this.name = name;
  }

  void setCreatedAt(DateTime createdAt) {
    this.createdAt = createdAt;
  }

  void setSupermarket(Supermarket supermarket) {
    this.supermarket = supermarket;
  }

  void setTotalPrice(double totalPrice) {
    this.totalPrice = totalPrice;
  }

  void computeTotalPrice() {
    totalPrice = products?.fold(0, (sum, product) => sum! + (product.getTotalPrice())) ?? 0.0;
  } 

  void setImage(Image image) {
    this.image = image;
  }

  void setIsRegistered(bool isRegistered) {
    this.isRegistered = isRegistered;
  }


}