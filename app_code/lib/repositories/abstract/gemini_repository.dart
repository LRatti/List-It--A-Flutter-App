import 'package:app_code/models/category.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/receipt_match.dart';
import 'package:app_code/models/recipe_response.dart';

abstract class GeminiRepository {
  Future<RecipeData> queryRecipe({
    required String recipeName,
    required List<Category> categories,
  });

  Future<String> categorizeProduct({
    required String productName,
    required List<Category> categories,
  });

  Future<List<ReceiptMatch>> extractReceiptMatches({
    required String receiptText,
    required List<PurchasedProduct> purchasedProducts,
  });
}
