import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_shopping_list.dart';
import 'package:app_code/services/database/sqlite/manage_supermarket.dart';
import 'package:app_code/services/database/sqlite/manage_purchased_product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_code/services/database/sqlite/manage_product.dart';
import 'package:app_code/services/database/sqlite/manage_category.dart';

Future<void> _insertSupermarket(Supermarket market) async {
  await ManageSupermarket.addSupermarket(market);
}

Future<PurchasedProduct> _purchased({
  required String id,
  required String listId,
  required String productName,
  required String categoryName,
  double price = 0,
  int quantity = 0,
}) async {
  final product = Product(id: 'prod-$id', name: productName);
  final category = Category(id: 'cat-$id', name: categoryName);
  // Ensure dependencies exist when added directly.
  await ManageProduct.addProduct(product);
  await ManageCategory.addCategory(category);
  return PurchasedProduct(
    id: id,
    listId: listId,
    product: product,
    category: category,
    price: price,
    quantity: quantity,
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
    await db.delete('shopping_list');
    await db.delete('purchased_product');
    await db.delete('supermarket');
    await db.delete('supermarket_category');
    await db.delete('product');
    await db.delete('category');
  });

  test('addShoppingList stores list without products', () async {
    final list = ShoppingList(
      id: 'list-empty',
      name: 'Empty',
      createdAt: DateTime(2024, 1, 1),
    );

    await ManageShoppingList.addShoppingList(list);

    final fetched = await ManageShoppingList.getShoppingListById('list-empty');
    expect(fetched, isNotNull);
    expect(fetched!.getName(), 'Empty');
    expect(fetched.getProducts(), isEmpty);
  });

  test('addShoppingList persists attached products', () async {
    final list = ShoppingList(
      id: 'list-prod',
      name: 'With products',
      createdAt: DateTime(2024, 1, 2),
    );
    final item = await _purchased(
      id: 'pp-1',
      listId: 'list-prod',
      productName: 'Milk',
      categoryName: 'Dairy',
      price: 1.5,
      quantity: 2,
    );
    list.setPurchasedProducts([item]);

    await ManageShoppingList.addShoppingList(list);

    final products =
        await ManagePurchasedProduct.getPurchasedProductsByList('list-prod');
    expect(products, hasLength(1));
    expect(products.first.price, 1.5);
  });

  test('getShoppingListById returns null when missing', () async {
    final result = await ManageShoppingList.getShoppingListById('missing');
    expect(result, isNull);
  });

  test('getShoppingListById hydrates supermarket and products', () async {
    final supermarket = Supermarket(
      id: 'sup-1',
      name: 'Market',
      categories: [Category(id: 'cat-x', name: 'Shelf')],
    );
    await _insertSupermarket(supermarket);

    final list = ShoppingList(
      id: 'list-full',
      name: 'Full',
      createdAt: DateTime(2024, 1, 3),
      supermarket: supermarket,
    );
    final item = await _purchased(
      id: 'pp-2',
      listId: 'list-full',
      productName: 'Bread',
      categoryName: 'Bakery',
    );
    list.setPurchasedProducts([item]);

    await ManageShoppingList.addShoppingList(list);

    final fetched = await ManageShoppingList.getShoppingListById('list-full');
    expect(fetched, isNotNull);
    expect(fetched!.getSupermarket()!.id, 'sup-1');
    expect(fetched.getProducts(), hasLength(1));
  });

  test('getAllShoppingLists returns lists with their data', () async {
    final sup = Supermarket(
      id: 'sup-2',
      name: 'Grocer',
      categories: [Category(id: 'cat-y', name: 'Canned')],
    );
    await _insertSupermarket(sup);

    final listA = ShoppingList(
      id: 'list-a',
      name: 'A',
      createdAt: DateTime(2024, 1, 4),
      supermarket: sup,
    );
    final listB = ShoppingList(
      id: 'list-b',
      name: 'B',
      createdAt: DateTime(2024, 1, 5),
      supermarket: sup,
    );
    listA.setPurchasedProducts([
      await _purchased(
        id: 'pp-3',
        listId: 'list-a',
        productName: 'Pasta',
        categoryName: 'Canned',
      ),
    ]);

    await ManageShoppingList.addShoppingList(listA);
    await ManageShoppingList.addShoppingList(listB);

    final all = await ManageShoppingList.getAllShoppingLists();
    expect(all.map((l) => l.id).toSet(), {'list-a', 'list-b'});
    final listAProducts = all.firstWhere((l) => l.id == 'list-a').getProducts();
    expect(listAProducts, hasLength(1));
    expect(all.first.getSupermarket()!.id, 'sup-2');
  });

  test('updateShoppingList updates fields and syncs products', () async {
    final list = ShoppingList(
      id: 'list-up',
      name: 'Original',
      createdAt: DateTime(2024, 1, 6),
    );
    final original = await _purchased(
      id: 'pp-old',
      listId: 'list-up',
      productName: 'Rice',
      categoryName: 'Grains',
      price: 1,
      quantity: 1,
    );
    list.setPurchasedProducts([original]);
    await ManageShoppingList.addShoppingList(list);

    final updatedExisting = await _purchased(
      id: 'pp-old',
      listId: 'list-up',
      productName: 'Rice',
      categoryName: 'Grains',
      price: 3,
      quantity: 4,
    );
    final newItem = await _purchased(
      id: 'pp-new',
      listId: 'list-up',
      productName: 'Beans',
      categoryName: 'Canned',
      price: 2,
      quantity: 5,
    );
    list.setName('Updated');
    list.setIsRegistered(true);
    list.setIsInTheTrash(true);
    list.setPurchasedProducts([updatedExisting, newItem]);

    await ManageShoppingList.updateShoppingList(list);

    final fetched = await ManageShoppingList.getShoppingListById('list-up');
    expect(fetched, isNotNull);
    expect(fetched!.getName(), 'Updated');
    expect(fetched.getIsRegistered(), isTrue);
    expect(fetched.getIsInTheTrash(), isTrue);
    expect(fetched.getProducts(), hasLength(2));
    expect(fetched.getProducts().firstWhere((p) => p.id == 'pp-old').price, 3);
    expect(fetched.getDeletionTimestamp(), isNotNull);
  });

  test('deleteShoppingList removes list and linked purchases', () async {
    final list = ShoppingList(
      id: 'list-del',
      name: 'Delete me',
      createdAt: DateTime(2024, 1, 7),
    );
    final item = await _purchased(
      id: 'pp-del',
      listId: 'list-del',
      productName: 'Soda',
      categoryName: 'Drinks',
    );
    list.setPurchasedProducts([item]);

    await ManageShoppingList.addShoppingList(list);
    await ManageShoppingList.deleteShoppingList(list);

    final listAfter = await ManageShoppingList.getShoppingListById('list-del');
    final productsAfter =
        await ManagePurchasedProduct.getPurchasedProductsByList('list-del');
    expect(listAfter, isNull);
    expect(productsAfter, isEmpty);
  });
}