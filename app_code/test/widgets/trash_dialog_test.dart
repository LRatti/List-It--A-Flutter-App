import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/widgets/trash_dialog.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/repositories/mock_repo/mock_shopping_list_repository.dart';

void main() {
  group('TrashDialog', () {
    
    /// Helper method to build the widget using the same pattern as SideMenu.
    Future<void> pumpTrashDialog(
      WidgetTester tester, {
      List<ShoppingList> lists = const [],
      AsyncValue<List<ShoppingList>>? manualState,
      bool usePumpOnly = false,
    }) async {
      // 1. Setup Mock Repository (like in SideMenu)
      final mockRepo = MockShoppingListRepository();
      for (final list in lists) {
        await mockRepo.add(list);
      }

      // 2. Setup ProviderContainer with overrides
      final container = ProviderContainer(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // 3. Initialize the state of the notifier
      // If manualState is provided (for loading/error), we use it, 
      // otherwise we use the provided lists.
      container.read(shoppingListsProvider.notifier).state = 
          manualState ?? AsyncValue.data(lists);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const TrashDialog(),
                  ),
                  child: const Text('Show Trash'),
                ),
              ),
            ),
          ),
        ),
      );

      // Trigger the dialog open
      await tester.tap(find.text('Show Trash'));
      if (usePumpOnly) {
        await tester.pump();
      } else {
        await tester.pumpAndSettle();
      }
    }

    testWidgets('shows empty trash message', (tester) async {
      await pumpTrashDialog(tester, lists: const []);

      expect(find.text('Trash is empty'), findsOneWidget);
    });

    testWidgets('displays only trashed lists', (tester) async {
      final lists = [
        ShoppingList(id: '1', name: 'Trashed Item', createdAt: DateTime.now())
          ..setIsInTheTrash(true),
        ShoppingList(id: '2', name: 'Active Item', createdAt: DateTime.now())
          ..setIsInTheTrash(false),
      ];

      await pumpTrashDialog(tester, lists: lists);

      expect(find.text('Trashed Item'), findsOneWidget);
      expect(find.text('Active Item'), findsNothing);
    });

    testWidgets('delete button shows confirmation dialog', (tester) async {
      final list = ShoppingList(id: '1', name: 'Test List', createdAt: DateTime.now())
        ..setIsInTheTrash(true);

      await pumpTrashDialog(tester, lists: [list]);

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text('Delete permanently'), findsOneWidget);
      expect(
        find.text("Are you sure you want to permanently delete 'Test List'?"),
        findsOneWidget,
      );
    });

    testWidgets('cancel button closes confirmation dialog', (tester) async {
      final list = ShoppingList(id: '1', name: 'Test', createdAt: DateTime.now())
        ..setIsInTheTrash(true);

      await pumpTrashDialog(tester, lists: [list]);

      // Open confirm
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Should be back to Trash title
      expect(find.text('Trash'), findsOneWidget);
    });

    testWidgets('close button dismisses dialog', (tester) async {
      await pumpTrashDialog(tester);

      expect(find.byType(TrashDialog), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(TrashDialog), findsNothing);
    });
  });
}