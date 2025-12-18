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
}
