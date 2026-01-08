import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';

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
}
