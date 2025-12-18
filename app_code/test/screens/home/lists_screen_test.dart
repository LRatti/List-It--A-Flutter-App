import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_code/screens/home/lists_screen_mobile.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/repositories/test/in_memory_shopping_list_repository.dart';
import 'package:app_code/controllers/lists_controller.dart';

void main() {
  late InMemoryShoppingListRepository repository;
  late ListsController controller;

  setUp(() {
    repository = InMemoryShoppingListRepository();
    controller = ListsController(repository);
  });

  Future<void> pumpListsScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListsScreenMobile(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows empty state when there are no shopping lists', (tester) async {
    await pumpListsScreen(tester);
    expect(find.textContaining('No lists yet'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('renders shopping list card when a list exists', (tester) async {
    await controller.addList(ShoppingList(name: 'Groceries', createdAt: DateTime.now()));
    await pumpListsScreen(tester);

    expect(find.text('Groceries'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('FAB opens add list dialog', (tester) async {
    await pumpListsScreen(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Add new list'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('delete button removes a shopping list', (tester) async {
    final list = ShoppingList(name: 'To delete', createdAt: DateTime.now());
    await controller.addList(list);

    await pumpListsScreen(tester);

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('To delete'), findsNothing);
    expect(find.textContaining('No lists yet'), findsOneWidget);
  });

  testWidgets('edit button opens edit dialog and modifies list name', (tester) async {
    final list = ShoppingList(name: 'Editable list', createdAt: DateTime.now());
    await controller.addList(list);

    await pumpListsScreen(tester);

    // Tap edit icon
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.text('Edit list'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Modify the list name
    await tester.enterText(find.byType(TextField), 'Modified list');
    await tester.pumpAndSettle();

    // Tap Save button
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify the new name appears and old name is gone
    expect(find.text('Modified list'), findsOneWidget);
    expect(find.text('Editable list'), findsNothing);
  });
}
