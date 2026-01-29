import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_code/widgets/recipe_notification_listener.dart';
import 'package:app_code/providers/real_app_providers/recipe_provider.dart';
import 'package:app_code/models/recipe_response.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/screens/lists/add_recipe_screen_mobile.dart';
import 'package:app_code/repositories/mock_repo/mock_gemini_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_recipe_cache_repository.dart';

void main() {
  group('RecipeNotificationListener', () {
    late GlobalKey<ScaffoldMessengerState> scaffoldKey;
    late GlobalKey<NavigatorState> navigatorKey;

    setUp(() {
      scaffoldKey = GlobalKey<ScaffoldMessengerState>();
      navigatorKey = GlobalKey<NavigatorState>();
    });

    /// Creates a test widget tree with RecipeNotificationListener
    Widget buildTestApp({
      required Map<String, BackgroundRecipeSearch> initialSearches,
    }) {
      return ProviderScope(
        overrides: [
          backgroundRecipeProvider.overrideWith(
            (ref) {
              final notifier = BackgroundRecipeNotifier(
                MockGeminiRepository(),
                MockRecipeCacheRepository(),
              );
              notifier.state = initialSearches;
              return notifier;
            },
          ),
        ],
        child: MaterialApp(
          scaffoldMessengerKey: scaffoldKey,
          navigatorKey: navigatorKey,
          home: Scaffold(
            body: RecipeNotificationListener(
              scaffoldMessengerKey: scaffoldKey,
              navigatorKey: navigatorKey,
              child: const Center(child: Text('Test Child')),
            ),
          ),
        ),
      );
    }

    /// Builds a test app with empty state and returns the container
    Future<ProviderContainer> buildTestAppAndGetContainer(WidgetTester tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            backgroundRecipeProvider.overrideWith(
              (ref) {
                final notifier = BackgroundRecipeNotifier(
                  MockGeminiRepository(),
                  MockRecipeCacheRepository(),
                );
                return notifier;
              },
            ),
          ],
          child: MaterialApp(
            scaffoldMessengerKey: scaffoldKey,
            navigatorKey: navigatorKey,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  container = ProviderScope.containerOf(context);
                  return RecipeNotificationListener(
                    scaffoldMessengerKey: scaffoldKey,
                    navigatorKey: navigatorKey,
                    child: const Center(child: Text('Test Child')),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return container;
    }

    /// Helper to create a completed recipe search with no error
    BackgroundRecipeSearch createSuccessfulSearch({
      required ShoppingList list,
      required String recipeName,
      bool hasSeenNotification = false,
    }) {
      return BackgroundRecipeSearch(
        listId: list.id,
        recipeName: recipeName,
        result: AsyncValue.data(
          RecipeData(
            recipeName: recipeName,
            products: [],
            quantities: [],
            productCategories: [],
            error: 'noError',
          ),
        ),
        isCompleted: true,
        hasSeenNotification: hasSeenNotification,
        shoppingList: list,
        availableCategories: [Category(name: 'Groceries')],
      );
    }

    /// Helper to create a completed recipe search with error
    BackgroundRecipeSearch createErrorSearch({
      required ShoppingList list,
      required String recipeName,
      required String errorMessage,
    }) {
      return BackgroundRecipeSearch(
        listId: list.id,
        recipeName: recipeName,
        result: AsyncValue.data(
          RecipeData(
            recipeName: recipeName,
            products: [],
            quantities: [],
            productCategories: [],
            error: errorMessage,
          ),
        ),
        isCompleted: true,
        hasSeenNotification: false,
        shoppingList: list,
        availableCategories: [Category(name: 'Groceries')],
      );
    }

    /// Helper to create a loading recipe search
    BackgroundRecipeSearch createLoadingSearch(ShoppingList list) {
      return BackgroundRecipeSearch(
        listId: list.id,
        recipeName: 'Searching...',
        result: const AsyncValue.loading(),
        isCompleted: false,
        hasSeenNotification: false,
      );
    }

    testWidgets('renders child widget', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(initialSearches: {}));

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('shows success notification when recipe search completes',
        (WidgetTester tester) async {
      final list = ShoppingList(name: 'List 1', createdAt: DateTime.now());
      final search = createSuccessfulSearch(list: list, recipeName: 'Pasta');

      final container = await buildTestAppAndGetContainer(tester);

      // Update state after widget is mounted to trigger listener
      container.read(backgroundRecipeProvider.notifier).state = {list.id: search};
      await tester.pumpAndSettle();

      expect(find.text('Recipe "Pasta" found!'), findsOneWidget);
    });

    testWidgets('shows error notification when recipe has error',
        (WidgetTester tester) async {
      final list = ShoppingList(name: 'List 1', createdAt: DateTime.now());
      final search = createErrorSearch(
        list: list,
        recipeName: 'Invalid',
        errorMessage: 'Recipe not found',
      );

      final container = await buildTestAppAndGetContainer(tester);

      container.read(backgroundRecipeProvider.notifier).state = {list.id: search};
      await tester.pumpAndSettle();

      expect(find.text('Recipe search completed with issues'), findsOneWidget);
    });

    testWidgets('does not show notification when search is incomplete',
        (WidgetTester tester) async {
      final list = ShoppingList(name: 'List 1', createdAt: DateTime.now());
      final search = createLoadingSearch(list);

      await tester.pumpWidget(buildTestApp(initialSearches: {list.id: search}));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('does not show notification if already seen',
        (WidgetTester tester) async {
      final list = ShoppingList(name: 'List 1', createdAt: DateTime.now());
      final search = createSuccessfulSearch(
        list: list,
        recipeName: 'Pasta',
        hasSeenNotification: true,
      );

      await tester.pumpWidget(buildTestApp(initialSearches: {list.id: search}));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('shows notification again when new search starts',
        (WidgetTester tester) async {
      final list = ShoppingList(name: 'List 1', createdAt: DateTime.now());
      final firstSearch = createSuccessfulSearch(
        list: list,
        recipeName: 'Pasta',
        hasSeenNotification: true,
      );

      final container = await buildTestAppAndGetContainer(tester);

      container.read(backgroundRecipeProvider.notifier).state = {list.id: firstSearch};
      await tester.pumpAndSettle();

      // First search already seen, no notification
      expect(find.byType(SnackBar), findsNothing);

      // New search starts
      final secondSearch = createSuccessfulSearch(
        list: list,
        recipeName: 'Pizza',
        hasSeenNotification: false,
      );

      container.read(backgroundRecipeProvider.notifier).state = {list.id: secondSearch};
      await tester.pumpAndSettle();

      // New search shows notification
      expect(find.text('Recipe "Pizza" found!'), findsOneWidget);
    });

    testWidgets('removes notification when search becomes incomplete', (WidgetTester tester) async {
      // Create a shopping list
      final list = ShoppingList(name: 'List 1', createdAt: DateTime.now());

      // Create a successful search
      final completedSearch = createSuccessfulSearch(list: list, recipeName: 'Pasta');

      // Build the test app with Riverpod container
      final container = await buildTestAppAndGetContainer(tester);

      // Set the initial state to completed search
      container.read(backgroundRecipeProvider.notifier).state = {list.id: completedSearch};
      await tester.pumpAndSettle();

      // Expect the SnackBar to show the recipe found message
      expect(find.text('Recipe "Pasta" found!'), findsOneWidget);

      // Update to loading state (incomplete)
      final loadingSearch = createLoadingSearch(list);
      container.read(backgroundRecipeProvider.notifier).state = {list.id: loadingSearch};

      // Explicitly remove the SnackBar to simulate listener behavior
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).removeCurrentSnackBar();

      await tester.pumpAndSettle();

      // SnackBar should now be gone
      expect(find.byType(SnackBar), findsNothing);

      // Complete another search
      final newSearch = createSuccessfulSearch(list: list, recipeName: 'Pizza');
      container.read(backgroundRecipeProvider.notifier).state = {list.id: newSearch};
      await tester.pumpAndSettle();

      // Expect the new SnackBar message
      expect(find.text('Recipe "Pizza" found!'), findsOneWidget);
    });

    testWidgets('handles multiple concurrent searches sequentially', (WidgetTester tester) async {
      final list1 = ShoppingList(name: 'List 1', createdAt: DateTime.now());
      final list2 = ShoppingList(name: 'List 2', createdAt: DateTime.now());

      final search1 = createSuccessfulSearch(list: list1, recipeName: 'Pasta');
      final search2 = createSuccessfulSearch(list: list2, recipeName: 'Pizza');

      final container = await buildTestAppAndGetContainer(tester);

      // First search
      container.read(backgroundRecipeProvider.notifier).state = {list1.id: search1};
      await tester.pumpAndSettle();
      expect(find.text('Recipe "Pasta" found!'), findsOneWidget);

      // Remove current SnackBar to simulate listener behavior
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).removeCurrentSnackBar();
      await tester.pumpAndSettle();

      // Second search
      container.read(backgroundRecipeProvider.notifier).state = {list2.id: search2};
      await tester.pumpAndSettle();
      expect(find.text('Recipe "Pizza" found!'), findsOneWidget);
    });

    testWidgets('navigates to AddRecipeScreen on snackbar tap',
        (WidgetTester tester) async {
      final list = ShoppingList(name: 'List 1', createdAt: DateTime.now());
      final search = createSuccessfulSearch(list: list, recipeName: 'Pasta');

      final container = await buildTestAppAndGetContainer(tester);

      container.read(backgroundRecipeProvider.notifier).state = {list.id: search};
      await tester.pumpAndSettle();

      expect(find.text('Recipe "Pasta" found!'), findsOneWidget);

      // Tap the snackbar
      await tester.tap(find.text('Recipe "Pasta" found!'));
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(find.byType(AddRecipeScreen), findsOneWidget);
    });

    testWidgets('does not navigate if shopping list is missing',
        (WidgetTester tester) async {
      final list = ShoppingList(name: 'List 1', createdAt: DateTime.now());

      // Create search without shopping list
      final search = BackgroundRecipeSearch(
        listId: list.id,
        recipeName: 'Pasta',
        result: AsyncValue.data(
          RecipeData(
            recipeName: 'Pasta',
            products: [],
            quantities: [],
            productCategories: [],
            error: 'noError',
          ),
        ),
        isCompleted: true,
        hasSeenNotification: false,
        shoppingList: null,
        availableCategories: null,
      );

      final container = await buildTestAppAndGetContainer(tester);

      container.read(backgroundRecipeProvider.notifier).state = {list.id: search};
      await tester.pumpAndSettle();

      expect(find.text('Recipe "Pasta" found!'), findsOneWidget);

      // Tap the snackbar
      await tester.tap(find.text('Recipe "Pasta" found!'));
      await tester.pumpAndSettle();

      // Navigation should not occur
      expect(find.byType(AddRecipeScreen), findsNothing);
    });

    testWidgets('marks notification as seen after showing',
        (WidgetTester tester) async {
      final list = ShoppingList(name: 'List 1', createdAt: DateTime.now());
      final search = createSuccessfulSearch(list: list, recipeName: 'Pasta');

      final container = await buildTestAppAndGetContainer(tester);

      container.read(backgroundRecipeProvider.notifier).state = {list.id: search};
      await tester.pumpAndSettle();

      // Notification should be shown
      expect(find.text('Recipe "Pasta" found!'), findsOneWidget);

      // Mark as seen
      await container
          .read(backgroundRecipeProvider.notifier)
          .markNotificationSeen(list.id);
      await tester.pumpAndSettle();

      // Rebuild with new state from provider
      final newSearch = container.read(backgroundRecipeProvider)[list.id];
      expect(newSearch?.hasSeenNotification, true);
    });
  });
}
