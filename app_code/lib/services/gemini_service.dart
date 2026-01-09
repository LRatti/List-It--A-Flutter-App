import 'dart:convert';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/recipe_response.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // Read the API key from a compile-time define. Do NOT hardcode secrets.
  //TODO: don't use default value in production
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'AIzaSyALVy8BB5S7jkszDZdGlLgWc6QXIj4Cg4s');

  late final GenerativeModel _model;
  
  GeminiService() {
    _initModel();
  }

  void _initModel() {
    if (_apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
      );
    }
  }

  /// Sends a recipe query to Gemini and receives a structured response
  Future<RecipeData> queryRecipe({
    required String recipeName,
    required List<Category> categories,
  }) async {
    try {
      if (_apiKey.isEmpty) {
        return RecipeData.error('GEMINI_API_KEY is not set.');
      }

      final categoryNames = categories.map((c) => c.getName()).join(', ');
      
      final prompt = _buildPrompt(recipeName, categoryNames);

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      final responseText = response.text ?? '';
      
      if (responseText.isEmpty) {
        return RecipeData.error('Unable to process your request. Try again please');
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
        return RecipeData.error('Connection error: try later, please');
      }
      return RecipeData.error('Unable to process your request. Try again please');
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
      return RecipeData.error('You inserted an invalid recipe, try again please');
    }

    // Check for quota/rate limit errors
    if (lowerMsg.contains('quota') || 
        lowerMsg.contains('rate limit') ||
        lowerMsg.contains('exceeded')) {
      return RecipeData.error('Service temporarily unavailable. Try again later, please');
    }

    // Check for connection errors
    if (lowerMsg.contains('socket') || 
        lowerMsg.contains('connection') || 
        lowerMsg.contains('timeout') ||
        lowerMsg.contains('network')) {
      return RecipeData.error('Connection error: try later, please');
    }

    // Default error
    return RecipeData.error('Unable to process your request. Try again please');
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
        return RecipeData.error('Invalid response from Gemini');
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

      return RecipeData(
        products: products,
        quantities: quantities,
        productCategories: productCategories,
        recipeName: recipeName,
        error: error.isEmpty ? 'noError' : error,
      );
    } catch (e) {
      return RecipeData.error('Failed to parse Gemini response: $e');
    }
  }
}
