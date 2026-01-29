import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/recipe_provider.dart';
import 'package:app_code/providers/real_app_providers/global_keys_provider.dart';
import 'package:app_code/services/recipe_notification_service.dart';

/// Service provider that handles recipe search side effects
/// This provider initializes the RecipeNotificationService and sets up listeners
/// Returns void to indicate this is a pure side-effect provider
final recipeNotificationServiceProvider = Provider<void>((ref) {
  final navigatorKey = ref.read(navigatorKeyProvider);
  final scaffoldMessengerKey = ref.read(scaffoldMessengerKeyProvider);
  final backgroundNotifier = ref.read(backgroundRecipeProvider.notifier);

  // Create the notification service
  final service = RecipeNotificationService(
    navigatorKey: navigatorKey,
    scaffoldMessengerKey: scaffoldMessengerKey,
    backgroundNotifier: backgroundNotifier,
  );

  // Set up listener for background recipe searches
  // This listener will NOT cause widget rebuilds
  ref.listen<Map<String, BackgroundRecipeSearch>>(
    backgroundRecipeProvider,
    (_, searches) {
      service.processBackgroundSearches(searches);
    },
  );
});
