import 'package:app_code/models/category.dart';
import 'package:app_code/models/recipe_response.dart';
import 'package:app_code/repositories/abstract/gemini_repository.dart';
import 'package:app_code/services/gemini_service.dart';

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
      return RecipeData.error('Error querying Gemini: $e');
    }
  }
}
