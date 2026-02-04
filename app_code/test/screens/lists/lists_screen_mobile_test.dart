import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/screens/lists/lists_screen_mobile.dart';
import 'package:app_code/screens/lists/list_detail_screen_mobile.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/selected_list_notifier.dart';
import 'package:app_code/providers/real_app_providers/recipe/recipe_provider.dart';
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

  group('ListsScreenMobile - Navigation to ListDetailScreenMobile', () {
    late MockShoppingListRepository mockRepo;
    late MockRecipeCacheRepository mockRecipeCache;
    late MockSelectedListNotifier mockSelectedListNotifier;

    setUp(() {
      mockRepo = MockShoppingListRepository();
      mockRecipeCache = MockRecipeCacheRepository();
      mockSelectedListNotifier = MockSelectedListNotifier();
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
          selectedListProvider.overrideWith(() => mockSelectedListNotifier),
        ],
        child: const MaterialApp(
          home: ListsScreenMobile(),
        ),
      );
    }

    /// Helper to create a test widget for detail screen with null list
    Widget createDetailScreenWithNullList() {
      final nullListNotifier = MockSelectedListNotifier();
      nullListNotifier.setList(null);

      return ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(mockRepo),
          recipeCacheRepositoryProvider.overrideWithValue(mockRecipeCache),
          selectedListProvider.overrideWith(() => nullListNotifier),
        ],
        child: const MaterialApp(
          home: ListDetailScreenMobile(),
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

    testWidgets('tapping on an existing shopping list navigates to list detail screen', (tester) async {
      final testList = createList('list-1', 'Groceries');
      await tester.pumpWidget(createTestWidget(initialLists: [testList]));
      await tester.pumpAndSettle();

      // Verify the list is displayed
      expect(find.text('Groceries'), findsOneWidget);

      // Tap on the shopping list
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      // Verify we navigated to the detail screen
      // The detail screen should show the list name in the app bar
      expect(find.byType(ListDetailScreenMobile), findsOneWidget);
    });

    testWidgets('list detail screen shows empty state when no list is selected', (tester) async {
      final testList = createList('list-1', 'Groceries');
      await tester.pumpWidget(createTestWidget(initialLists: [testList]));
      await tester.pumpAndSettle();
      // Verify the list is displayed
      expect(find.text('Groceries'), findsOneWidget);

      // Tap on the shopping list
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      // Verify empty state is displayed
      expect(find.text('Shopping List'), findsOneWidget); // AppBar title
      expect(find.text('No list selected'), findsOneWidget); // Empty state message
      expect(find.byType(CircularProgressIndicator), findsNothing); // Not loading
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

/// Mock implementation of SelectedListNotifier for testing
class MockSelectedListNotifier extends SelectedListNotifier {
  ShoppingList? _list;
  Supermarket? _supermarket;

  void setList(ShoppingList? list) {
    _list = list;
  }

  void setSupermarket(Supermarket? supermarket) {
    _supermarket = supermarket;
  }

  @override
  Future<SelectedListState> build() async {
    return SelectedListState(list: _list, supermarket: _supermarket);
  }

  @override
  Future<void> selectList(ShoppingList list) async {
    _list = list;
    _supermarket = list.getSupermarket();
    state = AsyncValue.data(
      SelectedListState(list: _list, supermarket: _supermarket),
    );
  }

  @override
  Future<void> clearSelection() async {
    _list = null;
    _supermarket = null;
    state = AsyncValue.data(
      SelectedListState(list: null, supermarket: null),
    );
  }

  @override
  Future<void> updateSelectedList(ShoppingList updatedList) async {
    if (_list != null && _list!.id == updatedList.id) {
      _list = updatedList;
      state = AsyncValue.data(
        SelectedListState(list: _list, supermarket: _supermarket),
      );
    }
  }

  @override
  String? getSelectedListId() {
    return _list?.id;
  }

  @override
  bool isSelected(String listId) {
    return _list?.id == listId;
  }

  @override
  Future<void> updateSelectedSupermarket(Supermarket? supermarket) async {
    _supermarket = supermarket;
    state = AsyncValue.data(
      SelectedListState(list: _list, supermarket: _supermarket),
    );
  }

  @override
  Supermarket? getSelectedSupermarket() {
    return _supermarket;
  }
}
