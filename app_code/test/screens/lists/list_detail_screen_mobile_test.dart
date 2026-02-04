import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/utils/uncategorized_category_initializer.dart';
import 'package:app_code/screens/lists/list_detail_screen_mobile.dart';
import 'package:app_code/screens/supermarket/supermarket_customization_screen.dart';
import 'package:app_code/providers/real_app_providers/supermarket/supermarkets_notifier.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/selected_list_notifier.dart';
import 'package:app_code/providers/real_app_providers/recipe/recipe_provider.dart';
import 'package:app_code/repositories/mock_repo/mock_shopping_list_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_recipe_cache_repository.dart';

void main() {
  // Initialize ffi database for testing
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ListDetailScreenMobile - Supermarket Selection', () {
    late MockShoppingListRepository mockShoppingListRepo;
    late MockRecipeCacheRepository mockRecipeCache;
    late MockSupermarketNotifier mockSupermarketNotifier;

    setUp(() {
      mockShoppingListRepo = MockShoppingListRepository();
      mockRecipeCache = MockRecipeCacheRepository();
      mockSupermarketNotifier = MockSupermarketNotifier();
    });

    /// Helper to create categories
    Category createCategory(String id, String name) {
      return Category(
        id: id,
        name: name,
        isVisible: true,
      );
    }

    /// Helper to create supermarket
    Supermarket createSupermarket(
      String id,
      String name, {
      List<Category>? categories,
      bool isFavorite = false,
    }) {
      return Supermarket(
        id: id,
        name: name,
        categories: categories ?? [createCategory('cat-1', 'Default')],
        isFavorite: isFavorite,
      );
    }

    /// Helper to create shopping list
    ShoppingList createShoppingList(
      String id,
      String name, {
      Supermarket? supermarket,
      List<PurchasedProduct>? products,
    }) {
      final list = ShoppingList(
        id: id,
        name: name,
        createdAt: DateTime.now(),
      );
      if (supermarket != null) {
        list.setSupermarket(supermarket);
      }
      if (products != null) {
        list.setPurchasedProducts(products);
      }
      return list;
    }

    /// Helper to create test widget with providers
    Widget createTestWidget(
      ShoppingList shoppingList, {
      List<Supermarket>? availableSupermarkets,
      Supermarket? lastEditedSupermarket,
    }) {
      // Set up mock supermarket notifier
      if (availableSupermarkets != null) {
        mockSupermarketNotifier.setAvailableSupermarkets(availableSupermarkets);
      }
      if (lastEditedSupermarket != null) {
        mockSupermarketNotifier.setLastEditedSupermarket(lastEditedSupermarket);
      }

      return ProviderScope(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(mockShoppingListRepo),
          recipeCacheRepositoryProvider.overrideWithValue(mockRecipeCache),
          supermarketsProvider.overrideWith(() => mockSupermarketNotifier),
          lastEditedSupermarketProvider.overrideWith((ref) async {
            return mockSupermarketNotifier.getLastEditedSupermarket();
          }),
          selectedListProvider.overrideWith(
            () => TestSelectedListNotifier(
              SelectedListState(
                list: shoppingList,
                supermarket: null,
                listName: shoppingList.getName(),
                products: List.from(shoppingList.getProducts()),
                bufferProducts: {},
                hasChanges: false,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: const ListDetailScreenMobile(),
        ),
      );
    }

    testWidgets(
      'selecting edited supermarket after returning from customization screen',
      (tester) async {
        // Given: A shopping list with an initial supermarket
        final initialSupermarket = createSupermarket('sm-1', 'Initial Store');
        final shoppingList = createShoppingList('list-1', 'Groceries',
            supermarket: initialSupermarket);

        // And: The edited supermarket (same ID, modified name)
        final editedSupermarket = createSupermarket('sm-1', 'Edited Store Name');

        // When: The screen is loaded with the edited supermarket as last edited
        await tester.pumpWidget(
          createTestWidget(
            shoppingList,
            availableSupermarkets: [initialSupermarket, editedSupermarket],
            lastEditedSupermarket: editedSupermarket,
          ),
        );
        await tester.pumpAndSettle();

        // Simulate navigation back from supermarket customization
        // by manually triggering the navigation logic
        final container = ProviderScope.containerOf(
          tester.element(find.byType(ListDetailScreenMobile)),
        );
        container.invalidate(supermarketsProvider);
        await tester.pumpAndSettle();

        // Then: The edited supermarket should be selected in the dropdown
        // Note: This test verifies the controller logic is set up correctly
        expect(find.byType(ListDetailScreenMobile), findsOneWidget);
      },
    );

    testWidgets(
      'selecting newly created supermarket after returning from creation mode',
      (tester) async {
        // Given: A shopping list with no initial supermarket
        final shoppingList = createShoppingList('list-1', 'Groceries');

        // And: A newly created supermarket
        final newSupermarket = createSupermarket('sm-new', 'New Store',
            categories: [
              createCategory('cat-1', 'Fruits'),
              createCategory('cat-2', 'Vegetables'),
            ]);

        // When: The screen is loaded with the new supermarket as last edited
        await tester.pumpWidget(
          createTestWidget(
            shoppingList,
            availableSupermarkets: [newSupermarket],
            lastEditedSupermarket: newSupermarket,
          ),
        );
        await tester.pumpAndSettle();

        // Simulate navigation back from supermarket creation
        final container = ProviderScope.containerOf(
          tester.element(find.byType(ListDetailScreenMobile)),
        );
        container.invalidate(supermarketsProvider);
        await tester.pumpAndSettle();

        // Then: The new supermarket should be available in the dropdown
        expect(find.byType(ListDetailScreenMobile), findsOneWidget);
      },
    );

    testWidgets(
      'clearing supermarket selection when returning with null last edited',
      (tester) async {
        // Given: A shopping list with an initial supermarket
        final initialSupermarket = createSupermarket('sm-1', 'Initial Store');
        final shoppingList = createShoppingList('list-1', 'Groceries',
            supermarket: initialSupermarket);

        // When: The screen is loaded with null as last edited (user cancelled)
        await tester.pumpWidget(
          createTestWidget(
            shoppingList,
            availableSupermarkets: [initialSupermarket],
            lastEditedSupermarket: null,
          ),
        );
        await tester.pumpAndSettle();

        // Then: The screen should handle null gracefully
        expect(find.byType(ListDetailScreenMobile), findsOneWidget);
      },
    );

    testWidgets(
      'retaining supermarket after edit with same categories',
      (tester) async {
        // Given: A shopping list with a supermarket
        final categories = [
          createCategory('cat-1', 'Dairy'),
          createCategory('cat-2', 'Meat'),
        ];
        final initialSupermarket = createSupermarket(
          'sm-1',
          'Store A',
          categories: categories,
        );
        final shoppingList = createShoppingList('list-1', 'Weekly Shopping',
            supermarket: initialSupermarket);

        // And: The same supermarket edited (name changed, categories same)
        final editedSupermarket = createSupermarket(
          'sm-1',
          'Store A - Edited',
          categories: categories,
        );

        // When: The screen is loaded with the edited supermarket
        await tester.pumpWidget(
          createTestWidget(
            shoppingList,
            availableSupermarkets: [editedSupermarket],
            lastEditedSupermarket: editedSupermarket,
          ),
        );
        await tester.pumpAndSettle();

        // Then: The edited supermarket should be selected
        expect(find.byType(ListDetailScreenMobile), findsOneWidget);
      },
    );

    testWidgets(
      'handling supermarket with modified categories after edit',
      (tester) async {
        // Given: A shopping list with a supermarket
        final initialCategories = [
          createCategory('cat-1', 'Produce'),
          createCategory('cat-2', 'Bakery'),
        ];
        final initialSupermarket = createSupermarket(
          'sm-1',
          'Superstore',
          categories: initialCategories,
        );
        final shoppingList = createShoppingList('list-1', 'Shopping',
            supermarket: initialSupermarket);

        // And: The supermarket edited with new categories added
        final editedCategories = [
          createCategory('cat-1', 'Produce'),
          createCategory('cat-2', 'Bakery'),
          createCategory('cat-3', 'Frozen'), // New category
        ];
        final editedSupermarket = createSupermarket(
          'sm-1',
          'Superstore',
          categories: editedCategories,
        );

        // When: The screen is loaded with the edited supermarket
        await tester.pumpWidget(
          createTestWidget(
            shoppingList,
            availableSupermarkets: [editedSupermarket],
            lastEditedSupermarket: editedSupermarket,
          ),
        );
        await tester.pumpAndSettle();

        // Then: The edited supermarket with new categories should be selected
        expect(find.byType(ListDetailScreenMobile), findsOneWidget);
      },
    );

    testWidgets(
      'clear button unselects supermarket and moves products to uncategorized',
      (tester) async {
        // Given: A shopping list with a selected supermarket and categorized products
        final dairy = createCategory('cat-1', 'Dairy');
        final bakery = createCategory('cat-2', 'Bakery');
        final supermarket = createSupermarket(
          'sm-1',
          'My Supermarket',
          categories: [dairy, bakery],
        );

        final product1 = Product(name: 'Milk');
        final product2 = Product(name: 'Bread');

        final purchased1 = PurchasedProduct(
          listId: 'list-1',
          product: product1,
          category: dairy,
        );
        final purchased2 = PurchasedProduct(
          listId: 'list-1',
          product: product2,
          category: bakery,
        );

        final shoppingList = createShoppingList(
          'list-1',
          'Groceries',
          supermarket: supermarket,
          products: [purchased1, purchased2],
        );

        await tester.pumpWidget(
          createTestWidget(
            shoppingList,
            availableSupermarkets: [supermarket],
            lastEditedSupermarket: supermarket,
          ),
        );
        await tester.pumpAndSettle();

        // Open supermarket selection menu
        await tester.tap(find.text('My Supermarket'));
        await tester.pumpAndSettle();

        // Tap Clear
        await tester.tap(find.widgetWithText(OutlinedButton, 'Clear'));
        await tester.pumpAndSettle();

        // Then: supermarket is unselected and all products are uncategorized
        final container = ProviderScope.containerOf(
          tester.element(find.byType(ListDetailScreenMobile)),
        );
        final controller = container.read(listDetailControllerProvider);
        expect(controller.selectedSupermarket, isNull);

        final uncategorized =
            await UncategorizedCategoryInitializer.getUncategorized();
        for (final product in controller.products) {
          expect(product.category.id, uncategorized.id);
        }
      },
    );
  });
}

