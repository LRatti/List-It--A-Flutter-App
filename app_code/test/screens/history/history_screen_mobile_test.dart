import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/screens/history/history_screen_mobile.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/real_app_providers/shopping_lists_notifier.dart';

class _FakeShoppingListsNotifier extends ShoppingListsNotifier {
  _FakeShoppingListsNotifier(this.initialState);

  final AsyncValue<List<ShoppingList>> initialState;

  @override
  Future<List<ShoppingList>> build() async {
    state = initialState;
    return initialState.value ?? <ShoppingList>[];
  }
}

ShoppingList _list(
  String name, {
  bool registered = true,
  bool inTrash = false,
  DateTime? createdAt,
}) {
  final list = ShoppingList(
    name: name,
    createdAt: createdAt ?? DateTime.now(),
    isRegistered: registered,
    isInTheTrash: inTrash,
  );
  return list;
}

Future<ProviderContainer> _pumpHistory(
  WidgetTester tester, {
  AsyncValue<List<ShoppingList>>? state,
}) async {
  final container = ProviderContainer(
    overrides: [
      if (state != null)
        shoppingListsProvider.overrideWith(
          () => _FakeShoppingListsNotifier(state),
        ),
    ],
  );

  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: HistoryScreenMobile(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {

  testWidgets('shows only registered non-trash lists', (tester) async {
    final lists = [
      _list('Registered A', createdAt: DateTime(2024, 5, 2)),
      _list('Registered B', createdAt: DateTime(2024, 6, 10)),
      _list('Unregistered', registered: false),
      _list('In Trash', inTrash: true),
    ];

    await _pumpHistory(
      tester,
      state: AsyncValue.data(lists),
    );

    expect(find.text('Registered A'), findsOneWidget);
    expect(find.text('Registered B'), findsOneWidget);
    expect(find.text('Unregistered'), findsNothing);
    expect(find.text('In Trash'), findsNothing);
  });

  testWidgets('shows empty message when no registered lists', (tester) async {
    await _pumpHistory(
      tester,
      state: const AsyncValue.data(<ShoppingList>[]),
    );

    expect(find.text('No registered lists yet.'), findsOneWidget);
  });
}
