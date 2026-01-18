import 'dart:convert';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/recipe_response.dart';

/// Parses Gemini API responses into structured RecipeData.
class GeminiResponseParser {
  /// Parses JSON response text from Gemini into RecipeData.
  static RecipeData parse(String content) {
    try {
      // Try to extract JSON from the response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);

      if (jsonMatch == null) {
        return RecipeData.error(
          'Recipe service returned an unexpected response. Please try again.',
        );
      }

      final jsonString = jsonMatch.group(0)!;
      final jsonResponse = jsonDecode(jsonString);

      // Build response using existing Product model
      final products = <Product>[];
      final quantities = <String>[];
      final productCategories = <String>[];

      if (jsonResponse['products'] is List) {
        for (final item in (jsonResponse['products'] as List)) {
          if (item is Map<String, dynamic>) {
            products.add(Product(name: (item['name'] ?? '').toString()));
            quantities.add((item['quantity'] ?? '').toString());
            productCategories.add((item['category'] ?? '').toString());
          }
        }
      }

      final recipeName = (jsonResponse['recipe_name'] ?? '').toString();
      final error = (jsonResponse['error'] ?? '').toString();

      // Check if error indicates recipe not found
      if (error.isNotEmpty && error.toLowerCase() != 'noerror') {
        // Return formatted error message with recipe name if not found
        return RecipeData.error('"$recipeName" not found. Try again.');
      }

      return RecipeData(
        products: products,
        quantities: quantities,
        productCategories: productCategories,
        recipeName: recipeName,
        error: error.isEmpty ? 'noError' : error,
      );
    } catch (e) {
      return RecipeData.error(
        'Could not process the recipe. Please try again.',
      );
    }
  }
}
