import 'package:app_code/models/recipe_response.dart';

abstract class RecipeCacheRepository {
  /// Save a recipe search result to cache
  Future<void> saveRecipeCache({
    required String listId,
    required String recipeName,
    required RecipeData recipeData,
    bool hasSeenNotification,
  });

  /// Load a cached recipe search for a specific list
  Future<({String recipeName, RecipeData recipeData, bool hasSeenNotification})?> loadRecipeCache(
    String listId,
  );

  /// Delete the cached recipe search for a specific list
  Future<void> deleteRecipeCache(String listId);

  /// Check if there is a cached recipe for a specific list
  Future<bool> hasCachedRecipe(String listId);

  /// Mark the cached recipe notification as seen
  Future<void> markNotificationSeen(String listId);

  /// Clear all recipe caches
  Future<void> clearAllCaches();
}
