import 'package:app_code/models/category.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_supermarket.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Supermarket _market(String id,
    {String name = 'Market', List<Category>? categories, bool isVisible = true}) {
  return Supermarket(
    id: id,
    name: name,
    isVisible: isVisible,
    categories: categories ?? [Category(id: 'cat-$id', name: 'Cat $id')],
  );
}

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

  test('addSupermarket saves market and categories', () async {
    final market = _market('sup-1');

    await ManageSupermarket.addSupermarket(market);

    final fetched = await ManageSupermarket.getSupermarketById('sup-1');
    expect(fetched, isNotNull);
    expect(fetched!.getCategories(), hasLength(1));
    expect(fetched.getCategories().first.id, 'cat-sup-1');
  });

  test('getAllSupermarkets returns stored markets with ordered categories',
      () async {
    final marketA = _market('sup-a', categories: [
      Category(id: 'c1', name: 'One'),
      Category(id: 'c2', name: 'Two'),
    ]);
    final marketB = _market('sup-b');

    await ManageSupermarket.addSupermarket(marketA);
    await ManageSupermarket.addSupermarket(marketB);

    final all = await ManageSupermarket.getAllSupermarkets();
    expect(all.map((m) => m.id).toSet(), {'sup-a', 'sup-b'});
    final catOrder = all.firstWhere((m) => m.id == 'sup-a').getCategories();
    expect(catOrder.map((c) => c.id).toList(), ['c1', 'c2']);
  });

  test('getSupermarketByName resolves by name', () async {
    final market = _market('sup-name', name: 'Friendly');
    await ManageSupermarket.addSupermarket(market);

    final fetched = await ManageSupermarket.getSupermarketByName('Friendly');
    final missing = await ManageSupermarket.getSupermarketByName('Nope');

    expect(fetched, isNotNull);
    expect(fetched!.id, 'sup-name');
    expect(missing, isNull);
  });

  test('updateSupermarket updates fields and category order', () async {
    final market = _market('sup-up', categories: [
      Category(id: 'ca', name: 'A'),
      Category(id: 'cb', name: 'B'),
    ]);
    await ManageSupermarket.addSupermarket(market);

    final updated = Supermarket(
      id: 'sup-up',
      name: 'Updated',
      isVisible: false,
      categories: [Category(id: 'cb', name: 'B'), Category(id: 'ca', name: 'A')],
    );

    await ManageSupermarket.updateSupermarket(updated);

    final fetched = await ManageSupermarket.getSupermarketById('sup-up');
    expect(fetched, isNotNull);
    expect(fetched!.getName(), 'Updated');
    expect(fetched.isVisible, isFalse);
    expect(fetched.getCategories().map((c) => c.id).toList(), ['cb', 'ca']);
  });

  test('replaceCategoriesOrder rewrites associations with new order', () async {
    final market = _market('sup-repl', categories: [
      Category(id: 'c1', name: 'One'),
      Category(id: 'c2', name: 'Two'),
    ]);
    await ManageSupermarket.addSupermarket(market);

    final newOrder = [Category(id: 'c2', name: 'Two'), Category(id: 'c1', name: 'One')];
    await ManageSupermarket.replaceCategoriesOrder('sup-repl', newOrder);

    final cats = await ManageSupermarket.getSupermarketCategories('sup-repl');
    expect(cats.map((c) => c.id).toList(), ['c2', 'c1']);
  });

  test('addCategoryToSupermarket inserts category at position', () async {
    final market = _market('sup-add', categories: []);
    await ManageSupermarket.addSupermarket(market);

    final cat = Category(id: 'c-new', name: 'Fresh');
    await ManageSupermarket.addCategoryToSupermarket('sup-add', cat, 0);

    final cats = await ManageSupermarket.getSupermarketCategories('sup-add');
    expect(cats.map((c) => c.id).toList(), ['c-new']);
  });

  test('reorderCategories updates order_index for mapped categories', () async {
    final market = _market('sup-reorder', categories: [
      Category(id: 'c1', name: 'One'),
      Category(id: 'c2', name: 'Two'),
    ]);
    await ManageSupermarket.addSupermarket(market);

    await ManageSupermarket.reorderCategories('sup-reorder', {'c1': 1, 'c2': 0});

    final cats = await ManageSupermarket.getSupermarketCategories('sup-reorder');
    expect(cats.map((c) => c.id).toList(), ['c2', 'c1']);
  });

  test('deleteSupermarket removes market and category links', () async {
    final market = _market('sup-del');
    await ManageSupermarket.addSupermarket(market);

    await ManageSupermarket.deleteSupermarket('sup-del');

    final fetched = await ManageSupermarket.getSupermarketById('sup-del');
    final cats = await ManageSupermarket.getSupermarketCategories('sup-del');
    expect(fetched, isNull);
    expect(cats, isEmpty);
  });

}
