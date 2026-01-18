import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PurchasedProduct', () {
    final category = Category(id: 'cat1', name: 'Snacks');
    final product = Product(id: 'prod1', name: 'Chips');

    test('defaults price and quantity', () {
      final purchased = PurchasedProduct(listId: 'list1', product: product, category: category);

      expect(purchased.id.isNotEmpty, true);
      expect(purchased.price, 0.0);
      expect(purchased.quantity, 0);
      expect(purchased.product.id, 'prod1');
      expect(purchased.category.id, 'cat1');
    });

    test('toDatabase and fromDatabase roundtrip', () {
      final purchased = PurchasedProduct(
        id: 'pp1',
        listId: 'list1',
        product: product,
        category: category,
        price: 3.5,
        quantity: 2,
      );

      final dbMap = purchased.toDatabase();
      final restored = PurchasedProduct.fromDatabase(dbMap, category, product);

      expect(restored.id, 'pp1');
      expect(restored.listId, 'list1');
      expect(restored.price, 3.5);
      expect(restored.quantity, 2);
      expect(restored.product.id, 'prod1');
      expect(restored.category.id, 'cat1');
    });

    test('toJson and fromJson roundtrip', () {
      final purchased = PurchasedProduct(
        id: 'pp2',
        listId: 'list2',
        product: product,
        category: category,
        price: 5.0,
        quantity: 1,
      );

      final json = purchased.toJson();
      final restored = PurchasedProduct.fromJson(json);

      expect(restored.id, 'pp2');
      expect(restored.listId, 'list2');
      expect(restored.price, 5.0);
      expect(restored.quantity, 1);
      expect(restored.product.getName(), 'Chips');
      expect(restored.category.getName(), 'Snacks');
    });

    test('setProduct updates product', () {
      final otherProduct = Product(id: 'prod2', name: 'Crackers');
      final purchased = PurchasedProduct(listId: 'list3', product: product, category: category);

      purchased.setProduct = otherProduct;

      expect(purchased.product.id, 'prod2');
      expect(purchased.product.getName(), 'Crackers');
    });
  });
}
