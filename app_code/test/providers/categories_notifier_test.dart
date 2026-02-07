import 'package:app_code/models/category.dart';
import 'package:app_code/providers/real_app_providers/category/categories_notifier.dart';
import 'package:app_code/repositories/mock_repo/mock_category_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoriesNotifier', () {
    late MockCategoryRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockCategoryRepository();

      container = ProviderContainer(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    /// Helper to get the notifier
    CategoriesNotifier getNotifier() =>
        container.read(categoriesProvider.notifier);

    /// Helper to get current state as a list
    Future<List<Category>> getState() async {
      return await container.read(categoriesProvider.future);
    }

    /// Helper to create a category
    Category createCategory(String id, String name, {bool isVisible = true}) =>
        Category(
          id: id,
          name: name,
          isVisible: isVisible,
        );

    group('build()', () {
      test('initial state loads empty list', () async {
        final state = await getState();
        expect(state, isEmpty);
      });

      test('is side-effect free and loads from repository', () async {
        // Add categories to mock repo first
        final cat1 = createCategory('cat-1', 'Fruits');
        final cat2 = createCategory('cat-2', 'Vegetables');
        await mockRepo.add(cat1);
        await mockRepo.add(cat2);

        // Create new container to trigger build()
        final newContainer = ProviderContainer(
          overrides: [
            categoryRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        final state = await newContainer.read(categoriesProvider.future);
        expect(state.length, 2);
        expect(state[0].id, 'cat-1');
        expect(state[1].id, 'cat-2');

        newContainer.dispose();
      });

      test('loads categories with correct visibility flags', () async {
        final visible = createCategory('cat-1', 'Visible', isVisible: true);
        final invisible = createCategory('cat-2', 'Invisible', isVisible: false);
        await mockRepo.add(visible);
        await mockRepo.add(invisible);

        final newContainer = ProviderContainer(
          overrides: [
            categoryRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        final state = await newContainer.read(categoriesProvider.future);
        expect(state.length, 2);
        expect(state[0].isVisible, isTrue);
        expect(state[1].isVisible, isFalse);

        newContainer.dispose();
      });
    });

    group('addCategory()', () {
      test('adds to repository and invalidates state', () async {
        final notifier = getNotifier();
        final newCategory = createCategory('cat-1', 'Fruits');

        await notifier.addCategory(newCategory);

        // Verify it was added to repository
        final repoCategories = await mockRepo.getAll();
        expect(repoCategories.length, 1);
        expect(repoCategories[0].id, 'cat-1');
        expect(repoCategories[0].getName(), 'Fruits');

        // Verify state was invalidated and reloaded
        final state = await getState();
        expect(state.length, 1);
        expect(state[0].id, 'cat-1');
      });

      test('handles multiple additions correctly', () async {
        final notifier = getNotifier();
        await notifier.addCategory(createCategory('cat-1', 'First'));
        await notifier.addCategory(createCategory('cat-2', 'Second'));
        await notifier.addCategory(createCategory('cat-3', 'Third'));

        final state = await getState();
        expect(state.length, 3);
        expect(state.map((c) => c.id).toList(), ['cat-1', 'cat-2', 'cat-3']);
      });

      test('preserves category properties', () async {
        final notifier = getNotifier();
        final category = Category(
          id: 'cat-1',
          name: 'Custom Category',
          isVisible: false,
          createdAt: DateTime(2025, 1, 1),
          lastModified: DateTime(2025, 1, 2),
        );

        await notifier.addCategory(category);

        final state = await getState();
        final added = state.first;
        expect(added.getName(), 'Custom Category');
        expect(added.isVisible, isFalse);
      });
    });

    group('updateCategory()', () {
      test('updates in repository and invalidates state', () async {
        final notifier = getNotifier();
        final original = createCategory('cat-1', 'Original Name');
        await notifier.addCategory(original);

        final updated = createCategory('cat-1', 'Updated Name');
        await notifier.updateCategory(updated);

        final state = await getState();
        expect(state.length, 1);
        expect(state[0].getName(), 'Updated Name');

        // Verify repository was updated
        final repoCategories = await mockRepo.getAll();
        expect(repoCategories[0].getName(), 'Updated Name');
      });

      test('updates visibility flag correctly', () async {
        final notifier = getNotifier();
        final category = createCategory('cat-1', 'Test', isVisible: true);
        await notifier.addCategory(category);

        category.setVisibility(false);
        await notifier.updateCategory(category);

        final state = await getState();
        expect(state[0].isVisible, isFalse);
      });

      test('handles updating non-existent category gracefully', () async {
        final notifier = getNotifier();
        final nonExistent = createCategory('cat-999', 'Does Not Exist');

        // Should not throw, just do nothing
        await notifier.updateCategory(nonExistent);

        final state = await getState();
        expect(state, isEmpty);
      });
    });

    group('deleteCategory()', () {
      test('marks category as invisible instead of deleting', () async {
        final notifier = getNotifier();
        final category = createCategory('cat-1', 'Test', isVisible: true);
        await notifier.addCategory(category);

        await notifier.deleteCategory('cat-1');

        final state = await getState();
        expect(state.length, 1);
        expect(state[0].isVisible, isFalse);
        expect(state[0].getName(), 'Test');
      });

      test('does not delete "Uncategorized" category', () async {
        final notifier = getNotifier();
        final uncategorized = createCategory('cat-1', 'Uncategorized');
        final normal = createCategory('cat-2', 'Normal');
        await notifier.addCategory(uncategorized);
        await notifier.addCategory(normal);

        await notifier.deleteCategory('cat-1');

        final state = await getState();
        final cat1 = state.firstWhere((c) => c.id == 'cat-1');
        expect(cat1.isVisible, isTrue); // Should remain visible
      });

      test('does not delete "uncategorized" (case insensitive)', () async {
        final notifier = getNotifier();
        final uncategorized = createCategory('cat-1', 'uncategorized');
        await notifier.addCategory(uncategorized);

        await notifier.deleteCategory('cat-1');

        final state = await getState();
        expect(state[0].isVisible, isTrue);
      });

      test('does not delete " UNCATEGORIZED " (with spaces)', () async {
        final notifier = getNotifier();
        final uncategorized = createCategory('cat-1', ' UNCATEGORIZED ');
        await notifier.addCategory(uncategorized);

        await notifier.deleteCategory('cat-1');

        final state = await getState();
        expect(state[0].isVisible, isTrue);
      });

      test('handles deleting non-existent category gracefully', () async {
        final notifier = getNotifier();

        // Should not throw
        await notifier.deleteCategory('non-existent-id');

        final state = await getState();
        expect(state, isEmpty);
      });
    });

    group('deleteCategories()', () {
      test('deletes multiple categories and returns count', () async {
        final notifier = getNotifier();
        await notifier.addCategory(createCategory('cat-1', 'First'));
        await notifier.addCategory(createCategory('cat-2', 'Second'));
        await notifier.addCategory(createCategory('cat-3', 'Third'));

        final deletedCount = await notifier.deleteCategories(['cat-1', 'cat-2']);

        expect(deletedCount, 2);

        final state = await getState();
        expect(state.where((c) => !c.isVisible).length, 2);
        expect(state.where((c) => c.isVisible).length, 1);
      });

      test('skips Uncategorized category in bulk deletion', () async {
        final notifier = getNotifier();
        await notifier.addCategory(createCategory('cat-1', 'Uncategorized'));
        await notifier.addCategory(createCategory('cat-2', 'Normal'));

        final deletedCount = await notifier.deleteCategories(['cat-1', 'cat-2']);

        expect(deletedCount, 1); // Only 'Normal' deleted

        final state = await getState();
        final uncategorized = state.firstWhere((c) => c.id == 'cat-1');
        expect(uncategorized.isVisible, isTrue);
      });

      test('returns 0 when deleting empty list', () async {
        final notifier = getNotifier();
        await notifier.addCategory(createCategory('cat-1', 'Test'));

        final deletedCount = await notifier.deleteCategories([]);

        expect(deletedCount, 0);
      });

      test('ignores non-existent IDs', () async {
        final notifier = getNotifier();
        await notifier.addCategory(createCategory('cat-1', 'Exists'));

        final deletedCount = await notifier.deleteCategories(['cat-1', 'non-existent', 'also-fake']);

        expect(deletedCount, 1);
      });

      test('returns correct count with mixed valid/invalid IDs', () async {
        final notifier = getNotifier();
        await notifier.addCategory(createCategory('cat-1', 'First'));
        await notifier.addCategory(createCategory('cat-2', 'Uncategorized'));
        await notifier.addCategory(createCategory('cat-3', 'Third'));

        final deletedCount = await notifier.deleteCategories([
          'cat-1',
          'cat-2', // Uncategorized - won't delete
          'cat-3',
          'cat-4', // Non-existent
        ]);

        expect(deletedCount, 2); // Only cat-1 and cat-3
      });

      test('handles all non-existent IDs gracefully', () async {
        final notifier = getNotifier();

        final deletedCount = await notifier.deleteCategories(['fake-1', 'fake-2']);

        expect(deletedCount, 0);
      });
    });

    group('getCategoryById()', () {
      test('retrieves existing category', () async {
        final notifier = getNotifier();
        final category = createCategory('cat-1', 'Test Category');
        await notifier.addCategory(category);

        final retrieved = await notifier.getCategoryById('cat-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.id, 'cat-1');
        expect(retrieved.getName(), 'Test Category');
      });

      test('returns null for non-existent ID', () async {
        final notifier = getNotifier();

        final retrieved = await notifier.getCategoryById('non-existent');

        expect(retrieved, isNull);
      });

      test('retrieves invisible category', () async {
        final notifier = getNotifier();
        final category = createCategory('cat-1', 'Invisible', isVisible: false);
        await notifier.addCategory(category);

        final retrieved = await notifier.getCategoryById('cat-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.isVisible, isFalse);
      });
    });

    group('getVisibleCategories()', () {
      test('returns only visible categories', () async {
        final notifier = getNotifier();
        await notifier.addCategory(createCategory('cat-1', 'Visible1', isVisible: true));
        await notifier.addCategory(createCategory('cat-2', 'Invisible', isVisible: false));
        await notifier.addCategory(createCategory('cat-3', 'Visible2', isVisible: true));

        final visible = await notifier.getVisibleCategories();

        expect(visible.length, 2);
        expect(visible.every((c) => c.isVisible), isTrue);
        expect(visible.map((c) => c.getName()).toList(), ['Visible1', 'Visible2']);
      });

      test('returns empty list when all categories are invisible', () async {
        final notifier = getNotifier();
        await notifier.addCategory(createCategory('cat-1', 'Invisible1', isVisible: false));
        await notifier.addCategory(createCategory('cat-2', 'Invisible2', isVisible: false));

        final visible = await notifier.getVisibleCategories();

        expect(visible, isEmpty);
      });

      test('returns empty list when no categories exist', () async {
        final notifier = getNotifier();

        final visible = await notifier.getVisibleCategories();

        expect(visible, isEmpty);
      });

      test('returns all categories when all are visible', () async {
        final notifier = getNotifier();
        await notifier.addCategory(createCategory('cat-1', 'First'));
        await notifier.addCategory(createCategory('cat-2', 'Second'));
        await notifier.addCategory(createCategory('cat-3', 'Third'));

        final visible = await notifier.getVisibleCategories();

        expect(visible.length, 3);
      });
    });

    group('Providers', () {
      test('categoryByIdProvider fetches category by ID', () async {
        final category = createCategory('cat-1', 'Test Category');
        await mockRepo.add(category);

        final retrieved = await container.read(categoryByIdProvider('cat-1').future);

        expect(retrieved, isNotNull);
        expect(retrieved!.id, 'cat-1');
        expect(retrieved.getName(), 'Test Category');
      });

      test('categoryByIdProvider returns null for non-existent ID', () async {
        final retrieved = await container.read(categoryByIdProvider('non-existent').future);

        expect(retrieved, isNull);
      });

      test('visibleCategoriesProvider filters invisible categories', () async {
        await mockRepo.add(createCategory('cat-1', 'Visible', isVisible: true));
        await mockRepo.add(createCategory('cat-2', 'Invisible', isVisible: false));

        final visible = await container.read(visibleCategoriesProvider.future);

        expect(visible.length, 1);
        expect(visible[0].getName(), 'Visible');
      });
    });

    group('Edge Cases', () {
      test('handles null ID gracefully', () async {
        final notifier = getNotifier();

        final retrieved = await notifier.getCategoryById('');

        expect(retrieved, isNull);
      });

      test('handles category with empty name', () async {
        final notifier = getNotifier();
        final category = createCategory('cat-1', '');
        await notifier.addCategory(category);

        final state = await getState();
        expect(state.length, 1);
        expect(state[0].getName(), '');
      });

      test('handles duplicate category additions', () async {
        final notifier = getNotifier();
        final category = createCategory('cat-1', 'Duplicate');

        await notifier.addCategory(category);
        await notifier.addCategory(category);

        final state = await getState();
        expect(state.length, 2); // Both added (no uniqueness check)
      });

      test('state remains AsyncData after successful operations', () async {
        final notifier = getNotifier();
        final category = createCategory('cat-1', 'Test');

        await notifier.addCategory(category);

        final state = container.read(categoriesProvider);
        expect(
          state.maybeWhen(
            data: (_) => true,
            orElse: () => false,
          ),
          isTrue,
        );
      });
    });

    group('State Invalidation', () {
      test('addCategory invalidates and reloads state', () async {
        final notifier = getNotifier();

        // Load initial state
        await getState();

        // Manually add to repository (simulating external change)
        await mockRepo.add(createCategory('cat-external', 'External'));

        // addCategory should reload all from repository
        await notifier.addCategory(createCategory('cat-1', 'New'));

        final state = await getState();
        expect(state.length, 2); // Both categories present
      });

      test('updateCategory invalidates and reloads state', () async {
        final notifier = getNotifier();
        final category = createCategory('cat-1', 'Original');
        await notifier.addCategory(category);

        // Manually add another category
        await mockRepo.add(createCategory('cat-external', 'External'));

        category.setName('Updated');
        await notifier.updateCategory(category);

        final state = await getState();
        expect(state.length, 2); // Both categories present
      });

      test('deleteCategory invalidates and reloads state', () async {
        final notifier = getNotifier();
        await notifier.addCategory(createCategory('cat-1', 'To Delete'));

        // Manually add another category
        await mockRepo.add(createCategory('cat-external', 'External'));

        await notifier.deleteCategory('cat-1');

        final state = await getState();
        expect(state.length, 2); // Both categories still present
      });
    });
  });
}
