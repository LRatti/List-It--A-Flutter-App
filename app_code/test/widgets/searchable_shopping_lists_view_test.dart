import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/widgets/searchable_shopping_lists_view.dart';
import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/real_app_providers/navigation_provider.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/repositories/mock_repo/mock_shopping_list_repository.dart';
import 'package:app_code/providers/real_app_providers/recipe/recipe_provider.dart';
import 'package:app_code/repositories/mock_repo/mock_recipe_cache_repository.dart';

void main() {
  group('SearchableShoppingListsView', () {
    late List<ShoppingList> testLists;
    ShoppingList? capturedList;
    late int tapCount;

    setUp(() {
      testLists = [
        ShoppingList(id: '1', name: 'Grocery Shopping', createdAt: DateTime(2024, 1, 1)),
        ShoppingList(id: '2', name: 'Weekly Essentials', createdAt: DateTime(2024, 1, 1)),
        ShoppingList(id: '3', name: 'Party Supplies', createdAt: DateTime(2024, 1, 1)),
      ];
      tapCount = 0;
      capturedList = null;
    });

    // Helper to pump the widget with ProviderScope
    Future<void> pumpSearchableView(
      WidgetTester tester, {
      List<ShoppingList>? lists,
      String? emptyMessage,
      void Function(BuildContext, ShoppingList)? onListTap,
      Widget? floatingActionButton,
      bool showRegistered = false,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Mock repositories to avoid database dependencies
            shoppingListRepositoryProvider.overrideWithValue(MockShoppingListRepository()),
            recipeCacheRepositoryProvider.overrideWithValue(MockRecipeCacheRepository()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: SearchableShoppingListsView(
              lists: lists ?? testLists,
              emptyMessage: emptyMessage ?? 'No lists available',
              onListTap: onListTap ??
                  (context, list) {
                    capturedList = list;
                    tapCount++;
                  },
              floatingActionButton: floatingActionButton,
              showRegistered: showRegistered,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders with normal AppBar initially', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('displays all lists initially', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      expect(find.text('Grocery Shopping'), findsOneWidget);
      expect(find.text('Weekly Essentials'), findsOneWidget);
      expect(find.text('Party Supplies'), findsOneWidget);
    });

    testWidgets('shows empty message when no lists provided', (WidgetTester tester) async {
      await pumpSearchableView(
        tester,
        lists: [],
        emptyMessage: 'No lists found',
      );

      expect(find.text('No lists found'), findsOneWidget);
    });

    testWidgets('starts search mode when search icon is tapped', (WidgetTester tester) async {
      await pumpSearchableView(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(SearchableShoppingListsView)))!;

      // Tap search icon
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Should show search TextField
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text(l10n.searchListsHint), findsOneWidget);
    });

    testWidgets('filters lists based on search query', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      // Start search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'grocery');
      await tester.pumpAndSettle();

      // Should only show Grocery Shopping
      expect(find.text('Grocery Shopping'), findsOneWidget);
      expect(find.text('Weekly Essentials'), findsNothing);
      expect(find.text('Party Supplies'), findsNothing);
    });

    testWidgets('search is case-insensitive', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Search with different cases
      await tester.enterText(find.byType(TextField), 'WEEKLY');
      await tester.pumpAndSettle();

      expect(find.text('Weekly Essentials'), findsOneWidget);
    });

    testWidgets('shows custom empty message when no search results', (WidgetTester tester) async {
      await pumpSearchableView(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(SearchableShoppingListsView)))!;

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pumpAndSettle();

      expect(find.text(l10n.noListsFoundMatching('nonexistent')), findsOneWidget);
    });

    testWidgets('clears search when clear icon is tapped', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'grocery');
      await tester.pumpAndSettle();

      // Tap clear icon
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Should show all lists again
      expect(find.text('Grocery Shopping'), findsOneWidget);
      expect(find.text('Weekly Essentials'), findsOneWidget);
      expect(find.text('Party Supplies'), findsOneWidget);
    });

    testWidgets('stops search when back arrow is tapped', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'grocery');
      await tester.pumpAndSettle();

      // Tap back arrow
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should exit search mode and show all lists
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Grocery Shopping'), findsOneWidget);
      expect(find.text('Weekly Essentials'), findsOneWidget);
      expect(find.text('Party Supplies'), findsOneWidget);
    });

    testWidgets('calls onListTap when a list is tapped', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      // Find and tap the InkWell widget for the first list
      final inkWells = find.byType(InkWell);
      expect(inkWells, findsWidgets);
      
      await tester.tap(inkWells.first);
      await tester.pumpAndSettle();

      expect(tapCount, 1);
      expect(capturedList?.getName(), 'Grocery Shopping');
    });

    testWidgets('stops search when list is tapped', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      // Start search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'grocery');
      await tester.pumpAndSettle();

      // Tap the InkWell for the filtered list
      final inkWells = find.byType(InkWell);
      await tester.tap(inkWells.first);
      await tester.pumpAndSettle();

      // Should exit search mode
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('renders floating action button when provided', (WidgetTester tester) async {
      final fab = FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      );

      await pumpSearchableView(tester, floatingActionButton: fab);

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('updates filtered lists when widget updates', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      expect(find.text('Grocery Shopping'), findsOneWidget);

      // Update with new lists
      final newLists = [
        ShoppingList(id: '4', name: 'New List', createdAt: DateTime(2024, 1, 1)),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingListRepositoryProvider.overrideWithValue(MockShoppingListRepository()),
            recipeCacheRepositoryProvider.overrideWithValue(MockRecipeCacheRepository()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: SearchableShoppingListsView(
              lists: newLists,
              emptyMessage: 'No lists available',
              onListTap: (context, list) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New List'), findsOneWidget);
      expect(find.text('Grocery Shopping'), findsNothing);
    });

    testWidgets('maintains search filter when widget updates', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      // Start search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'grocery');
      await tester.pumpAndSettle();

      // Update lists
      final updatedLists = [
        ShoppingList(id: '1', name: 'Grocery Shopping', createdAt: DateTime(2024, 1, 1)),
        ShoppingList(id: '4', name: 'Grocery Store', createdAt: DateTime(2024, 1, 1)),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingListRepositoryProvider.overrideWithValue(MockShoppingListRepository()),
            recipeCacheRepositoryProvider.overrideWithValue(MockRecipeCacheRepository()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: SearchableShoppingListsView(
              lists: updatedLists,
              emptyMessage: 'No lists available',
              onListTap: (context, list) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should still be filtering with 'grocery'
      expect(find.text('Grocery Shopping'), findsOneWidget);
      expect(find.text('Grocery Store'), findsOneWidget);
    });

    testWidgets('hides AppBar in deletion mode', (WidgetTester tester) async {
      await pumpSearchableView(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(SearchableShoppingListsView)))!;

      // Initial AppBar should exist
      expect(find.byType(AppBar), findsOneWidget);

      // Long press on InkWell to enter deletion mode
      final inkWells = find.byType(InkWell);
      await tester.longPress(inkWells.first);
      await tester.pumpAndSettle();

      // AppBar should be hidden in deletion mode (SearchableShoppingListsView AppBar)
      // But ShoppingListsGridView creates its own AppBar in deletion mode
      // So we check for the selection mode AppBar
      expect(find.text(l10n.selectedItemsCount(1)), findsOneWidget);
    });

    testWidgets('stops search when entering deletion mode', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      // Start search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'grocery');
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      // Enter deletion mode via long press on InkWell
      final inkWells = find.byType(InkWell);
      await tester.longPress(inkWells.first);
      await tester.pumpAndSettle();

      // Search should be stopped
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('resets state when navigation signal changes', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(MockShoppingListRepository()),
          recipeCacheRepositoryProvider.overrideWithValue(MockRecipeCacheRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: SearchableShoppingListsView(
              lists: testLists,
              emptyMessage: 'No lists available',
              onListTap: (context, list) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'grocery');
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      // Trigger navigation signal
      container.read(appNavigationSignalProvider.notifier).state++;
      await tester.pumpAndSettle();

      // Search should be stopped
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('search query filters partial matches', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Search for partial word
      await tester.enterText(find.byType(TextField), 'shop');
      await tester.pumpAndSettle();

      expect(find.text('Grocery Shopping'), findsOneWidget);
      expect(find.text('Weekly Essentials'), findsNothing);
      expect(find.text('Party Supplies'), findsNothing);
    });

    testWidgets('empty search shows all lists', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'grocery');
      await tester.pumpAndSettle();

      // Clear the search
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // Should show all lists
      expect(find.text('Grocery Shopping'), findsOneWidget);
      expect(find.text('Weekly Essentials'), findsOneWidget);
      expect(find.text('Party Supplies'), findsOneWidget);
    });
  });
}
