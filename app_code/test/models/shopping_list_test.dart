import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShoppingList', () {
    final supermarket = Supermarket(id: 'sup1', name: 'Market');
    final category = Category(id: 'cat1', name: 'Fruit');
    final product = Product(id: 'prod1', name: 'Apple');

    ShoppingList buildList() {
      return ShoppingList(
        id: 'list1',
        name: 'Weekly',
        createdAt: DateTime(2024, 1, 1),
        supermarket: supermarket,
        products: [],
        isRegistered: false,
      );
    }

    test('defaults when supermarket not provided', () {
      final list = ShoppingList(id: 'listX', name: 'No market', createdAt: DateTime.now());

      expect(list.getSupermarket(), isNotNull);
      expect(list.getName(), 'No market');
      expect(list.getIsRegistered(), false);
      expect(list.getIsInTheTrash(), false);
    });

    test('toDatabase and fromDatabase roundtrip', () {
      final list = buildList();

      final db = list.toDatabase();
      final restored = ShoppingList.fromDatabase(db);

      expect(restored.id, 'list1');
      expect(restored.getName(), 'Weekly');
      expect(restored.getTotalPrice(), 0.0);
      expect(restored.getIsRegistered(), false);
    });

    test('toJson and fromJson roundtrip', () {
      final purchased = PurchasedProduct(
        id: 'pp1',
        listId: 'list1',
        product: product,
        category: category,
        price: 2.5,
        quantity: 2,
      );
      final list = buildList();
      list.addPurchasedProduct(purchased);

      final json = list.toJson();
      final restored = ShoppingList.fromJson(json);

      expect(restored.id, 'list1');
      expect(restored.getName(), 'Weekly');
      expect(restored.products?.length, 1);
      expect(restored.products?.first.price, 2.5);
    });

    test('addProduct creates purchased product with defaults', () {
      final list = buildList();

      list.addProduct(product, category);

      expect(list.products?.length, 1);
      final added = list.products!.first;
      expect(added.listId, 'list1');
      expect(added.product.id, 'prod1');
      expect(added.category.id, 'cat1');
      expect(added.price, 0.0);
      expect(added.quantity, 1);
    });

    test('registerProduct updates price and quantity', () {
      final list = buildList();
      list.addProduct(product, category);

      list.registerProduct('Apple', 3.0, 4);

      final registered = list.getProductByName('Apple');
      expect(registered?.price, 3.0);
      expect(registered?.quantity, 4);
    });

    test('remove helpers', () {
      final list = buildList();
      final purchased = PurchasedProduct(
        id: 'pp2',
        listId: 'list1',
        product: product,
        category: category,
        price: 1.0,
        quantity: 1,
      );
      list.addPurchasedProduct(purchased);

      list.removeProductById('pp2');
      expect(list.products, isEmpty);

      list.addPurchasedProduct(purchased);
      list.removeAllProducts();
      expect(list.products, isEmpty);
    });

    test('computeTotalPrice sums product prices', () {
      final list = buildList();
      list.addPurchasedProduct(PurchasedProduct(
        id: 'pp3',
        listId: 'list1',
        product: product,
        category: category,
        price: 2.0,
        quantity: 1,
      ));
      list.addPurchasedProduct(PurchasedProduct(
        id: 'pp4',
        listId: 'list1',
        product: product,
        category: category,
        price: 3.0,
        quantity: 2,
      ));

      list.computeTotalPrice();

      expect(list.getTotalPrice(), 5.0);
    });

    test('trash state sets deletion timestamp and messages', () {
      final list = buildList();

      list.setIsInTheTrash(true);
      expect(list.getIsInTheTrash(), true);
      expect(list.getDeletionTimestamp(), isNotNull);
      expect(list.getDeletionMessage().isNotEmpty, true);

      list.setIsInTheTrash(false);
      expect(list.getIsInTheTrash(), false);
      expect(list.getDeletionTimestamp(), isNull);
      expect(list.getDeletionMessage(), '');
    });

    test('days until deletion clamps at zero', () {
      final list = buildList();
      list.setIsInTheTrash(true);

      list.setDeletionTimestamp(DateTime.now().subtract(const Duration(days: 40)));

      expect(list.getDaysUntilDeletion(), 0);
    });
  });
}
