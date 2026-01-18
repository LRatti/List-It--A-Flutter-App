import 'package:app_code/models/recipe_response.dart';
import 'package:app_code/repositories/abstract/recipe_cache_repository.dart';
import 'package:app_code/services/database/sqlite/manage_recipe_cache.dart';

/// SQLite implementation of RecipeCacheRepository
/// Manages cached recipe searches in the local database
class RecipeCacheRepositoryReal implements RecipeCacheRepository {
  @override
  Future<void> saveRecipeCache({
    required String listId,
    required String recipeName,
    required RecipeData recipeData,
    bool hasSeenNotification = false,
  }) async {
    await ManageRecipeCache.saveRecipeCache(
      listId: listId,
      recipeName: recipeName,
      recipeData: recipeData,
      hasSeenNotification: hasSeenNotification,
    );
  }

  @override
  Future<({String recipeName, RecipeData recipeData, bool hasSeenNotification})?> loadRecipeCache(
    String listId,
  ) async {
    return ManageRecipeCache.loadRecipeCache(listId);
  }

  @override
  Future<void> deleteRecipeCache(String listId) async {
    await ManageRecipeCache.deleteRecipeCache(listId);
  }

  @override
  Future<bool> hasCachedRecipe(String listId) async {
    return ManageRecipeCache.hasCachedRecipe(listId);
  }

  @override
  Future<void> markNotificationSeen(String listId) async {
    await ManageRecipeCache.markNotificationSeen(listId);
  }

  @override
  Future<void> clearAllCaches() async {
    await ManageRecipeCache.clearAllCaches();
  }
}
