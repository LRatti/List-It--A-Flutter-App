import 'package:app_code/models/product.dart';
import 'dart:convert';

/// Represents a recipe response from Gemini with product list and recipe name
class RecipeData {
  final List<Product> products;
  final List<String> quantities; // Parallel list to products for quantities
  final List<String> productCategories; // Category names for each product
  final String recipeName;
  final String error;
  final bool hasError;

  RecipeData({
    required this.products,
    required this.quantities,
    required this.productCategories,
    required this.recipeName,
    required this.error,
  }) : hasError = error != 'noError' && error.isNotEmpty;

  factory RecipeData.empty() {
    return RecipeData(
      products: [],
      quantities: [],
      productCategories: [],
      recipeName: '',
      error: 'noError',
    );
  }

  factory RecipeData.error(String errorMessage) {
    return RecipeData(
      products: [],
      quantities: [],
      productCategories: [],
      recipeName: '',
      error: errorMessage,
    );
  }

  /// Convert RecipeData to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'products': products.map((p) => p.getName()).toList(),
      'quantities': quantities,
      'productCategories': productCategories,
      'recipeName': recipeName,
      'error': error,
    };
  }

  /// Create RecipeData from JSON
  factory RecipeData.fromJson(Map<String, dynamic> json) {
    return RecipeData(
      products: (json['products'] as List<dynamic>)
          .map((name) => Product(name: name as String))
          .toList(),
      quantities: List<String>.from(json['quantities'] as List<dynamic>),
      productCategories:
          List<String>.from(json['productCategories'] as List<dynamic>),
      recipeName: json['recipeName'] as String,
      error: json['error'] as String,
    );
  }

  /// Convert to JSON string for database storage
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON string
  factory RecipeData.fromJsonString(String jsonString) {
    return RecipeData.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}

