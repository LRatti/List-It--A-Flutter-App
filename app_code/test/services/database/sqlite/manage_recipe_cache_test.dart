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

  // --- Load non-existent cache returns null ---
  test('returns null when loading non-existent recipe cache', () async {
    final cached = await ManageRecipeCache.loadRecipeCache('non_existent_list');
    expect(cached, isNull);
  });

  // --- Get creation date for non-existent cache ---
  test('returns null when getting creation date for non-existent cache', () async {
    final createdAt = await ManageRecipeCache.getCacheCreatedAt('non_existent_list');
    expect(createdAt, isNull);
  });

  // --- Save and verify all cached recipes are retrieved ---
  test('getAllCachedRecipes returns all saved recipes', () async {
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
    await ManageRecipeCache.saveRecipeCache(
      listId: 'list3',
      recipeName: 'Recipe 3',
      recipeData: recipeData,
    );

    final allRecipes = await ManageRecipeCache.getAllCachedRecipes();
    expect(allRecipes.length, 3);
    expect(allRecipes.map((r) => r.listId).toSet(), {'list1', 'list2', 'list3'});
  });

  // --- getAllCachedRecipes returns empty list when no caches ---
  test('getAllCachedRecipes returns empty list when no caches exist', () async {
    final allRecipes = await ManageRecipeCache.getAllCachedRecipes();
    expect(allRecipes, isEmpty);
  });

  // --- markNotificationSeen on non-existent cache ---
  test('markNotificationSeen on non-existent cache does not throw', () async {
    expect(
      () async => await ManageRecipeCache.markNotificationSeen('non_existent'),
      returnsNormally,
    );
  });

  // --- Delete cache that doesn't exist ---
  test('deleteRecipeCache on non-existent cache does not throw', () async {
    expect(
      () async => await ManageRecipeCache.deleteRecipeCache('non_existent'),
      returnsNormally,
    );
  });

  // --- Save multiple caches and check hasCachedRecipe ---
  test('hasCachedRecipe returns correct values for multiple caches', () async {
    final recipeData = RecipeData.empty();

    expect(await ManageRecipeCache.hasCachedRecipe('list1'), false);
    
    await ManageRecipeCache.saveRecipeCache(
      listId: 'list1',
      recipeName: 'Recipe 1',
      recipeData: recipeData,
    );
    
    expect(await ManageRecipeCache.hasCachedRecipe('list1'), true);
    expect(await ManageRecipeCache.hasCachedRecipe('list2'), false);
  });

  // --- Save cache with hasSeenNotification = true ---
  test('saves recipe cache with hasSeenNotification as true', () async {
    final recipeData = RecipeData.empty();

    await ManageRecipeCache.saveRecipeCache(
      listId: 'list1',
      recipeName: 'Test Recipe',
      recipeData: recipeData,
      hasSeenNotification: true,
    );

    final cached = await ManageRecipeCache.loadRecipeCache('list1');
    expect(cached!.hasSeenNotification, true);
  });

  

  // --- Save cache with complex recipe data ---
  test('saves and loads complex recipe data correctly', () async {
    final recipeData = RecipeData(
      products: [
        Product(name: 'Pasta'),
        Product(name: 'Tomato'),
        Product(name: 'Garlic'),
        Product(name: 'Olive Oil'),
      ],
      quantities: ['400g', '800g', '3 cloves', '50ml'],
      productCategories: ['Grains', 'Vegetables', 'Vegetables', 'Oils'],
      recipeName: 'Pasta Pomodoro',
      error: 'noError',
    );

    await ManageRecipeCache.saveRecipeCache(
      listId: 'list1',
      recipeName: 'Pasta Pomodoro',
      recipeData: recipeData,
    );

    final cached = await ManageRecipeCache.loadRecipeCache('list1');
    expect(cached!.recipeData.products.length, 4);
    expect(cached.recipeData.quantities.length, 4);
    expect(cached.recipeData.productCategories.length, 4);
  });

  // --- clearAllCaches when empty ---
  test('clearAllCaches works correctly when database is empty', () async {
    expect(
      () async => await ManageRecipeCache.clearAllCaches(),
      returnsNormally,
    );

    final allCached = await ManageRecipeCache.getAllCachedRecipes();
    expect(allCached, isEmpty);
  });

}
