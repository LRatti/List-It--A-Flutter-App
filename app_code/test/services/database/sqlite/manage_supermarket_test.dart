import 'package:app_code/models/category.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_supermarket.dart';
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
    // Clear tables used in tests to avoid cross-test leakage.
    await db.delete('supermarket_category');
    await db.delete('supermarket');
    await db.delete('category');
  });

  test('adds and retrieves a supermarket by id', () async {
    final category1 = Category(id: 'cat1', name: 'Fruit');
    final category2 = Category(id: 'cat2', name: 'Vegetables');

    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Super Market A',
      categories: [category1, category2],
    );

    await ManageSupermarket.addSupermarket(supermarket);

    final fetched = await ManageSupermarket.getSupermarketById('sup1');
    expect(fetched, isNotNull);
    expect(fetched!.id, 'sup1');
    expect(fetched.getName(), 'Super Market A');
    expect(fetched.getCategories().length, 2);
    expect(fetched.getCategories().map((c) => c.id).toSet(), {'cat1', 'cat2'});
  });

  test('retrieves all supermarkets', () async {
    final category = Category(id: 'cat1', name: 'Dairy');

    final super1 = Supermarket(
      id: 'sup1',
      name: 'Market One',
      categories: [category],
    );

    final super2 = Supermarket(
      id: 'sup2',
      name: 'Market Two',
    );

    await ManageSupermarket.addSupermarket(super1);
    await ManageSupermarket.addSupermarket(super2);

    final all = await ManageSupermarket.getAllSupermarkets();
    expect(all.length, 2);
    expect(all.map((s) => s.id).toSet(), {'sup1', 'sup2'});
  });

  test('finds supermarket by name', () async {
    final category = Category(id: 'cat1', name: 'Bakery');

    final supermarket = Supermarket(
      id: 'sup1',
      name: 'City Market',
      categories: [category],
    );

    await ManageSupermarket.addSupermarket(supermarket);

    final found = await ManageSupermarket.getSupermarketByName('City Market');
    expect(found, isNotNull);
    expect(found!.id, 'sup1');
    expect(found.getName(), 'City Market');
    expect(found.getCategories().length, 1);
  });

  test('updates an existing supermarket', () async {
    final category1 = Category(id: 'cat1', name: 'Meat');
    final category2 = Category(id: 'cat2', name: 'Fish');

    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Original Name',
      categories: [category1],
    );

    await ManageSupermarket.addSupermarket(supermarket);

    supermarket.setName('Updated Name');
    supermarket.setCategories([category1, category2]);

    await ManageSupermarket.updateSupermarket(supermarket);

    final updated = await ManageSupermarket.getSupermarketById('sup1');
    expect(updated, isNotNull);
    expect(updated!.getName(), 'Updated Name');
    expect(updated.getCategories().length, 2);
    expect(updated.getCategories().map((c) => c.getName()).toSet(), {'Meat', 'Fish'});
  });

  test('deletes a supermarket', () async {
    final category = Category(id: 'cat1', name: 'Snacks');

    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Market to Delete',
      categories: [category],
    );

    await ManageSupermarket.addSupermarket(supermarket);

    await ManageSupermarket.deleteSupermarket('sup1');

    final remaining = await ManageSupermarket.getAllSupermarkets();
    expect(remaining, isEmpty);
  });

  test('deletes category associations when deleting supermarket', () async {
    final db = await DatabaseHelper.database;

    final category = Category(id: 'cat1', name: 'Beverages');

    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Market with Categories',
      categories: [category],
    );

    await ManageSupermarket.addSupermarket(supermarket);

    final associationsBefore = await db.query(
      'supermarket_category',
      where: 'supermarket_id = ?',
      whereArgs: ['sup1'],
    );
    expect(associationsBefore.length, 1);

    await ManageSupermarket.deleteSupermarket('sup1');

    final associationsAfter = await db.query(
      'supermarket_category',
      where: 'supermarket_id = ?',
      whereArgs: ['sup1'],
    );
    expect(associationsAfter, isEmpty);
  });

  test('handles supermarket with no categories', () async {
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Empty Categories Market',
    );

    await ManageSupermarket.addSupermarket(supermarket);

    final fetched = await ManageSupermarket.getSupermarketById('sup1');
    expect(fetched, isNotNull);
    expect(fetched!.getName(), 'Empty Categories Market');
    expect(fetched.getCategories(), isEmpty);
  });

  test('updates supermarket categories correctly', () async {
    final cat1 = Category(id: 'cat1', name: 'Category 1');
    final cat2 = Category(id: 'cat2', name: 'Category 2');
    final cat3 = Category(id: 'cat3', name: 'Category 3');

    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Market',
      categories: [cat1, cat2],
    );

    await ManageSupermarket.addSupermarket(supermarket);

    // Update to different categories
    supermarket.setCategories([cat2, cat3]);
    await ManageSupermarket.updateSupermarket(supermarket);

    final updated = await ManageSupermarket.getSupermarketById('sup1');
    expect(updated!.getCategories().length, 2);
    expect(updated.getCategories().map((c) => c.id).toSet(), {'cat2', 'cat3'});
  });

  test('returns null when supermarket does not exist', () async {
    final result = await ManageSupermarket.getSupermarketById('nonexistent');
    expect(result, isNull);
  });

  test('returns null when supermarket name not found', () async {
    final result = await ManageSupermarket.getSupermarketByName('Nonexistent Market');
    expect(result, isNull);
  });

  test('handles empty database when retrieving all supermarkets', () async {
    final all = await ManageSupermarket.getAllSupermarkets();
    expect(all, isEmpty);
  });

  test('handles supermarket visibility flag', () async {
    final category = Category(id: 'cat1', name: 'Dairy');

    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Visible Market',
      categories: [category],
      isVisible: true,
    );

    await ManageSupermarket.addSupermarket(supermarket);

    final fetched = await ManageSupermarket.getSupermarketById('sup1');
    expect(fetched, isNotNull);
    expect(fetched!.isVisible, true);
  });

  test('updates supermarket visibility', () async {
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Market',
      isVisible: true,
    );

    await ManageSupermarket.addSupermarket(supermarket);

    supermarket.isVisible = false;
    await ManageSupermarket.updateSupermarket(supermarket);

    final updated = await ManageSupermarket.getSupermarketById('sup1');
    expect(updated, isNotNull);
    expect(updated!.isVisible, false);
  });

  test('handles adding supermarket with many categories', () async {
    final categories = List.generate(
      10,
      (i) => Category(id: 'cat$i', name: 'Category $i'),
    );

    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Big Market',
      categories: categories,
    );

    await ManageSupermarket.addSupermarket(supermarket);

    final fetched = await ManageSupermarket.getSupermarketById('sup1');
    expect(fetched, isNotNull);
    expect(fetched!.getCategories().length, 10);
  });

  test('handles updating supermarket to remove all categories', () async {
    final cat1 = Category(id: 'cat1', name: 'Category 1');
    final cat2 = Category(id: 'cat2', name: 'Category 2');

    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Market',
      categories: [cat1, cat2],
    );

    await ManageSupermarket.addSupermarket(supermarket);

    supermarket.setCategories([]);
    await ManageSupermarket.updateSupermarket(supermarket);

    final updated = await ManageSupermarket.getSupermarketById('sup1');
    expect(updated, isNotNull);
    expect(updated!.getCategories(), isEmpty);
  });

  test('handles adding multiple supermarkets with overlapping categories', () async {
    final sharedCategory = Category(id: 'cat1', name: 'Shared Category');

    final super1 = Supermarket(
      id: 'sup1',
      name: 'Market 1',
      categories: [sharedCategory],
    );

    final super2 = Supermarket(
      id: 'sup2',
      name: 'Market 2',
      categories: [sharedCategory],
    );

    await ManageSupermarket.addSupermarket(super1);
    await ManageSupermarket.addSupermarket(super2);

    final fetched1 = await ManageSupermarket.getSupermarketById('sup1');
    final fetched2 = await ManageSupermarket.getSupermarketById('sup2');

    expect(fetched1, isNotNull);
    expect(fetched2, isNotNull);
    expect(fetched1!.getCategories().first.id, 'cat1');
    expect(fetched2!.getCategories().first.id, 'cat1');
  });

  test('updates supermarket name only without affecting categories', () async {
    final category = Category(id: 'cat1', name: 'Category');

    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Original Name',
      categories: [category],
    );

    await ManageSupermarket.addSupermarket(supermarket);

    supermarket.setName('New Name');
    await ManageSupermarket.updateSupermarket(supermarket);

    final updated = await ManageSupermarket.getSupermarketById('sup1');
    expect(updated, isNotNull);
    expect(updated!.getName(), 'New Name');
    expect(updated.getCategories().length, 1);
    expect(updated.getCategories().first.getName(), 'Category');
  });

  test('handles deleting supermarket without categories', () async {
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Empty Market',
    );

    await ManageSupermarket.addSupermarket(supermarket);
    await ManageSupermarket.deleteSupermarket('sup1');

    final result = await ManageSupermarket.getSupermarketById('sup1');
    expect(result, isNull);
  });

  test(
  'updateSupermarket ignores existing category conflicts and preserves relations',
  () async {
    final db = await DatabaseHelper.database;

    // Pre-insert an existing category
    await db.insert('category', {
      'id': 'cat1',
      'name': 'Existing Category',
      'is_default': 0,
    });

    // Create initial supermarket WITHOUT categories
    final initialSupermarket = Supermarket(
      id: 'sup1',
      name: 'Market',
      isVisible: true,
      categories: [],
    );

    await ManageSupermarket.addSupermarket(initialSupermarket);

    // Update supermarket adding a category that already exists
    final updatedSupermarket = Supermarket(
      id: 'sup1',
      name: 'Market',
      isVisible: true,
      categories: [
        Category(id: 'cat1', name: 'Existing Category'),
      ],
    );

    await ManageSupermarket.updateSupermarket(updatedSupermarket);

    // --- Category must NOT be duplicated ---
    final categoryRows = await db.query(
      'category',
      where: 'id = ?',
      whereArgs: ['cat1'],
    );
    expect(categoryRows.length, 1);

    // --- Relation must exist ---
    final relationRows = await db.query(
      'supermarket_category',
      where: 'supermarket_id = ? AND category_id = ?',
      whereArgs: ['sup1', 'cat1'],
    );
    expect(relationRows.length, 1);
    expect(relationRows.first['order_index'], 0);

    // --- Fetch supermarket and verify category list ---
    final fetched =
        await ManageSupermarket.getSupermarketById('sup1');

    expect(fetched, isNotNull);
    expect(fetched!.getCategories().length, 1);
    expect(fetched.getCategories().first.id, 'cat1');
  },
);


  test('deletes supermarket that does not exist without error', () async {
    // Should not throw error when deleting non-existent supermarket
    await ManageSupermarket.deleteSupermarket('nonexistent-id');

    final all = await ManageSupermarket.getAllSupermarkets();
    expect(all, isEmpty);
  });

  test('categories are retrieved in correct order based on order_index', () async {
    final cat1 = Category(id: 'cat1', name: 'Category 1');
    final cat2 = Category(id: 'cat2', name: 'Category 2');
    final cat3 = Category(id: 'cat3', name: 'Category 3');

    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Ordered Market',
      categories: [cat1, cat2, cat3],
    );

    await ManageSupermarket.addSupermarket(supermarket);

    final fetched = await ManageSupermarket.getSupermarketById('sup1');
    expect(fetched, isNotNull);
    expect(fetched!.getCategories().length, 3);
    expect(fetched.getCategories()[0].id, 'cat1');
    expect(fetched.getCategories()[1].id, 'cat2');
    expect(fetched.getCategories()[2].id, 'cat3');
  });

  test('getSupermarketCategories returns categories in order', () async {
    final cat1 = Category(id: 'cat1', name: 'Category 1');
    final cat2 = Category(id: 'cat2', name: 'Category 2');
    final cat3 = Category(id: 'cat3', name: 'Category 3');

    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Market',
      categories: [cat1, cat2, cat3],
    );

    await ManageSupermarket.addSupermarket(supermarket);

    final categories = await ManageSupermarket.getSupermarketCategories('sup1');
    expect(categories.length, 3);
    expect(categories[0].id, 'cat1');
    expect(categories[1].id, 'cat2');
    expect(categories[2].id, 'cat3');
  });

  test('addCategoryToSupermarket adds category with specific order', () async {
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Market',
    );

    await ManageSupermarket.addSupermarket(supermarket);

    final cat1 = Category(id: 'cat1', name: 'Category 1');
    final cat2 = Category(id: 'cat2', name: 'Category 2');
    final cat3 = Category(id: 'cat3', name: 'Category 3');

    await ManageSupermarket.addCategoryToSupermarket('sup1', cat1, 0);
    await ManageSupermarket.addCategoryToSupermarket('sup1', cat2, 1);
    await ManageSupermarket.addCategoryToSupermarket('sup1', cat3, 2);

    final categories = await ManageSupermarket.getSupermarketCategories('sup1');
    expect(categories.length, 3);
    expect(categories[0].id, 'cat1');
    expect(categories[1].id, 'cat2');
    expect(categories[2].id, 'cat3');
  });

  test('reorderCategories reorders multiple categories at once', () async {
    final cat1 = Category(id: 'cat1', name: 'Category 1');
    final cat2 = Category(id: 'cat2', name: 'Category 2');
    final cat3 = Category(id: 'cat3', name: 'Category 3');

    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Market',
      categories: [cat1, cat2, cat3],
    );

    await ManageSupermarket.addSupermarket(supermarket);

    // Reorder: cat3 at position 0, cat1 at position 1, cat2 at position 2
    await ManageSupermarket.reorderCategories('sup1', {
      'cat3': 0,
      'cat1': 1,
      'cat2': 2,
    });

    final categories = await ManageSupermarket.getSupermarketCategories('sup1');
    expect(categories.length, 3);
    expect(categories[0].id, 'cat3');
    expect(categories[1].id, 'cat1');
    expect(categories[2].id, 'cat2');
  });

  test('updating supermarket maintains category order', () async {
    final cat1 = Category(id: 'cat1', name: 'Category 1');
    final cat2 = Category(id: 'cat2', name: 'Category 2');
    final cat3 = Category(id: 'cat3', name: 'Category 3');

    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Original Name',
      categories: [cat1, cat2, cat3],
    );

    await ManageSupermarket.addSupermarket(supermarket);

    supermarket.setName('Updated Name');
    supermarket.setCategories([cat1, cat2, cat3]);
    await ManageSupermarket.updateSupermarket(supermarket);

    final updated = await ManageSupermarket.getSupermarketById('sup1');
    expect(updated, isNotNull);
    expect(updated!.getName(), 'Updated Name');
    expect(updated.getCategories().length, 3);
    expect(updated.getCategories()[0].id, 'cat1');
    expect(updated.getCategories()[1].id, 'cat2');
    expect(updated.getCategories()[2].id, 'cat3');
  });

  test('replaces supermarket categories with a new ordered list', () async {
    final db = await DatabaseHelper.database;

    final cat1 = Category(id: 'cat1', name: 'Category 1');
    final cat2 = Category(id: 'cat2', name: 'Category 2');
    final cat3 = Category(id: 'cat3', name: 'Category 3');

    // Initial supermarket with cat1, cat2
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Market',
      categories: [cat1, cat2],
    );

    await ManageSupermarket.addSupermarket(supermarket);

    // Replace categories with a new ordered list
    await ManageSupermarket.replaceCategoriesOrder(
      'sup1',
      [cat1, cat3],
    );

    // Fetch current categories from DB
    final result = await db.rawQuery('''
      SELECT c.id, sc.order_index
      FROM category c
      JOIN supermarket_category sc ON sc.category_id = c.id
      WHERE sc.supermarket_id = ?
      ORDER BY sc.order_index ASC
    ''', ['sup1']);

    // --- Only new categories must exist ---
    expect(result.length, 2);

    // cat2 must be gone
    final ids = result.map((row) => row['id']).toList();
    expect(ids, containsAll(['cat1', 'cat3']));
    expect(ids, isNot(contains('cat2')));

    // --- Order must match the provided list ---
    expect(result[0]['id'], 'cat1');
    expect(result[0]['order_index'], 0);

    expect(result[1]['id'], 'cat3');
    expect(result[1]['order_index'], 1);
  });


  test('handles empty category list when updating supermarket', () async {
    final cat1 = Category(id: 'cat1', name: 'Category 1');

    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Market',
      categories: [cat1],
    );

    await ManageSupermarket.addSupermarket(supermarket);

    supermarket.setCategories([]);
    await ManageSupermarket.updateSupermarket(supermarket);

    final categories = await ManageSupermarket.getSupermarketCategories('sup1');
    expect(categories, isEmpty);
  });

  // Test replacing supermarket categories with a new ordered list
  test('replaces supermarket categories with a new ordered list', () async {
    final db = await DatabaseHelper.database;

    final cat1 = Category(id: 'cat1', name: 'Category 1');
    final cat2 = Category(id: 'cat2', name: 'Category 2');
    final cat3 = Category(id: 'cat3', name: 'Category 3');

    // Initial supermarket with cat1 and cat2
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Market',
      categories: [cat1, cat2],
    );

    await ManageSupermarket.addSupermarket(supermarket);

    // Replace categories with a new list: cat1 and cat3
    await ManageSupermarket.replaceCategoriesOrder(
      'sup1',
      [cat1, cat3],
    );

    // Fetch current categories from DB
    final result = await db.rawQuery('''
      SELECT c.id, sc.order_index
      FROM category c
      JOIN supermarket_category sc ON sc.category_id = c.id
      WHERE sc.supermarket_id = ?
      ORDER BY sc.order_index ASC
    ''', ['sup1']);

    // --- Only new categories must exist ---
    expect(result.length, 2);

    // cat2 must be removed
    final ids = result.map((row) => row['id']).toList();
    expect(ids, containsAll(['cat1', 'cat3']));
    expect(ids, isNot(contains('cat2')));

    // --- Verify order matches provided list ---
    expect(result[0]['id'], 'cat1');
    expect(result[0]['order_index'], 0);
    expect(result[1]['id'], 'cat3');
    expect(result[1]['order_index'], 1);
  });

  // Test handling empty category list when replacing supermarket categories
  test('handles empty category list when replacing supermarket categories', () async {
    final cat1 = Category(id: 'cat1', name: 'Category 1');

    // Create supermarket with one category
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Market',
      categories: [cat1],
    );

    await ManageSupermarket.addSupermarket(supermarket);

    // Replace categories with empty list
    await ManageSupermarket.replaceCategoriesOrder('sup1', []);

    final categories = await ManageSupermarket.getSupermarketCategories('sup1');
    expect(categories, isEmpty);
  });

  // Test that replacing categories preserves existing category entries in DB
  test('does not duplicate existing categories when replacing supermarket categories', () async {
    final db = await DatabaseHelper.database;

    // Pre-insert a category
    await db.insert('category', {
      'id': 'cat1',
      'name': 'Existing Category',
      'is_default': 0,
    });

    // Create supermarket with no categories
    final supermarket = Supermarket(
      id: 'sup1',
      name: 'Market',
      categories: [],
    );

    await ManageSupermarket.addSupermarket(supermarket);

    // Replace categories including the existing one
    final newCat = Category(id: 'cat1', name: 'Existing Category');
    await ManageSupermarket.replaceCategoriesOrder('sup1', [newCat]);

    // --- Verify category is not duplicated ---
    final categoryRows = await db.query('category', where: 'id = ?', whereArgs: ['cat1']);
    expect(categoryRows.length, 1);

    // --- Relation must exist ---
    final relationRows = await db.query(
      'supermarket_category',
      where: 'supermarket_id = ? AND category_id = ?',
      whereArgs: ['sup1', 'cat1'],
    );
    expect(relationRows.length, 1);
    expect(relationRows.first['order_index'], 0);

    // --- Fetch supermarket and verify category list ---
    final fetched = await ManageSupermarket.getSupermarketById('sup1');
    expect(fetched, isNotNull);
    expect(fetched!.getCategories().length, 1);
    expect(fetched.getCategories().first.id, 'cat1');
  });


}
