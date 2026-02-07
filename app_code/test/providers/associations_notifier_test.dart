import 'package:app_code/providers/real_app_providers/associations/associations_notifier.dart';
import 'package:app_code/providers/real_app_providers/product/product_repositories_provider.dart';
import 'package:app_code/repositories/abstract/association_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_association_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssociationsNotifier', () {
    late MockAssociationRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockAssociationRepository();

      container = ProviderContainer(
        overrides: [
          associationRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    /// Helper to get the notifier
    AssociationsNotifier getNotifier() =>
        container.read(associationsProvider.notifier);

    /// Helper to get current state (synchronous access)
    AssociationMap getState() {
      return container.read(associationsProvider);
    }

    group('build()', () {
      test('initial state is empty map', () {
        final state = getState();
        expect(state, isEmpty);
        expect(state, isA<Map<String, Map<String, String>>>());
      });

      test('state starts with no pending associations', () {
        final state = getState();
        expect(state.length, 0);
        expect(state.keys, isEmpty);
      });

      test('build is side-effect free', () {
        // Create multiple containers - each should start fresh
        final container1 = ProviderContainer(
          overrides: [
            associationRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );
        final container2 = ProviderContainer(
          overrides: [
            associationRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        expect(container1.read(associationsProvider), isEmpty);
        expect(container2.read(associationsProvider), isEmpty);

        container1.dispose();
        container2.dispose();
      });
    });

    group('markAssociationChanged()', () {
      test('marks single association for persistence', () {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        
        final state = getState();
        expect(state.length, 1);
        expect(state['prod-1'], isNotNull);
        expect(state['prod-1']!['super-1'], 'cat-1');
      });

      test('accumulates multiple associations for same product', () {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        notifier.markAssociationChanged('prod-1', 'super-2', 'cat-2');
        notifier.markAssociationChanged('prod-1', 'super-3', 'cat-3');
        
        final state = getState();
        expect(state.length, 1);
        expect(state['prod-1']!.length, 3);
        expect(state['prod-1']!['super-1'], 'cat-1');
        expect(state['prod-1']!['super-2'], 'cat-2');
        expect(state['prod-1']!['super-3'], 'cat-3');
      });

      test('tracks associations for multiple products', () {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        notifier.markAssociationChanged('prod-2', 'super-1', 'cat-2');
        notifier.markAssociationChanged('prod-3', 'super-2', 'cat-1');
        
        final state = getState();
        expect(state.length, 3);
        expect(state.keys.toSet(), {'prod-1', 'prod-2', 'prod-3'});
      });

      test('overwrites existing association for same product-supermarket pair', () {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-2');
        
        final state = getState();
        expect(state['prod-1']!.length, 1);
        expect(state['prod-1']!['super-1'], 'cat-2');
      });

      test('triggers state rebuild', () {
        final notifier = getNotifier();

        var rebuildCount = 0;
        container.listen(
          associationsProvider,
          (previous, next) {
            rebuildCount++;
          },
        );

        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        expect(rebuildCount, greaterThanOrEqualTo(1));

        notifier.markAssociationChanged('prod-1', 'super-2', 'cat-2');
        expect(rebuildCount, greaterThanOrEqualTo(2));
      });

      test('maintains state immutability', () {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        final state1 = getState();
        
        notifier.markAssociationChanged('prod-2', 'super-2', 'cat-2');
        final state2 = getState();
        
        // States should be different objects
        expect(identical(state1, state2), isFalse);
        
        // Original state should not be modified
        expect(state1.length, 1);
        expect(state2.length, 2);
      });
    });

    group('getPendingAssociations()', () {
      test('returns null for product with no pending associations', () {
        final notifier = getNotifier();
        
        final pending = notifier.getPendingAssociations('prod-1');
        expect(pending, isNull);
      });

      test('returns pending associations for product', () {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        notifier.markAssociationChanged('prod-1', 'super-2', 'cat-2');
        
        final pending = notifier.getPendingAssociations('prod-1');
        expect(pending, isNotNull);
        expect(pending!.length, 2);
        expect(pending['super-1'], 'cat-1');
        expect(pending['super-2'], 'cat-2');
      });

      test('returns null for non-existent product', () {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        
        final pending = notifier.getPendingAssociations('prod-999');
        expect(pending, isNull);
      });

      test('returns empty map after product associations are cleared', () {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        notifier.clearPendingForProduct('prod-1');
        
        final pending = notifier.getPendingAssociations('prod-1');
        expect(pending, isNull);
      });
    });

    group('hasPendingAssociations()', () {
      test('returns false when no pending associations exist', () {
        final notifier = getNotifier();
        
        expect(notifier.hasPendingAssociations(), isFalse);
      });

      test('returns true when pending associations exist', () {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        
        expect(notifier.hasPendingAssociations(), isTrue);
      });

      test('returns false after all pending associations are cleared', () {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        notifier.markAssociationChanged('prod-2', 'super-2', 'cat-2');
        notifier.clearPending();
        
        expect(notifier.hasPendingAssociations(), isFalse);
      });

      test('returns false after flush completes', () async {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        await notifier.flushAssociations();
        
        expect(notifier.hasPendingAssociations(), isFalse);
      });
    });

    group('flushAssociations()', () {
      test('persists pending associations to repository', () async {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        notifier.markAssociationChanged('prod-1', 'super-2', 'cat-2');
        notifier.markAssociationChanged('prod-2', 'super-1', 'cat-3');
        
        await notifier.flushAssociations();
        
        // Verify repository received the batch
        expect(mockRepo.callLog, contains('addBatch'));
        
        final repoData = mockRepo.getAll();
        expect(repoData.length, 2);
        expect(repoData['prod-1']!['super-1'], 'cat-1');
        expect(repoData['prod-1']!['super-2'], 'cat-2');
        expect(repoData['prod-2']!['super-1'], 'cat-3');
      });

      test('clears pending associations after successful flush', () async {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        notifier.markAssociationChanged('prod-2', 'super-2', 'cat-2');
        
        await notifier.flushAssociations();
        
        final state = getState();
        expect(state, isEmpty);
      });

      test('does nothing when no pending associations exist', () async {
        final notifier = getNotifier();
        
        await notifier.flushAssociations();
        
        expect(mockRepo.callLog, isEmpty);
        expect(getState(), isEmpty);
      });

      test('handles empty state gracefully', () async {
        final notifier = getNotifier();
        
        // Initially empty
        expect(getState(), isEmpty);
        
        // Should not throw
        await notifier.flushAssociations();
        
        expect(getState(), isEmpty);
        expect(mockRepo.callLog, isEmpty);
      });

      test('rethrows repository errors', () async {
        // Create a mock that throws an error
        final failingRepo = _FailingMockAssociationRepository();
        final failingContainer = ProviderContainer(
          overrides: [
            associationRepositoryProvider.overrideWithValue(failingRepo),
          ],
        );

        final notifier = failingContainer.read(associationsProvider.notifier);
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');

        expect(
          () => notifier.flushAssociations(),
          throwsA(isA<Exception>()),
        );

        // State should not be cleared on error
        final state = failingContainer.read(associationsProvider);
        expect(state.isNotEmpty, isTrue);

        failingContainer.dispose();
      });

      test('preserves state when flush fails', () async {
        final failingRepo = _FailingMockAssociationRepository();
        final failingContainer = ProviderContainer(
          overrides: [
            associationRepositoryProvider.overrideWithValue(failingRepo),
          ],
        );

        final notifier = failingContainer.read(associationsProvider.notifier);
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        notifier.markAssociationChanged('prod-2', 'super-2', 'cat-2');

        try {
          await notifier.flushAssociations();
        } catch (e) {
          // Expected to fail
        }

        final state = failingContainer.read(associationsProvider);
        expect(state.length, 2);
        expect(state['prod-1']!['super-1'], 'cat-1');
        expect(state['prod-2']!['super-2'], 'cat-2');

        failingContainer.dispose();
      });

      test('can flush multiple times', () async {
        final notifier = getNotifier();
        
        // First flush
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        await notifier.flushAssociations();
        expect(getState(), isEmpty);
        
        // Second flush
        notifier.markAssociationChanged('prod-2', 'super-2', 'cat-2');
        await notifier.flushAssociations();
        expect(getState(), isEmpty);
        
        // Verify both batches were persisted
        final repoData = mockRepo.getAll();
        expect(repoData.length, 2);
      });
    });

    group('clearPending()', () {
      test('clears all pending associations', () {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        notifier.markAssociationChanged('prod-2', 'super-2', 'cat-2');
        notifier.markAssociationChanged('prod-3', 'super-3', 'cat-3');
        
        notifier.clearPending();
        
        final state = getState();
        expect(state, isEmpty);
      });

      test('does not affect repository', () {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        notifier.clearPending();
        
        // Repository should not be called
        expect(mockRepo.callLog, isEmpty);
      });

      test('can clear already empty state', () {
        final notifier = getNotifier();
        
        expect(getState(), isEmpty);
        
        // Should not throw
        notifier.clearPending();
        
        expect(getState(), isEmpty);
      });

      test('allows adding new associations after clear', () {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        notifier.clearPending();
        notifier.markAssociationChanged('prod-2', 'super-2', 'cat-2');
        
        final state = getState();
        expect(state.length, 1);
        expect(state['prod-2']!['super-2'], 'cat-2');
      });

      test('triggers state rebuild', () {
        final notifier = getNotifier();
        var rebuildCount = 0;

        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');

        container.listen(
          associationsProvider,
          (previous, next) {
            rebuildCount++;
          },
        );

        notifier.clearPending();
        expect(rebuildCount, 1);
      });
    });

    group('clearPendingForProduct()', () {
      test('clears pending associations for specific product', () {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        notifier.markAssociationChanged('prod-1', 'super-2', 'cat-2');
        notifier.markAssociationChanged('prod-2', 'super-3', 'cat-3');
        
        notifier.clearPendingForProduct('prod-1');
        
        final state = getState();
        expect(state.length, 1);
        expect(state.containsKey('prod-1'), isFalse);
        expect(state['prod-2']!['super-3'], 'cat-3');
      });

      test('does not affect other products', () {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        notifier.markAssociationChanged('prod-2', 'super-2', 'cat-2');
        notifier.markAssociationChanged('prod-3', 'super-3', 'cat-3');
        
        notifier.clearPendingForProduct('prod-2');
        
        final state = getState();
        expect(state.length, 2);
        expect(state.containsKey('prod-1'), isTrue);
        expect(state.containsKey('prod-2'), isFalse);
        expect(state.containsKey('prod-3'), isTrue);
      });

      test('handles non-existent product gracefully', () {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        
        // Should not throw
        notifier.clearPendingForProduct('prod-999');
        
        final state = getState();
        expect(state.length, 1);
        expect(state['prod-1']!['super-1'], 'cat-1');
      });

      test('can clear from empty state', () {
        final notifier = getNotifier();
        
        expect(getState(), isEmpty);
        
        // Should not throw
        notifier.clearPendingForProduct('prod-1');
        
        expect(getState(), isEmpty);
      });

      test('allows adding associations after clearing product', () {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        notifier.clearPendingForProduct('prod-1');
        notifier.markAssociationChanged('prod-1', 'super-2', 'cat-2');
        
        final state = getState();
        expect(state.length, 1);
        expect(state['prod-1']!.length, 1);
        expect(state['prod-1']!['super-2'], 'cat-2');
      });

      test('triggers state rebuild', () {
        final notifier = getNotifier();
        var rebuildCount = 0;

        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');

        container.listen(
          associationsProvider,
          (previous, next) {
            rebuildCount++;
          },
        );

        notifier.clearPendingForProduct('prod-1');
        expect(rebuildCount, 1);
      });

      test('maintains state immutability', () {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        notifier.markAssociationChanged('prod-2', 'super-2', 'cat-2');
        
        final state1 = getState();
        
        notifier.clearPendingForProduct('prod-1');
        
        final state2 = getState();
        
        // States should be different objects
        expect(identical(state1, state2), isFalse);
        
        // Original state should not be modified
        expect(state1.length, 2);
        expect(state2.length, 1);
      });
    });

    group('Edge cases and integration', () {
      test('handles rapid sequential operations', () {
        final notifier = getNotifier();
        
        for (var i = 0; i < 100; i++) {
          notifier.markAssociationChanged('prod-$i', 'super-1', 'cat-1');
        }
        
        final state = getState();
        expect(state.length, 100);
      });

      test('handles complex workflow: mark, clear, mark, flush', () async {
        final notifier = getNotifier();
        
        // Mark some associations
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        notifier.markAssociationChanged('prod-2', 'super-2', 'cat-2');
        
        // Clear one product
        notifier.clearPendingForProduct('prod-1');
        
        // Add more
        notifier.markAssociationChanged('prod-3', 'super-3', 'cat-3');
        
        // Flush
        await notifier.flushAssociations();
        
        // Verify only prod-2 and prod-3 were persisted
        final repoData = mockRepo.getAll();
        expect(repoData.length, 2);
        expect(repoData.containsKey('prod-1'), isFalse);
        expect(repoData.containsKey('prod-2'), isTrue);
        expect(repoData.containsKey('prod-3'), isTrue);
      });

      test('handles multiple supermarkets for same product', () {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        notifier.markAssociationChanged('prod-1', 'super-2', 'cat-2');
        notifier.markAssociationChanged('prod-1', 'super-3', 'cat-3');
        notifier.markAssociationChanged('prod-1', 'super-4', 'cat-4');
        notifier.markAssociationChanged('prod-1', 'super-5', 'cat-5');
        
        final state = getState();
        expect(state.length, 1);
        expect(state['prod-1']!.length, 5);
      });

      test('verifies getPendingAssociations returns correct data after multiple operations', () {
        final notifier = getNotifier();
        
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        notifier.markAssociationChanged('prod-1', 'super-2', 'cat-2');
        notifier.markAssociationChanged('prod-1', 'super-1', 'cat-3'); // Update
        
        final pending = notifier.getPendingAssociations('prod-1');
        expect(pending!.length, 2);
        expect(pending['super-1'], 'cat-3'); // Updated value
        expect(pending['super-2'], 'cat-2');
      });

      test('state remains consistent across multiple container instances', () {
        final container1 = ProviderContainer(
          overrides: [
            associationRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );
        final container2 = ProviderContainer(
          overrides: [
            associationRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        // Each container has independent state
        final notifier1 = container1.read(associationsProvider.notifier);
        final notifier2 = container2.read(associationsProvider.notifier);

        notifier1.markAssociationChanged('prod-1', 'super-1', 'cat-1');
        notifier2.markAssociationChanged('prod-2', 'super-2', 'cat-2');

        final state1 = container1.read(associationsProvider);
        final state2 = container2.read(associationsProvider);

        expect(state1.length, 1);
        expect(state2.length, 1);
        expect(state1.containsKey('prod-1'), isTrue);
        expect(state2.containsKey('prod-2'), isTrue);

        container1.dispose();
        container2.dispose();
      });
    });
  });
}

/// Mock repository that always fails for error testing
class _FailingMockAssociationRepository implements AssociationRepository {
  @override
  Future<void> addBatch(
    Map<String, Map<String, String>> associationsByProduct,
  ) async {
    throw Exception('Repository error: addBatch failed');
  }

  @override
  Future<void> deleteBatch(
    List<({String productId, String supermarketId})> associationsToDelete,
  ) async {
    throw Exception('Repository error: deleteBatch failed');
  }

  @override
  Future<void> add(
    String productId,
    String supermarketId,
    String categoryId,
  ) async {
    throw Exception('Repository error: add failed');
  }

  @override
  Future<void> update(
    String productId,
    String supermarketId,
    String categoryId,
  ) async {
    throw Exception('Repository error: update failed');
  }

  @override
  Future<void> delete(
    String productId,
    String supermarketId,
  ) async {
    throw Exception('Repository error: delete failed');
  }

  @override
  Future<Map<String, String>> getProductAssociations(String productId) async {
    throw Exception('Repository error: getProductAssociations failed');
  }

  @override
  Future<String?> getCategoryForProduct(
    String productId,
    String supermarketId,
  ) async {
    throw Exception('Repository error: getCategoryForProduct failed');
  }
}
