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

    test('fromJson with null product/category uses fallback', () {
      final json = {
        'id': 'pp1',
        'list_id': 'list1',
        'price': 5.0,
        'quantity': 2,
      };

      final purchased = PurchasedProduct.fromJson(json);

      expect(purchased.id, 'pp1');
      expect(purchased.listId, 'list1');
      expect(purchased.price, 5.0);
      expect(purchased.quantity, 2);
      expect(purchased.product.getName(), 'Unknown');
      expect(purchased.category.getName(), 'Uncategorized');
    });

    test('fromJson with valid product and category', () {
      final json = {
        'id': 'pp2',
        'list_id': 'list2',
        'price': 3.0,
        'quantity': 1,
        'product': {'id': 'prod3', 'name': 'Juice', 'isVisible': true},
        'category': {'id': 'cat3', 'name': 'Beverages', 'is_default': false},
      };

      final purchased = PurchasedProduct.fromJson(json);

      expect(purchased.product.getName(), 'Juice');
      expect(purchased.category.getName(), 'Beverages');
    });

    test('toDatabase includes all required fields', () {
      final purchased = PurchasedProduct(
        id: 'pp3',
        listId: 'list3',
        product: product,
        category: category,
        price: 7.5,
        quantity: 3,
      );

      final db = purchased.toDatabase();

      expect(db['id'], 'pp3');
      expect(db['list_id'], 'list3');
      expect(db['product_id'], 'prod1');
      expect(db['category_id'], 'cat1');
      expect(db['price'], 7.5);
      expect(db['quantity'], 3);
    });

    test('toJson includes nested product and category', () {
      final purchased = PurchasedProduct(
        id: 'pp4',
        listId: 'list4',
        product: product,
        category: category,
        price: 2.0,
        quantity: 5,
      );

      final json = purchased.toJson();

      expect(json['id'], 'pp4');
      expect(json['list_id'], 'list4');
      expect(json['price'], 2.0);
      expect(json['quantity'], 5);
      expect(json['product'], isNotNull);
      expect(json['category'], isNotNull);
      expect(json['product']['name'], 'Chips');
      expect(json['category']['name'], 'Snacks');
    });

    test('fromDatabase constructs correctly with all fields', () {
      final dbMap = {
        'id': 'pp5',
        'list_id': 'list5',
        'price': 10.0,
        'quantity': 2,
      };

      final purchased = PurchasedProduct.fromDatabase(dbMap, category, product);

      expect(purchased.id, 'pp5');
      expect(purchased.listId, 'list5');
      expect(purchased.price, 10.0);
      expect(purchased.quantity, 2);
      expect(purchased.product.id, 'prod1');
      expect(purchased.category.id, 'cat1');
    });

    test('handles zero quantity and price', () {
      final purchased = PurchasedProduct(
        listId: 'list6',
        product: product,
        category: category,
        price: 0.0,
        quantity: 0,
      );

      expect(purchased.price, 0.0);
      expect(purchased.quantity, 0);
    });

    test('handles very large quantity', () {
      final purchased = PurchasedProduct(
        listId: 'list7',
        product: product,
        category: category,
        price: 1.0,
        quantity: 999999,
      );

      expect(purchased.quantity, 999999);
    });

    test('handles negative price (edge case)', () {
      final purchased = PurchasedProduct(
        listId: 'list8',
        product: product,
        category: category,
        price: -5.0,
        quantity: 1,
      );

      expect(purchased.price, -5.0);
    });
  });
}
