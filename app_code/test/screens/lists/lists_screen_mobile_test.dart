import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/screens/lists/lists_screen_mobile.dart';
import 'package:app_code/providers/real_app_providers/shopping_lists_notifier.dart';
import 'package:app_code/providers/real_app_providers/recipe_provider.dart';
import 'package:app_code/repositories/mock_repo/mock_shopping_list_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_recipe_cache_repository.dart';

void main() {
  group('ListsScreenMobile', () {
    late MockShoppingListRepository mockRepo;
    late MockRecipeCacheRepository mockRecipeCache;

    setUp(() {
      mockRepo = MockShoppingListRepository();
      mockRecipeCache = MockRecipeCacheRepository();
    });

    /// Helper to create a test widget with providers
    Widget createTestWidget({List<ShoppingList>? initialLists}) {
      // Pre-populate repository if needed
      if (initialLists != null) {
        for (final list in initialLists) {
          mockRepo.add(list);
        }
      }

      return ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(mockRepo),
          recipeCacheRepositoryProvider.overrideWithValue(mockRecipeCache),
        ],
        child: const MaterialApp(
          home: ListsScreenMobile(),
        ),
      );
    }

    /// Helper to create a shopping list
    ShoppingList createList(
      String id,
      String name, {
      DateTime? createdAt,
      bool isInTrash = false,
      bool isRegistered = false,
    }) {
      return ShoppingList(
        id: id,
        name: name,
        createdAt: createdAt ?? DateTime.now(),
        isInTheTrash: isInTrash,
        isRegistered: isRegistered,
      );
    }

    testWidgets('shows empty state message when no lists exist', (tester) async {
      await tester.pumpWidget(createTestWidget(initialLists: []));
      await tester.pumpAndSettle();

      expect(find.text('No lists yet.'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows only active lists and filters out trashed and registered lists', (tester) async {
      final lists = [
        createList('list-1', 'Active List 1'),
        createList('list-2', 'Trashed List', isInTrash: true),
        createList('list-3', 'Active List 2'),
        createList('list-4', 'Registered List', isRegistered: true),
      ];

      await tester.pumpWidget(createTestWidget(initialLists: lists));
      await tester.pumpAndSettle();

      // Only active lists should be visible
      expect(find.text('Active List 1'), findsOneWidget);
      expect(find.text('Active List 2'), findsOneWidget);
      expect(find.text('Trashed List'), findsNothing);
      expect(find.text('Registered List'), findsNothing);
    });

    testWidgets('floating action button opens add list dialog', (tester) async {
      await tester.pumpWidget(createTestWidget(initialLists: []));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add new list'), findsOneWidget);
      expect(find.text('Please enter the name of your list:'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('add list dialog can be cancelled without adding a list', (tester) async {
      await tester.pumpWidget(createTestWidget(initialLists: []));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Add new list'), findsNothing);
      expect(find.text('No lists yet.'), findsOneWidget);
    });

    testWidgets('adding a list through dialog makes it visible in the list', (tester) async {
      await tester.pumpWidget(createTestWidget(initialLists: []));
      await tester.pumpAndSettle();

      expect(find.text('No lists yet.'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'My New List');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Add new list'), findsNothing);
      expect(find.text('My New List'), findsOneWidget);
      expect(find.text('No lists yet.'), findsNothing);
    });

    testWidgets('submitting dialog with empty name does not add a list', (tester) async {
      await tester.pumpWidget(createTestWidget(initialLists: []));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Submit without entering text
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Add new list'), findsNothing);
      expect(find.text('No lists yet.'), findsOneWidget);
    });

    testWidgets('whitespace-only list name is treated as empty and not added', (tester) async {
      await tester.pumpWidget(createTestWidget(initialLists: []));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Add new list'), findsNothing);
      expect(find.text('No lists yet.'), findsOneWidget);
    });

    testWidgets('list name with surrounding whitespace is trimmed and displayed correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(initialLists: []));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '  Trimmed List  ');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify the trimmed name is visible in the UI
      expect(find.text('Trimmed List'), findsOneWidget);
    });

    testWidgets('displays multiple active lists correctly', (tester) async {
      final lists = [
        createList('list-1', 'Groceries'),
        createList('list-2', 'Hardware'),
        createList('list-3', 'Clothing'),
      ];

      await tester.pumpWidget(createTestWidget(initialLists: lists));
      await tester.pumpAndSettle();

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Hardware'), findsOneWidget);
      expect(find.text('Clothing'), findsOneWidget);
    });

    testWidgets('shows error message when repository fails', (tester) async {
      final failingRepo = _FailingShoppingListRepository();

      final widget = ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(failingRepo),
          recipeCacheRepositoryProvider.overrideWithValue(mockRecipeCache),
        ],
        child: const MaterialApp(
          home: ListsScreenMobile(),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.textContaining('Exception'), findsOneWidget);
    });

    testWidgets('floating action button is always visible', (tester) async {
      await tester.pumpWidget(createTestWidget(initialLists: []));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Also verify with lists present
      final lists = [createList('list-1', 'Test List')];
      await tester.pumpWidget(createTestWidget(initialLists: lists));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}

/// Mock repository that throws errors for testing error handling
class _FailingShoppingListRepository extends MockShoppingListRepository {
  @override
  Future<List<ShoppingList>> getAll() async {
    throw Exception('Failed to load lists');
  }
}
