import 'package:app_code/models/category.dart';
import 'package:app_code/providers/real_app_providers/category/categories_notifier.dart';
import 'package:app_code/repositories/abstract/category_repository.dart';
import 'package:app_code/repositories/sync/category_repository_sync.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_category.dart';
import 'package:app_code/utils/uncategorized_category_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    // Initialize sqflite_ffi for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Clean up any existing database
    final dbPath = await getDatabasesPath();
    await deleteDatabase('$dbPath/shopping_app.db');
  });

  setUp(() async {
    // Clear tables before each test
    final db = await DatabaseHelper.database;
    await db.delete('category');
    await db.delete('sync_box');
  });

  group('CategoriesNotifier - build -', () {
    test('builds with empty list when no categories exist', () async {
      // Arrange
      final container = ProviderContainer();

      // Act
      final result = await container.read(categoriesProvider.future);

      // Assert
      expect(result, isNotNull);
      expect(result, isEmpty);
    });

    test('builds with all categories from repository', () async {
      // Arrange
      final repository = CategoryRepositoryWithSync();
      await repository.add(Category(id: 'cat-1', name: 'Fruits'));
      await repository.add(Category(id: 'cat-2', name: 'Vegetables'));
      await repository.add(Category(id: 'cat-3', name: 'Dairy'));

      final container = ProviderContainer();

      // Act
      final result = await container.read(categoriesProvider.future);

      // Assert
      expect(result.length, 3);
      expect(
        result.map((c) => c.id).toList(),
        containsAll(['cat-1', 'cat-2', 'cat-3']),
      );
    });

    test('includes all category properties in build result', () async {
      // Arrange
      final repository = CategoryRepositoryWithSync();
      final category = Category(
        id: 'cat-complete',
        name: 'Complete Category',
        isVisible: true,
      );
      await repository.add(category);

      final container = ProviderContainer();

      // Act
      final result = await container.read(categoriesProvider.future);

      // Assert
      expect(result.length, 1);
      expect(result[0].id, 'cat-complete');
      expect(result[0].getName(), 'Complete Category');
      expect(result[0].isVisible, true);
    });
  });

  group('CategoriesNotifier - addCategory -', () {
    test('saves category and invalidates provider', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);

      // Act
      await notifier.addCategory(Category(id: 'new-cat', name: 'New Category'));

      // Assert
      final result = await ManageCategory.getCategoryById('new-cat');
      expect(result, isNotNull);
      expect(result!.getName(), 'New Category');
    });

    test('sets createdAt timestamp on add', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      final beforeAdd = DateTime.now();

      // Act
      await notifier.addCategory(Category(id: 'cat-ts', name: 'With Timestamp'));

      // Assert
      final result = await ManageCategory.getCategoryById('cat-ts');
      expect(result, isNotNull);
      expect(result!.createdAt, isNotNull);
      expect(
        result.createdAt.isAfter(beforeAdd.subtract(Duration(seconds: 1))),
        true,
      );
    });

    test('updates provider state after adding category', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);

      // Act
      await notifier.addCategory(Category(id: 'cat-1', name: 'Category 1'));
      await notifier.addCategory(Category(id: 'cat-2', name: 'Category 2'));

      final updatedList = await container.read(categoriesProvider.future);

      // Assert
      expect(updatedList.length, 2);
      expect(
        updatedList.map((c) => c.id).toList(),
        containsAll(['cat-1', 'cat-2']),
      );
    });

    test('handles adding multiple categories', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);

      // Act
      for (int i = 1; i <= 5; i++) {
        await notifier.addCategory(
          Category(id: 'cat-$i', name: 'Category $i'),
        );
      }

      final result = await container.read(categoriesProvider.future);

      // Assert
      expect(result.length, 5);
    });

    test('adds category with visibility flag', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);

      // Act
      await notifier.addCategory(
        Category(id: 'cat-visible', name: 'Visible', isVisible: true),
      );

      // Assert
      final result = await ManageCategory.getCategoryById('cat-visible');
      expect(result, isNotNull);
      expect(result!.isVisible, true);
    });
  });

  group('CategoriesNotifier - updateCategory -', () {
    test('updates category and invalidates provider', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      final category = Category(id: 'cat-update', name: 'Original Name');
      await notifier.addCategory(category);

      // Act
      category.setName('Updated Name');
      await notifier.updateCategory(category);

      // Assert
      final result = await ManageCategory.getCategoryById('cat-update');
      expect(result, isNotNull);
      expect(result!.getName(), 'Updated Name');
    });

    test('updates visibility and invalidates provider', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      final category = Category(id: 'cat-vis', name: 'Test', isVisible: true);
      await notifier.addCategory(category);

      // Act
      category.setVisibility(false);
      await notifier.updateCategory(category);

      // Assert
      final result = await ManageCategory.getCategoryById('cat-vis');
      expect(result, isNotNull);
      expect(result!.isVisible, false);
    });

    test('updates provider state after modification', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      final category = Category(id: 'cat-state', name: 'Original');
      await notifier.addCategory(category);

      // Act
      category.setName('Modified');
      await notifier.updateCategory(category);

      final updatedList = await container.read(categoriesProvider.future);

      // Assert
      expect(updatedList.length, 1);
      expect(updatedList[0].getName(), 'Modified');
    });

    test('generates new timestamp on update', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      final category = Category(id: 'cat-ts-update', name: 'Test');
      await notifier.addCategory(category);

      final originalTimestamp = category.lastModified;
      await Future.delayed(Duration(milliseconds: 2));

      // Act
      category.setName('Updated');
      await notifier.updateCategory(category);

      // Assert
      final result = await ManageCategory.getCategoryById('cat-ts-update');
      expect(result, isNotNull);
      expect(
        result!.lastModified!.isAfter(originalTimestamp!),
        true,
      );
    });
  });

  group('CategoriesNotifier - deleteCategory -', () {
    test('marks category as invisible instead of deleting', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      final category = Category(
        id: 'cat-delete',
        name: 'To Delete',
        isVisible: true,
      );
      await notifier.addCategory(category);

      // Act
      await notifier.deleteCategory('cat-delete');

      // Assert
      final result = await ManageCategory.getCategoryById('cat-delete');
      expect(result, isNotNull);
      expect(result!.isVisible, false);
    });

    test('returns provider invalidated after delete', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      await notifier.addCategory(Category(id: 'cat-1', name: 'Category 1'));
      await notifier.addCategory(Category(id: 'cat-2', name: 'Category 2'));

      // Act
      await notifier.deleteCategory('cat-1');

      final result = await container.read(categoriesProvider.future);

      // Assert - both categories still exist but cat-1 is invisible
      expect(result.length, 2);
      final cat1 = result.firstWhere((c) => c.id == 'cat-1');
      final cat2 = result.firstWhere((c) => c.id == 'cat-2');
      expect(cat1.isVisible, false);
      expect(cat2.isVisible, true);
    });

    test('does not delete uncategorized category', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      final uncategorized = Category(
        id: 'uncategorized',
        name: UncategorizedCategoryUtils.name,
        isVisible: true,
      );
      await notifier.addCategory(uncategorized);

      // Act
      await notifier.deleteCategory('uncategorized');

      // Assert
      final result = await ManageCategory.getCategoryById('uncategorized');
      expect(result, isNotNull);
      expect(result!.isVisible, true); // Should still be visible
    });

    test('does nothing gracefully when deleting non-existent category', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);

      // Act & Assert - should not throw
      try {
        await notifier.deleteCategory('non-existent');
        // If we reach here, the test passes
        expect(true, true);
      } catch (e) {
        fail('deleteCategory should not throw for non-existent id');
      }
    });

    test('updates visibility timestamp on delete', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      final category = Category(
        id: 'cat-ts-delete',
        name: 'Test',
        isVisible: true,
      );
      await notifier.addCategory(category);

      final beforeDelete = DateTime.now();
      await Future.delayed(Duration(milliseconds: 2));

      // Act
      await notifier.deleteCategory('cat-ts-delete');

      // Assert
      final result = await ManageCategory.getCategoryById('cat-ts-delete');
      expect(result, isNotNull);
      expect(result!.isVisible, false);
      expect(result.lastModified!.isAfter(beforeDelete), true);
    });
  });

  group('CategoriesNotifier - deleteCategories -', () {
    test('marks multiple categories as invisible', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      await notifier.addCategory(Category(id: 'cat-1', name: 'Category 1'));
      await notifier.addCategory(Category(id: 'cat-2', name: 'Category 2'));
      await notifier.addCategory(Category(id: 'cat-3', name: 'Category 3'));

      // Act
      final deletedCount = await notifier.deleteCategories(['cat-1', 'cat-2']);

      // Assert
      expect(deletedCount, 2);
      final cat1 = await ManageCategory.getCategoryById('cat-1');
      final cat2 = await ManageCategory.getCategoryById('cat-2');
      final cat3 = await ManageCategory.getCategoryById('cat-3');

      expect(cat1!.isVisible, false);
      expect(cat2!.isVisible, false);
      expect(cat3!.isVisible, true);
    });

    test('returns count of successfully deleted categories', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      await notifier.addCategory(Category(id: 'cat-1', name: 'Category 1'));
      await notifier.addCategory(Category(id: 'cat-2', name: 'Category 2'));

      // Act
      final deletedCount = await notifier.deleteCategories(
        ['cat-1', 'cat-2', 'non-existent'],
      );

      // Assert
      expect(deletedCount, 2);
    });

    test('excludes uncategorized from bulk delete', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      await notifier.addCategory(
        Category(id: 'uncategorized', name: UncategorizedCategoryUtils.name),
      );
      await notifier.addCategory(Category(id: 'cat-1', name: 'Category 1'));

      // Act
      final deletedCount = await notifier.deleteCategories(
        ['uncategorized', 'cat-1'],
      );

      // Assert
      expect(deletedCount, 1);
      final uncategorized = await ManageCategory.getCategoryById('uncategorized');
      expect(uncategorized!.isVisible, true);
    });

    test('updates provider state after bulk delete', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      await notifier.addCategory(Category(id: 'cat-1', name: 'Category 1'));
      await notifier.addCategory(Category(id: 'cat-2', name: 'Category 2'));

      // Act
      await notifier.deleteCategories(['cat-1', 'cat-2']);

      final result = await container.read(categoriesProvider.future);

      // Assert - both still exist but are invisible
      expect(result.length, 2);
      expect(result.every((c) => !c.isVisible), true);
    });

    test('handles empty deletion list', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      await notifier.addCategory(Category(id: 'cat-1', name: 'Category 1'));

      // Act
      final deletedCount = await notifier.deleteCategories([]);

      // Assert
      expect(deletedCount, 0);
      final result = await container.read(categoriesProvider.future);
      expect(result.length, 1);
    });

    test('handles all non-existent categories', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);

      // Act
      final deletedCount = await notifier.deleteCategories([
        'non-existent-1',
        'non-existent-2',
      ]);

      // Assert
      expect(deletedCount, 0);
    });
  });

  group('CategoriesNotifier - getCategoryById -', () {
    test('returns category by id', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      await notifier.addCategory(Category(id: 'cat-1', name: 'Test Category'));

      // Act
      final result = await notifier.getCategoryById('cat-1');

      // Assert
      expect(result, isNotNull);
      expect(result!.id, 'cat-1');
      expect(result.getName(), 'Test Category');
    });

    test('returns null for non-existent category', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);

      // Act
      final result = await notifier.getCategoryById('non-existent');

      // Assert
      expect(result, isNull);
    });

    test('returns correct category when multiple exist', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      await notifier.addCategory(Category(id: 'cat-1', name: 'Category 1'));
      await notifier.addCategory(Category(id: 'cat-2', name: 'Category 2'));
      await notifier.addCategory(Category(id: 'cat-3', name: 'Category 3'));

      // Act
      final result = await notifier.getCategoryById('cat-2');

      // Assert
      expect(result, isNotNull);
      expect(result!.id, 'cat-2');
      expect(result.getName(), 'Category 2');
    });
  });

  group('CategoriesNotifier - getCategoryByName -', () {
    test('returns category by name', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      await notifier.addCategory(Category(id: 'cat-1', name: 'Fruits'));

      // Act
      final result = await notifier.getCategoryByName('Fruits');

      // Assert
      expect(result, isNotNull);
      expect(result!.getName(), 'Fruits');
    });

    test('returns null for non-existent name', () async {
      // Arrange
      final container = ProviderContainer();

      // Act
      final result = await ProviderContainer()
          .read(categoriesProvider.notifier)
          .getCategoryByName('Non-existent');

      // Assert
      expect(result, isNull);
    });

    test('returns correct category when multiple exist', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      await notifier.addCategory(Category(id: 'cat-1', name: 'Fruits'));
      await notifier.addCategory(Category(id: 'cat-2', name: 'Vegetables'));
      await notifier.addCategory(Category(id: 'cat-3', name: 'Dairy'));

      // Act
      final result = await notifier.getCategoryByName('Vegetables');

      // Assert
      expect(result, isNotNull);
      expect(result!.getName(), 'Vegetables');
    });
  });

  group('CategoriesNotifier - getVisibleCategories -', () {
    test('returns only visible categories', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      await notifier.addCategory(
        Category(id: 'cat-1', name: 'Visible 1', isVisible: true),
      );
      await notifier.addCategory(
        Category(id: 'cat-2', name: 'Visible 2', isVisible: true),
      );
      await notifier.addCategory(
        Category(id: 'cat-3', name: 'Hidden', isVisible: false),
      );

      // Act
      final result = await notifier.getVisibleCategories();

      // Assert
      expect(result.length, 2);
      expect(
        result.map((c) => c.id).toList(),
        containsAll(['cat-1', 'cat-2']),
      );
      expect(
        result.map((c) => c.id).toList(),
        isNot(contains('cat-3')),
      );
    });

    test('returns empty list when all categories are hidden', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      await notifier.addCategory(
        Category(id: 'cat-1', name: 'Hidden 1', isVisible: false),
      );
      await notifier.addCategory(
        Category(id: 'cat-2', name: 'Hidden 2', isVisible: false),
      );

      // Act
      final result = await notifier.getVisibleCategories();

      // Assert
      expect(result, isEmpty);
    });

    test('returns all categories when all are visible', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      await notifier.addCategory(
        Category(id: 'cat-1', name: 'Category 1', isVisible: true),
      );
      await notifier.addCategory(
        Category(id: 'cat-2', name: 'Category 2', isVisible: true),
      );
      await notifier.addCategory(
        Category(id: 'cat-3', name: 'Category 3', isVisible: true),
      );

      // Act
      final result = await notifier.getVisibleCategories();

      // Assert
      expect(result.length, 3);
    });

    test('returns empty list when no categories exist', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);

      // Act
      final result = await notifier.getVisibleCategories();

      // Assert
      expect(result, isEmpty);
    });
  });

  group('Riverpod Providers - categoryByIdProvider -', () {
    test('categoryByIdProvider returns category by id', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      await notifier.addCategory(Category(id: 'cat-1', name: 'Test'));

      // Act
      final result = await container.read(
        categoryByIdProvider('cat-1').future,
      );

      // Assert
      expect(result, isNotNull);
      expect(result!.id, 'cat-1');
    });

    test('categoryByIdProvider returns null for non-existent id', () async {
      // Arrange
      final container = ProviderContainer();

      // Act
      final result = await container.read(
        categoryByIdProvider('non-existent').future,
      );

      // Assert
      expect(result, isNull);
    });
  });

  group('Riverpod Providers - categoryByNameProvider -', () {
    test('categoryByNameProvider returns category by name', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      await notifier.addCategory(Category(id: 'cat-1', name: 'Fruits'));

      // Act
      final result = await container.read(
        categoryByNameProvider('Fruits').future,
      );

      // Assert
      expect(result, isNotNull);
      expect(result!.getName(), 'Fruits');
    });

    test('categoryByNameProvider returns null for non-existent name', () async {
      // Arrange
      final container = ProviderContainer();

      // Act
      final result = await container.read(
        categoryByNameProvider('Non-existent').future,
      );

      // Assert
      expect(result, isNull);
    });
  });

  group('Riverpod Providers - visibleCategoriesProvider -', () {
    test('visibleCategoriesProvider returns only visible categories', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      await notifier.addCategory(
        Category(id: 'cat-1', name: 'Visible', isVisible: true),
      );
      await notifier.addCategory(
        Category(id: 'cat-2', name: 'Hidden', isVisible: false),
      );

      // Act
      final result = await container.read(visibleCategoriesProvider.future);

      // Assert
      expect(result.length, 1);
      expect(result[0].id, 'cat-1');
    });

    test('visibleCategoriesProvider returns empty for all hidden', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);
      await notifier.addCategory(
        Category(id: 'cat-1', name: 'Hidden', isVisible: false),
      );

      // Act
      final result = await container.read(visibleCategoriesProvider.future);

      // Assert
      expect(result, isEmpty);
    });
  });

  group('Categories Notifier - Integration -', () {
    test('workflow: add, read, update, delete categories', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);

      // Act 1: Add categories
      await notifier.addCategory(Category(id: 'cat-1', name: 'Fruits'));
      await notifier.addCategory(Category(id: 'cat-2', name: 'Vegetables'));

      // Assert 1: Initial state
      var list = await container.read(categoriesProvider.future);
      expect(list.length, 2);

      // Act 2: Get by id
      var cat1 = await notifier.getCategoryById('cat-1');
      expect(cat1, isNotNull);

      // Act 3: Update category
      cat1!.setName('Fresh Fruits');
      await notifier.updateCategory(cat1);

      // Assert 3: Updated
      var updated = await notifier.getCategoryById('cat-1');
      expect(updated!.getName(), 'Fresh Fruits');

      // Act 4: Delete category
      await notifier.deleteCategory('cat-2');

      // Assert 4: Both still exist but cat-2 is invisible
      list = await container.read(categoriesProvider.future);
      expect(list.length, 2);
      var cat2 = list.firstWhere((c) => c.id == 'cat-2');
      expect(cat2.isVisible, false);
    });

    test('ensures timestamps progress monotonically', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);

      // Act
      await notifier.addCategory(Category(id: 'cat-1', name: 'Test'));
      var cat1 = await notifier.getCategoryById('cat-1');
      var ts1 = cat1!.lastModified;

      await Future.delayed(Duration(milliseconds: 5));

      cat1.setName('Updated');
      await notifier.updateCategory(cat1);
      cat1 = await notifier.getCategoryById('cat-1');
      var ts2 = cat1!.lastModified;

      // Assert
      expect(ts2!.isAfter(ts1!), true);
    });

    test('maintains data consistency across operations', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(categoriesProvider.notifier);

      // Act: Add multiple categories
      for (int i = 1; i <= 10; i++) {
        await notifier.addCategory(
          Category(
            id: 'cat-$i',
            name: 'Category $i',
            isVisible: i % 2 == 0, // Alternate visible/hidden
          ),
        );
      }

      // Assert: Count and visibility
      final allList = await container.read(categoriesProvider.future);
      final visibleList = await notifier.getVisibleCategories();

      expect(allList.length, 10);
      expect(visibleList.length, 5);
    });
  });
}
