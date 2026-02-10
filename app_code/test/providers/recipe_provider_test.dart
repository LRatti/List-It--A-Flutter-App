import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_code/models/category.dart';
import 'package:app_code/models/recipe_response.dart';
import 'package:app_code/models/shopping_list.dart';

import 'package:app_code/providers/real_app_providers/recipe/recipe_provider.dart';
import 'package:app_code/repositories/mock_repo/mock_gemini_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_recipe_cache_repository.dart';

/// Spy implementation to track cache side effects
class RecipeCacheRepositorySpy extends MockRecipeCacheRepository {
  int saveCalls = 0;
  int deleteCalls = 0;
  int clearCalls = 0;

  @override
  Future<void> saveRecipeCache({
    required String listId,
    required String recipeName,
    required RecipeData recipeData,
    bool hasSeenNotification = false,
  }) async {
    saveCalls++;
    await super.saveRecipeCache(
      listId: listId,
      recipeName: recipeName,
      recipeData: recipeData,
      hasSeenNotification: hasSeenNotification,
    );
  }

  @override
  Future<void> deleteRecipeCache(String listId) async {
    deleteCalls++;
    await super.deleteRecipeCache(listId);
  }

  @override
  Future<void> clearAllCaches() async {
    clearCalls++;
    await super.clearAllCaches();
  }
}

