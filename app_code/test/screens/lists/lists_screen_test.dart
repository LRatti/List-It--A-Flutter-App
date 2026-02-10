import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/screens/lists/lists_screen.dart';
import 'package:app_code/screens/lists/list_detail_screen_mobile.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/providers/real_app_providers/recipe/recipe_provider.dart';
import 'package:app_code/providers/real_app_providers/supermarket/supermarkets_notifier.dart';
import 'package:app_code/repositories/mock_repo/mock_shopping_list_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_recipe_cache_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_gemini_repository.dart';
import 'package:app_code/widgets/shopping_list_widget.dart';

/// Fake supermarkets notifier to avoid DB access in ListDetailScreenMobile
class _TestSupermarketsNotifier extends SupermarketsNotifier {
  @override
  Future<List<Supermarket>> build() async => [];

  @override
  Future<Supermarket?> getFavoriteSupermarket() async => null;
}

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
          geminiRepositoryProvider.overrideWithValue(MockGeminiRepository()),
          supermarketsProvider.overrideWith(() => _TestSupermarketsNotifier()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
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
      final l10n = AppLocalizations.of(tester.element(find.byType(ListsScreenMobile)))!;

      expect(find.text(l10n.noListsYet), findsOneWidget);
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
      final l10n = AppLocalizations.of(tester.element(find.byType(ListsScreenMobile)))!;

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text(l10n.addNewListTitle), findsOneWidget);
      expect(find.text(l10n.enterListNamePrompt), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(l10n.cancelLabel), findsOneWidget);
      expect(find.text(l10n.addLabel), findsOneWidget);
    });

    testWidgets('add list dialog can be cancelled without adding a list', (tester) async {
      await tester.pumpWidget(createTestWidget(initialLists: []));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(ListsScreenMobile)))!;

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.cancelLabel));
      await tester.pumpAndSettle();

      expect(find.text(l10n.addNewListTitle), findsNothing);
      expect(find.text(l10n.noListsYet), findsOneWidget);
    });

    testWidgets('adding a list through dialog makes it visible in the list', (tester) async {
      await tester.pumpWidget(createTestWidget(initialLists: []));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(ListsScreenMobile)))!;

      expect(find.text(l10n.noListsYet), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'My New List');
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.addLabel));
      await tester.pumpAndSettle();

      expect(find.text(l10n.addNewListTitle), findsNothing);
      expect(find.byType(ListDetailScreenMobile), findsOneWidget);
      final stored = await mockRepo.getAll();
      expect(stored.any((l) => l.getName() == 'My New List'), isTrue);
    });

    testWidgets('submitting dialog with empty name does not add a list', (tester) async {
      await tester.pumpWidget(createTestWidget(initialLists: []));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(ListsScreenMobile)))!;

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Submit without entering text
      await tester.tap(find.text(l10n.addLabel));
      await tester.pumpAndSettle();

      expect(find.text(l10n.addNewListTitle), findsOneWidget);
      final stored = await mockRepo.getAll();
      expect(stored, isEmpty);
    });

    testWidgets('whitespace-only list name is treated as empty and not added', (tester) async {
      await tester.pumpWidget(createTestWidget(initialLists: []));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(ListsScreenMobile)))!;

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.addLabel));
      await tester.pumpAndSettle();

      expect(find.text(l10n.addNewListTitle), findsOneWidget);
      final stored = await mockRepo.getAll();
      expect(stored, isEmpty);
    });

    testWidgets('list name with surrounding whitespace is trimmed and displayed correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(initialLists: []));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(ListsScreenMobile)))!;

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '  Trimmed List  ');
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.addLabel));
      await tester.pumpAndSettle();

      final stored = await mockRepo.getAll();
      expect(stored.any((l) => l.getName() == 'Trimmed List'), isTrue);
      expect(find.byType(ListDetailScreenMobile), findsOneWidget);
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
          geminiRepositoryProvider.overrideWithValue(MockGeminiRepository()),
          supermarketsProvider.overrideWith(() => _TestSupermarketsNotifier()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: ListsScreenMobile(),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(ListsScreenMobile)))!;
      expect(find.text(l10n.errorWithDetails('Exception: Failed to load lists')),
          findsOneWidget);
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

    testWidgets('search filters lists and shows empty state when no match', (tester) async {
      final lists = [
        createList('list-1', 'Groceries'),
        createList('list-2', 'Hardware'),
      ];

      await tester.pumpWidget(createTestWidget(initialLists: lists));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(ListsScreenMobile)))!;

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hard');
      await tester.pumpAndSettle();

      expect(find.text('Hardware'), findsOneWidget);
      expect(find.text('Groceries'), findsNothing);

      await tester.enterText(find.byType(TextField), 'NoMatch');
      await tester.pumpAndSettle();

      expect(find.text(l10n.noListsFoundMatching('NoMatch')), findsOneWidget);
    });

    testWidgets('selection mode delete moves list to trash', (tester) async {
      final lists = [
        createList('list-1', 'Groceries'),
        createList('list-2', 'Hardware'),
      ];

      await tester.pumpWidget(createTestWidget(initialLists: lists));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(ListsScreenMobile)))!;

      await tester.longPress(find.byType(ShoppingListCard).first);
      await tester.pumpAndSettle();

      expect(find.text(l10n.selectedItemsCount(1)), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.deleteLabel));
      await tester.pumpAndSettle();

      expect(find.text('Groceries'), findsNothing);
      expect(find.text('Hardware'), findsOneWidget);
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
