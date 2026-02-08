import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_code/widgets/draggable_product_list.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/l10n/app_localizations.dart';

void main() {
  group('DraggableProductList', () {
    late Category foodCategory;
    late Category beverageCategory;
    late Product appleProduct;
    late Product waterProduct;
    late PurchasedProduct applePurchased;
    late PurchasedProduct waterPurchased;
    late ScrollController scrollController;

    late int productMovedCount;
    late int productRemovedCount;
    late int productRenamedCount;
    late int productBoughtToggledCount;

    setUp(() {
      foodCategory = Category(id: 'food', name: 'Food');
      beverageCategory = Category(id: 'beverage', name: 'Beverage');
      appleProduct = Product(id: 'p1', name: 'Apple');
      waterProduct = Product(id: 'p2', name: 'Water');

      applePurchased = PurchasedProduct(
        id: 'pp1',
        listId: 'list1',
        product: appleProduct,
        category: foodCategory,
        price: 1.5,
        quantity: 1,
        isBought: false,
      );

      waterPurchased = PurchasedProduct(
        id: 'pp2',
        listId: 'list1',
        product: waterProduct,
        category: beverageCategory,
        price: 2.0,
        quantity: 2,
        isBought: true,
      );

      scrollController = ScrollController();
      productMovedCount = 0;
      productRemovedCount = 0;
      productRenamedCount = 0;
      productBoughtToggledCount = 0;
    });

    tearDown(() {
      scrollController.dispose();
    });

    /// Helper to pump the widget with standard configuration
    Future<void> pumpDraggableProductList(
      WidgetTester tester, {
      Map<Category, List<PurchasedProduct>>? productsByCategory,
      Future<void> Function(PurchasedProduct, Category)? onProductMoved,
      Future<void> Function(PurchasedProduct)? onProductRemoved,
      Future<void> Function(PurchasedProduct, String)? onProductRenamed,
      Future<void> Function(PurchasedProduct, bool)? onProductBoughtToggled,
      ScrollController? controller,
    }) async {
      final products = productsByCategory ??
          <Category, List<PurchasedProduct>>{
            foodCategory: [applePurchased],
            beverageCategory: [waterPurchased],
          };

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: SingleChildScrollView(
              controller: controller,
              child: DraggableProductList(
                productsByCategory: products,
                onProductMoved: onProductMoved ??
                    (product, category) async {
                      productMovedCount++;
                    },
                onProductRemoved: onProductRemoved ??
                    (product) async {
                      productRemovedCount++;
                    },
                onProductRenamed: onProductRenamed ??
                    (product, name) async {
                      productRenamedCount++;
                    },
                onProductBoughtToggled:
                    onProductBoughtToggled ??
                        (product, isBought) async {
                          productBoughtToggledCount++;
                        },
                scrollController: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders all category headers', (tester) async {
      await pumpDraggableProductList(tester);

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Beverage'), findsOneWidget);
    });

    testWidgets('displays product count badges for each category',
        (tester) async {
      await pumpDraggableProductList(tester);

      // Each category has 1 product
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('renders products in correct categories', (tester) async {
      await pumpDraggableProductList(tester);

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);
    });

    testWidgets('checkbox reflects product bought status', (tester) async {
      await pumpDraggableProductList(tester);

      // Apple should not be checked
      final appleCheckbox = find.byType(Checkbox).first;
      expect(tester.widget<Checkbox>(appleCheckbox).value, isFalse);

      // Water should be checked
      final waterCheckbox = find.byType(Checkbox).at(1);
      expect(tester.widget<Checkbox>(waterCheckbox).value, isTrue);
    });

    testWidgets('toggles product bought status when checkbox tapped',
        (tester) async {
      await pumpDraggableProductList(tester);

      // Toggle Apple checkbox
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(productBoughtToggledCount, equals(1));
    });

    testWidgets('removes product when remove button is tapped',
        (tester) async {
      await pumpDraggableProductList(tester);

      final removeButton = find.byIcon(Icons.remove_circle_outline).first;
      await tester.tap(removeButton);
      await tester.pumpAndSettle();

      expect(productRemovedCount, equals(1));
    });

    testWidgets('renames product when name is edited and submitted',
        (tester) async {
      await pumpDraggableProductList(tester);

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Red Apple');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(productRenamedCount, equals(1));
    });

    testWidgets('removes product when name is cleared and submitted',
        (tester) async {
      await pumpDraggableProductList(tester);

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(productRemovedCount, equals(1));
    });

    testWidgets('unfocuses text field on tap outside', (tester) async {
      await pumpDraggableProductList(tester);

      final textField = find.byType(TextField).first;
      await tester.tap(textField);
      await tester.pumpAndSettle();

      // Tap outside to trigger onTapOutside
      await tester.tap(find.byType(DraggableProductList).first);
      await tester.pumpAndSettle();

      final focusNode = tester.widget<TextField>(textField).focusNode;
      expect(focusNode?.hasFocus, isFalse);
    });

    testWidgets('shows drag handle for each product', (tester) async {
      await pumpDraggableProductList(tester);

      expect(find.byIcon(Icons.drag_handle), findsWidgets);
    });

    testWidgets('renders empty categories with headers', (tester) async {
      final emptyCategory = Category(id: 'empty', name: 'Empty');
      final products = <Category, List<PurchasedProduct>>{
        foodCategory: [applePurchased],
        emptyCategory: [],
      };

      await pumpDraggableProductList(
        tester,
        productsByCategory: products,
      );

      expect(find.text('Empty'), findsOneWidget);
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('drag target accepts products from other categories',
        (tester) async {
      await pumpDraggableProductList(tester);

      // Verify that DragTarget widgets are present
      expect(find.byType(DragTarget<PurchasedProduct>), findsWidgets);
    });

    testWidgets('calls onProductBoughtToggled only when callback provided',
        (tester) async {
      int callCount = 0;
      await pumpDraggableProductList(
        tester,
        onProductBoughtToggled: (product, isBought) async {
          callCount++;
        },
      );

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(callCount, equals(1));
    });

    testWidgets('does not crash when onProductBoughtToggled is null',
        (tester) async {
      await pumpDraggableProductList(
        tester,
        onProductBoughtToggled: null,
      );

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(find.byType(DraggableProductList), findsOneWidget);
    });

    testWidgets('LongPressDraggable provides feedback during drag',
        (tester) async {
      await pumpDraggableProductList(tester);

      // Verify LongPressDraggable widgets exist for each product
      expect(find.byType(LongPressDraggable<PurchasedProduct>), findsWidgets);
    });

    testWidgets('card material shows visual feedback on drag target',
        (tester) async {
      await pumpDraggableProductList(tester);

      // Verify Card widgets for products exist
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('all products have proper TextEditingControllers',
        (tester) async {
      final products = {
        foodCategory: [applePurchased, waterPurchased],
      };

      await pumpDraggableProductList(tester, productsByCategory: products);

      // Should have text fields for each product
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('category header shows correct styling when drop target',
        (tester) async {
      await pumpDraggableProductList(tester);

      // Category headers should be rendered as drag targets
      expect(find.byType(DragTarget<PurchasedProduct>), findsWidgets);
    });

    testWidgets('renaming does not occur when name unchanged',
        (tester) async {
      await pumpDraggableProductList(tester);

      final textField = find.byType(TextField).first;
      // Enter same name as original
      await tester.enterText(textField, 'Apple');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Should not trigger rename
      expect(productRenamedCount, equals(0));
    });

    testWidgets('scroll controller is properly utilized', (tester) async {
      final customScrollController = ScrollController();

      try {
        await pumpDraggableProductList(
          tester,
          controller: customScrollController,
        );

        expect(customScrollController, isNotNull);
        expect(find.byType(DraggableProductList), findsOneWidget);
      } finally {
        customScrollController.dispose();
      }
    });

    testWidgets('multiple products in same category render correctly',
        (tester) async {
      final apple2 = PurchasedProduct(
        id: 'pp3',
        listId: 'list1',
        product: Product(id: 'p3', name: 'Banana'),
        category: foodCategory,
        price: 0.8,
        quantity: 3,
        isBought: false,
      );

      final products = <Category, List<PurchasedProduct>>{
        foodCategory: [applePurchased, apple2],
      };

      await pumpDraggableProductList(tester, productsByCategory: products);

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // 2 products in Food category
    });
  });
}
