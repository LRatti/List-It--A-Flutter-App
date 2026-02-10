import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/receipt_match.dart';
import 'package:app_code/models/recipe_response.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/providers/real_app_providers/product/product_categorization_provider.dart';
import 'package:app_code/repositories/abstract/gemini_repository.dart';
import 'package:app_code/screens/lists/list_detail_screen_mobile.dart';
import 'package:app_code/screens/lists/lists_screen.dart';
import 'package:app_code/services/database/sqlite/manage_purchased_product.dart';
import 'package:app_code/services/database/sqlite/manage_shopping_list.dart';
import 'package:app_code/services/database/sqlite/manage_supermarket.dart';
import 'package:app_code/utils/uncategorized_category_initializer.dart';
import 'package:app_code/widgets/shopping_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class FastGeminiRepository implements GeminiRepository {
  @override
  Future<RecipeData> queryRecipe({
    required String recipeName,
    required List<Category> categories,
  }) async {
    return RecipeData.empty();
  }

  @override
  Future<String> categorizeProduct({
    required String productName,
    required List<Category> categories,
  }) async {
    return 'uncategorized';
  }

  @override
  Future<List<ReceiptMatch>> extractReceiptMatches({
    required String receiptText,
    required List<PurchasedProduct> purchasedProducts,
  }) async {
    return [];
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp() {
    return ProviderScope(
      overrides: [
        productCategorizationRepositoryProvider.overrideWithValue(
          FastGeminiRepository(),
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
    'change category persists when list is reopened',
    (tester) async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final listName = 'Category Persist $timestamp';
      final productName = 'Mystery Item $timestamp';
      final supermarketName = 'Test Market $timestamp';

      final uncategorized =
          await UncategorizedCategoryInitializer.ensureInitialized();
      final vegetables = Category(name: 'Vegetables');
      final supermarket = Supermarket(
        name: supermarketName,
        categories: [uncategorized, vegetables],
      );
      await ManageSupermarket.addSupermarket(supermarket);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, listName);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ListDetailScreenMobile)),
      )!;

      final supermarketIcon = find.byIcon(Icons.store);
      expect(supermarketIcon, findsOneWidget);
      final supermarketDropdown = find.ancestor(
        of: supermarketIcon,
        matching: find.byType(InkWell),
      );
      expect(supermarketDropdown, findsOneWidget);
      await tester.tap(supermarketDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text(supermarketName));
      await tester.pumpAndSettle();

      final productField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == l10n.addProductHint,
      );
      await tester.enterText(productField, productName);
      await tester.tap(find.byTooltip(l10n.addProductTooltip));
      await tester.pumpAndSettle();

      final productFinder = find.text(productName);
      final targetFinder = find.text('Vegetables');
      expect(productFinder, findsOneWidget);
      expect(targetFinder, findsOneWidget);

      final productTile = find.ancestor(
        of: productFinder,
        matching: find.byType(ListTile),
      );
      expect(productTile, findsOneWidget);
      final dragHandle = find.descendant(
        of: productTile,
        matching: find.byIcon(Icons.drag_handle),
      );
      expect(dragHandle, findsOneWidget);

      final gesture = await tester.startGesture(
        tester.getCenter(dragHandle),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveTo(tester.getCenter(targetFinder));
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.up();
      await tester.pumpAndSettle();

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

      final lists = await ManageShoppingList.getAllShoppingLists();
      final list = lists.firstWhere((l) => l.getName() == listName);
      final products =
          await ManagePurchasedProduct.getPurchasedProductsByList(list.id);
      final moved =
          products.firstWhere((p) => p.product.getName() == productName);

      expect(moved.category.getName(), 'Vegetables');
    },
  );
}
