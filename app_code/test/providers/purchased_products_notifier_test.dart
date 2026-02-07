import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/providers/real_app_providers/product/product_repositories_provider.dart';
import 'package:app_code/providers/real_app_providers/purchased_products/purchased_products_notifier.dart';
import 'package:app_code/repositories/mock_repo/mock_purchased_product_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PurchasedProductsNotifier', () {
    late MockPurchasedProductRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockPurchasedProductRepository();

      container = ProviderContainer(
        overrides: [
          purchasedProductRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    /// Helper to get the notifier
    PurchasedProductsNotifier getNotifier() =>
        container.read(purchasedProductsProvider.notifier);

    /// Helper to get current state (synchronous access)
    Map<String, PurchasedProduct> getState() {
      return container.read(purchasedProductsProvider);
    }

    /// Helper to create a purchased product
    PurchasedProduct createPurchasedProduct(
      String id,
      String listId,
      Product product,
      Category category, {
      double price = 0.0,
      int quantity = 0,
      bool isDeleted = false,
      bool isBought = false,
    }) =>
        PurchasedProduct(
          id: id,
          listId: listId,
          product: product,
          category: category,
          price: price,
          quantity: quantity,
          isDeleted: isDeleted,
          isBought: isBought,
        );

    /// Helper to create a product
    Product createProduct(String id, String name) {
      final product = Product(id: id, name: name);
      product.setName(name);
      return product;
    }

    /// Helper to create a category
    Category createCategory(String id, String name) =>
        Category(id: id, name: name);

    group('build()', () {
      test('initial state is empty map', () {
        final state = getState();
        expect(state, isEmpty);
        expect(state, isA<Map<String, PurchasedProduct>>());
      });

      test('state starts with no cached products', () {
        final state = getState();
        expect(state.length, 0);
        expect(state.keys, isEmpty);
      });

      test('build is side-effect free', () {
        // Create multiple containers - each should start fresh
        final container1 = ProviderContainer(
          overrides: [
            purchasedProductRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );
        final container2 = ProviderContainer(
          overrides: [
            purchasedProductRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        expect(container1.read(purchasedProductsProvider), isEmpty);
        expect(container2.read(purchasedProductsProvider), isEmpty);

        container1.dispose();
        container2.dispose();
      });
    });

    group('addPurchasedProduct()', () {
      test('adds product to repository', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Apple');
        final category = createCategory('cat-1', 'Fruits');
        final purchasedProduct = createPurchasedProduct(
          'pp-1',
          'list-1',
          product,
          category,
        );

        await notifier.addPurchasedProduct(purchasedProduct);

        expect(mockRepo.addCallCount, 1);
        final repoProducts = await mockRepo.getAll();
        expect(repoProducts.length, 1);
        expect(repoProducts[0].id, 'pp-1');
      });

      test('adds product to local cache', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Apple');
        final category = createCategory('cat-1', 'Fruits');
        final purchasedProduct = createPurchasedProduct(
          'pp-1',
          'list-1',
          product,
          category,
        );

        await notifier.addPurchasedProduct(purchasedProduct);

        final state = getState();
        expect(state.containsKey('pp-1'), isTrue);
        expect(state['pp-1']?.product.getName(), 'Apple');
      });

      test('maintains state immutability', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Apple');
        final category = createCategory('cat-1', 'Fruits');
        final purchasedProduct = createPurchasedProduct(
          'pp-1',
          'list-1',
          product,
          category,
        );

        final stateBefore = getState();
        await notifier.addPurchasedProduct(purchasedProduct);
        final stateAfter = getState();

        expect(identical(stateBefore, stateAfter), isFalse);
      });

      test('adds multiple products correctly', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');

        await notifier.addPurchasedProduct(
          createPurchasedProduct(
            'pp-1',
            'list-1',
            createProduct('prod-1', 'Apple'),
            cat,
          ),
        );
        await notifier.addPurchasedProduct(
          createPurchasedProduct(
            'pp-2',
            'list-1',
            createProduct('prod-2', 'Banana'),
            cat,
          ),
        );
        await notifier.addPurchasedProduct(
          createPurchasedProduct(
            'pp-3',
            'list-1',
            createProduct('prod-3', 'Orange'),
            cat,
          ),
        );

        final state = getState();
        expect(state.length, 3);
        expect(state.keys.toList(), ['pp-1', 'pp-2', 'pp-3']);
        expect(mockRepo.addCallCount, 3);
      });

      test('preserves product properties', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Apple');
        final category = createCategory('cat-1', 'Fruits');
        final purchasedProduct = PurchasedProduct(
          id: 'pp-1',
          listId: 'list-1',
          product: product,
          category: category,
          price: 1.99,
          quantity: 5,
          isBought: true,
        );

        await notifier.addPurchasedProduct(purchasedProduct);

        final state = getState();
        final added = state['pp-1']!;
        expect(added.price, 1.99);
        expect(added.quantity, 5);
        expect(added.isBought, isTrue);
      });

      test('overwrites existing product with same ID in cache', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product1 = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Apple'),
          cat,
          quantity: 1,
        );
        final product2 = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Apple'),
          cat,
          quantity: 5,
        );

        await notifier.addPurchasedProduct(product1);
        await notifier.addPurchasedProduct(product2);

        final state = getState();
        expect(state.length, 1);
        expect(state['pp-1']?.quantity, 5);
        expect(mockRepo.addCallCount, 2);
      });

      test('handles product with zero price', () async {
        final notifier = getNotifier();
        final purchasedProduct = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Free Item'),
          createCategory('cat-1', 'Free'),
          price: 0.0,
        );

        await notifier.addPurchasedProduct(purchasedProduct);

        final state = getState();
        expect(state['pp-1']?.price, 0.0);
      });

      test('handles product with zero quantity', () async {
        final notifier = getNotifier();
        final purchasedProduct = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Item'),
          createCategory('cat-1', 'Some'),
          quantity: 0,
        );

        await notifier.addPurchasedProduct(purchasedProduct);

        final state = getState();
        expect(state['pp-1']?.quantity, 0);
      });

      test('handles product marked as already bought', () async {
        final notifier = getNotifier();
        final purchasedProduct = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Item'),
          createCategory('cat-1', 'Some'),
          isBought: true,
        );

        await notifier.addPurchasedProduct(purchasedProduct);

        final state = getState();
        expect(state['pp-1']?.isBought, isTrue);
      });
    });

    group('updatePurchasedProduct()', () {
      test('updates product in repository', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final original = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Apple'),
          cat,
          quantity: 1,
        );
        await notifier.addPurchasedProduct(original);
        mockRepo.resetCounters();

        final updated = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Apple'),
          cat,
          quantity: 5,
        );
        await notifier.updatePurchasedProduct(updated);

        expect(mockRepo.updateCallCount, 1);
        final repoProducts = await mockRepo.getAll();
        expect(repoProducts.length, 1);
        expect(repoProducts[0].quantity, 5);
      });

      test('updates product in local cache', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final original = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Apple'),
          cat,
          quantity: 1,
        );
        await notifier.addPurchasedProduct(original);

        final updated = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Apple'),
          cat,
          quantity: 5,
        );
        await notifier.updatePurchasedProduct(updated);

        final state = getState();
        expect(state['pp-1']?.quantity, 5);
      });

      test('maintains state immutability', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Apple'),
          cat,
        );
        await notifier.addPurchasedProduct(product);

        final stateBefore = getState();
        final updated = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Apple'),
          cat,
          quantity: 3,
        );
        await notifier.updatePurchasedProduct(updated);
        final stateAfter = getState();

        expect(identical(stateBefore, stateAfter), isFalse);
      });

      test('updates quantity correctly', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Apple'),
          cat,
          quantity: 2,
        );
        await notifier.addPurchasedProduct(product);

        product.quantity = 10;
        await notifier.updatePurchasedProduct(product);

        final state = getState();
        expect(state['pp-1']?.quantity, 10);
      });

      test('updates price correctly', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Apple'),
          cat,
          price: 1.50,
        );
        await notifier.addPurchasedProduct(product);

        product.price = 2.99;
        await notifier.updatePurchasedProduct(product);

        final state = getState();
        expect(state['pp-1']?.price, 2.99);
      });

      test('updates bought status correctly', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Apple'),
          cat,
          isBought: false,
        );
        await notifier.addPurchasedProduct(product);

        product.isBought = true;
        await notifier.updatePurchasedProduct(product);

        final state = getState();
        expect(state['pp-1']?.isBought, isTrue);
      });

      test('handles updating non-existent product gracefully', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final nonExistent = createPurchasedProduct(
          'pp-999',
          'list-1',
          createProduct('prod-999', 'Does Not Exist'),
          cat,
        );

        // Should not throw
        await notifier.updatePurchasedProduct(nonExistent);

        final state = getState();
        // Product should be in cache
        expect(state['pp-999'], isNotNull);
        expect(mockRepo.updateCallCount, 1);
      });

      test('preserves other cached products', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        await notifier.addPurchasedProduct(
          createPurchasedProduct(
            'pp-1',
            'list-1',
            createProduct('prod-1', 'Apple'),
            cat,
          ),
        );
        await notifier.addPurchasedProduct(
          createPurchasedProduct(
            'pp-2',
            'list-1',
            createProduct('prod-2', 'Banana'),
            cat,
          ),
        );
        await notifier.addPurchasedProduct(
          createPurchasedProduct(
            'pp-3',
            'list-1',
            createProduct('prod-3', 'Orange'),
            cat,
          ),
        );

        final updated = createPurchasedProduct(
          'pp-2',
          'list-1',
          createProduct('prod-2', 'Banana'),
          cat,
          quantity: 10,
        );
        await notifier.updatePurchasedProduct(updated);

        final state = getState();
        expect(state.length, 3);
        expect(state['pp-1']?.product.getName(), 'Apple');
        expect(state['pp-2']?.quantity, 10);
        expect(state['pp-3']?.product.getName(), 'Orange');
      });
    });

    group('deletePurchasedProductById()', () {
      test('deletes product from repository', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'To Delete'),
          cat,
        );
        await notifier.addPurchasedProduct(product);
        mockRepo.resetCounters();

        await notifier.deletePurchasedProductById('pp-1');

        expect(mockRepo.deleteByIdCallCount, 1);
        final repoProducts = await mockRepo.getAll();
        expect(repoProducts, isEmpty);
      });

      test('removes product from local cache', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'To Delete'),
          cat,
        );
        await notifier.addPurchasedProduct(product);

        await notifier.deletePurchasedProductById('pp-1');

        final state = getState();
        expect(state.containsKey('pp-1'), isFalse);
      });

      test('maintains state immutability', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Product'),
          cat,
        );
        await notifier.addPurchasedProduct(product);

        final stateBefore = getState();
        await notifier.deletePurchasedProductById('pp-1');
        final stateAfter = getState();

        expect(identical(stateBefore, stateAfter), isFalse);
      });

      test('preserves other cached products', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        await notifier.addPurchasedProduct(
          createPurchasedProduct(
            'pp-1',
            'list-1',
            createProduct('prod-1', 'First'),
            cat,
          ),
        );
        await notifier.addPurchasedProduct(
          createPurchasedProduct(
            'pp-2',
            'list-1',
            createProduct('prod-2', 'Second'),
            cat,
          ),
        );
        await notifier.addPurchasedProduct(
          createPurchasedProduct(
            'pp-3',
            'list-1',
            createProduct('prod-3', 'Third'),
            cat,
          ),
        );

        await notifier.deletePurchasedProductById('pp-2');

        final state = getState();
        expect(state.length, 2);
        expect(state.containsKey('pp-1'), isTrue);
        expect(state.containsKey('pp-2'), isFalse);
        expect(state.containsKey('pp-3'), isTrue);
      });

      test('handles deleting non-existent product gracefully', () async {
        final notifier = getNotifier();

        // Should not throw
        await notifier.deletePurchasedProductById('non-existent-id');

        final state = getState();
        expect(state, isEmpty);
        expect(mockRepo.deleteByIdCallCount, 1);
      });

      test('handles deleting from empty cache', () async {
        final notifier = getNotifier();

        await notifier.deletePurchasedProductById('pp-1');

        final state = getState();
        expect(state, isEmpty);
      });

      test('deletes multiple products sequentially', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        await notifier.addPurchasedProduct(
          createPurchasedProduct(
            'pp-1',
            'list-1',
            createProduct('prod-1', 'First'),
            cat,
          ),
        );
        await notifier.addPurchasedProduct(
          createPurchasedProduct(
            'pp-2',
            'list-1',
            createProduct('prod-2', 'Second'),
            cat,
          ),
        );
        await notifier.addPurchasedProduct(
          createPurchasedProduct(
            'pp-3',
            'list-1',
            createProduct('prod-3', 'Third'),
            cat,
          ),
        );

        await notifier.deletePurchasedProductById('pp-1');
        await notifier.deletePurchasedProductById('pp-3');

        final state = getState();
        expect(state.length, 1);
        expect(state.containsKey('pp-2'), isTrue);
        expect(mockRepo.deleteByIdCallCount, 2);
      });

      test('handles empty string ID gracefully', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        await notifier.addPurchasedProduct(
          createPurchasedProduct(
            'pp-1',
            'list-1',
            createProduct('prod-1', 'Test'),
            cat,
          ),
        );

        await notifier.deletePurchasedProductById('');

        final state = getState();
        expect(state.length, 1); // Original product still there
        expect(mockRepo.deleteByIdCallCount, 1);
      });
    });

    group('getPurchasedProductById()', () {
      test('retrieves existing product from repository', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Test Product'),
          cat,
        );
        await mockRepo.add(product);

        final retrieved = await notifier.getPurchasedProductById('pp-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.id, 'pp-1');
        expect(retrieved.product.getName(), 'Test Product');
        expect(mockRepo.getByIdCallCount, 1);
      });

      test('returns null for non-existent ID', () async {
        final notifier = getNotifier();

        final retrieved = await notifier.getPurchasedProductById('non-existent');

        expect(retrieved, isNull);
        expect(mockRepo.getByIdCallCount, 1);
      });

      test('retrieves deleted product (soft delete)', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Deleted'),
          cat,
          isDeleted: true,
        );
        await mockRepo.add(product);

        final retrieved = await notifier.getPurchasedProductById('pp-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.isDeleted, isTrue);
      });

      test('retrieves product with all properties', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = PurchasedProduct(
          id: 'pp-1',
          listId: 'list-1',
          product: createProduct('prod-1', 'Product'),
          category: cat,
          price: 5.99,
          quantity: 3,
          isBought: true,
        );
        await mockRepo.add(product);

        final retrieved = await notifier.getPurchasedProductById('pp-1');

        expect(retrieved!.price, 5.99);
        expect(retrieved.quantity, 3);
        expect(retrieved.isBought, isTrue);
      });

      test('does not use cache - always queries repository', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'In Repo'),
          cat,
        );
        await mockRepo.add(product);

        // Add different version to cache
        notifier.cachePurchasedProduct(
          createPurchasedProduct(
            'pp-1',
            'list-1',
            createProduct('prod-1', 'In Cache'),
            cat,
          ),
        );

        final retrieved = await notifier.getPurchasedProductById('pp-1');

        // Should get repo version, not cache version
        expect(retrieved!.product.getName(), 'In Repo');
      });

      test('handles empty string ID', () async {
        final notifier = getNotifier();

        final retrieved = await notifier.getPurchasedProductById('');

        expect(retrieved, isNull);
      });
    });

    group('cachePurchasedProduct()', () {
      test('adds product to cache', () {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Cached Product'),
          cat,
        );

        notifier.cachePurchasedProduct(product);

        final state = getState();
        expect(state.containsKey('pp-1'), isTrue);
        expect(state['pp-1']?.product.getName(), 'Cached Product');
      });

      test('does not modify repository', () {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Cached Product'),
          cat,
        );

        notifier.cachePurchasedProduct(product);

        // Repository should still be empty
        expect(mockRepo.getAll(), completion(isEmpty));
        expect(mockRepo.addCallCount, 0);
      });

      test('maintains state immutability', () {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Product'),
          cat,
        );

        final stateBefore = getState();
        notifier.cachePurchasedProduct(product);
        final stateAfter = getState();

        expect(identical(stateBefore, stateAfter), isFalse);
      });

      test('overwrites existing cache entry', () {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product1 = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'First'),
          cat,
          quantity: 1,
        );
        final product2 = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'First'),
          cat,
          quantity: 5,
        );

        notifier.cachePurchasedProduct(product1);
        notifier.cachePurchasedProduct(product2);

        final state = getState();
        expect(state.length, 1);
        expect(state['pp-1']?.quantity, 5);
      });

      test('caches multiple products', () {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');

        notifier.cachePurchasedProduct(
          createPurchasedProduct(
            'pp-1',
            'list-1',
            createProduct('prod-1', 'First'),
            cat,
          ),
        );
        notifier.cachePurchasedProduct(
          createPurchasedProduct(
            'pp-2',
            'list-1',
            createProduct('prod-2', 'Second'),
            cat,
          ),
        );
        notifier.cachePurchasedProduct(
          createPurchasedProduct(
            'pp-3',
            'list-1',
            createProduct('prod-3', 'Third'),
            cat,
          ),
        );

        final state = getState();
        expect(state.length, 3);
        expect(state['pp-1']?.product.getName(), 'First');
        expect(state['pp-2']?.product.getName(), 'Second');
        expect(state['pp-3']?.product.getName(), 'Third');
      });

      test('caches product with complex state', () {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = PurchasedProduct(
          id: 'pp-1',
          listId: 'list-1',
          product: createProduct('prod-1', 'Complex'),
          category: cat,
          price: 9.99,
          quantity: 7,
          isBought: true,
        );

        notifier.cachePurchasedProduct(product);

        final state = getState();
        expect(state['pp-1']?.price, 9.99);
        expect(state['pp-1']?.quantity, 7);
        expect(state['pp-1']?.isBought, isTrue);
      });
    });

    group('getCachedPurchasedProduct()', () {
      test('retrieves cached product by ID', () {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Cached'),
          cat,
        );
        notifier.cachePurchasedProduct(product);

        final retrieved = notifier.getCachedPurchasedProduct('pp-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.id, 'pp-1');
      });

      test('returns null for non-existent cached product', () {
        final notifier = getNotifier();

        final retrieved = notifier.getCachedPurchasedProduct('non-existent');

        expect(retrieved, isNull);
      });

      test('returns null from empty cache', () {
        final notifier = getNotifier();

        final retrieved = notifier.getCachedPurchasedProduct('pp-1');

        expect(retrieved, isNull);
      });

      test('retrieves correct product when multiple are cached', () {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        notifier.cachePurchasedProduct(
          createPurchasedProduct(
            'pp-1',
            'list-1',
            createProduct('prod-1', 'First'),
            cat,
          ),
        );
        notifier.cachePurchasedProduct(
          createPurchasedProduct(
            'pp-2',
            'list-1',
            createProduct('prod-2', 'Second'),
            cat,
          ),
        );
        notifier.cachePurchasedProduct(
          createPurchasedProduct(
            'pp-3',
            'list-1',
            createProduct('prod-3', 'Third'),
            cat,
          ),
        );

        final retrieved = notifier.getCachedPurchasedProduct('pp-2');

        expect(retrieved!.product.getName(), 'Second');
      });

      test('returns product that was added via addPurchasedProduct', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Added'),
          cat,
        );
        await notifier.addPurchasedProduct(product);

        final retrieved = notifier.getCachedPurchasedProduct('pp-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.product.getName(), 'Added');
      });

      test('returns product with all properties', () {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = PurchasedProduct(
          id: 'pp-1',
          listId: 'list-1',
          product: createProduct('prod-1', 'Product'),
          category: cat,
          price: 3.50,
          quantity: 2,
          isBought: false,
        );
        notifier.cachePurchasedProduct(product);

        final retrieved = notifier.getCachedPurchasedProduct('pp-1');

        expect(retrieved!.price, 3.50);
        expect(retrieved.quantity, 2);
        expect(retrieved.isBought, isFalse);
      });
    });

    group('removeCachedProduct()', () {
      test('removes product from cache', () {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'To Remove'),
          cat,
        );
        notifier.cachePurchasedProduct(product);

        notifier.removeCachedProduct('pp-1');

        final state = getState();
        expect(state.containsKey('pp-1'), isFalse);
      });

      test('does not modify repository', () {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'To Remove'),
          cat,
        );
        notifier.cachePurchasedProduct(product);

        notifier.removeCachedProduct('pp-1');

        expect(mockRepo.getAll(), completion(isEmpty));
        expect(mockRepo.deleteByIdCallCount, 0);
      });

      test('maintains state immutability', () {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Product'),
          cat,
        );
        notifier.cachePurchasedProduct(product);

        final stateBefore = getState();
        notifier.removeCachedProduct('pp-1');
        final stateAfter = getState();

        expect(identical(stateBefore, stateAfter), isFalse);
      });

      test('handles removing non-existent product gracefully', () {
        final notifier = getNotifier();

        // Should not throw
        notifier.removeCachedProduct('non-existent');

        final state = getState();
        expect(state, isEmpty);
      });

      test('preserves other cached products', () {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        notifier.cachePurchasedProduct(
          createPurchasedProduct(
            'pp-1',
            'list-1',
            createProduct('prod-1', 'First'),
            cat,
          ),
        );
        notifier.cachePurchasedProduct(
          createPurchasedProduct(
            'pp-2',
            'list-1',
            createProduct('prod-2', 'Second'),
            cat,
          ),
        );
        notifier.cachePurchasedProduct(
          createPurchasedProduct(
            'pp-3',
            'list-1',
            createProduct('prod-3', 'Third'),
            cat,
          ),
        );

        notifier.removeCachedProduct('pp-2');

        final state = getState();
        expect(state.length, 2);
        expect(state.containsKey('pp-1'), isTrue);
        expect(state.containsKey('pp-2'), isFalse);
        expect(state.containsKey('pp-3'), isTrue);
      });

      test('removes product added via addPurchasedProduct', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'To Remove'),
          cat,
        );
        await notifier.addPurchasedProduct(product);

        notifier.removeCachedProduct('pp-1');

        // Repository still has it (no delete)
        final repoProducts = await mockRepo.getAll();
        expect(repoProducts.length, 1);

        // Cache doesn't have it
        final state = getState();
        expect(state.containsKey('pp-1'), isFalse);
      });

      test('removes multiple products sequentially', () {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        notifier.cachePurchasedProduct(
          createPurchasedProduct(
            'pp-1',
            'list-1',
            createProduct('prod-1', 'First'),
            cat,
          ),
        );
        notifier.cachePurchasedProduct(
          createPurchasedProduct(
            'pp-2',
            'list-1',
            createProduct('prod-2', 'Second'),
            cat,
          ),
        );
        notifier.cachePurchasedProduct(
          createPurchasedProduct(
            'pp-3',
            'list-1',
            createProduct('prod-3', 'Third'),
            cat,
          ),
        );

        notifier.removeCachedProduct('pp-1');
        notifier.removeCachedProduct('pp-3');

        final state = getState();
        expect(state.length, 1);
        expect(state.containsKey('pp-2'), isTrue);
      });
    });

    group('Cache vs Repository Consistency', () {
      test('cache can differ from repository content', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Product'),
          cat,
        );

        // Add to repository only
        await mockRepo.add(product);

        // Cache should be empty
        final state = getState();
        expect(state, isEmpty);

        // But repository has it
        final repoProducts = await mockRepo.getAll();
        expect(repoProducts.length, 1);
      });

      test('cache addition does not affect repository', () {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Cached'),
          cat,
        );

        notifier.cachePurchasedProduct(product);

        final state = getState();
        expect(state.length, 1);

        final repoProducts = mockRepo.getAll();
        expect(repoProducts, completion(isEmpty));
      });

      test('add syncs to both cache and repository', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Synced'),
          cat,
        );

        await notifier.addPurchasedProduct(product);

        final state = getState();
        expect(state['pp-1'], isNotNull);

        final repoProducts = await mockRepo.getAll();
        expect(repoProducts.length, 1);
      });

      test('delete syncs to both cache and repository', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'To Delete'),
          cat,
        );
        await notifier.addPurchasedProduct(product);

        await notifier.deletePurchasedProductById('pp-1');

        final state = getState();
        expect(state, isEmpty);

        final repoProducts = await mockRepo.getAll();
        expect(repoProducts, isEmpty);
      });

      test('update syncs to both cache and repository', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final product = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'Product'),
          cat,
          quantity: 1,
        );
        await notifier.addPurchasedProduct(product);

        product.quantity = 5;
        await notifier.updatePurchasedProduct(product);

        final state = getState();
        expect(state['pp-1']?.quantity, 5);

        final repoProducts = await mockRepo.getAll();
        expect(repoProducts[0].quantity, 5);
      });
    });

    group('Edge Cases and Error Handling', () {
      test('handles empty string product ID', () {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');

        // This should still work, client creates ID
        final product = PurchasedProduct(
          id: '',
          listId: 'list-1',
          product: createProduct('prod-1', 'Product'),
          category: cat,
        );

        // Should be cacheable
        notifier.cachePurchasedProduct(product);
        final state = getState();
        expect(state.containsKey(''), isTrue);
      });

      test('handles operations on empty cache', () async {
        final notifier = getNotifier();

        final retrieved = await notifier.getPurchasedProductById('pp-1');
        final cached = notifier.getCachedPurchasedProduct('pp-1');

        expect(retrieved, isNull);
        expect(cached, isNull);
      });

      test('handles rapid sequential operations', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');

        final product1 = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'First'),
          cat,
        );
        final product2 = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'First'),
          cat,
          quantity: 5,
        );

        // Rapid operations
        await notifier.addPurchasedProduct(product1);
        await notifier.updatePurchasedProduct(product2);
        await notifier.deletePurchasedProductById('pp-1');

        final state = getState();
        expect(state, isEmpty);
      });

      test('maintains consistency across cache modifications', () {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');

        final p1 = createPurchasedProduct(
          'pp-1',
          'list-1',
          createProduct('prod-1', 'First'),
          cat,
        );
        final p2 = createPurchasedProduct(
          'pp-2',
          'list-1',
          createProduct('prod-2', 'Second'),
          cat,
        );

        notifier.cachePurchasedProduct(p1);
        notifier.cachePurchasedProduct(p2);
        notifier.removeCachedProduct('pp-1');
        notifier.cachePurchasedProduct(p1);

        final state = getState();
        expect(state.length, 2);
        expect(state['pp-1'], isA<PurchasedProduct>());
        expect(state['pp-2'], isA<PurchasedProduct>());
      });
    });
  });
}
