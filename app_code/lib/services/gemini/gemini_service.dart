import 'package:app_code/models/category.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/receipt_match.dart';
import 'package:app_code/models/recipe_response.dart';
import 'package:app_code/services/gemini/gemini_client.dart';
import 'package:app_code/services/gemini/gemini_exception_handler.dart';
import 'package:app_code/services/gemini/gemini_prompt_builder.dart';
import 'package:app_code/services/gemini/gemini_response_parser.dart';
import 'package:app_code/services/receipt/receipt_response_parser.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // Read the API key from environment. Must be provided via compile-time define.
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  final GeminiClient _client;

  /// Creates a GeminiService with a custom client (for testing).
  GeminiService.withClient(this._client);

  /// Creates a GeminiService with the real Gemini API client.
  /// Requires GEMINI_API_KEY to be set via compile-time environment variable.
  factory GeminiService() {
    if (_apiKey.isEmpty) {
      throw Exception(
        'GEMINI_API_KEY environment variable is not set. '
        'Pass it via: --dart-define=GEMINI_API_KEY=your_key',
      );
    }
    return GeminiService.withClient(RealGeminiClient(apiKey: _apiKey));
  }

  /// Sends a recipe query to Gemini and receives a structured response
  Future<RecipeData> queryRecipe({
    required String recipeName,
    required List<Category> categories,
  }) async {
    try {
      final categoryNames = categories.map((c) => c.getName()).join(', ');
      final prompt = GeminiPromptBuilder.buildRecipePrompt(
        recipeName,
        categoryNames,
      );

      final responseText = await _client.generateText(prompt);

      if (responseText.isEmpty) {
        return RecipeData.error(
          'Recipe service did not return a response. Please try again.',
        );
      }

      return GeminiResponseParser.parse(responseText);
    } on GenerativeAIException catch (e) {
      return GeminiExceptionHandler.handleGenerativeAIException(e);
    } catch (e) {
      return GeminiExceptionHandler.handleGenericException(e as Exception);
    }
  }

  /// Categorizes a product using Gemini AI
  Future<String> categorizeProduct({
    required String productName,
    required List<Category> categories,
  }) async {
    try {
      final categoryNames = categories.map((c) => c.getName()).join(', ');
      final prompt =
          GeminiPromptBuilder.buildCategorizationPrompt(productName, categoryNames);

      final responseText = await _client.generateText(prompt);

      if (responseText.isEmpty) {
        return 'uncategorized';
      }

      // Validate the response is one of the available categories
      final normalizedResponse = responseText.toLowerCase().trim();
      final matchingCategory = categories.firstWhere(
        (cat) => cat.getName().toLowerCase() == normalizedResponse,
        orElse: () => Category(name: 'uncategorized'),
      );

      return matchingCategory.getName();
    } catch (e) {
      return 'uncategorized';
    }
  }

  /// Extracts prices and quantities for purchased products from receipt text.
  Future<List<ReceiptMatch>> extractReceiptMatches({
    required String receiptText,
    required List<PurchasedProduct> purchasedProducts,
  }) async {
    try {
      final purchasedProductsText = purchasedProducts
          .map((p) => '- id: ${p.id}, name: ${p.product.getName()}')
          .join('\n');

      final prompt = GeminiPromptBuilder.buildReceiptExtractionPrompt(
        receiptText: receiptText,
        purchasedProducts: purchasedProductsText,
      );

      final responseText = await _client.generateText(prompt);

      if (responseText.isEmpty) {
        throw Exception('Receipt service did not return a response.');
      }

      return ReceiptResponseParser.parse(responseText);
    } on GenerativeAIException catch (e) {
      final msg = e.message ?? e.toString();
      final lowerMsg = msg.toLowerCase();

      if (lowerMsg.contains('quota') ||
          lowerMsg.contains('rate limit') ||
          lowerMsg.contains('exceeded')) {
        throw Exception('Receipt service is temporarily unavailable. Try again later.');
      }

      if (lowerMsg.contains('socket') ||
          lowerMsg.contains('connection') ||
          lowerMsg.contains('timeout') ||
          lowerMsg.contains('network')) {
        throw Exception('Connection error. Check your internet and try again.');
      }

      throw Exception('Receipt service failed. Please try again.');
    } catch (e) {
      throw Exception('Receipt processing failed. Please try again.');
    }
  }
}
