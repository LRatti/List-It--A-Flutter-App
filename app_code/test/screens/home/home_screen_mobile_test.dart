import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_code/screens/home/home_screen_mobile.dart';
import 'package:app_code/controllers/lists_controller.dart';
import '../../../lib/repositories_impl/test/in_memory_shopping_list_repository.dart';

void main() {
  testWidgets('HomePage switches tabs correctly', (tester) async {
    final controller = ListsController(InMemoryShoppingListRepository());

    await tester.pumpWidget(
      MaterialApp(
        home: MobileHomePage(listsController: controller),
      ),
    );
    await tester.pumpAndSettle();

    // Starts on Lists tab
    expect(find.byKey(const Key('lists_tab')), findsOneWidget);

    // Go to History
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history_tab')), findsOneWidget);

    // Go to Supermarkets
    await tester.tap(find.text('Supermarkets'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('supermarkets_tab')), findsOneWidget);

    // Go to Statistics
    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('statistics_tab')), findsOneWidget);

    // Back to Lists
    await tester.tap(find.text('Lists'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lists_tab')), findsOneWidget);
  });
}