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

    test('removeProduct removes specific product from list', () {
      final list = buildList();
      final purchased1 = PurchasedProduct(
        id: 'pp1',
        listId: 'list1',
        product: product,
        category: category,
        price: 1.0,
        quantity: 1,
      );
      final purchased2 = PurchasedProduct(
        id: 'pp2',
        listId: 'list1',
        product: product,
        category: category,
        price: 2.0,
        quantity: 2,
      );

      list.addPurchasedProduct(purchased1);
      list.addPurchasedProduct(purchased2);

      list.removeProduct(purchased1);

      expect(list.products?.length, 1);
      expect(list.products?.first.id, 'pp2');
    });

    test('getDaysUntilDeletion returns null when not in trash', () {
      final list = buildList();

      expect(list.getDaysUntilDeletion(), null);
    });

    test('getDaysUntilDeletion returns correct remaining days', () {
      final list = buildList();
      list.setIsInTheTrash(true);
      list.setDeletionTimestamp(DateTime.now().subtract(const Duration(days: 10)));

      final daysRemaining = list.getDaysUntilDeletion();
      expect(daysRemaining, greaterThanOrEqualTo(19));
      expect(daysRemaining, lessThanOrEqualTo(20));
    });

    test('getDeletionMessage for different day counts', () {
      final list = buildList();
      list.setIsInTheTrash(true);

      list.setDeletionTimestamp(DateTime.now().subtract(const Duration(days: 29)));
      expect(list.getDeletionMessage(), 'Delete in 1 day');

      list.setDeletionTimestamp(DateTime.now().subtract(const Duration(days: 25)));
      expect(list.getDeletionMessage(), contains('Delete in'));
      expect(list.getDeletionMessage(), contains('days'));

      list.setDeletionTimestamp(DateTime.now().subtract(const Duration(days: 35)));
      expect(list.getDeletionMessage(), 'Deleting now...');
    });

    test('getProductByName returns null when product not found', () {
      final list = buildList();
      final purchased = PurchasedProduct(
        id: 'pp1',
        listId: 'list1',
        product: product,
        category: category,
        price: 1.0,
        quantity: 1,
      );
      list.addPurchasedProduct(purchased);

      final result = list.getProductByName('Nonexistent');
      expect(result, isNull);
    });

    test('setImage updates image path', () {
      final list = buildList();
      
      list.setImage('/path/to/image.jpg');
      expect(list.image, '/path/to/image.jpg');

      list.setImage('/new/path.png');
      expect(list.image, '/new/path.png');
    });

    test('setIsRegistered updates registered flag', () {
      final list = buildList();
      
      expect(list.getIsRegistered(), false);
      
      list.setIsRegistered(true);
      expect(list.getIsRegistered(), true);

      list.setIsRegistered(false);
      expect(list.getIsRegistered(), false);
    });

    test('setSupermarket updates supermarket', () {
      final list = buildList();
      final newSupermarket = Supermarket(id: 'sup2', name: 'New Market');

      list.setSupermarket(newSupermarket);

      expect(list.getSupermarket()?.id, 'sup2');
      expect(list.getSupermarket()?.getName(), 'New Market');
    });

    test('computeTotalPrice with empty products', () {
      final list = buildList();

      list.computeTotalPrice();

      expect(list.getTotalPrice(), 0.0);
    });

    test('fromDatabase handles missing optional fields', () {
      final db = {
        'id': 'list2',
        'name': 'Minimal List',
        'created_at': DateTime.now().toIso8601String(),
      };

      final list = ShoppingList.fromDatabase(db);

      expect(list.id, 'list2');
      expect(list.getName(), 'Minimal List');
      expect(list.getTotalPrice(), 0.0);
      expect(list.image, isNull);
      expect(list.getIsRegistered(), false);
      expect(list.getIsInTheTrash(), false);
    });

    test('fromDatabase handles malformed created_at', () {
      final db = {
        'id': 'list3',
        'name': 'Bad Date List',
        'created_at': 'not-a-date',
      };

      final list = ShoppingList.fromDatabase(db);

      expect(list.id, 'list3');
      expect(list.getCreatedAt(), isNotNull);
    });

    test('toJson includes supermarket_id', () {
      final list = buildList();
      
      final json = list.toJson();

      expect(json['supermarket_id'], 'sup1');
    });

    test('addProduct with same product multiple times creates separate entries', () {
      final list = buildList();

      list.addProduct(product, category);
      list.addProduct(product, category);

      expect(list.products?.length, 2);
    });

    test('registerProduct does nothing if product not found', () {
      final list = buildList();

      list.registerProduct('Nonexistent', 10.0, 5);

      // Should not crash or throw error
      expect(list.products, anyOf(isNull, isEmpty));
    });

    test('getDeletionMessage returns empty string when not in trash', () {
      final list = buildList();

      expect(list.getDeletionMessage(), '');
    });
  });
}
