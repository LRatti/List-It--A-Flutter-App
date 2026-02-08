import 'package:app_code/services/database/sqlite/database_helper.dart';
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

  test('database is created successfully', () async {
    final db = await DatabaseHelper.database;
    expect(db, isNotNull);
    expect(db.isOpen, true);
  });

  test('database returns the same instance on multiple calls', () async {
    final db1 = await DatabaseHelper.database;
    final db2 = await DatabaseHelper.database;

    expect(db1, same(db2));
  });

  test('shopping_list table exists with correct schema', () async {
    final db = await DatabaseHelper.database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='shopping_list'",
    );
    expect(tables.length, 1);

    final columns = await db.rawQuery("PRAGMA table_info(shopping_list)");
    final columnNames = columns.map((c) => c['name'] as String).toList();

    expect(columnNames, contains('id'));
    expect(columnNames, contains('name'));
    expect(columnNames, contains('created_at'));
    expect(columnNames, contains('supermarket_id'));
    expect(columnNames, contains('total_price'));
    expect(columnNames, contains('image'));
    expect(columnNames, contains('is_registered'));
    expect(columnNames, contains('is_in_the_trash'));
    expect(columnNames, contains('deletion_timestamp'));
  });

  test('product table exists with correct schema', () async {
    final db = await DatabaseHelper.database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='product'",
    );
    expect(tables.length, 1);

    final columns = await db.rawQuery("PRAGMA table_info(product)");
    final columnNames = columns.map((c) => c['name'] as String).toList();

    expect(columnNames, contains('id'));
    expect(columnNames, contains('name'));
    expect(columnNames, contains('is_visible'));
    expect(columnNames, contains('created_at'));
    expect(columnNames, contains('last_modified'));
  });

  test('category table exists with correct schema', () async {
    final db = await DatabaseHelper.database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='category'",
    );
    expect(tables.length, 1);

    final columns = await db.rawQuery("PRAGMA table_info(category)");
    final columnNames = columns.map((c) => c['name'] as String).toList();

    expect(columnNames, contains('id'));
    expect(columnNames, contains('name'));
    expect(columnNames, contains('is_visible'));
    expect(columnNames, contains('created_at'));
    expect(columnNames, contains('last_modified'));
  });

  test('associations table exists with correct schema', () async {
    final db = await DatabaseHelper.database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='associations'",
    );
    expect(tables.length, 1);

    final columns = await db.rawQuery("PRAGMA table_info(associations)");
    final columnNames = columns.map((c) => c['name'] as String).toList();

    expect(columnNames, contains('product_id'));
    expect(columnNames, contains('supermarket_id'));
    expect(columnNames, contains('category_id'));
  });

  test('supermarket table exists with correct schema', () async {
    final db = await DatabaseHelper.database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='supermarket'",
    );
    expect(tables.length, 1);

    final columns = await db.rawQuery("PRAGMA table_info(supermarket)");
    final columnNames = columns.map((c) => c['name'] as String).toList();

    expect(columnNames, contains('id'));
    expect(columnNames, contains('name'));
    expect(columnNames, contains('is_visible'));
  });

  test('supermarket_category table exists with correct schema', () async {
    final db = await DatabaseHelper.database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='supermarket_category'",
    );
    expect(tables.length, 1);

    final columns = await db.rawQuery("PRAGMA table_info(supermarket_category)");
    final columnNames = columns.map((c) => c['name'] as String).toList();

    expect(columnNames, contains('supermarket_id'));
    expect(columnNames, contains('category_id'));
    expect(columnNames, contains('order_index'));
  });

  test('purchased_product table exists with correct schema', () async {
    final db = await DatabaseHelper.database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='purchased_product'",
    );
    expect(tables.length, 1);

    final columns = await db.rawQuery("PRAGMA table_info(purchased_product)");
    final columnNames = columns.map((c) => c['name'] as String).toList();

    expect(columnNames, contains('id'));
    expect(columnNames, contains('list_id'));
    expect(columnNames, contains('product_id'));
    expect(columnNames, contains('category_id'));
    expect(columnNames, contains('price'));
    expect(columnNames, contains('quantity'));
    expect(columnNames, contains('created_at'));
    expect(columnNames, contains('last_modified'));
    expect(columnNames, contains('is_deleted'));
    expect(columnNames, contains('is_bought'));
  });

  test('recipe_cache table exists with correct schema', () async {
    final db = await DatabaseHelper.database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='recipe_cache'",
    );
    expect(tables.length, 1);

    final columns = await db.rawQuery("PRAGMA table_info(recipe_cache)");
    final columnNames = columns.map((c) => c['name'] as String).toList();

    expect(columnNames, contains('list_id'));
    expect(columnNames, contains('recipe_name'));
    expect(columnNames, contains('recipe_data'));
    expect(columnNames, contains('error_message'));
    expect(columnNames, contains('has_seen_notification'));
    expect(columnNames, contains('created_at'));
  });

  test('all expected tables are created', () async {
    final db = await DatabaseHelper.database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );

    final tableNames = tables.map((t) => t['name'] as String).toSet();

    expect(tableNames, contains('shopping_list'));
    expect(tableNames, contains('product'));
    expect(tableNames, contains('category'));
    expect(tableNames, contains('associations'));
    expect(tableNames, contains('supermarket'));
    expect(tableNames, contains('supermarket_category'));
    expect(tableNames, contains('purchased_product'));
    expect(tableNames, contains('recipe_cache'));
  });

  test('shopping_list primary key is id', () async {
    final db = await DatabaseHelper.database;

    final columns = await db.rawQuery("PRAGMA table_info(shopping_list)");
    final idColumn = columns.firstWhere((c) => c['name'] == 'id');

    expect(idColumn['pk'], 1);
  });

  test('product primary key is id', () async {
    final db = await DatabaseHelper.database;

    final columns = await db.rawQuery("PRAGMA table_info(product)");
    final idColumn = columns.firstWhere((c) => c['name'] == 'id');

    expect(idColumn['pk'], 1);
  });

  test('category primary key is id', () async {
    final db = await DatabaseHelper.database;

    final columns = await db.rawQuery("PRAGMA table_info(category)");
    final idColumn = columns.firstWhere((c) => c['name'] == 'id');

    expect(idColumn['pk'], 1);
  });

  test('associations has composite primary key', () async {
    final db = await DatabaseHelper.database;

    final columns = await db.rawQuery("PRAGMA table_info(associations)");
    final primaryKeys = columns.where((c) => c['pk'] != 0).toList();

    expect(primaryKeys.length, 2);
    final pkNames = primaryKeys.map((c) => c['name'] as String).toSet();
    expect(pkNames, contains('product_id'));
    expect(pkNames, contains('supermarket_id'));
  });

  test('supermarket_category has composite primary key', () async {
    final db = await DatabaseHelper.database;

    final columns = await db.rawQuery("PRAGMA table_info(supermarket_category)");
    final primaryKeys = columns.where((c) => c['pk'] != 0).toList();

    expect(primaryKeys.length, 2);
    final pkNames = primaryKeys.map((c) => c['name'] as String).toSet();
    expect(pkNames, contains('supermarket_id'));
    expect(pkNames, contains('category_id'));
  });

  test('recipe_cache primary key is list_id', () async {
    final db = await DatabaseHelper.database;

    final columns = await db.rawQuery("PRAGMA table_info(recipe_cache)");
    final idColumn = columns.firstWhere((c) => c['name'] == 'list_id');

    expect(idColumn['pk'], 1);
  });

  test('shopping_list is_in_the_trash has default value', () async {
    final db = await DatabaseHelper.database;

    // Insert row without specifying is_in_the_trash
    await db.insert('shopping_list', {
      'id': 'test-list',
      'name': 'Test',
      'created_at': DateTime.now().toIso8601String(),
      'last_modified': DateTime.now().toIso8601String(),
      'is_registered': 0,
    });

    final result = await db.query('shopping_list', where: 'id = ?', whereArgs: ['test-list']);
    expect(result.first['is_in_the_trash'], 0);

    await db.delete('shopping_list', where: 'id = ?', whereArgs: ['test-list']);
  });

  test('recipe_cache has_seen_notification has default value', () async {
    final db = await DatabaseHelper.database;

    // Insert shopping list first (foreign key)
    await db.insert('shopping_list', {
      'id': 'test-list',
      'name': 'Test',
      'created_at': DateTime.now().toIso8601String(),
      'last_modified': DateTime.now().toIso8601String(),
      'is_registered': 0,
    });

    // Insert recipe cache without specifying has_seen_notification
    await db.insert('recipe_cache', {
      'list_id': 'test-list',
      'recipe_name': 'Test Recipe',
      'recipe_data': '{}',
      'created_at': DateTime.now().toIso8601String(),
    });

    final result = await db.query('recipe_cache', where: 'list_id = ?', whereArgs: ['test-list']);
    expect(result.first['has_seen_notification'], 0);

    await db.delete('recipe_cache', where: 'list_id = ?', whereArgs: ['test-list']);
    await db.delete('shopping_list', where: 'id = ?', whereArgs: ['test-list']);
  });

  test('database version is 5', () async {
    final db = await DatabaseHelper.database;
    final version = await db.getVersion();
    expect(version, 5);
  });

  test('can insert and query data from shopping_list', () async {
    final db = await DatabaseHelper.database;

    await db.insert('shopping_list', {
      'id': 'test-id',
      'name': 'Test List',
      'created_at': DateTime.now().toIso8601String(),
      'last_modified': DateTime.now().toIso8601String(),
      'is_registered': 1,
      'is_in_the_trash': 0,
    });

    final result = await db.query('shopping_list', where: 'id = ?', whereArgs: ['test-id']);
    expect(result.length, 1);
    expect(result.first['name'], 'Test List');

    await db.delete('shopping_list', where: 'id = ?', whereArgs: ['test-id']);
  });

  test('can insert and query data from product', () async {
    final db = await DatabaseHelper.database;

    await db.insert('product', {
      'id': 'prod-id',
      'name': 'Test Product',
      'is_visible': 1,
      'created_at': DateTime.now().toIso8601String(),
      'last_modified': DateTime.now().toIso8601String(),
    });

    final result = await db.query('product', where: 'id = ?', whereArgs: ['prod-id']);
    expect(result.length, 1);
    expect(result.first['name'], 'Test Product');

    await db.delete('product', where: 'id = ?', whereArgs: ['prod-id']);
  });

  test('can insert and query data from category', () async {
    final db = await DatabaseHelper.database;

    await db.insert('category', {
      'id': 'cat-id',
      'name': 'Test Category',
      'is_visible': 1,
      'created_at': DateTime.now().toIso8601String(),
      'last_modified': DateTime.now().toIso8601String(),
    });

    final result = await db.query('category', where: 'id = ?', whereArgs: ['cat-id']);
    expect(result.length, 1);
    expect(result.first['name'], 'Test Category');
    expect(result.first['is_visible'], 1);

    await db.delete('category', where: 'id = ?', whereArgs: ['cat-id']);
  });
}
