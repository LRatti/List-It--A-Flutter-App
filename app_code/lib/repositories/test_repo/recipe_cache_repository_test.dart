import 'package:app_code/models/recipe_response.dart';
import 'package:app_code/repositories/abstract/recipe_cache_repository.dart';

/// Test implementation of RecipeCacheRepository for testing purposes
/// Stores recipe caches in memory without actual database persistence
class RecipeCacheRepositoryTest implements RecipeCacheRepository {
  final Map<String, ({String recipeName, RecipeData recipeData})> _cache = {};

  @override
  Future<void> saveRecipeCache({
    required String listId,
    required String recipeName,
    required RecipeData recipeData,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 50));

    _cache[listId] = (recipeName: recipeName, recipeData: recipeData);
  }

  @override
  Future<({String recipeName, RecipeData recipeData})?> loadRecipeCache(
    String listId,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 50));

    return _cache[listId];
  }

  @override
  Future<void> deleteRecipeCache(String listId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 50));

    _cache.remove(listId);
  }

  @override
  Future<bool> hasCachedRecipe(String listId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 50));

    return _cache.containsKey(listId);
  }

  @override
  Future<void> clearAllCaches() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 50));

    _cache.clear();
  }
}
