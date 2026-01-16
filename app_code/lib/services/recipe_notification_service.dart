import 'package:flutter/material.dart';
import 'package:app_code/providers/real_app_providers/recipe_provider.dart';
import 'package:app_code/screens/lists/add_recipe.dart';
import 'package:app_code/widgets/app_snackbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service class dedicated to handling recipe search side effects
/// Responsible for showing notifications and navigation when recipes are found
class RecipeNotificationService {
  final GlobalKey<NavigatorState> _navigatorKey;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;
  final Set<String> _notifiedListIds = {};

  RecipeNotificationService({
    required GlobalKey<NavigatorState> navigatorKey,
    required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  })  : _navigatorKey = navigatorKey,
        _scaffoldMessengerKey = scaffoldMessengerKey;

  /// Process background recipe searches and show notifications
  void processBackgroundSearches(
    Map<String, BackgroundRecipeSearch> searches,
  ) {
    for (final entry in searches.entries) {
      final listId = entry.key;
      final search = entry.value;

      // Reset notification flag when a search starts (not completed)
      if (!search.isCompleted) {
        _notifiedListIds.remove(listId);
        continue;
      }

      // Show notification only once per completed search
      if (search.isCompleted && !_notifiedListIds.contains(listId)) {
        _notifiedListIds.add(listId);
        _handleRecipeSearchCompletion(search);
      }
    }

    // Clean up notified IDs for lists that no longer exist
    _notifiedListIds.removeWhere((id) => !searches.containsKey(id));
  }

  /// Handles recipe search completion - shows SnackBar and optionally navigates
  void _handleRecipeSearchCompletion(BackgroundRecipeSearch search) {
    search.result.whenData((recipe) {
      final scaffoldMessenger = _scaffoldMessengerKey.currentState;
      if (scaffoldMessenger == null) return;

      final isError = recipe.hasError;
      final message = isError
          ? 'Recipe search completed with issues'
          : 'Recipe "${recipe.recipeName}" found!';

      scaffoldMessenger.showSnackBar(
        buildAppSnackBar(
          message: message,
          isError: isError,
          onTap: () {
            scaffoldMessenger.hideCurrentSnackBar();
            _navigateToRecipeScreen(search);
          },
        ),
      );
    });
  }

  /// Navigates to AddRecipeScreen with recipe data
  void _navigateToRecipeScreen(BackgroundRecipeSearch search) {
    if (search.shoppingList == null || search.availableCategories == null) {
      return;
    }

    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => AddRecipeScreen(
          shoppingList: search.shoppingList!,
          availableCategories: search.availableCategories!,
        ),
      ),
    );
  }
}
