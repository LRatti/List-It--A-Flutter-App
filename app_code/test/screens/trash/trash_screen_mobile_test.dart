import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/screens/trash/trash_screen_mobile.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/real_app_providers/shopping_lists_notifier.dart';

class _FakeShoppingListsNotifier extends ShoppingListsNotifier {
  _FakeShoppingListsNotifier(this.initialState);

  final AsyncValue<List<ShoppingList>> initialState;
  final List<ShoppingList> updateCalls = [];
  final List<ShoppingList> deleteCalls = [];

  @override
  Future<List<ShoppingList>> build() async {
    state = initialState;
    return initialState.value ?? <ShoppingList>[];
  }

  @override
  Future<void> updateList(ShoppingList list) async {
    updateCalls.add(list);
    // keep state stable for UI; no repo interaction
  }

  @override
  Future<void> deleteList(ShoppingList list) async {
    deleteCalls.add(list);
    // keep state stable for UI; no repo interaction
  }
}

ShoppingList _trashList(String name, {DateTime? createdAt}) {
  return ShoppingList(
    name: name,
    createdAt: createdAt ?? DateTime.now(),
    isRegistered: true,
    isInTheTrash: true,
    deletionTimestamp: DateTime.now(),
  );
}

Future<(ProviderContainer, _FakeShoppingListsNotifier)> _pumpTrash(
  WidgetTester tester, {
  AsyncValue<List<ShoppingList>>? state,
}) async {
  final notifier = _FakeShoppingListsNotifier(
    state ?? const AsyncValue.loading(),
  );

  final container = ProviderContainer(
    overrides: [
      shoppingListsProvider.overrideWith(() => notifier),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: TrashScreenMobile()),
    ),
  );
  await tester.pumpAndSettle();
  return (container, notifier);
}

void main() {

  testWidgets('shows empty message when trash is empty', (tester) async {
    await _pumpTrash(
      tester,
      state: const AsyncValue.data(<ShoppingList>[]),
    );

    expect(find.text('Trash is empty'), findsOneWidget);
  });

  testWidgets('Restore all triggers update on each trashed list', (tester) async {
    final lists = [
      _trashList('A', createdAt: DateTime(2024, 5, 1)),
      _trashList('B', createdAt: DateTime(2024, 6, 1)),
    ];

    final (_, notifier) = await _pumpTrash(
      tester,
      state: AsyncValue.data(lists),
    );

    await tester.tap(find.text('Restore all'));
    await tester.pumpAndSettle();

    // Confirm dialog
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(notifier.updateCalls.length, lists.length);
    expect(notifier.updateCalls.map((l) => l.getIsInTheTrash()).every((v) => v == false), isTrue);
  });

  testWidgets('Empty trash deletes all trashed lists after confirmation', (tester) async {
    final lists = [
      _trashList('C'),
      _trashList('D'),
    ];

    final (_, notifier) = await _pumpTrash(
      tester,
      state: AsyncValue.data(lists),
    );

    await tester.tap(find.text('Empty trash'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete all'));
    await tester.pumpAndSettle();

    expect(notifier.deleteCalls.length, lists.length);
  });

  testWidgets('Single restore button updates the selected list', (tester) async {
    final lists = [
      _trashList('Solo'),
    ];

    final (_, notifier) = await _pumpTrash(
      tester,
      state: AsyncValue.data(lists),
    );

    await tester.tap(find.byIcon(Icons.restore));
    await tester.pumpAndSettle();

    expect(notifier.updateCalls.length, 1);
    expect(notifier.updateCalls.first.getIsInTheTrash(), isFalse);
  });
}
