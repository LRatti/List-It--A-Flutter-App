import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:app_code/models/recipe_response.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/repositories/abstract/gemini_repository.dart';
import 'package:app_code/repositories/real_app_repo/gemini_repository_real.dart';

/// Provides the concrete Gemini repository implementation.
/// Using Provider is correct for dependency injection.
final geminiRepositoryProvider = Provider<GeminiRepository>((ref) {
  return GeminiRepositoryReal();
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
    StateNotifierProvider.autoDispose<RecipeNotifier, AsyncValue<RecipeData>>(
  (ref) {
    final geminiRepository = ref.watch(geminiRepositoryProvider);
    return RecipeNotifier(geminiRepository);
  },
);