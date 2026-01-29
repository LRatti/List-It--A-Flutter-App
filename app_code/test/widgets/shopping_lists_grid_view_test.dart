import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/real_app_providers/navigation_provider.dart';
import 'package:app_code/providers/real_app_providers/recipe_provider.dart';
import 'package:app_code/providers/real_app_providers/shopping_lists_notifier.dart';
import 'package:app_code/repositories/mock_repo/mock_recipe_cache_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_shopping_list_repository.dart';
import 'package:app_code/widgets/shopping_lists_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_code/widgets/shopping_list_widget.dart';

void main() {
  group('ShoppingListsGridView', () {
    late List<ShoppingList> defaultLists;
    late MockShoppingListRepository mockRepository;

    setUp(() {
      defaultLists = [
        ShoppingList(id: '1', name: 'List 1'),
        ShoppingList(id: '2', name: 'List 2'),
      ];
      mockRepository = MockShoppingListRepository();
    });

    Future<ProviderContainer> pumpGrid(
      WidgetTester tester, {
      List<ShoppingList>? lists,
      String emptyMessage = 'No lists yet',
      void Function(BuildContext, ShoppingList)? onListTap,
      Widget? floatingActionButton,
      void Function(bool)? onDeletionModeChanged,
    }) async {
      final activeLists = lists ?? defaultLists;

      // Seed mock repository so notifier reads have data
      for (final list in activeLists) {
        await mockRepository.add(list);
      }

      final container = ProviderContainer(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(mockRepository),
          recipeCacheRepositoryProvider.overrideWithValue(
            MockRecipeCacheRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(shoppingListsProvider.notifier).state =
          AsyncValue.data(activeLists);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ShoppingListsGridView(
              lists: activeLists,
              emptyMessage: emptyMessage,
              onListTap: onListTap,
              floatingActionButton: floatingActionButton,
              onDeletionModeChanged: onDeletionModeChanged,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('shows empty state and floating action button', (tester) async {
      final fab = FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      );

      await pumpGrid(
        tester,
        lists: const [],
        emptyMessage: 'Nothing here',
        floatingActionButton: fab,
      );

      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('calls onListTap when a card is tapped', (tester) async {
      ShoppingList? tapped;

      await pumpGrid(
        tester,
        onListTap: (context, list) => tapped = list,
      );

      final firstCardInkWell = find.descendant(
        of: find.byType(ShoppingListCard).first,
        matching: find.byType(InkWell),
      );

      await tester.tap(firstCardInkWell.first);
      await tester.pumpAndSettle();

      expect(tapped?.id, '1');
    });

    testWidgets('long press toggles selection mode and callback', (tester) async {
      bool? deletionMode;

      await pumpGrid(
        tester,
        onDeletionModeChanged: (active) => deletionMode = active,
      );

      final firstCardInkWell = find.descendant(
        of: find.byType(ShoppingListCard).first,
        matching: find.byType(InkWell),
      );

      await tester.longPress(firstCardInkWell.first);
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
      expect(deletionMode, isTrue);

      await tester.tap(firstCardInkWell.first);
      await tester.pumpAndSettle();

      expect(find.textContaining('selected'), findsNothing);
      expect(find.byIcon(Icons.delete), findsNothing);
      expect(deletionMode, isFalse);
    });

    testWidgets('delete selected moves lists to trash and clears selection',
        (tester) async {
      bool? deletionMode;

      final container = await pumpGrid(
        tester,
        onDeletionModeChanged: (active) => deletionMode = active,
      );

      final firstCardInkWell = find.descendant(
        of: find.byType(ShoppingListCard).first,
        matching: find.byType(InkWell),
      );

      await tester.longPress(firstCardInkWell.first);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      final updatedLists = container.read(shoppingListsProvider).value ?? [];

      expect(updatedLists.map((list) => list.id), contains('1'));

      final trashed = updatedLists
          .firstWhere((list) => list.id == '1')
          .getIsInTheTrash();

      expect(trashed, isTrue);
      expect(deletionMode, isFalse);
      expect(find.byIcon(Icons.delete), findsNothing);
    });

    testWidgets('navigation signal clears selection', (tester) async {
      final container = await pumpGrid(tester);

      final firstCardInkWell = find.descendant(
        of: find.byType(ShoppingListCard).first,
        matching: find.byType(InkWell),
      );

      await tester.longPress(firstCardInkWell.first);
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);

      container.read(appNavigationSignalProvider.notifier).state++;
      await tester.pumpAndSettle();

      expect(find.textContaining('selected'), findsNothing);
      expect(find.byIcon(Icons.delete), findsNothing);
    });
  });
}