void main() {
  group('RecipeNotifier', () {
    test('initial state is empty RecipeData', () {
      final container = ProviderContainer(
        overrides: [
          geminiRepositoryProvider
              .overrideWithValue(MockGeminiRepository()),
        ],
      );

      final state = container.read(recipeProvider);

      expect(
        state.maybeWhen(
          data: (data) => data.products.isEmpty,
          orElse: () => false,
        ),
        isTrue,
      );
    });

    test('reset sets state back to empty RecipeData', () {
      final container = ProviderContainer(
        overrides: [
          geminiRepositoryProvider
              .overrideWithValue(MockGeminiRepository()),
        ],
      );

      final notifier = container.read(recipeProvider.notifier);

      notifier.reset();

      final state = container.read(recipeProvider);

      expect(
        state.maybeWhen(
          data: (data) => data.products.isEmpty,
          orElse: () => false,
        ),
        isTrue,
      );
    });
  });

  group('BackgroundRecipeNotifier', () {
    test('initial state is empty', () {
      final container = ProviderContainer(
        overrides: [
          geminiRepositoryProvider
              .overrideWithValue(MockGeminiRepository()),
        ],
      );

      final state = container.read(backgroundRecipeProvider);

      expect(state, isEmpty);
    });

    test('getSearchForList returns null for unknown list', () {
      final container = ProviderContainer(
        overrides: [
          geminiRepositoryProvider
              .overrideWithValue(MockGeminiRepository()),
        ],
      );

      final notifier = container.read(backgroundRecipeProvider.notifier);

      expect(notifier.getSearchForList('missing-list'), isNull);
    });

    test('loadCachedSearch loads cached data into state', () async {
      final cacheRepo = MockRecipeCacheRepository();

      final container = ProviderContainer(
        overrides: [
          geminiRepositoryProvider
              .overrideWithValue(MockGeminiRepository()),
          recipeCacheRepositoryProvider.overrideWithValue(cacheRepo),
        ],
      );

      final recipeData = RecipeData.empty();

      await cacheRepo.saveRecipeCache(
        listId: 'list-1',
        recipeName: 'Tiramisu',
        recipeData: recipeData,
        hasSeenNotification: false,
      );

      final notifier = container.read(backgroundRecipeProvider.notifier);

      await notifier.loadCachedSearch('list-1');

      final result = notifier.getSearchForList('list-1');

      expect(result, isNotNull);
      expect(result!.recipeName, 'Tiramisu');
      expect(result.isCompleted, isTrue);
      expect(result.hasSeenNotification, isFalse);
    });

    test('startBackgroundSearch updates state and saves cache', () async {
      final cacheRepo = RecipeCacheRepositorySpy();

      final container = ProviderContainer(
        overrides: [
          geminiRepositoryProvider
              .overrideWithValue(MockGeminiRepository()),
          recipeCacheRepositoryProvider.overrideWithValue(cacheRepo),
        ],
      );

      final notifier = container.read(backgroundRecipeProvider.notifier);

      await notifier.startBackgroundSearch(
        listId: 'list-2',
        recipeName: 'Lasagna',
        categories: [],
      );

      final result = notifier.getSearchForList('list-2');

      expect(result, isNotNull);
      expect(result!.isCompleted, isTrue);
      expect(result.result.hasValue, isTrue);
      expect(cacheRepo.saveCalls, 1);
    });

    test('clearSearchForList removes state and deletes cache', () async {
      final cacheRepo = RecipeCacheRepositorySpy();

      final container = ProviderContainer(
        overrides: [
          geminiRepositoryProvider
              .overrideWithValue(MockGeminiRepository()),
          recipeCacheRepositoryProvider.overrideWithValue(cacheRepo),
        ],
      );

      final notifier = container.read(backgroundRecipeProvider.notifier);

      notifier.state = {
        'list-3': BackgroundRecipeSearch(
          listId: 'list-3',
          recipeName: 'Pizza',
          result: AsyncValue.data(RecipeData.empty()),
          isCompleted: true,
        ),
      };

      await notifier.clearSearchForList('list-3');

      expect(notifier.getSearchForList('list-3'), isNull);
      expect(cacheRepo.deleteCalls, 1);
    });

    test('markNotificationSeen updates state only', () async {
      final container = ProviderContainer(
        overrides: [
          geminiRepositoryProvider
              .overrideWithValue(MockGeminiRepository()),
        ],
      );

      final notifier = container.read(backgroundRecipeProvider.notifier);

      notifier.state = {
        'list-4': BackgroundRecipeSearch(
          listId: 'list-4',
          recipeName: 'Risotto',
          result: AsyncValue.data(RecipeData.empty()),
          isCompleted: true,
          hasSeenNotification: false,
        ),
      };

      await notifier.markNotificationSeen('list-4');

      final result = notifier.getSearchForList('list-4');

      expect(result!.hasSeenNotification, isTrue);
    });

    test('cancelSearchForList removes state and deletes cache', () async {
      final cacheRepo = RecipeCacheRepositorySpy();

      final container = ProviderContainer(
        overrides: [
          geminiRepositoryProvider
              .overrideWithValue(MockGeminiRepository()),
          recipeCacheRepositoryProvider.overrideWithValue(cacheRepo),
        ],
      );

      final notifier = container.read(backgroundRecipeProvider.notifier);

      notifier.state = {
        'list-5': BackgroundRecipeSearch(
          listId: 'list-5',
          recipeName: 'Gnocchi',
          result: AsyncValue.data(RecipeData.empty()),
          isCompleted: true,
        ),
      };

      await notifier.cancelSearchForList('list-5');

      expect(notifier.getSearchForList('list-5'), isNull);
      expect(cacheRepo.deleteCalls, 1);
    });

    test('clearAllSearches clears state and cache', () async {
      final cacheRepo = RecipeCacheRepositorySpy();

      final container = ProviderContainer(
        overrides: [
          geminiRepositoryProvider
              .overrideWithValue(MockGeminiRepository()),
          recipeCacheRepositoryProvider.overrideWithValue(cacheRepo),
        ],
      );

      final notifier = container.read(backgroundRecipeProvider.notifier);

      notifier.state = {
        'a': BackgroundRecipeSearch(
          listId: 'a',
          recipeName: 'Pasta',
          result: AsyncValue.data(RecipeData.empty()),
          isCompleted: true,
        ),
        'b': BackgroundRecipeSearch(
          listId: 'b',
          recipeName: 'Burger',
          result: AsyncValue.data(RecipeData.empty()),
          isCompleted: true,
        ),
      };

      await notifier.clearAllSearches();

      expect(container.read(backgroundRecipeProvider), isEmpty);
      expect(cacheRepo.clearCalls, 1);
    });
  });
}
