import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_code/services/recipe_notification_service.dart';
import 'package:app_code/providers/real_app_providers/recipe_provider.dart';
import 'package:app_code/models/recipe_response.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/repositories/mock_repo/mock_gemini_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_recipe_cache_repository.dart';

/// Test spy implementation of [BackgroundRecipeNotifier].
///
/// This class is used in tests to observe side effects triggered by
/// [RecipeNotificationService] without relying on real persistence or I/O.
///
/// In particular, it tracks how many times `markNotificationSeen` is called,
/// allowing tests to verify that notifications are marked as seen
/// exactly when expected.
class BackgroundNotifierSpy extends BackgroundRecipeNotifier {
  /// Counts how many times [markNotificationSeen] is invoked.
  int markSeenCalls = 0;

  /// Creates a spy notifier using test repositories.
  ///
  /// Real implementations are replaced with in-memory test versions
  /// to avoid database access or external API calls during tests.
  BackgroundNotifierSpy()
      : super(
          MockGeminiRepository(),
          MockRecipeCacheRepository(),
        );

  /// Overrides the real persistence behavior.
  ///
  /// Instead of saving state, this method only increments [markSeenCalls]
  /// so tests can assert that the notification was marked as seen.
  @override
  Future<void> markNotificationSeen(String listId) async {
    markSeenCalls++;
  }
}

void main() {
  group('RecipeNotificationService', () {
    late GlobalKey<NavigatorState> navigatorKey;
    late GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
    late BackgroundNotifierSpy notifier;

    setUp(() {
      navigatorKey = GlobalKey<NavigatorState>();
      scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
      notifier = BackgroundNotifierSpy();
    });

    Widget buildHost() {
      return ProviderScope(
        overrides: [
          recipeCacheRepositoryProvider
              .overrideWithValue(MockRecipeCacheRepository()),
          geminiRepositoryProvider
              .overrideWithValue(MockGeminiRepository()),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: scaffoldMessengerKey,
          home: const Scaffold(),
        ),
      );
    }

    testWidgets('shows success SnackBar and marks notification as seen',
        (tester) async {
      await tester.pumpWidget(buildHost());

      final service = RecipeNotificationService(
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        backgroundNotifier: notifier,
      );

      final listId = 'list-1';
      final recipe = RecipeData(
        products: const [],
        quantities: const [],
        productCategories: const [],
        recipeName: 'Pasta',
        error: 'noError',
      );

      final search = BackgroundRecipeSearch(
        listId: listId,
        recipeName: recipe.recipeName,
        result: AsyncValue.data(recipe),
        isCompleted: true,
        hasSeenNotification: false,
        shoppingList: ShoppingList(
          id: listId,
          name: 'List',
          createdAt: DateTime.now(),
        ),
        availableCategories: [Category(name: 'Veg')],
      );

      service.processBackgroundSearches({listId: search});
      await tester.pump();

      expect(find.text('Recipe "Pasta" found!'), findsOneWidget);
      expect(notifier.markSeenCalls, 1);
    });

    testWidgets('shows error SnackBar and marks notification as seen',
        (tester) async {
      await tester.pumpWidget(buildHost());

      final service = RecipeNotificationService(
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        backgroundNotifier: notifier,
      );

      final listId = 'list-2';
      final recipe = RecipeData.error('bad');

      final search = BackgroundRecipeSearch(
        listId: listId,
        recipeName: 'Err',
        result: AsyncValue.data(recipe),
        isCompleted: true,
        hasSeenNotification: false,
      );

      service.processBackgroundSearches({listId: search});
      await tester.pump();

      expect(
        find.text('Recipe search completed with issues'),
        findsOneWidget,
      );
      expect(notifier.markSeenCalls, 1);
    });

    testWidgets('does not notify when search is not completed',
        (tester) async {
      await tester.pumpWidget(buildHost());

      final service = RecipeNotificationService(
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        backgroundNotifier: notifier,
      );

      final search = BackgroundRecipeSearch(
        listId: 'list-3',
        recipeName: 'X',
        result: const AsyncValue.loading(),
        isCompleted: false,
        hasSeenNotification: false,
      );

      service.processBackgroundSearches({'list-3': search});
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
      expect(notifier.markSeenCalls, 0);
    });

    testWidgets('does not notify when notification was already seen',
        (tester) async {
      await tester.pumpWidget(buildHost());

      final service = RecipeNotificationService(
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        backgroundNotifier: notifier,
      );

      final recipe = RecipeData(
        products: const [],
        quantities: const [],
        productCategories: const [],
        recipeName: 'Pizza',
        error: 'noError',
      );

      final search = BackgroundRecipeSearch(
        listId: 'list-4',
        recipeName: recipe.recipeName,
        result: AsyncValue.data(recipe),
        isCompleted: true,
        hasSeenNotification: true,
      );

      service.processBackgroundSearches({'list-4': search});
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
      expect(notifier.markSeenCalls, 0);
    });

    testWidgets(
        'cleanup allows notification again when list is removed and re-added',
        (tester) async {
      await tester.pumpWidget(buildHost());

      final service = RecipeNotificationService(
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        backgroundNotifier: notifier,
      );

      final recipe = RecipeData(
        products: const [],
        quantities: const [],
        productCategories: const [],
        recipeName: 'Soup',
        error: 'noError',
      );

      final search = BackgroundRecipeSearch(
        listId: 'list-5',
        recipeName: recipe.recipeName,
        result: AsyncValue.data(recipe),
        isCompleted: true,
        hasSeenNotification: false,
      );

      service.processBackgroundSearches({'list-5': search});
      await tester.pump();
      expect(notifier.markSeenCalls, 1);

      service.processBackgroundSearches({});
      await tester.pump();

      service.processBackgroundSearches({'list-5': search});
      await tester.pump();
      expect(notifier.markSeenCalls, 2);
    });
  });
}
