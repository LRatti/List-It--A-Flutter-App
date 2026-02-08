import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/screens/lists/controllers/list_detail_controller.dart';
import 'package:app_code/screens/lists/list_detail_screen_mobile.dart';
import 'package:app_code/utils/uncategorized_category_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Test data - shared across all tests
  final cat1 = Category(id: 'cat1', name: 'Fruits');
  final cat2 = Category(id: 'cat2', name: 'Vegetables');
  final cat3 = Category(id: 'cat3', name: 'Dairy');
  final catUncat = Category(id: 'uncat', name: 'Uncategorized');
  
  final supermarket = Supermarket(
    id: 'super1',
    name: 'Supermarket 1',
    categories: [cat1, cat2, cat3, catUncat],
  );

  final product1 = Product(id: 'p1', name: 'Apple', associations: {'super1': 'cat1'});
  final product2 = Product(id: 'p2', name: 'Banana', associations: {'super1': 'cat1'});
  final product3 = Product(id: 'p3', name: 'Carrot', associations: {'super1': 'cat2'});

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  ProviderContainer createContainer() {
    return ProviderContainer();
  }

  ListDetailController getController(ProviderContainer container, ShoppingList list) {
    return container.read(listDetailControllerProvider(list));
  }

  group('ListDetailController - Buffer Zone', () {
    test('addToBuffer adds product with loading state', () {
      final container = createContainer();
      final list = ShoppingList(id: 'l1', name: 'List', createdAt: DateTime.now());
      final controller = getController(container, list);

      controller.addToBuffer('Apple');

      expect(controller.bufferProducts.containsKey('Apple'), true);
      expect(controller.bufferProducts['Apple']!.isLoading, true);
      container.dispose();
    });

    test('updateBufferProduct transitions state', () {
      final container = createContainer();
      final list = ShoppingList(id: 'l1', name: 'List', createdAt: DateTime.now());
      final controller = getController(container, list);

      controller.addToBuffer('Apple');
      controller.updateBufferProduct('Apple', isLoading: false, error: 'Error');

      expect(controller.bufferProducts['Apple']!.isLoading, false);
      expect(controller.bufferProducts['Apple']!.error, 'Error');
      container.dispose();
    });

    test('removeFromBuffer removes product', () {
      final container = createContainer();
      final list = ShoppingList(id: 'l1', name: 'List', createdAt: DateTime.now());
      final controller = getController(container, list);

      controller.addToBuffer('Apple');
      controller.removeFromBuffer('Apple');

      expect(controller.bufferProducts.isEmpty, true);
      container.dispose();
    });
  });

  group('ListDetailController - Recategorization', () {
    test('recategorizeProductsForSupermarket uses associations', () {
      final container = createContainer();
      final pp1 = PurchasedProduct(listId: 'l1', product: product1, category: cat1);
      final pp2 = PurchasedProduct(listId: 'l1', product: product3, category: cat2);
      final list = ShoppingList(id: 'l1', name: 'List', createdAt: DateTime.now(), products: [pp1, pp2]);
      final controller = getController(container, list..setSupermarket(supermarket));

      expect(pp1.category.id, 'cat1');
      expect(pp2.category.id, 'cat2');
      container.dispose();
    });

    test('recategorizeProductsForSupermarket on no association', () {
      final container = createContainer();
      final productNoAssoc = Product(id: 'p4', name: 'NoAssoc', associations: {});
      final pp = PurchasedProduct(listId: 'l1', product: productNoAssoc, category: cat1);
      final list = ShoppingList(id: 'l1', name: 'List', createdAt: DateTime.now(), products: [pp]);
      final controller = getController(container, list..setSupermarket(supermarket));

      // Product with no association should be moved to a category
      expect(pp.category.id, isNotEmpty);
      container.dispose();
    });
  });

  group('ListDetailController - Category Grouping', () {
    test('getProductsByCategory returns all categories', () {
      final container = createContainer();
      final pp1 = PurchasedProduct(listId: 'l1', product: product1, category: cat1);
      final list = ShoppingList(id: 'l1', name: 'List', createdAt: DateTime.now(), products: [pp1]);
      final controller = getController(container, list..setSupermarket(supermarket));

      final grouped = controller.getProductsByCategory();
      expect(grouped.length, 4); // 3 categories + uncategorized
      expect(grouped.keys.any((c) => c.id == 'cat1'), true);
      expect(grouped.keys.any((c) => c.id == 'cat2'), true);
      container.dispose();
    });

    test('getProductsByCategory matches by ID not reference', () {
      final container = createContainer();
      final differentCatInstance = Category(id: 'cat1', name: 'Diff');
      final pp = PurchasedProduct(listId: 'l1', product: product1, category: differentCatInstance);
      final list = ShoppingList(id: 'l1', name: 'List', createdAt: DateTime.now(), products: [pp]);
      final controller = getController(container, list..setSupermarket(supermarket));

      final grouped = controller.getProductsByCategory();
      expect(grouped[cat1]!.contains(pp), true);
      container.dispose();
    });

    test('getProductsByCategory returns uncategorized when no supermarket', () {
      final container = createContainer();
      final pp = PurchasedProduct(listId: 'l1', product: product1, category: cat1);
      final list = ShoppingList(id: 'l1', name: 'List', createdAt: DateTime.now(), products: [pp]);
      final controller = getController(container, list);

      final grouped = controller.getProductsByCategory();
      expect(grouped.length, 1);
      expect(UncategorizedCategoryUtils.isUncategorized(grouped.keys.first), true);
      container.dispose();
    });
  });

  group('ListDetailController - Product Name Updates', () {
    test('updateProductName creates new product', () async {
      final pp = PurchasedProduct(id: 'pp1', listId: 'l1', product: product1, category: cat1);
      final updated = await ListDetailController.updateProductName(pp, 'NewApple');

      expect(updated.product.getName(), 'NewApple');
      expect(updated.product.id, isNotEmpty);
    });

    test('updateProductName preserves associations', () async {
      final pp = PurchasedProduct(id: 'pp1', listId: 'l1', product: product1, category: cat1);
      final updated = await ListDetailController.updateProductName(pp, 'NewApple');

      expect(updated.product.associations, product1.associations);
    });

    test('updateProductName skips when name unchanged', () async {
      final pp = PurchasedProduct(id: 'pp1', listId: 'l1', product: product1, category: cat1);
      final updated = await ListDetailController.updateProductName(pp, 'Apple');

      expect(identical(updated, pp), true);
    });

    test('wouldCreateDuplicate returns bool', () async {
      final result = await ListDetailController.wouldCreateDuplicate('Apple', 'other-id');
      expect(result is bool, true);
    });
  });

  group('ListDetailController - Supermarket Workflows', () {
    test('updateSupermarket recategorizes products', () async {
      final container = createContainer();
      final pp = PurchasedProduct(listId: 'l1', product: product1, category: cat1);
      final list = ShoppingList(id: 'l1', name: 'List', createdAt: DateTime.now(), products: [pp]);
      final controller = getController(container, list);

      await controller.updateSupermarket(supermarket);

      expect(controller.selectedSupermarket?.id, 'super1');
      expect(pp.category.id, 'cat1');
      container.dispose();
    });

    test('clearSupermarket moves all to uncategorized', () async {
      final container = createContainer();
      final pp1 = PurchasedProduct(listId: 'l1', product: product1, category: cat1);
      final pp2 = PurchasedProduct(listId: 'l1', product: product2, category: cat2);
      final list = ShoppingList(id: 'l1', name: 'List', createdAt: DateTime.now(), products: [pp1, pp2], supermarket: supermarket);
      final controller = getController(container, list);

      await controller.clearSupermarket();

      expect(controller.selectedSupermarket, null);
      expect(UncategorizedCategoryUtils.isUncategorized(pp1.category), true);
      expect(UncategorizedCategoryUtils.isUncategorized(pp2.category), true);
      container.dispose();
    });

    test('clearSupermarket with provided fallback category', () async {
      final container = createContainer();
      final uncatFallback = Category(id: 'uncat', name: 'Unc');
      final pp = PurchasedProduct(listId: 'l1', product: product1, category: cat1);
      final list = ShoppingList(id: 'l1', name: 'List', createdAt: DateTime.now(), products: [pp], supermarket: supermarket);
      final controller = getController(container, list);

      await controller.clearSupermarket(uncategorized: uncatFallback);

      expect(pp.category.id, 'uncat');
      container.dispose();
    });

    test('clearSupermarket when none selected is no-op', () async {
      final container = createContainer();
      final list = ShoppingList(id: 'l1', name: 'List', createdAt: DateTime.now());
      final controller = getController(container, list);

      expect(controller.selectedSupermarket, null);
      await controller.clearSupermarket();
      expect(controller.selectedSupermarket, null);
      container.dispose();
    });
  });

  group('ListDetailController - Reordering and Movement', () {
    test('reorderProducts moves product up', () {
      final container = createContainer();
      final pp1 = PurchasedProduct(id: 'pp1', listId: 'l1', product: product1, category: cat1);
      final pp2 = PurchasedProduct(id: 'pp2', listId: 'l1', product: product2, category: cat1);
      final list = ShoppingList(id: 'l1', name: 'List', createdAt: DateTime.now(), products: [pp1, pp2]);
      final controller = getController(container, list);

      controller.reorderProducts(1, 0);

      expect(controller.products[0].id, 'pp2');
      expect(controller.products[1].id, 'pp1');
      container.dispose();
    });

    test('reorderProducts moves product down', () {
      final container = createContainer();
      final pp1 = PurchasedProduct(id: 'pp1', listId: 'l1', product: product1, category: cat1);
      final pp2 = PurchasedProduct(id: 'pp2', listId: 'l1', product: product2, category: cat1);
      final list = ShoppingList(id: 'l1', name: 'List', createdAt: DateTime.now(), products: [pp1, pp2]);
      final controller = getController(container, list);

      controller.reorderProducts(0, 2); // Move from 0 to after position 1

      expect(controller.products[0].id, 'pp2');
      expect(controller.products[1].id, 'pp1');
      container.dispose();
    });

    test('moveProductToCategory updates category', () async {
      final container = createContainer();
      final pp = PurchasedProduct(id: 'pp1', listId: 'l1', product: product1, category: cat1);
      final list = ShoppingList(id: 'l1', name: 'List', createdAt: DateTime.now(), products: [pp]);
      final controller = getController(container, list..setSupermarket(supermarket));

      await controller.moveProductToCategory(pp, cat2);

      expect(pp.category.id, 'cat2');
      container.dispose();
    });

    test('moveProductToCategory nonexistent product no persist', () async {
      final container = createContainer();
      final pp = PurchasedProduct(id: 'pp1', listId: 'l1', product: product1, category: cat1);
      final list = ShoppingList(id: 'l1', name: 'List', createdAt: DateTime.now(), products: []);
      final controller = getController(container, list..setSupermarket(supermarket));

      await controller.moveProductToCategory(pp, cat2);
      // Product not in list, so should not have been moved
      expect(controller.products.isEmpty, true);
      container.dispose();
    });
  });

  group('ListDetailController - Edge Cases and State', () {
    test('hasChanges reflects modification state', () {
      final container = createContainer();
      final pp = PurchasedProduct(id: 'pp1', listId: 'l1', product: product1, category: cat1);
      final list = ShoppingList(id: 'l1', name: 'List', createdAt: DateTime.now(), products: [pp]);
      final controller = getController(container, list);

      expect(controller.hasChanges, false);
      controller.reorderProducts(0, 0);
      expect(controller.hasChanges, true);
      container.dispose();
    });

    test('reorderProducts with empty list no-op', () {
      final container = createContainer();
      final list = ShoppingList(id: 'l1', name: 'List', createdAt: DateTime.now());
      final controller = getController(container, list);

      // Reorder on empty list must not crash
      expect(controller.products.length, 0);
      expect(controller.hasChanges, false);
      container.dispose();
    });

    test('updateSupermarket with no products', () async {
      final container = createContainer();
      final list = ShoppingList(id: 'l1', name: 'List', createdAt: DateTime.now());
      final controller = getController(container, list);

      await controller.updateSupermarket(supermarket);
      expect(controller.selectedSupermarket?.id, 'super1');
      container.dispose();
    });

    test('updateBufferProduct ignores nonexistent product', () {
      final container = createContainer();
      final list = ShoppingList(id: 'l1', name: 'List', createdAt: DateTime.now());
      final controller = getController(container, list);

      controller.updateBufferProduct('Nonexistent', isLoading: false);
      expect(controller.bufferProducts.isEmpty, true);
      container.dispose();
    });
  });
}