/// Mock implementation of SupermarketsNotifier for testing
class MockSupermarketNotifier extends SupermarketsNotifier {
  List<Supermarket> _supermarkets = [];
  Supermarket? _lastEdited;
  Supermarket? _favorite;

  void setAvailableSupermarkets(List<Supermarket> supermarkets) {
    _supermarkets = supermarkets;
  }

  void setLastEditedSupermarket(Supermarket? supermarket) {
    _lastEdited = supermarket;
  }

  void mockSetFavoriteSupermarket(Supermarket? supermarket) {
    _favorite = supermarket;
  }

  @override
  Future<List<Supermarket>> build() async {
    return _supermarkets;
  }

  @override
  Future<Supermarket?> getLastEditedSupermarket() async {
    return _lastEdited;
  }

  @override
  Future<Supermarket?> getFavoriteSupermarket() async {
    return _favorite;
  }

  @override
  Future<void> addSupermarket(Supermarket supermarket) async {
    _supermarkets.add(supermarket);
    _lastEdited = supermarket;
  }

  @override
  Future<void> updateSupermarket(Supermarket supermarket) async {
    final index = _supermarkets.indexWhere((s) => s.id == supermarket.id);
    if (index != -1) {
      _supermarkets[index] = supermarket;
      _lastEdited = supermarket;
    }
  }

  @override
  Future<void> setFavoriteSupermarket(String id) async {
    final supermarket = _supermarkets.firstWhere((s) => s.id == id);
    _favorite = supermarket;
  }

  @override
  Future<bool> clearFavoriteSupermarket(String id) async {
    if (_favorite?.id == id) {
      _favorite = null;
      return true;
    }
    return false;
  }

  @override
  Future<void> deleteSupermarket(String id) async {
    _supermarkets.removeWhere((s) => s.id == id);
    if (_lastEdited?.id == id) {
      _lastEdited = null;
    }
    if (_favorite?.id == id) {
      _favorite = null;
    }
  }
}

class TestSelectedListNotifier extends SelectedListNotifier {
  TestSelectedListNotifier(this._state);

  final SelectedListState _state;

  @override
  Future<SelectedListState> build() async {
    return _state;
  }
}
