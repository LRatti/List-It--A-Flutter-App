import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:app_code/models/recipe_response.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/repositories/abstract/gemini_repository.dart';
import 'package:app_code/repositories/real_app_repo/gemini_repository_real.dart';
import 'package:app_code/repositories/test_repo/gemini_repository_test.dart';
import 'package:app_code/repositories/abstract/recipe_cache_repository.dart';
import 'package:app_code/repositories/real_app_repo/recipe_cache_repository_real.dart';

/// Background recipe search state
class BackgroundRecipeSearch {
  final String listId;
  final String recipeName;
  final AsyncValue<RecipeData> result;
  final bool isCompleted;
  final ShoppingList? shoppingList;
  final List<Category>? availableCategories;

  BackgroundRecipeSearch({
    required this.listId,
    required this.recipeName,
    required this.result,
    required this.isCompleted,
    this.shoppingList,
    this.availableCategories,
  });

  BackgroundRecipeSearch copyWith({
    String? listId,
    String? recipeName,
    AsyncValue<RecipeData>? result,
    bool? isCompleted,
    ShoppingList? shoppingList,
    List<Category>? availableCategories,
  }) {
    return BackgroundRecipeSearch(
      listId: listId ?? this.listId,
      recipeName: recipeName ?? this.recipeName,
      result: result ?? this.result,
      isCompleted: isCompleted ?? this.isCompleted,
      shoppingList: shoppingList ?? this.shoppingList,
      availableCategories: availableCategories ?? this.availableCategories,
    );
  }
}

/// Provides the concrete Gemini repository implementation.
/// Using Provider is correct for dependency injection.
final geminiRepositoryProvider = Provider<GeminiRepository>((ref) {
  // Use test repository for mock data
  return GeminiRepositoryTest();
  // Use real repository for actual API calls
  // return GeminiRepositoryReal();
});

/// Provider for recipe cache repository
final recipeCacheRepositoryProvider = Provider<RecipeCacheRepository>((ref) {
  return RecipeCacheRepositoryReal();
});

/// State notifier for recipe queries.
/// We use AsyncValue<RecipeData> to handle loading, error, and data states elegantly.
class RecipeNotifier extends StateNotifier<AsyncValue<RecipeData>> {
  final GeminiRepository _geminiRepository;

  RecipeNotifier(this._geminiRepository)
    : super(AsyncValue.data(RecipeData.empty()));

  /// Queries Gemini for a recipe.
  Future<void> queryRecipe({
    required String recipeName,
    required List<Category> categories,
  }) async {
    // Set state to loading while waiting for the repository.
    state = const AsyncValue.loading();

    // AsyncValue.guard is a clean way to catch errors and wrap them in AsyncError.
    state = await AsyncValue.guard(() async {
      final response = await _geminiRepository.queryRecipe(
        recipeName: recipeName,
        categories: categories,
      );
      return response;
    });
  }

  /// Resets the state to an empty RecipeData object.
  void reset() {
    state = AsyncValue.data(RecipeData.empty());
  }
}

/// Provider for the recipe query state.
/// .autoDispose ensures the state is cleaned up when the UI stops listening.
final recipeProvider =
    StateNotifierProvider.autoDispose<RecipeNotifier, AsyncValue<RecipeData>>((
      ref,
    ) {
      final geminiRepository = ref.watch(geminiRepositoryProvider);
      return RecipeNotifier(geminiRepository);
    });

/// State notifier for background recipe searches
class BackgroundRecipeNotifier
    extends StateNotifier<Map<String, BackgroundRecipeSearch>> {
  final GeminiRepository _geminiRepository;
  final RecipeCacheRepository _cacheRepository;

  BackgroundRecipeNotifier(this._geminiRepository, this._cacheRepository)
    : super({});

  /// Load cached recipe search for a specific list
  Future<void> loadCachedSearch(String listId) async {
    final cachedData = await _cacheRepository.loadRecipeCache(listId);

    if (cachedData != null) {
      state = {
        ...state,
        listId: BackgroundRecipeSearch(
          listId: listId,
          recipeName: cachedData.recipeName,
          result: AsyncValue.data(cachedData.recipeData),
          isCompleted: true,
        ),
      };
    }
  }

  /// Start a background recipe search for a specific list
  Future<void> startBackgroundSearch({
    required String listId,
    required String recipeName,
    required List<Category> categories,
    ShoppingList? shoppingList,
  }) async {
    // Initialize the search state as loading
    state = {
      ...state,
      listId: BackgroundRecipeSearch(
        listId: listId,
        recipeName: recipeName,
        result: const AsyncValue.loading(),
        isCompleted: false,
        shoppingList: shoppingList,
        availableCategories: categories,
      ),
    };

    // Perform the search in background
    final result = await AsyncValue.guard(() async {
      final response = await _geminiRepository.queryRecipe(
        recipeName: recipeName,
        categories: categories,
      );
      return response;
    });

    // Check if the list still exists (wasn't deleted while searching)
    if (!state.containsKey(listId)) {
      // List was deleted, don't update state or cache
      return;
    }

    // Update state with result and mark as completed
    state = {
      ...state,
      listId: BackgroundRecipeSearch(
        listId: listId,
        recipeName: recipeName,
        result: result,
        isCompleted: true,
        shoppingList: shoppingList,
        availableCategories: categories,
      ),
    };

    // Save to cache
    result.whenData((recipeData) async {
      await _cacheRepository.saveRecipeCache(
        listId: listId,
        recipeName: recipeName,
        recipeData: recipeData,
      );
    });
  }

  /// Get the search result for a specific list
  BackgroundRecipeSearch? getSearchForList(String listId) {
    return state[listId];
  }

  /// Clear the search result for a specific list (also deletes from cache)
  Future<void> clearSearchForList(String listId) async {
    state = {...state}..remove(listId);
    await _cacheRepository.deleteRecipeCache(listId);
  }

  /// Cancel a search (e.g., when its list is deleted) and remove cache/notifications
  Future<void> cancelSearchForList(String listId) async {
    state = {...state}..remove(listId);
    await _cacheRepository.deleteRecipeCache(listId);
  }

  /// Clear all searches
  Future<void> clearAllSearches() async {
    state = {};
    await _cacheRepository.clearAllCaches();
  }
}

/// Provider for background recipe searches
final backgroundRecipeProvider =
    StateNotifierProvider<
      BackgroundRecipeNotifier,
      Map<String, BackgroundRecipeSearch>
    >((ref) {
      final geminiRepository = ref.watch(geminiRepositoryProvider);
      final cacheRepository = ref.watch(recipeCacheRepositoryProvider);
      return BackgroundRecipeNotifier(geminiRepository, cacheRepository);
    });
