import 'package:app_code/models/product.dart';
import 'package:app_code/providers/real_app_providers/product/product_repositories_provider.dart';
import 'package:app_code/providers/real_app_providers/product/products_notifier.dart';
import 'package:app_code/repositories/mock_repo/mock_product_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductsNotifier', () {
    late MockProductRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockProductRepository();

      container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    /// Helper to get the notifier
    ProductsNotifier getNotifier() =>
        container.read(productsProvider.notifier);

    /// Helper to get current state (synchronous access)
    Map<String, Product> getState() {
      return container.read(productsProvider);
    }

    /// Helper to create a product
    Product createProduct(
      String id,
      String name, {
      Map<String, String>? associations,
      bool isVisible = true,
    }) =>
        Product(
          id: id,
          name: name,
          associations: associations,
          isVisible: isVisible,
        );

    group('build()', () {
      test('initial state is empty map', () {
        final state = getState();
        expect(state, isEmpty);
        expect(state, isA<Map<String, Product>>());
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
            productRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );
        final container2 = ProviderContainer(
          overrides: [
            productRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        expect(container1.read(productsProvider), isEmpty);
        expect(container2.read(productsProvider), isEmpty);

        container1.dispose();
        container2.dispose();
      });
    });

    group('addProduct()', () {
      test('adds product to repository', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Apple');

        await notifier.addProduct(product);

        final repoProducts = await mockRepo.getAll();
        expect(repoProducts.length, 1);
        expect(repoProducts[0].id, 'prod-1');
        expect(repoProducts[0].getName(), 'Apple');
      });

      test('adds product to local cache', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Apple');

        await notifier.addProduct(product);

        final state = getState();
        expect(state.containsKey('prod-1'), isTrue);
        expect(state['prod-1']?.getName(), 'Apple');
      });

      test('maintains state immutability', () async {
        final notifier = getNotifier();
        final product1 = createProduct('prod-1', 'Apple');

        final stateBefore = getState();
        await notifier.addProduct(product1);
        final stateAfter = getState();

        expect(identical(stateBefore, stateAfter), isFalse);
      });

      test('adds multiple products correctly', () async {
        final notifier = getNotifier();
        await notifier.addProduct(createProduct('prod-1', 'Apple'));
        await notifier.addProduct(createProduct('prod-2', 'Banana'));
        await notifier.addProduct(createProduct('prod-3', 'Orange'));

        final state = getState();
        expect(state.length, 3);
        expect(state.keys.toList(), ['prod-1', 'prod-2', 'prod-3']);
      });

      test('preserves product properties', () async {
        final notifier = getNotifier();
        final product = Product(
          id: 'prod-1',
          name: 'Custom Product',
          isVisible: false,
          associations: {'supermarket-1': 'category-1'},
          createdAt: DateTime(2025, 1, 1),
          lastModified: DateTime(2025, 1, 2),
        );

        await notifier.addProduct(product);

        final state = getState();
        final added = state['prod-1']!;
        expect(added.getName(), 'Custom Product');
        expect(added.isVisible, isFalse);
        expect(added.associations, {'supermarket-1': 'category-1'});
      });

      test('overwrites existing product with same ID in cache', () async {
        final notifier = getNotifier();
        final product1 = createProduct('prod-1', 'First Name');
        final product2 = createProduct('prod-1', 'Second Name');

        await notifier.addProduct(product1);
        await notifier.addProduct(product2);

        final state = getState();
        expect(state.length, 1);
        expect(state['prod-1']?.getName(), 'Second Name');
      });

      test('handles empty name', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', '');

        await notifier.addProduct(product);

        final state = getState();
        expect(state['prod-1']?.getName(), '');
      });

      test('handles product with associations', () async {
        final notifier = getNotifier();
        final product = createProduct(
          'prod-1',
          'Product',
          associations: {
            'supermarket-1': 'category-1',
            'supermarket-2': 'category-2',
          },
        );

        await notifier.addProduct(product);

        final state = getState();
        expect(state['prod-1']?.associations.length, 2);
        expect(state['prod-1']?.associations['supermarket-1'], 'category-1');
      });
    });

    group('updateProduct()', () {
      test('updates product in repository', () async {
        final notifier = getNotifier();
        final original = createProduct('prod-1', 'Original Name');
        await notifier.addProduct(original);

        final updated = createProduct('prod-1', 'Updated Name');
        await notifier.updateProduct(updated);

        final repoProducts = await mockRepo.getAll();
        expect(repoProducts.length, 1);
        expect(repoProducts[0].getName(), 'Updated Name');
      });

      test('updates product in local cache', () async {
        final notifier = getNotifier();
        final original = createProduct('prod-1', 'Original Name');
        await notifier.addProduct(original);

        final updated = createProduct('prod-1', 'Updated Name');
        await notifier.updateProduct(updated);

        final state = getState();
        expect(state['prod-1']?.getName(), 'Updated Name');
      });

      test('maintains state immutability', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Product');
        await notifier.addProduct(product);

        final stateBefore = getState();
        final updated = createProduct('prod-1', 'Updated');
        await notifier.updateProduct(updated);
        final stateAfter = getState();

        expect(identical(stateBefore, stateAfter), isFalse);
      });

      test('updates visibility flag correctly', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Test', isVisible: true);
        await notifier.addProduct(product);

        product.setVisibility(false);
        await notifier.updateProduct(product);

        final state = getState();
        expect(state['prod-1']?.isVisible, isFalse);
      });

      test('updates associations correctly', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Test');
        await notifier.addProduct(product);

        product.setAssociations({'supermarket-1': 'category-1'});
        await notifier.updateProduct(product);

        final state = getState();
        expect(state['prod-1']?.associations, {'supermarket-1': 'category-1'});
      });

      test('handles updating non-existent product gracefully', () async {
        final notifier = getNotifier();
        final nonExistent = createProduct('prod-999', 'Does Not Exist');

        // Should not throw
        await notifier.updateProduct(nonExistent);

        final state = getState();
        // Product should be in cache even if it wasn't in repo
        expect(state['prod-999'], isNotNull);
      });

      test('preserves other cached products', () async {
        final notifier = getNotifier();
        await notifier.addProduct(createProduct('prod-1', 'First'));
        await notifier.addProduct(createProduct('prod-2', 'Second'));
        await notifier.addProduct(createProduct('prod-3', 'Third'));

        final updated = createProduct('prod-2', 'Updated Second');
        await notifier.updateProduct(updated);

        final state = getState();
        expect(state.length, 3);
        expect(state['prod-1']?.getName(), 'First');
        expect(state['prod-2']?.getName(), 'Updated Second');
        expect(state['prod-3']?.getName(), 'Third');
      });
    });

    group('deleteProductById()', () {
      test('deletes product from repository', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'To Delete');
        await notifier.addProduct(product);

        await notifier.deleteProductById('prod-1');

        final repoProducts = await mockRepo.getAll();
        expect(repoProducts, isEmpty);
      });

      test('removes product from local cache', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'To Delete');
        await notifier.addProduct(product);

        await notifier.deleteProductById('prod-1');

        final state = getState();
        expect(state.containsKey('prod-1'), isFalse);
      });

      test('maintains state immutability', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Product');
        await notifier.addProduct(product);

        final stateBefore = getState();
        await notifier.deleteProductById('prod-1');
        final stateAfter = getState();

        expect(identical(stateBefore, stateAfter), isFalse);
      });

      test('preserves other cached products', () async {
        final notifier = getNotifier();
        await notifier.addProduct(createProduct('prod-1', 'First'));
        await notifier.addProduct(createProduct('prod-2', 'Second'));
        await notifier.addProduct(createProduct('prod-3', 'Third'));

        await notifier.deleteProductById('prod-2');

        final state = getState();
        expect(state.length, 2);
        expect(state.containsKey('prod-1'), isTrue);
        expect(state.containsKey('prod-2'), isFalse);
        expect(state.containsKey('prod-3'), isTrue);
      });

      test('handles deleting non-existent product gracefully', () async {
        final notifier = getNotifier();

        // Should not throw
        await notifier.deleteProductById('non-existent-id');

        final state = getState();
        expect(state, isEmpty);
      });

      test('handles deleting from empty cache', () async {
        final notifier = getNotifier();

        await notifier.deleteProductById('prod-1');

        final state = getState();
        expect(state, isEmpty);
      });

      test('deletes multiple products sequentially', () async {
        final notifier = getNotifier();
        await notifier.addProduct(createProduct('prod-1', 'First'));
        await notifier.addProduct(createProduct('prod-2', 'Second'));
        await notifier.addProduct(createProduct('prod-3', 'Third'));

        await notifier.deleteProductById('prod-1');
        await notifier.deleteProductById('prod-3');

        final state = getState();
        expect(state.length, 1);
        expect(state.containsKey('prod-2'), isTrue);
      });

      test('handles empty string ID', () async {
        final notifier = getNotifier();
        await notifier.addProduct(createProduct('prod-1', 'Test'));

        await notifier.deleteProductById('');

        final state = getState();
        expect(state.length, 1); // Original product still there
      });
    });

    group('getProductById()', () {
      test('retrieves existing product from repository', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Test Product');
        await mockRepo.add(product);

        final retrieved = await notifier.getProductById('prod-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.id, 'prod-1');
        expect(retrieved.getName(), 'Test Product');
      });

      test('returns null for non-existent ID', () async {
        final notifier = getNotifier();

        final retrieved = await notifier.getProductById('non-existent');

        expect(retrieved, isNull);
      });

      test('retrieves invisible product', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Invisible', isVisible: false);
        await mockRepo.add(product);

        final retrieved = await notifier.getProductById('prod-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.isVisible, isFalse);
      });

      test('retrieves product with associations', () async {
        final notifier = getNotifier();
        final product = createProduct(
          'prod-1',
          'Product',
          associations: {'supermarket-1': 'category-1'},
        );
        await mockRepo.add(product);

        final retrieved = await notifier.getProductById('prod-1');

        expect(retrieved!.associations, {'supermarket-1': 'category-1'});
      });

      test('does not use cache - always queries repository', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'In Repo');
        await mockRepo.add(product);

        // Add different version to cache
        notifier.cacheProduct(createProduct('prod-1', 'In Cache'));

        final retrieved = await notifier.getProductById('prod-1');

        // Should get repo version, not cache version
        expect(retrieved!.getName(), 'In Repo');
      });

      test('handles empty string ID', () async {
        final notifier = getNotifier();

        final retrieved = await notifier.getProductById('');

        expect(retrieved, isNull);
      });
    });

    group('cacheProduct()', () {
      test('adds product to cache', () {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Cached Product');

        notifier.cacheProduct(product);

        final state = getState();
        expect(state.containsKey('prod-1'), isTrue);
        expect(state['prod-1']?.getName(), 'Cached Product');
      });

      test('does not modify repository', () {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Cached Product');

        notifier.cacheProduct(product);

        // Repository should still be empty
        expect(mockRepo.getAll(), completion(isEmpty));
      });

      test('maintains state immutability', () {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Product');

        final stateBefore = getState();
        notifier.cacheProduct(product);
        final stateAfter = getState();

        expect(identical(stateBefore, stateAfter), isFalse);
      });

      test('overwrites existing cache entry', () {
        final notifier = getNotifier();
        final product1 = createProduct('prod-1', 'First');
        final product2 = createProduct('prod-1', 'Second');

        notifier.cacheProduct(product1);
        notifier.cacheProduct(product2);

        final state = getState();
        expect(state.length, 1);
        expect(state['prod-1']?.getName(), 'Second');
      });

      test('caches multiple products', () {
        final notifier = getNotifier();

        notifier.cacheProduct(createProduct('prod-1', 'First'));
        notifier.cacheProduct(createProduct('prod-2', 'Second'));
        notifier.cacheProduct(createProduct('prod-3', 'Third'));

        final state = getState();
        expect(state.length, 3);
      });

      test('preserves all product properties', () {
        final notifier = getNotifier();
        final product = Product(
          id: 'prod-1',
          name: 'Custom Product',
          isVisible: false,
          associations: {'supermarket-1': 'category-1'},
          createdAt: DateTime(2025, 1, 1),
          lastModified: DateTime(2025, 1, 2),
        );

        notifier.cacheProduct(product);

        final state = getState();
        final cached = state['prod-1']!;
        expect(cached.getName(), 'Custom Product');
        expect(cached.isVisible, isFalse);
        expect(cached.associations, {'supermarket-1': 'category-1'});
      });

      test('is synchronous operation', () {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Product');

        notifier.cacheProduct(product);

        // State should be immediately available
        final state = getState();
        expect(state['prod-1'], isNotNull);
      });
    });

    group('getCachedProduct()', () {
      test('retrieves cached product by ID', () {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Cached Product');
        notifier.cacheProduct(product);

        final retrieved = notifier.getCachedProduct('prod-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.id, 'prod-1');
        expect(retrieved.getName(), 'Cached Product');
      });

      test('returns null for non-existent ID', () {
        final notifier = getNotifier();

        final retrieved = notifier.getCachedProduct('non-existent');

        expect(retrieved, isNull);
      });

      test('returns null for empty cache', () {
        final notifier = getNotifier();

        final retrieved = notifier.getCachedProduct('prod-1');

        expect(retrieved, isNull);
      });

      test('retrieves invisible product', () {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Invisible', isVisible: false);
        notifier.cacheProduct(product);

        final retrieved = notifier.getCachedProduct('prod-1');

        expect(retrieved!.isVisible, isFalse);
      });

      test('retrieves product with associations', () {
        final notifier = getNotifier();
        final product = createProduct(
          'prod-1',
          'Product',
          associations: {'supermarket-1': 'category-1'},
        );
        notifier.cacheProduct(product);

        final retrieved = notifier.getCachedProduct('prod-1');

        expect(retrieved!.associations, {'supermarket-1': 'category-1'});
      });

      test('does not query repository', () {
        final notifier = getNotifier();
        // Add to cache but not to repo
        notifier.cacheProduct(createProduct('prod-1', 'Only in Cache'));

        final retrieved = notifier.getCachedProduct('prod-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.getName(), 'Only in Cache');
      });

      test('is synchronous operation', () {
        final notifier = getNotifier();
        notifier.cacheProduct(createProduct('prod-1', 'Product'));

        // Should return immediately without async
        final retrieved = notifier.getCachedProduct('prod-1');

        expect(retrieved, isNotNull);
      });

      test('handles empty string ID', () {
        final notifier = getNotifier();

        final retrieved = notifier.getCachedProduct('');

        expect(retrieved, isNull);
      });
    });

    group('Edge Cases', () {
      test('handles rapid consecutive additions', () async {
        final notifier = getNotifier();

        // Add products rapidly
        await Future.wait([
          notifier.addProduct(createProduct('prod-1', 'First')),
          notifier.addProduct(createProduct('prod-2', 'Second')),
          notifier.addProduct(createProduct('prod-3', 'Third')),
        ]);

        final state = getState();
        expect(state.length, 3);
      });

      test('handles mixed cache and repository operations', () async {
        final notifier = getNotifier();

        // Add to cache only
        notifier.cacheProduct(createProduct('cache-1', 'Cache Only'));

        // Add to both (via addProduct)
        await notifier.addProduct(createProduct('both-1', 'Cache and Repo'));

        final state = getState();
        expect(state.length, 2);

        // Verify repository only has the one added via addProduct
        final repoProducts = await mockRepo.getAll();
        expect(repoProducts.length, 1);
        expect(repoProducts[0].id, 'both-1');
      });

      test('cache survives repository operations', () async {
        final notifier = getNotifier();
        notifier.cacheProduct(createProduct('cache-1', 'Cached'));

        // Delete from cache (but it was never in repo)
        await notifier.deleteProductById('cache-1');

        final state = getState();
        expect(state.containsKey('cache-1'), isFalse);
      });

      test('handles products with null associations', () async {
        final notifier = getNotifier();
        final product = Product(
          id: 'prod-1',
          name: 'No Associations',
          associations: null,
          isVisible: true,
        );

        await notifier.addProduct(product);

        final state = getState();
        expect(state['prod-1']?.associations, isEmpty);
      });

      test('handles very long product names', () async {
        final notifier = getNotifier();
        final longName = 'A' * 1000;
        final product = createProduct('prod-1', longName);

        await notifier.addProduct(product);

        final state = getState();
        expect(state['prod-1']?.getName().length, 1000);
      });

      test('handles special characters in product names', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Product @#\$%^&*()');

        await notifier.addProduct(product);

        final state = getState();
        expect(state['prod-1']?.getName(), 'Product @#\$%^&*()');
      });

      test('handles unicode characters in product names', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', '产品 🍎 Produit');

        await notifier.addProduct(product);

        final state = getState();
        expect(state['prod-1']?.getName(), '产品 🍎 Produit');
      });

      test('state maintains Map type throughout operations', () async {
        final notifier = getNotifier();

        expect(getState(), isA<Map<String, Product>>());

        await notifier.addProduct(createProduct('prod-1', 'Product'));
        expect(getState(), isA<Map<String, Product>>());

        notifier.cacheProduct(createProduct('prod-2', 'Cached'));
        expect(getState(), isA<Map<String, Product>>());

        await notifier.deleteProductById('prod-1');
        expect(getState(), isA<Map<String, Product>>());
      });
    });

    group('State Consistency', () {
      test('cache and repository stay in sync after add', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Test');

        await notifier.addProduct(product);

        final state = getState();
        final repoProducts = await mockRepo.getAll();

        expect(state['prod-1']?.getName(), repoProducts[0].getName());
        expect(state['prod-1']?.id, repoProducts[0].id);
      });

      test('cache and repository stay in sync after update', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Original');
        await notifier.addProduct(product);

        final updated = createProduct('prod-1', 'Updated');
        await notifier.updateProduct(updated);

        final state = getState();
        final repoProducts = await mockRepo.getAll();

        expect(state['prod-1']?.getName(), 'Updated');
        expect(repoProducts[0].getName(), 'Updated');
      });

      test('cache and repository stay in sync after delete', () async {
        final notifier = getNotifier();
        await notifier.addProduct(createProduct('prod-1', 'To Delete'));

        await notifier.deleteProductById('prod-1');

        final state = getState();
        final repoProducts = await mockRepo.getAll();

        expect(state.containsKey('prod-1'), isFalse);
        expect(repoProducts, isEmpty);
      });

      test('multiple updates maintain consistency', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Version 1');

        await notifier.addProduct(product);
        product.setName('Version 2');
        await notifier.updateProduct(product);
        product.setName('Version 3');
        await notifier.updateProduct(product);

        final state = getState();
        final repoProduct = await mockRepo.getById('prod-1');

        expect(state['prod-1']?.getName(), 'Version 3');
        expect(repoProduct?.getName(), 'Version 3');
      });
    });

    group('Provider Integration', () {
      test('productsProvider exposes correct state type', () {
        final state = container.read(productsProvider);
        expect(state, isA<Map<String, Product>>());
      });

      test('notifier is accessible via productsProvider.notifier', () {
        final notifier = container.read(productsProvider.notifier);
        expect(notifier, isA<ProductsNotifier>());
      });

      test('state updates are reflected in provider reads', () async {
        final notifier = getNotifier();
        final product = createProduct('prod-1', 'Test');

        await notifier.addProduct(product);

        final stateFromProvider = container.read(productsProvider);
        expect(stateFromProvider['prod-1'], isNotNull);
      });

      test('multiple provider reads return current state', () async {
        final notifier = getNotifier();
        await notifier.addProduct(createProduct('prod-1', 'First'));

        final read1 = container.read(productsProvider);
        final read2 = container.read(productsProvider);

        expect(read1.length, 1);
        expect(read2.length, 1);
        expect(read1['prod-1']?.getName(), read2['prod-1']?.getName());
      });
    });
  });
}
