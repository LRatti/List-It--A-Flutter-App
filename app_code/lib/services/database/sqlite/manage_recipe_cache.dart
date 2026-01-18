import 'package:sqflite/sqflite.dart';
import 'package:app_code/models/recipe_response.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';

/// Manages recipe cache operations in SQLite database
class ManageRecipeCache {
  /// Saves a recipe cache for a shopping list
  static Future<void> saveRecipeCache({
    required String listId,
    required String recipeName,
    required RecipeData recipeData,
    bool hasSeenNotification = false,
  }) async {
    final db = await DatabaseHelper.database;

    // Delete any existing cache for this list first
    await deleteRecipeCache(listId);

    // Insert new cache
    await db.insert(
      'recipe_cache',
      {
        'list_id': listId,
        'recipe_name': recipeName,
        'recipe_data': recipeData.toJsonString(),
        'error_message': recipeData.hasError ? recipeData.error : null,
        'has_seen_notification': hasSeenNotification ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Loads a recipe cache for a shopping list
  static Future<({String recipeName, RecipeData recipeData, bool hasSeenNotification})?> loadRecipeCache(
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

  /// Deletes recipe cache for a specific shopping list
  static Future<void> deleteRecipeCache(String listId) async {
    final db = await DatabaseHelper.database;

    await db.delete(
      'recipe_cache',
      where: 'list_id = ?',
      whereArgs: [listId],
    );
  }

  /// Checks if a recipe cache exists for a shopping list
  static Future<bool> hasCachedRecipe(String listId) async {
    final db = await DatabaseHelper.database;

    final results = await db.query(
      'recipe_cache',
      where: 'list_id = ?',
      whereArgs: [listId],
      columns: ['list_id'],
    );

    return results.isNotEmpty;
  }

  /// Marks a recipe notification as seen
  static Future<void> markNotificationSeen(String listId) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'recipe_cache',
      {'has_seen_notification': 1},
      where: 'list_id = ?',
      whereArgs: [listId],
    );
  }

  /// Clears all recipe caches from the database
  static Future<void> clearAllCaches() async {
    final db = await DatabaseHelper.database;
    await db.delete('recipe_cache');
  }

  /// Gets the creation date of a recipe cache
  static Future<DateTime?> getCacheCreatedAt(String listId) async {
    final db = await DatabaseHelper.database;

    final results = await db.query(
      'recipe_cache',
      where: 'list_id = ?',
      whereArgs: [listId],
      columns: ['created_at'],
    );

    if (results.isEmpty) return null;

    final createdAt = results.first['created_at'] as String?;
    return createdAt != null ? DateTime.parse(createdAt) : null;
  }

  /// Gets all cached recipes
  static Future<List<({String listId, String recipeName, DateTime createdAt})>> getAllCachedRecipes() async {
    final db = await DatabaseHelper.database;

    final results = await db.query('recipe_cache');

    return results
        .map((row) => (
              listId: row['list_id'] as String,
              recipeName: row['recipe_name'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
            ))
        .toList();
  }

  /// Deletes recipe caches older than a specific number of days
  static Future<int> deleteCachesOlderThan(int days) async {
    final db = await DatabaseHelper.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: days)).toIso8601String();

    return db.delete(
      'recipe_cache',
      where: 'created_at < ?',
      whereArgs: [cutoffDate],
    );
  }
}
