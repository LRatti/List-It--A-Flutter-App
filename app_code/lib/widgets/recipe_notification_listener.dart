import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/recipe/recipe_provider.dart';
import 'package:app_code/screens/lists/add_recipe_screen_mobile.dart';
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
    ref.listen<Map<String, BackgroundRecipeSearch>>(
      backgroundRecipeProvider,
      (_, searches) {
        // Remove IDs for lists that no longer exist
        _notifiedListIds.removeWhere((id) => !searches.containsKey(id));

        for (final entry in searches.entries) {
          final listId = entry.key;
          final search = entry.value;

          // Reset notification flag if search is not completed
          if (!search.isCompleted) {
            _notifiedListIds.remove(listId);
          }

          // Show notification if search is completed, not yet notified, and not seen
          if (search.isCompleted &&
              !_notifiedListIds.contains(listId) &&
              !search.hasSeenNotification) {
            _showRecipeNotification(search);
          }
        }
      },
    );

    return widget.child;
  }

  void _showRecipeNotification(BackgroundRecipeSearch search) {
    search.result.whenData((recipe) {
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final scaffoldMessenger = widget.scaffoldMessengerKey.currentState;
        if (scaffoldMessenger == null) return;

        final message = recipe.hasError
            ? 'Recipe search completed with issues'
            : 'Recipe "${recipe.recipeName}" found!';

        // Mark as seen before showing to handle app closure during display
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

        // Track this list as notified
        _notifiedListIds.add(search.listId);
      });
    });
  }

  void _navigateToRecipeScreen(BackgroundRecipeSearch search) {
    if (!mounted) return;

    if (search.shoppingList == null || search.availableCategories == null) return;

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
