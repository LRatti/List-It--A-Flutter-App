import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/screens/history/history_screen_mobile.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/repositories/mock_repo/mock_shopping_list_repository.dart';

class _ThrowingShoppingListRepository extends MockShoppingListRepository {
  @override
  Future<List<ShoppingList>> getAll() async {
    throw Exception('boom');
  }
}

ShoppingList _list(
  String name, {
  bool registered = true,
  bool inTrash = false,
  DateTime? createdAt,
}) {
  return ShoppingList(
    name: name,
    createdAt: createdAt ?? DateTime.now(),
    isRegistered: registered,
    isInTheTrash: inTrash,
  );
}

Future<ProviderContainer> _pumpHistory(
  WidgetTester tester, {
  List<ShoppingList>? seedLists,
  bool throwOnGetAll = false,
}) async {
  final repository =
      throwOnGetAll ? _ThrowingShoppingListRepository() : MockShoppingListRepository();

  if (!throwOnGetAll) {
    for (final list in seedLists ?? <ShoppingList>[]) {
      await repository.add(list);
    }
  }

  final container = ProviderContainer(
    overrides: [
      shoppingListRepositoryProvider.overrideWithValue(repository),
    ],
  );

  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: HistoryScreenMobile(),
      ),
    ),
  );
  return container;
}

void main() {
  testWidgets('shows loading indicator while lists load', (tester) async {
    await _pumpHistory(tester);

    // first frame: loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('shows error message when repository fails', (tester) async {
    await _pumpHistory(
      tester,
      throwOnGetAll: true,
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('boom'), findsOneWidget);
  });

  testWidgets('shows only registered non-trash lists', (tester) async {
    final lists = [
      _list('Registered A', createdAt: DateTime(2024, 5, 2)),
      _list('Registered B', createdAt: DateTime(2024, 6, 10)),
      _list('Unregistered', registered: false),
      _list('In Trash', inTrash: true),
    ];

    await _pumpHistory(
      tester,
      seedLists: lists,
    );

    await tester.pumpAndSettle();

    expect(find.text('Registered A'), findsOneWidget);
    expect(find.text('Registered B'), findsOneWidget);
    expect(find.text('Unregistered'), findsNothing);
    expect(find.text('In Trash'), findsNothing);
  });

  testWidgets('shows empty message when no registered lists', (tester) async {
    await _pumpHistory(
      tester,
      seedLists: const <ShoppingList>[],
    );

    await tester.pumpAndSettle();
    expect(find.text('No registered lists yet.'), findsOneWidget);
  });
}
