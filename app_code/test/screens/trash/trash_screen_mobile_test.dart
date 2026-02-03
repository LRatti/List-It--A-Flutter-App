import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_code/screens/trash/trash_screen_mobile.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/providers/real_app_providers/recipe/recipe_provider.dart';
import 'package:app_code/repositories/mock_repo/mock_shopping_list_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_gemini_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_recipe_cache_repository.dart';

class _ThrowingShoppingListRepository extends MockShoppingListRepository {
  @override
  Future<List<ShoppingList>> getAll() async => throw Exception('boom');
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

Future<(ProviderContainer, MockShoppingListRepository)> _pumpTrash(
  WidgetTester tester, {
  List<ShoppingList>? seed,
  bool throwOnGetAll = false,
}) async {
  final repository = throwOnGetAll
      ? _ThrowingShoppingListRepository()
      : MockShoppingListRepository();

  if (!throwOnGetAll) {
    for (final l in seed ?? const <ShoppingList>[]) {
      await repository.add(l);
    }
  }

  final container = ProviderContainer(
    overrides: [
      shoppingListRepositoryProvider.overrideWithValue(repository),
      geminiRepositoryProvider.overrideWithValue(MockGeminiRepository()),
      recipeCacheRepositoryProvider.overrideWithValue(MockRecipeCacheRepository()),
      backgroundRecipeProvider.overrideWith((ref) {
        final gemini = ref.read(geminiRepositoryProvider);
        final cache = ref.read(recipeCacheRepositoryProvider);
        return BackgroundRecipeNotifier(gemini, cache);
      }),
    ],
  );

  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: TrashScreenMobile()),
    ),
  );

  return (container, repository);
}

void main() {
  testWidgets('shows error message', (tester) async {
    await _pumpTrash(
      tester,
      throwOnGetAll: true,
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('boom'), findsOneWidget);
  });

  testWidgets('shows empty message when trash is empty', (tester) async {
    await _pumpTrash(
      tester,
      seed: const <ShoppingList>[],
    );

    await tester.pumpAndSettle();
    expect(find.text('Trash is empty'), findsOneWidget);
  });

  testWidgets('Restore all clears trash flags on all lists', (tester) async {
    final lists = [
      _trashList('A', createdAt: DateTime(2024, 5, 1)),
      _trashList('B', createdAt: DateTime(2024, 6, 1)),
    ];

    final (_, repo) = await _pumpTrash(
      tester,
      seed: lists,
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    final stored = await repo.getAll();
    expect(stored.length, lists.length);
    expect(stored.every((l) => l.getIsInTheTrash() == false), isTrue);
  });

  testWidgets('Empty trash deletes all trashed lists after confirmation', (tester) async {
    final lists = [
      _trashList('C'),
      _trashList('D'),
    ];

    final (_, repo) = await _pumpTrash(
      tester,
      seed: lists,
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Empty trash'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete all'));
    await tester.pumpAndSettle();

    final remaining = await repo.getAll();
    expect(remaining, isEmpty);
  });

  testWidgets('Single restore button updates the selected list', (tester) async {
    final lists = [
      _trashList('Solo'),
    ];

    final (_, repo) = await _pumpTrash(
      tester,
      seed: lists,
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.restore));
    await tester.pumpAndSettle();

    final stored = await repo.getAll();
    expect(stored.first.getIsInTheTrash(), isFalse);
  });
}
