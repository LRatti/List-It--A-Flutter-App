import 'package:app_code/models/product.dart';
import 'package:app_code/models/recipe_response.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_recipe_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await getDatabasesPath();
    await deleteDatabase('$dbPath/shopping_app.db');
  });

  setUp(() async {
    // Clear recipe cache table before each test
    final db = await DatabaseHelper.database;
    await db.delete('recipe_cache');
  });

  // --- Save and load a recipe cache ---
  test('saves and loads recipe cache correctly', () async {
    final db = await DatabaseHelper.database;

    final recipeData = RecipeData(
      products: [Product(name: 'Tomato'), Product(name: 'Pasta')],
      quantities: ['500g', '400g'],
      productCategories: ['Vegetables', 'Grains'],
      recipeName: 'Pasta Sauce',
      error: 'noError',
    );

    await ManageRecipeCache.saveRecipeCache(
      listId: 'list1',
      recipeName: 'Pasta Sauce',
      recipeData: recipeData,
      hasSeenNotification: false,
    );

    final cached = await ManageRecipeCache.loadRecipeCache('list1');
    expect(cached, isNotNull);
    expect(cached!.recipeName, 'Pasta Sauce');
    expect(cached.recipeData.products.length, 2);
    expect(cached.recipeData.quantities, ['500g', '400g']);
    expect(cached.hasSeenNotification, false);
  });

  // --- Save cache with error ---
  test('saves recipe cache with error information', () async {
    final recipeData = RecipeData.error('Failed to fetch recipe');

    await ManageRecipeCache.saveRecipeCache(
      listId: 'list1',
      recipeName: 'Failed Recipe',
      recipeData: recipeData,
    );

    final cached = await ManageRecipeCache.loadRecipeCache('list1');
    expect(cached, isNotNull);
    expect(cached!.recipeData.hasError, true);
    expect(cached.recipeData.error, 'Failed to fetch recipe');
  });

  // --- Delete recipe cache ---
  test('deletes recipe cache successfully', () async {
    final recipeData = RecipeData.empty();
    await ManageRecipeCache.saveRecipeCache(
      listId: 'list1',
      recipeName: 'Test Recipe',
      recipeData: recipeData,
    );

    await ManageRecipeCache.deleteRecipeCache('list1');

    final cached = await ManageRecipeCache.loadRecipeCache('list1');
    expect(cached, isNull);
  });

  // --- Check if cache exists ---
  test('checks existence of recipe cache', () async {
    final existsBefore = await ManageRecipeCache.hasCachedRecipe('list1');
    expect(existsBefore, false);

    final recipeData = RecipeData.empty();
    await ManageRecipeCache.saveRecipeCache(
      listId: 'list1',
      recipeName: 'Test Recipe',
      recipeData: recipeData,
    );

    final existsAfter = await ManageRecipeCache.hasCachedRecipe('list1');
    expect(existsAfter, true);
  });

  // --- Mark notification as seen ---
  test('marks recipe notification as seen', () async {
    final recipeData = RecipeData.empty();
    await ManageRecipeCache.saveRecipeCache(
      listId: 'list1',
      recipeName: 'Test Recipe',
      recipeData: recipeData,
      hasSeenNotification: false,
    );

    var cached = await ManageRecipeCache.loadRecipeCache('list1');
    expect(cached!.hasSeenNotification, false);

    await ManageRecipeCache.markNotificationSeen('list1');

    cached = await ManageRecipeCache.loadRecipeCache('list1');
    expect(cached!.hasSeenNotification, true);
  });

  // --- Clear all caches ---
  test('clears all recipe caches', () async {
    final recipeData = RecipeData.empty();

    await ManageRecipeCache.saveRecipeCache(
      listId: 'list1',
      recipeName: 'Recipe 1',
      recipeData: recipeData,
    );
    await ManageRecipeCache.saveRecipeCache(
      listId: 'list2',
      recipeName: 'Recipe 2',
      recipeData: recipeData,
    );

    var allCached = await ManageRecipeCache.getAllCachedRecipes();
    expect(allCached.length, 2);

    await ManageRecipeCache.clearAllCaches();

    allCached = await ManageRecipeCache.getAllCachedRecipes();
    expect(allCached, isEmpty);
  });

  // --- Get cache creation date ---
  test('retrieves cache creation date correctly', () async {
    final recipeData = RecipeData.empty();
    final beforeSave = DateTime.now();

    await ManageRecipeCache.saveRecipeCache(
      listId: 'list1',
      recipeName: 'Test Recipe',
      recipeData: recipeData,
    );

    final afterSave = DateTime.now();
    final createdAt = await ManageRecipeCache.getCacheCreatedAt('list1');

    expect(createdAt, isNotNull);
    expect(createdAt!.isAfter(beforeSave) || createdAt.isAtSameMomentAs(beforeSave), true);
    expect(createdAt.isBefore(afterSave.add(const Duration(seconds: 1))), true);
  });

  // --- Delete old caches ---
  test('deletes caches older than specified days', () async {
    final recipeData = RecipeData.empty();

    // Insert current cache
    await ManageRecipeCache.saveRecipeCache(
      listId: 'list1',
      recipeName: 'Recent Recipe',
      recipeData: recipeData,
    );

    // Insert old cache manually
    final db = await DatabaseHelper.database;
    final oldDate = DateTime.now().subtract(const Duration(days: 10)).toIso8601String();
    await db.insert('recipe_cache', {
      'list_id': 'list2',
      'recipe_name': 'Old Recipe',
      'recipe_data': recipeData.toJsonString(),
      'error_message': null,
      'has_seen_notification': 0,
      'created_at': oldDate,
    });

    final deletedCount = await ManageRecipeCache.deleteCachesOlderThan(5);
    expect(deletedCount, 1);

    final allCached = await ManageRecipeCache.getAllCachedRecipes();
    expect(allCached.length, 1);
    expect(allCached.first.listId, 'list1');
  });

  // --- Overwrite existing cache ---
  test('overwrites existing cache when saving with the same list id', () async {
    final recipeData1 = RecipeData(
      products: [Product(name: 'Tomato')],
      quantities: ['500g'],
      productCategories: ['Vegetables'],
      recipeName: 'Pasta 1',
      error: 'noError',
    );
    final recipeData2 = RecipeData(
      products: [Product(name: 'Chicken')],
      quantities: ['800g'],
      productCategories: ['Meat'],
      recipeName: 'Chicken 2',
      error: 'noError',
    );

    await ManageRecipeCache.saveRecipeCache(
      listId: 'list1',
      recipeName: 'Recipe 1',
      recipeData: recipeData1,
    );

    var cached = await ManageRecipeCache.loadRecipeCache('list1');
    expect(cached!.recipeName, 'Recipe 1');
    expect(cached.recipeData.products.first.getName(), 'Tomato');

    await ManageRecipeCache.saveRecipeCache(
      listId: 'list1',
      recipeName: 'Recipe 2',
      recipeData: recipeData2,
    );

    cached = await ManageRecipeCache.loadRecipeCache('list1');
    expect(cached!.recipeName, 'Recipe 2');
    expect(cached.recipeData.products.first.getName(), 'Chicken');
  });
}
