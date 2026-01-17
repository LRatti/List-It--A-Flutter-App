import 'dart:convert';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/recipe_response.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // Read the API key from a compile-time define. Do NOT hardcode secrets.
  //TODO: don't use default value in production
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyALVy8BB5S7jkszDZdGlLgWc6QXIj4Cg4s',
  );

  late final GenerativeModel _model;

  GeminiService() {
    _initModel();
  }

  void _initModel() {
    if (_apiKey.isNotEmpty) {
      _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
    }
  }

  /// Sends a recipe query to Gemini and receives a structured response
  Future<RecipeData> queryRecipe({
    required String recipeName,
    required List<Category> categories,
  }) async {
    try {
      if (_apiKey.isEmpty) {
        return RecipeData.error(
          'Service is not available at the moment. Please try again later.',
        );
      }

      final categoryNames = categories.map((c) => c.getName()).join(', ');

      final prompt = _buildPrompt(recipeName, categoryNames);

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      final responseText = response.text ?? '';

      if (responseText.isEmpty) {
        return RecipeData.error(
          'Recipe service did not return a response. Please try again.',
        );
      }

      return _parseGeminiResponse(responseText);
    } on GenerativeAIException catch (e) {
      return _handleGeminiException(e);
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      // Check for connection/network errors
      if (errorStr.contains('socket') ||
          errorStr.contains('connection') ||
          errorStr.contains('timeout') ||
          errorStr.contains('network')) {
        return RecipeData.error(
          'Connection error. Please check your internet connection and try again.',
        );
      }
      return RecipeData.error('Something went wrong. Please try again.');
    }
  }

  /// Handle Gemini-specific exceptions with user-friendly messages
  RecipeData _handleGeminiException(GenerativeAIException e) {
    final msg = e.message ?? e.toString();
    final lowerMsg = msg.toLowerCase();

    // Check for invalid/not found recipe
    if (lowerMsg.contains('not found') ||
        lowerMsg.contains('does not exist') ||
        lowerMsg.contains('unknown recipe')) {
      return RecipeData.error(
        'The recipe you searched for does not exist. Please check the spelling and try again.',
      );
    }

    // Check for quota/rate limit errors
    if (lowerMsg.contains('quota') ||
        lowerMsg.contains('rate limit') ||
        lowerMsg.contains('exceeded')) {
      return RecipeData.error(
        'Recipe service is temporarily unavailable. Please try again in a few moments.',
      );
    }

    // Check for connection errors
    if (lowerMsg.contains('socket') ||
        lowerMsg.contains('connection') ||
        lowerMsg.contains('timeout') ||
        lowerMsg.contains('network')) {
      return RecipeData.error(
        'Connection error. Please check your internet connection and try again.',
      );
    }

    // Default error
    return RecipeData.error(
      'Something went wrong while searching for the recipe. Please try again.',
    );
  }

  /// Builds the prompt to send to Gemini
  String _buildPrompt(String recipeName, String categories) {
    return '''
You are a recipe expert. The user wants to know the ingredients needed to make the recipe: "$recipeName".

Your task:
1. If the recipe exists, provide a list of all necessary products/ingredients with their quantities.
2. Classify each product into one of these categories: $categories
3. Return the corrected recipe name (in case the user misspelled it).
4. If the recipe doesn't exist, return an error message.

IMPORTANT GUIDELINES FOR PRODUCT NAMES:
- Use specific product names as they would be purchased. For example:
  - For carbonara: use "eggs" (not "whole egg")
  - For egg white only: use "egg white" (not "eggs")
  - For ground beef: use "ground beef" (not "beef")
  - For olive oil: use "olive oil" (not "oil")
- Always write the product name in its simplest shopping form.

IMPORTANT: You MUST return a valid JSON response with this exact structure:
{
  "products": [
    {
      "name": "ingredient name",
      "category": "category name",
      "quantity": "quantity with unit (e.g., 2 cups, 200g)"
    },
    ...
  ],
  "recipe_name": "actual recipe name",
  "error": "noError" or "Error description if recipe not found"
}

Ensure the JSON is valid and can be parsed. Return ONLY the JSON object, no additional text.
''';
  }

  /// Parses the response from Gemini
  RecipeData _parseGeminiResponse(String content) {
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

  /// Categorizes a product using Gemini AI
  Future<String> categorizeProduct({
    required String productName,
    required List<Category> categories,
  }) async {
    try {
      if (_apiKey.isEmpty) {
        return 'uncategorized';
      }

      final categoryNames = categories.map((c) => c.getName()).join(', ');

      final prompt = '''
You are a product categorization expert.

The user wants to categorize the product: "$productName"

Available categories: $categoryNames

Your task:
1. Choose the most appropriate category for this product from the available categories.
2. If the product doesn't fit any category well, choose "uncategorized".
3. Return ONLY the category name, nothing else.

IMPORTANT: Return ONLY the category name as plain text, no JSON, no quotes, no additional text.
''';

      final content = [Content.text(prompt)];

      final response = await _model.generateContent(content);

      final responseText = (response.text ?? '').trim();

      if (responseText.isEmpty) {
        return 'uncategorized';
      }

      // Validate the response is one of the available categories
      final normalizedResponse = responseText.toLowerCase();
      final matchingCategory = categories.firstWhere(
        (cat) => cat.getName().toLowerCase() == normalizedResponse,
        orElse: () => Category(name: 'uncategorized'),
      );

      return matchingCategory.getName();
    } catch (e) {
      return 'uncategorized';
    }
  }
}
