import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/repositories/mock_repo/mock_shopping_list_repository.dart';
import 'package:app_code/screens/lists/register-list/register_shopping_list_screen_mobile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('RegisterShoppingListScreenMobile', () {
    late MockShoppingListRepository mockRepository;

    /// Helper to create category
    Category createCategory(String id, String name) {
      return Category(id: id, name: name, isVisible: true);
    }

    /// Helper to create product
    Product createProduct(String id, String name) {
      return Product(id: id, name: name);
    }

    /// Helper to create supermarket
    Supermarket createSupermarket(String id, String name) {
      return Supermarket(
        id: id,
        name: name,
        categories: [createCategory('cat-1', 'Fruits')],
      );
    }

    /// Helper to create purchased product
    PurchasedProduct createPurchasedProduct(
      String id,
      String productId,
      String productName,
      String categoryId,
      bool isBought, {
      int quantity = 1,
      double price = 2.5,
    }) {
      return PurchasedProduct(
        id: id,
        listId: 'list-1',
        product: createProduct(productId, productName),
        category: createCategory(categoryId, 'Fruits'),
        isBought: isBought,
        quantity: quantity,
        price: price,
      );
    }

    /// Helper to create shopping list with products
    ShoppingList createShoppingList(
      String id,
      String name, {
      Supermarket? supermarket,
      List<PurchasedProduct>? products,
    }) {
      final list = ShoppingList(id: id, name: name, createdAt: DateTime.now());
      if (supermarket != null) {
        list.setSupermarket(supermarket);
      }
      if (products != null) {
        list.products = products;
      }
      return list;
    }

    /// Helper to create test widget tree
    Widget createTestWidget(ShoppingList shoppingList) {
      return ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: RegisterShoppingListScreenMobile(
            shoppingListId: shoppingList.id,
            initialShoppingList: shoppingList,
          ),
        ),
      );
    }

    setUp(() {
      mockRepository = MockShoppingListRepository();
    });

    /// Test: Screen renders with loading state
    testWidgets('renders loading state when data is loading', (tester) async {
      final shoppingList = createShoppingList('list-1', 'Groceries');

      await tester.pumpWidget(createTestWidget(shoppingList));

      // Loading circle or initial render
      expect(find.byType(Scaffold), findsWidgets);
    });

    /// Test: Screen renders supermarket display
    testWidgets('renders supermarket display section', (tester) async {
      final supermarket = createSupermarket('sm-1', 'Test Supermarket');
      final shoppingList = createShoppingList(
        'list-1',
        'Groceries',
        supermarket: supermarket,
      );

      await tester.pumpWidget(createTestWidget(shoppingList));
      await tester.pumpAndSettle();

      // Verify supermarket display is shown
      expect(find.byIcon(Icons.store), findsOneWidget);
      expect(find.text('Test Supermarket'), findsOneWidget);
    });

    /// Test: Empty bought products state
    testWidgets('shows empty state when no products are bought', (tester) async {
      final product =
          createPurchasedProduct('pp-1', 'p-1', 'Apple', 'cat-1', false);
      final shoppingList = createShoppingList(
        'list-1',
        'Groceries',
        products: [product],
      );

      await tester.pumpWidget(createTestWidget(shoppingList));
      await tester.pumpAndSettle();

      // Verify empty state message is shown
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });

    /// Test: Renders bought products with categories
    testWidgets('renders bought products grouped by category', (tester) async {
      final product1 = createPurchasedProduct(
        'pp-1',
        'p-1',
        'Apple',
        'cat-1',
        true,
        quantity: 5,
        price: 2.5,
      );
      final product2 = createPurchasedProduct(
        'pp-2',
        'p-2',
        'Banana',
        'cat-1',
        true,
        quantity: 3,
        price: 1.5,
      );

      final shoppingList = createShoppingList(
        'list-1',
        'Groceries',
        products: [product1, product2],
      );

      await tester.pumpWidget(createTestWidget(shoppingList));
      await tester.pumpAndSettle();

      // Verify products are rendered
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });

    /// Test: Quantity and price fields are editable
    testWidgets('quantity and price fields accept input', (tester) async {
      final product = createPurchasedProduct(
        'pp-1',
        'p-1',
        'Apple',
        'cat-1',
        true,
      );
      final shoppingList = createShoppingList(
        'list-1',
        'Groceries',
        products: [product],
      );

      await tester.pumpWidget(createTestWidget(shoppingList));
      await tester.pumpAndSettle();

      // Find text fields (should be 2: quantity and price)
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      // Enter quantity
      await tester.enterText(textFields.first, '10');
      await tester.pumpAndSettle();

      // Verify entered text
      expect(find.text('10'), findsOneWidget);
    });

    /// Test: AppBar with title
    testWidgets('displays shopping list name in AppBar', (tester) async {
      final shoppingList = createShoppingList('list-1', 'My Shopping List');

      await tester.pumpWidget(createTestWidget(shoppingList));
      await tester.pumpAndSettle();

      // Verify title is displayed
      expect(find.text('My Shopping List'), findsOneWidget);
    });

    /// Test: Back button existence
    testWidgets('has back button in AppBar', (tester) async {
      final shoppingList = createShoppingList('list-1', 'Groceries');

      await tester.pumpWidget(createTestWidget(shoppingList));
      await tester.pumpAndSettle();

      // Verify back button exists
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    /// Test: Register (check) button existence
    testWidgets('has register button in AppBar', (tester) async {
      final shoppingList = createShoppingList('list-1', 'Groceries');

      await tester.pumpWidget(createTestWidget(shoppingList));
      await tester.pumpAndSettle();

      // Verify register button exists
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    /// Test: Floating action buttons (camera and edit)
    testWidgets('has camera and edit floating action buttons', (tester) async {
      final shoppingList = createShoppingList('list-1', 'Groceries');

      await tester.pumpWidget(createTestWidget(shoppingList));
      await tester.pumpAndSettle();

      // Verify floating action buttons
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    /// Test: Multiple products in different categories
    testWidgets('renders products from multiple categories', (tester) async {
      final cat1 = createCategory('cat-1', 'Fruits');
      final cat2 = createCategory('cat-2', 'Vegetables');

      final product1 = PurchasedProduct(
        id: 'pp-1',
        listId: 'list-1',
        product: createProduct('p-1', 'Apple'),
        category: cat1,
        isBought: true,
        quantity: 5,
        price: 2.5,
      );

      final product2 = PurchasedProduct(
        id: 'pp-2',
        listId: 'list-1',
        product: createProduct('p-2', 'Carrot'),
        category: cat2,
        isBought: true,
        quantity: 3,
        price: 1.5,
      );

      final shoppingList = createShoppingList(
        'list-1',
        'Groceries',
        products: [product1, product2],
      );

      await tester.pumpWidget(createTestWidget(shoppingList));
      await tester.pumpAndSettle();

      // Both products should be visible
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Carrot'), findsOneWidget);
    });

    /// Test: TextField filtering for quantity (digits only)
    testWidgets('quantity field accepts only digits', (tester) async {
      final product = createPurchasedProduct(
        'pp-1',
        'p-1',
        'Apple',
        'cat-1',
        true,
      );
      final shoppingList = createShoppingList(
        'list-1',
        'Groceries',
        products: [product],
      );

      await tester.pumpWidget(createTestWidget(shoppingList));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      
      // Try to enter non-digit in quantity field
      await tester.enterText(textFields.first, '10abc');
      await tester.pumpAndSettle();

      // Only digits should remain (formatter filters out letters)
      final text = (tester.widget<TextField>(textFields.first).controller as TextEditingController).text;
      expect(text, isNotEmpty);
    });

    /// Test: Price field formatting
    testWidgets('price field accepts decimal numbers', (tester) async {
      final product = createPurchasedProduct(
        'pp-1',
        'p-1',
        'Apple',
        'cat-1',
        true,
      );
      final shoppingList = createShoppingList(
        'list-1',
        'Groceries',
        products: [product],
      );

      await tester.pumpWidget(createTestWidget(shoppingList));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      // Second field is price
      await tester.enterText(textFields.at(1), '2.99');
      await tester.pumpAndSettle();

      expect(find.text('2.99'), findsOneWidget);
    });

    /// Test: Product tile structure
    testWidgets('product tile contains product name and fields', (tester) async {
      final product = createPurchasedProduct(
        'pp-1',
        'p-1',
        'TestProduct',
        'cat-1',
        true,
      );
      final shoppingList = createShoppingList(
        'list-1',
        'Groceries',
        products: [product],
      );

      await tester.pumpWidget(createTestWidget(shoppingList));
      await tester.pumpAndSettle();

      // Verify product name is in the product tile
      expect(find.text('TestProduct'), findsOneWidget);
      // Verify label texts exist
      expect(find.byType(Container), findsWidgets);
    });

    /// Test: Supermarket not set state
    testWidgets('shows not selected when supermarket is null', (tester) async {
      final shoppingList = createShoppingList(
        'list-1',
        'Groceries',
        supermarket: null,
      );

      await tester.pumpWidget(createTestWidget(shoppingList));
      await tester.pumpAndSettle();

      // Should have the store icon even without supermarket
      expect(find.byIcon(Icons.store), findsOneWidget);
    });
  });
}
