import 'package:app_code/models/recipe_response.dart';
import 'package:app_code/repositories/abstract/recipe_cache_repository.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:sqflite/sqflite.dart';

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
    final db = await DatabaseHelper.database;

    // Delete any existing cache for this list first
    await deleteRecipeCache(listId);

    // Insert new cache
    await db.insert('recipe_cache', {
      'list_id': listId,
      'recipe_name': recipeName,
      'recipe_data': recipeData.toJsonString(),
      'error_message': recipeData.hasError ? recipeData.error : null,
      'has_seen_notification': hasSeenNotification ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<({String recipeName, RecipeData recipeData, bool hasSeenNotification})?> loadRecipeCache(
    String listId,
  ) async {
    final db = await DatabaseHelper.database;

    final results = await db.query(
      'recipe_cache',
      where: 'list_id = ?',
      whereArgs: [listId],
    );

    if (results.isEmpty) {
      return null;
    }

    final row = results.first;
    return (
      recipeName: row['recipe_name'] as String,
      recipeData: RecipeData.fromJsonString(row['recipe_data'] as String),
      hasSeenNotification: (row['has_seen_notification'] as int? ?? 0) == 1,
    );
  }

  @override
  Future<void> deleteRecipeCache(String listId) async {
    final db = await DatabaseHelper.database;

    await db.delete('recipe_cache', where: 'list_id = ?', whereArgs: [listId]);
  }

  @override
  Future<bool> hasCachedRecipe(String listId) async {
    final db = await DatabaseHelper.database;

    final results = await db.query(
      'recipe_cache',
      where: 'list_id = ?',
      whereArgs: [listId],
      columns: ['list_id'],
    );

    return results.isNotEmpty;
  }

  @override
  Future<void> markNotificationSeen(String listId) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'recipe_cache',
      {'has_seen_notification': 1},
      where: 'list_id = ?',
      whereArgs: [listId],
    );
  }

  @override
  Future<void> clearAllCaches() async {
    final db = await DatabaseHelper.database;
    await db.delete('recipe_cache');
  }
}
