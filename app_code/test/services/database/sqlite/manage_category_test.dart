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

  test('handles updating category with isDefault flag', () async {
    final category = Category(name: 'Default Cat', isDefault: true);
    await ManageCategory.addCategory(category);

    final updated = Category(id: category.id, name: 'Default Cat', isDefault: false);
    await ManageCategory.updateCategory(updated);

    final retrieved = await ManageCategory.getCategoryById(category.id);
    expect(retrieved, isNotNull);
    expect(retrieved!.isDefault, false);
  });

  test('handles adding category with isDefault flag', () async {
    final category = Category(name: 'Special', isDefault: true);
    await ManageCategory.addCategory(category);

    final retrieved = await ManageCategory.getCategoryById(category.id);
    expect(retrieved, isNotNull);
    expect(retrieved!.isDefault, true);
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
}
