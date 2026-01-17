import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/recipe_provider.dart';
import 'package:app_code/screens/lists/add_recipe.dart';
import 'package:app_code/widgets/app_snackbar.dart';

/// Global widget that listens for recipe search completions and shows notifications
class RecipeNotificationListener extends ConsumerStatefulWidget {
  final Widget child;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final GlobalKey<NavigatorState> navigatorKey;

  const RecipeNotificationListener({
    super.key,
    required this.child,
    required this.scaffoldMessengerKey,
    required this.navigatorKey,
  });

  @override
  ConsumerState<RecipeNotificationListener> createState() =>
      _RecipeNotificationListenerState();
}

class _RecipeNotificationListenerState
    extends ConsumerState<RecipeNotificationListener> {
  final Set<String> _notifiedListIds = {};

  @override
  Widget build(BuildContext context) {
    // Listen to recipe search changes
    ref.listen<Map<String, BackgroundRecipeSearch>>(backgroundRecipeProvider, (
      _,
      searches,
    ) {

      for (final entry in searches.entries) {
        final listId = entry.key;
        final search = entry.value;

        // Reset notification flag when a new search starts (not completed)
        if (!search.isCompleted) {
          _notifiedListIds.remove(listId);
        }

        // Only show notification if completed and not already notified
        if (search.isCompleted &&
            !_notifiedListIds.contains(listId) &&
            !search.hasSeenNotification) {
          _showRecipeNotification(search);
        }
      }

      // Clean up notified IDs for lists that no longer exist
      _notifiedListIds.removeWhere((id) => !searches.containsKey(id));
    });

    return widget.child;
  }

  void _showRecipeNotification(BackgroundRecipeSearch search) {
    search.result.whenData((recipe) {
      if (!mounted) {
        return;
      }

      // Use WidgetsBinding to ensure we have a valid context
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // Use the global ScaffoldMessenger key
        final scaffoldMessenger = widget.scaffoldMessengerKey.currentState;
        if (scaffoldMessenger == null) return;

        final message = recipe.hasError
            ? 'Recipe search completed with issues'
            : 'Recipe "${recipe.recipeName}" found!';

        // Persist that we have shown the notification
        // Mark as seen BEFORE showing to handle app closure during display
        ref.read(backgroundRecipeProvider.notifier).markNotificationSeen(search.listId);

        scaffoldMessenger.showSnackBar(
          buildAppSnackBar(
            message: message,
            isError: recipe.hasError,
            onTap: () {
              scaffoldMessenger.hideCurrentSnackBar();
              _navigateToRecipeScreen(search);
            },
          ),
        );
      });
    });
  }

  void _navigateToRecipeScreen(BackgroundRecipeSearch search) {
    if (!mounted) return;

    // Check if we have the necessary data to navigate
    if (search.shoppingList == null || search.availableCategories == null) {
      return;
    }

    final navigator = widget.navigatorKey.currentState;
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
