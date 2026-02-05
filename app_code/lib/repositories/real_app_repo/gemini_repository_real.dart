import 'package:app_code/models/category.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/receipt_match.dart';
import 'package:app_code/models/recipe_response.dart';
import 'package:app_code/repositories/abstract/gemini_repository.dart';
import 'package:app_code/services/gemini/gemini_service.dart';

class GeminiRepositoryReal implements GeminiRepository {
  final GeminiService _geminiService;

  GeminiRepositoryReal({GeminiService? geminiService})
      : _geminiService = geminiService ?? GeminiService();

  @override
  Future<RecipeData> queryRecipe({
    required String recipeName,
    required List<Category> categories,
  }) async {
    try {
      return await _geminiService.queryRecipe(
        recipeName: recipeName,
        categories: categories,
      );
    } catch (e) {
      return RecipeData.error('Something went wrong while searching for the recipe. Please try again.');
    }
  }

  @override
  Future<String> categorizeProduct({
    required String productName,
    required List<Category> categories,
  }) async {
    try {
      return await _geminiService.categorizeProduct(
        productName: productName,
        categories: categories,
      );
    } catch (e) {
      return 'uncategorized';
    }
  }

  @override
  Future<List<ReceiptMatch>> extractReceiptMatches({
    required String receiptText,
    required List<PurchasedProduct> purchasedProducts,
  }) async {
    try {
      return await _geminiService.extractReceiptMatches(
        receiptText: receiptText,
        purchasedProducts: purchasedProducts,
      );
    } catch (e) {
      rethrow;
    }
  }
}
