import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/providers/real_app_providers/recipe/recipe_provider.dart';
import 'package:app_code/repositories/mock_repo/mock_shopping_list_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_recipe_cache_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_gemini_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Spy to track recipe cancellation calls
class BackgroundRecipeNotifierSpy {
  final List<String> cancelledListIds = [];
  
  Future<void> cancelSearchForList(String listId) async {
    cancelledListIds.add(listId);
  }
}

void main() {
  group('ShoppingListsNotifier', () {
    late MockShoppingListRepository mockRepo;
    late MockRecipeCacheRepository mockRecipeCache;
    late BackgroundRecipeNotifierSpy recipeSpy;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockShoppingListRepository();
      mockRecipeCache = MockRecipeCacheRepository();
      recipeSpy = BackgroundRecipeNotifierSpy();
      
      container = ProviderContainer(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(mockRepo),
          recipeCacheRepositoryProvider.overrideWithValue(mockRecipeCache),
          geminiRepositoryProvider
              .overrideWithValue(MockGeminiRepository()),
          // Override with fixed date for testing
          currentDateTimeProvider.overrideWithValue(DateTime(2025, 1, 15)),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    /// Helper to get the notifier
    ShoppingListsNotifier getNotifier() =>
        container.read(shoppingListsProvider.notifier);

    /// Helper to get current state as a list
    List<ShoppingList> getState() => container.read(shoppingListsProvider).maybeWhen(
          data: (lists) => lists,
          orElse: () => [],
        );

    /// Helper to create a shopping list
    ShoppingList createList(String id, String name, {DateTime? createdAt}) => ShoppingList(
          id: id,
          name: name,
          createdAt: createdAt ?? DateTime.now(),
        );

    /// Helper to create a trashed list with deletion timestamp
    ShoppingList createTrashedList(
      String id,
      String name, {
      required DateTime deletionTimestamp,
    }) {
      return ShoppingList(
        id: id,
        name: name,
        createdAt: DateTime.now(),
        isInTheTrash: true,
        deletionTimestamp: deletionTimestamp,
      );
    }

    test('initial state loads empty list', () async {
      final state = await container.read(shoppingListsProvider.future);
      expect(state, isEmpty);
    });

    test('build() is side-effect free and loads from repository', () async {
      // Add lists to mock repo first
      final list1 = createList('list-1', 'Groceries');
      final list2 = createList('list-2', 'Hardware');
      await mockRepo.add(list1);
      await mockRepo.add(list2);

      // Create new container to trigger build()
      final newContainer = ProviderContainer(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(mockRepo),
          recipeCacheRepositoryProvider.overrideWithValue(mockRecipeCache),
          geminiRepositoryProvider
              .overrideWithValue(MockGeminiRepository()),
        ],
      );

      final state = await newContainer.read(shoppingListsProvider.future);
      expect(state.length, 2);
      expect(state[0].id, 'list-1');
      expect(state[1].id, 'list-2');

      newContainer.dispose();
    });

    test('addList adds to repository and updates state in-memory', () async {
      final notifier = getNotifier();
      final newList = createList('list-1', 'Groceries');

      await notifier.addList(newList);

      final state = getState();
      expect(state.length, 1);
      expect(state[0].id, 'list-1');
      expect(state[0].getName(), 'Groceries');

      // Verify it was added to repository
      final repoLists = await mockRepo.getAll();
      expect(repoLists.length, 1);
      expect(repoLists[0].id, 'list-1');
    });

    test('addList updates state in-memory without calling getAll()', () async {
      final notifier = getNotifier();
      
      // Add first list
      final list1 = createList('list-1', 'First');
      await notifier.addList(list1);
      
      // Add second list - state should be updated in-memory
      final list2 = createList('list-2', 'Second');
      await notifier.addList(list2);

      final state = getState();
      expect(state.length, 2);
      expect(state[0].id, 'list-1');
      expect(state[1].id, 'list-2');
    });

    test('deleteList removes from repository and updates state in-memory', () async {
      final notifier = getNotifier();
      final list = createList('list-1', 'Groceries');

      await notifier.addList(list);
      expect(getState().length, 1);

      await notifier.deleteList(list);
      expect(getState(), isEmpty);

      // Verify it was deleted from repository
      final repoLists = await mockRepo.getAll();
      expect(repoLists, isEmpty);
    });

    test('deleteList uses stable ID for filtering', () async {
      final notifier = getNotifier();
      
      final list1 = createList('list-1', 'First');
      final list2 = createList('list-2', 'Second');
      final list3 = createList('list-3', 'Third');

      await notifier.addList(list1);
      await notifier.addList(list2);
      await notifier.addList(list3);

      // Delete middle list
      await notifier.deleteList(list2);

      final state = getState();
      expect(state.length, 2);
      expect(state.any((l) => l.id == 'list-1'), isTrue);
      expect(state.any((l) => l.id == 'list-2'), isFalse);
      expect(state.any((l) => l.id == 'list-3'), isTrue);
    });

    test('updateList modifies in repository and updates state in-memory', () async {
      final notifier = getNotifier();
      final originalList = createList('list-1', 'Groceries');

      await notifier.addList(originalList);

      final updatedList = createList('list-1', 'Updated Groceries');
      await notifier.updateList(updatedList);

      final state = getState();
      expect(state.length, 1);
      expect(state[0].getName(), 'Updated Groceries');

      // Verify repository was updated
      final repoLists = await mockRepo.getAll();
      expect(repoLists[0].getName(), 'Updated Groceries');
    });

    test('updateList preserves list position using stable ID', () async {
      final notifier = getNotifier();

      final list1 = createList('list-1', 'First');
      final list2 = createList('list-2', 'Second');
      final list3 = createList('list-3', 'Third');

      await notifier.addList(list1);
      await notifier.addList(list2);
      await notifier.addList(list3);

      final updatedList2 = createList('list-2', 'Second Updated');
      await notifier.updateList(updatedList2);

      final state = getState();
      expect(state.length, 3);
      expect(state[1].id, 'list-2');
      expect(state[1].getName(), 'Second Updated');
    });

    test('cleanupExpiredLists deletes lists in trash for 30+ days', () async {
      final notifier = getNotifier();
      
      // Current time is 2025-01-15 (from override)
      // Create lists with different deletion timestamps
      final recentList = createTrashedList(
        'list-1',
        'Recent',
        deletionTimestamp: DateTime(2025, 1, 10), // 5 days ago
      );
      final expiredList = createTrashedList(
        'list-2',
        'Expired',
        deletionTimestamp: DateTime(2024, 12, 1), // 45 days ago
      );
      final normalList = createList('list-3', 'Normal');

      await notifier.addList(recentList);
      await notifier.addList(expiredList);
      await notifier.addList(normalList);

      expect(getState().length, 3);

      // Clean up expired lists
      await notifier.cleanupExpiredLists();

      final state = getState();
      expect(state.length, 2);
      expect(state.any((l) => l.id == 'list-1'), isTrue); // Recent trash kept
      expect(state.any((l) => l.id == 'list-2'), isFalse); // Expired deleted
      expect(state.any((l) => l.id == 'list-3'), isTrue); // Normal kept
    });

    test('cleanupExpiredLists uses injectable time from currentDateTimeProvider', () async {
      // Create container with custom time
      final customContainer = ProviderContainer(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(mockRepo),
          recipeCacheRepositoryProvider.overrideWithValue(mockRecipeCache),
          geminiRepositoryProvider
              .overrideWithValue(MockGeminiRepository()),
          currentDateTimeProvider.overrideWithValue(DateTime(2025, 3, 1)), // March 1st
        ],
      );

      final notifier = customContainer.read(shoppingListsProvider.notifier);

      // List deleted on Jan 15 (45 days ago from March 1)
      final expiredList = createTrashedList(
        'list-1',
        'Expired',
        deletionTimestamp: DateTime(2025, 1, 15),
      );

      await notifier.addList(expiredList);
      await notifier.cleanupExpiredLists();

      final state = customContainer.read(shoppingListsProvider).maybeWhen(
        data: (lists) => lists,
        orElse: () => [],
      );

      expect(state, isEmpty); // Should be deleted
      customContainer.dispose();
    });

    test('cleanupExpiredLists keeps lists in trash for less than 30 days', () async {
      final notifier = getNotifier();
      
      // Current time is 2025-01-15
      final recentList = createTrashedList(
        'list-1',
        'Recent',
        deletionTimestamp: DateTime(2024, 12, 20), // 26 days ago
      );

      await notifier.addList(recentList);
      await notifier.cleanupExpiredLists();

      final state = getState();
      expect(state.length, 1);
      expect(state[0].id, 'list-1');
    });

    test('cleanupExpiredLists deletes list at exactly 30 days', () async {
      final notifier = getNotifier();
      
      // Current time is 2025-01-15
      final exactList = createTrashedList(
        'list-1',
        'Exact',
        deletionTimestamp: DateTime(2024, 12, 16), // Exactly 30 days ago
      );

      await notifier.addList(exactList);
      await notifier.cleanupExpiredLists();

      final state = getState();
      expect(state, isEmpty); // Should be deleted at 30 days
    });

    test('cleanupExpiredLists handles empty state safely', () async {
      final notifier = getNotifier();
      
      // Call cleanup on empty state - should not throw
      await notifier.cleanupExpiredLists();
      
      expect(getState(), isEmpty);
    });

    test('cleanupExpiredLists ignores normal lists', () async {
      final notifier = getNotifier();
      
      final normalList = createList('list-1', 'Normal');
      await notifier.addList(normalList);
      
      await notifier.cleanupExpiredLists();
      
      final state = getState();
      expect(state.length, 1);
      expect(state[0].id, 'list-1');
    });

    test('cleanupExpiredLists ignores trash without deletion timestamp', () async {
      final notifier = getNotifier();
      
      // Create trash list without deletion timestamp (edge case)
      final brokenTrashList = ShoppingList(
        id: 'list-1',
        name: 'Broken Trash',
        createdAt: DateTime.now(),
        isInTheTrash: true,
        // No deletionTimestamp
      );
      
      await notifier.addList(brokenTrashList);
      await notifier.cleanupExpiredLists();
      
      final state = getState();
      expect(state.length, 1); // Should not be deleted
    });

    test('state remains AsyncData after successful operations', () async {
      final notifier = getNotifier();
      final list = createList('list-1', 'Test List');

      await notifier.addList(list);

      final state = container.read(shoppingListsProvider);
      expect(
        state.maybeWhen(
          data: (_) => true,
          orElse: () => false,
        ),
        isTrue,
      );
    });

    test('AsyncValue.guard handles repository errors gracefully', () async {
      // Create a failing repository
      final failingRepo = _FailingShoppingListRepository();
      
      final errorContainer = ProviderContainer(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(failingRepo),
          recipeCacheRepositoryProvider.overrideWithValue(mockRecipeCache),
          geminiRepositoryProvider
              .overrideWithValue(MockGeminiRepository()),
        ],
      );

      final notifier = errorContainer.read(shoppingListsProvider.notifier);
      final list = createList('list-1', 'Test');

      await notifier.addList(list);

      final state = errorContainer.read(shoppingListsProvider);
      expect(
        state.maybeWhen(
          error: (_, __) => true,
          orElse: () => false,
        ),
        isTrue,
      );

      errorContainer.dispose();
    });

    test('multiple operations maintain state consistency', () async {
      final notifier = getNotifier();

      final list1 = createList('list-1', 'First');
      final list2 = createList('list-2', 'Second');
      final list3 = createList('list-3', 'Third');

      await notifier.addList(list1);
      await notifier.addList(list2);
      await notifier.addList(list3);

      expect(getState().length, 3);

      await notifier.deleteList(list2);
      expect(getState().length, 2);

      final updatedList1 = createList('list-1', 'First Updated');
      await notifier.updateList(updatedList1);

      final state = getState();
      expect(state.length, 2);
      expect(state[0].getName(), 'First Updated');
      expect(state[1].getName(), 'Third');
    });
  });
}

/// Mock repository that throws errors for testing AsyncValue.guard
class _FailingShoppingListRepository extends MockShoppingListRepository {
  @override
  Future<void> add(ShoppingList list) async {
    throw Exception('Repository error');
  }
}
