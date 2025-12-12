import 'package:app_code/models/category.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
	// Use the FFI implementation so sqflite works in unit tests (no platform channels).
	setUpAll(() async {
		sqfliteFfiInit();
		databaseFactory = databaseFactoryFfi;

		// Ensure the database starts empty for the suite.
		final dbPath = await getDatabasesPath();
		await deleteDatabase('$dbPath/shopping_app.db');
	});

	// Clear the category table before each test to avoid cross-test leakage.
	setUp(() async {
		final db = await DatabaseHelper.database;
		await db.delete('category');
	});

	test('adds and retrieves a category', () async {
		final category = Category(name: 'Fruit');

		final inserted = await ManageCategory.addCategory(category);
		expect(inserted, greaterThan(0));

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
		final count = await ManageCategory.updateCategory(updated);
		expect(count, 1);

		final retrieved = await ManageCategory.getCategoryByName('Beverages');
		expect(retrieved, isNotNull);
		expect(retrieved!.id, category.id);
	});

	test('deletes a category', () async {
		final category = Category(name: 'Snacks');
		await ManageCategory.addCategory(category);

		final deleted = await ManageCategory.deleteCategory(category.id);
		expect(deleted, 1);

		final remaining = await ManageCategory.getAllCategories();
		expect(remaining, isEmpty);
	});
}