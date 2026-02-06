import 'package:app_code/models/category.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await getDatabasesPath();
    await deleteDatabase('$dbPath/shopping_app.db');
  });

  setUp(() async {
    final db = await DatabaseHelper.database;
    await db.delete('category');
  });

  test('adds and retrieves a category', () async {
    final category = Category(name: 'Fruit');

    await ManageCategory.addCategory(category);

    final all = await ManageCategory.getAllCategories();
    expect(all.length, 1);
    expect(all.first.getName(), 'Fruit');
  });

  test('finds category by name', () async {
    final category = Category(name: 'Bakery');
    await ManageCategory.addCategory(category);

    final found = await ManageCategory.getCategoryByName('Bakery');
    expect(found, isNotNull);
    expect(found!.id, category.id);
    expect(found.getName(), 'Bakery');
  });

  test('updates an existing category', () async {
  final category = Category(name: 'Drinks');
  await ManageCategory.addCategory(category);

  final updated = Category(id: category.id, name: 'Beverages');
  await ManageCategory.updateCategory(updated);

  final retrieved = await ManageCategory.getCategoryByName('Beverages');
  expect(retrieved, isNotNull);
  expect(retrieved!.id, category.id);
});

test('deletes a category', () async {
  final category = Category(name: 'Snacks');
  await ManageCategory.addCategory(category);

  await ManageCategory.deleteCategory(category.id);

  final remaining = await ManageCategory.getAllCategories();
  expect(remaining, isEmpty);
});

  test('returns null when category by id does not exist', () async {
    final result = await ManageCategory.getCategoryById('nonexistent-id');
    expect(result, isNull);
  });

  test('returns null when category by name does not exist', () async {
    final result = await ManageCategory.getCategoryByName('NonexistentName');
    expect(result, isNull);
  });

  test('finds category by id', () async {
    final category = Category(name: 'Electronics');
    await ManageCategory.addCategory(category);

    final found = await ManageCategory.getCategoryById(category.id);
    expect(found, isNotNull);
    expect(found!.id, category.id);
    expect(found.getName(), 'Electronics');
  });

  test('handles adding multiple categories', () async {
    final cat1 = Category(name: 'Category A');
    final cat2 = Category(name: 'Category B');
    final cat3 = Category(name: 'Category C');

    await ManageCategory.addCategory(cat1);
    await ManageCategory.addCategory(cat2);
    await ManageCategory.addCategory(cat3);

    final all = await ManageCategory.getAllCategories();
    expect(all.length, 3);
    expect(all.map((c) => c.getName()).toSet(), {'Category A', 'Category B', 'Category C'});
  });

  test('replaces category with same id using replace conflict algorithm', () async {
    final cat1 = Category(id: 'same-id', name: 'Original');
    final cat2 = Category(id: 'same-id', name: 'Replaced');

    await ManageCategory.addCategory(cat1);
    await ManageCategory.addCategory(cat2);

    final all = await ManageCategory.getAllCategories();
    expect(all.length, 1);
    expect(all.first.getName(), 'Replaced');
  });

  test('handles updating category with isVisible flag', () async {
    final category = Category(name: 'Default Cat', isVisible: true);
    await ManageCategory.addCategory(category);

    final updated = Category(id: category.id, name: 'Default Cat', isVisible: false);
    await ManageCategory.updateCategory(updated);

    final retrieved = await ManageCategory.getCategoryById(category.id);
    expect(retrieved, isNotNull);
    expect(retrieved!.isVisible, false);
  });

  test('handles adding category with isVisible flag', () async {
    final category = Category(name: 'Special', isVisible: true);
    await ManageCategory.addCategory(category);

    final retrieved = await ManageCategory.getCategoryById(category.id);
    expect(retrieved, isNotNull);
    expect(retrieved!.isVisible, true);
  });

  test('deletes non-existent category without error', () async {
    // Should not throw error when deleting non-existent category
    await ManageCategory.deleteCategory('nonexistent-id');

    final all = await ManageCategory.getAllCategories();
    expect(all, isEmpty);
  });

  test('handles empty database when retrieving all categories', () async {
    final all = await ManageCategory.getAllCategories();
    expect(all, isEmpty);
  });

  test('updates category name correctly', () async {
    final category = Category(id: 'cat1', name: 'Original Name', isVisible: true);
    await ManageCategory.addCategory(category);

    final updated = Category(id: 'cat1', name: 'Updated Name', isVisible: true);
    await ManageCategory.updateCategory(updated);

    final retrieved = await ManageCategory.getCategoryById('cat1');
    expect(retrieved, isNotNull);
    expect(retrieved!.getName(), 'Updated Name');
  });

  test('multiple categories with similar names can coexist', () async {
    final cat1 = Category(name: 'Fruit');
    final cat2 = Category(name: 'Fruit Juice');
    final cat3 = Category(name: 'Dried Fruit');

    await ManageCategory.addCategory(cat1);
    await ManageCategory.addCategory(cat2);
    await ManageCategory.addCategory(cat3);

    final all = await ManageCategory.getAllCategories();
    expect(all.length, 3);

    final fruitCat = await ManageCategory.getCategoryByName('Fruit');
    expect(fruitCat, isNotNull);
    expect(fruitCat!.getName(), 'Fruit');
    expect(fruitCat.id, cat1.id);
  });

  test('handles category with empty name', () async {
    final category = Category(name: '');
    await ManageCategory.addCategory(category);

    final retrieved = await ManageCategory.getCategoryById(category.id);
    expect(retrieved, isNotNull);
    expect(retrieved!.getName(), '');
  });

  test('handles updating to same values', () async {
    final category = Category(name: 'Unchanged', isVisible: true);
    await ManageCategory.addCategory(category);

    final sameCategory = Category(id: category.id, name: 'Unchanged', isVisible: true);
    await ManageCategory.updateCategory(sameCategory);

    final retrieved = await ManageCategory.getCategoryById(category.id);
    expect(retrieved, isNotNull);
    expect(retrieved!.getName(), 'Unchanged');
    expect(retrieved.isVisible, true);
  });

  test('getAllCategories returns all categories in database', () async {
    final categories = List.generate(
      5,
      (i) => Category(name: 'Category $i'),
    );

    for (final cat in categories) {
      await ManageCategory.addCategory(cat);
    }

    final all = await ManageCategory.getAllCategories();
    expect(all.length, 5);

    final names = all.map((c) => c.getName()).toSet();
    for (int i = 0; i < 5; i++) {
      expect(names.contains('Category $i'), true);
    }
  });
}
