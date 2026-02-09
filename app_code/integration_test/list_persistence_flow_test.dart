import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/providers/real_app_providers/supermarket/supermarkets_notifier.dart';
import 'package:app_code/screens/lists/lists_screen.dart';
import 'package:app_code/widgets/shopping_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class FakeSupermarketDatabaseManager implements SupermarketDatabaseManager {
  @override
  Future<Supermarket?> getFavoriteSupermarket() async {
    return null;
  }

  @override
  Future<void> setFavoriteSupermarket(String supermarketId) async {}

  @override
  Future<void> clearFavoriteSupermarket(String supermarketId) async {}

  @override
  Future<List<Category>> getSupermarketCategories(String supermarketId) async {
    return [];
  }

  @override
  Future<void> replaceCategoriesOrder(
    String supermarketId,
    List<Category> categories,
  ) async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp() {
    return ProviderScope(
      overrides: [
        supermarketDatabaseManagerProvider.overrideWithValue(
          FakeSupermarketDatabaseManager(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const ListsScreenMobile(),
      ),
    );
  }

  testWidgets(
    'create list add products toggle bought and persist after reopen',
    (tester) async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final listName = 'Integration List $timestamp';
      final productA = 'Milk $timestamp';
      final productB = 'Bread $timestamp';

      Future<void> addProduct(String name) async {
        final inputFinder = find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText == 'Add product...',
        );
        expect(inputFinder, findsOneWidget);
        await tester.enterText(inputFinder, name);
        await tester.tap(find.byTooltip('Add product'));
        await tester.pumpAndSettle();
      }

      Finder checkboxForProduct(String name) {
        final productText = find.text(name);
        final tile = find.ancestor(of: productText, matching: find.byType(ListTile));
        return find.descendant(of: tile, matching: find.byType(Checkbox));
      }

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, listName);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText == 'Add product...',
        ),
        findsOneWidget,
      );

      await addProduct(productA);
      await addProduct(productB);

      await tester.tap(checkboxForProduct(productA));
      await tester.pumpAndSettle();

      final Checkbox initialCheckbox = tester.widget(checkboxForProduct(productA));
      expect(initialCheckbox.value, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final listCard = find.byWidgetPredicate(
        (widget) =>
            widget is ShoppingListCard &&
            widget.shoppingList.getName() == listName,
      );
      expect(listCard, findsOneWidget);
      final cardInkWell = find.descendant(
        of: listCard,
        matching: find.byWidgetPredicate(
          (widget) => widget is InkWell && widget.child is ClipRRect,
        ),
      );
      expect(cardInkWell, findsOneWidget);
      await tester.tap(cardInkWell);
      await tester.pumpAndSettle();

      final Checkbox reopenedCheckbox = tester.widget(checkboxForProduct(productA));
      expect(reopenedCheckbox.value, isTrue);

      final Checkbox otherCheckbox = tester.widget(checkboxForProduct(productB));
      expect(otherCheckbox.value, isFalse);
    },
  );
}
