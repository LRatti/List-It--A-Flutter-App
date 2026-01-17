import 'package:app_code/models/category.dart';
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
}
