import 'package:app_code/models/category.dart';
import 'package:app_code/providers/real_app_providers/product_categorization_provider.dart';
import 'package:app_code/repositories/test_repo/gemini_repository_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackgroundProductCategorizationNotifier', () {
    test('initial state is empty map', () {
      final container = ProviderContainer();

      final state = container.read(backgroundProductCategorizationProvider);

      expect(state, isEmpty);
    });

    test(
        'startBackgroundCategorization updates state with loading then completed result',
        () async {
      final container = ProviderContainer(
        overrides: [
          productCategorizationRepositoryProvider
              .overrideWithValue(GeminiRepositoryTest()),
        ],
      );

      final notifier =
          container.read(backgroundProductCategorizationProvider.notifier);

      // Start the categorization
      notifier.startBackgroundCategorization(
        id: 'test-milk',
        productName: 'Milk',
        categories: [Category(id: '1', name: 'Dairy')],
      );

      // Immediately after call, state should have loading
      var state = container.read(backgroundProductCategorizationProvider);
      expect(state.containsKey('test-milk'), isTrue);
      expect(state['test-milk']!.isCompleted, isFalse);
      expect(
        state['test-milk']!.result,
        isA<AsyncValue<String>>(),
      );

      // Wait for completion
      await Future.delayed(const Duration(seconds: 6));

      // After completion, state should have result
      state = container.read(backgroundProductCategorizationProvider);
      expect(state['test-milk']!.isCompleted, isTrue);
      expect(state['test-milk']!.productName, 'Milk');
      expect(
        state['test-milk']!.result.maybeWhen(
          data: (category) => category.isNotEmpty,
          orElse: () => false,
        ),
        isTrue,
      );
    });

    test('getCategorization returns the correct state for a specific id',
        () async {
      final container = ProviderContainer(
        overrides: [
          productCategorizationRepositoryProvider
              .overrideWithValue(GeminiRepositoryTest()),
        ],
      );

      final notifier =
          container.read(backgroundProductCategorizationProvider.notifier);

      await notifier.startBackgroundCategorization(
        id: 'test-cheese',
        productName: 'Cheese',
        categories: [Category(id: '1', name: 'Dairy')],
      );

      final result = notifier.getCategorization('test-cheese');

      expect(result, isNotNull);
      expect(result!.id, 'test-cheese');
      expect(result.productName, 'Cheese');
      expect(result.isCompleted, isTrue);
      expect(
        result.result.maybeWhen(
          data: (category) => category == 'Dairy',
          orElse: () => false,
        ),
        isTrue,
      );
    });

    test('getCategorization returns null for missing id', () {
      final container = ProviderContainer();
      final notifier =
          container.read(backgroundProductCategorizationProvider.notifier);

      final result = notifier.getCategorization('nonexistent');

      expect(result, isNull);
    });

    test('clearCategorization removes a specific id from the state', () async {
      final container = ProviderContainer(
        overrides: [
          productCategorizationRepositoryProvider
              .overrideWithValue(GeminiRepositoryTest()),
        ],
      );

      final notifier =
          container.read(backgroundProductCategorizationProvider.notifier);

      // Add two categorizations
      await notifier.startBackgroundCategorization(
        id: 'item-1',
        productName: 'Milk',
        categories: [Category(id: '1', name: 'Dairy')],
      );
      await notifier.startBackgroundCategorization(
        id: 'item-2',
        productName: 'Bread',
        categories: [Category(id: '2', name: 'Bakery')],
      );

      var state = container.read(backgroundProductCategorizationProvider);
      expect(state.length, 2);

      // Clear only item-1
      await notifier.clearCategorization('item-1');

      state = container.read(backgroundProductCategorizationProvider);
      expect(state.length, 1);
      expect(state.containsKey('item-1'), isFalse);
      expect(state.containsKey('item-2'), isTrue);
    });

    test('clearAllCategorizations clears all entries from the state', () async {
      final container = ProviderContainer(
        overrides: [
          productCategorizationRepositoryProvider
              .overrideWithValue(GeminiRepositoryTest()),
        ],
      );

      final notifier =
          container.read(backgroundProductCategorizationProvider.notifier);

      // Add three categorizations
      await notifier.startBackgroundCategorization(
        id: 'cat-1',
        productName: 'Milk',
        categories: [Category(id: '1', name: 'Dairy')],
      );
      await notifier.startBackgroundCategorization(
        id: 'cat-2',
        productName: 'Bread',
        categories: [Category(id: '2', name: 'Bakery')],
      );
      await notifier.startBackgroundCategorization(
        id: 'cat-3',
        productName: 'Apple',
        categories: [Category(id: '3', name: 'Fruits')],
      );

      var state = container.read(backgroundProductCategorizationProvider);
      expect(state.length, 3);

      // Clear all
      await notifier.clearAllCategorizations();

      state = container.read(backgroundProductCategorizationProvider);
      expect(state, isEmpty);
    });

    test('categorization result contains data from GeminiRepositoryTest',
        () async {
      final container = ProviderContainer(
        overrides: [
          productCategorizationRepositoryProvider
              .overrideWithValue(GeminiRepositoryTest()),
        ],
      );

      final notifier =
          container.read(backgroundProductCategorizationProvider.notifier);

      await notifier.startBackgroundCategorization(
        id: 'test-products',
        productName: 'Yogurt',
        categories: [Category(id: '1', name: 'Dairy')],
      );

      final result = notifier.getCategorization('test-products');

      expect(result, isNotNull);
      expect(result!.isCompleted, isTrue);
      // GeminiRepositoryTest categorizes yogurt as Dairy
      expect(
        result.result.maybeWhen(
          data: (category) => category == 'Dairy',
          orElse: () => false,
        ),
        isTrue,
      );
    });

    test('multiple concurrent categorizations are handled correctly', () async {
      final container = ProviderContainer(
        overrides: [
          productCategorizationRepositoryProvider
              .overrideWithValue(GeminiRepositoryTest()),
        ],
      );

      final notifier =
          container.read(backgroundProductCategorizationProvider.notifier);

      // Start multiple categorizations concurrently
      await Future.wait([
        notifier.startBackgroundCategorization(
          id: 'concurrent-1',
          productName: 'Milk',
          categories: [Category(id: '1', name: 'Dairy')],
        ),
        notifier.startBackgroundCategorization(
          id: 'concurrent-2',
          productName: 'Tomato',
          categories: [Category(id: '2', name: 'Vegetables')],
        ),
        notifier.startBackgroundCategorization(
          id: 'concurrent-3',
          productName: 'Chicken',
          categories: [Category(id: '3', name: 'Meat')],
        ),
      ]);

      final state = container.read(backgroundProductCategorizationProvider);

      expect(state.length, 3);
      expect(state['concurrent-1']!.isCompleted, isTrue);
      expect(state['concurrent-2']!.isCompleted, isTrue);
      expect(state['concurrent-3']!.isCompleted, isTrue);
      expect(state['concurrent-1']!.productName, 'Milk');
      expect(state['concurrent-2']!.productName, 'Tomato');
      expect(state['concurrent-3']!.productName, 'Chicken');
    });
  });
}
