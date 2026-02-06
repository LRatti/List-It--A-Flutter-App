import 'package:app_code/models/receipt_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReceiptMatch', () {
    test('creates instance with all fields', () {
      final receiptMatch = ReceiptMatch(
        productId: 'prod123',
        productName: 'Milk',
        quantity: 2,
        price: 3.50,
      );

      expect(receiptMatch.productId, 'prod123');
      expect(receiptMatch.productName, 'Milk');
      expect(receiptMatch.quantity, 2);
      expect(receiptMatch.price, 3.50);
    });

    test('creates instance with null productId', () {
      final receiptMatch = ReceiptMatch(
        productId: null,
        productName: 'Unknown Product',
        quantity: 1,
        price: 5.00,
      );

      expect(receiptMatch.productId, isNull);
      expect(receiptMatch.productName, 'Unknown Product');
      expect(receiptMatch.quantity, 1);
      expect(receiptMatch.price, 5.00);
    });

    test('creates instance with null productName', () {
      final receiptMatch = ReceiptMatch(
        productId: 'prod456',
        productName: null,
        quantity: 3,
        price: 2.25,
      );

      expect(receiptMatch.productId, 'prod456');
      expect(receiptMatch.productName, isNull);
      expect(receiptMatch.quantity, 3);
      expect(receiptMatch.price, 2.25);
    });

    test('creates instance with both null productId and productName', () {
      final receiptMatch = ReceiptMatch(
        productId: null,
        productName: null,
        quantity: 4,
        price: 10.99,
      );

      expect(receiptMatch.productId, isNull);
      expect(receiptMatch.productName, isNull);
      expect(receiptMatch.quantity, 4);
      expect(receiptMatch.price, 10.99);
    });

    test('handles zero quantity', () {
      final receiptMatch = ReceiptMatch(
        productId: 'prod789',
        productName: 'Bread',
        quantity: 0,
        price: 1.50,
      );

      expect(receiptMatch.quantity, 0);
    });

    test('handles zero price', () {
      final receiptMatch = ReceiptMatch(
        productId: 'prod012',
        productName: 'Free Sample',
        quantity: 1,
        price: 0.0,
      );

      expect(receiptMatch.price, 0.0);
    });

    test('handles negative quantity', () {
      final receiptMatch = ReceiptMatch(
        productId: 'prod345',
        productName: 'Refund Item',
        quantity: -1,
        price: 5.00,
      );

      expect(receiptMatch.quantity, -1);
    });

    test('handles negative price', () {
      final receiptMatch = ReceiptMatch(
        productId: 'prod678',
        productName: 'Discount',
        quantity: 1,
        price: -2.50,
      );

      expect(receiptMatch.price, -2.50);
    });

    test('handles large quantity values', () {
      final receiptMatch = ReceiptMatch(
        productId: 'prod999',
        productName: 'Bulk Item',
        quantity: 1000,
        price: 0.01,
      );

      expect(receiptMatch.quantity, 1000);
    });

    test('handles large price values', () {
      final receiptMatch = ReceiptMatch(
        productId: 'prod111',
        productName: 'Expensive Item',
        quantity: 1,
        price: 9999.99,
      );

      expect(receiptMatch.price, 9999.99);
    });

    test('handles decimal prices correctly', () {
      final receiptMatch = ReceiptMatch(
        productId: 'prod222',
        productName: 'Precise Item',
        quantity: 2,
        price: 3.141592,
      );

      expect(receiptMatch.price, closeTo(3.141592, 0.000001));
    });

    test('const constructor allows compile-time constants', () {
      const receiptMatch = ReceiptMatch(
        productId: 'const_prod',
        productName: 'Const Product',
        quantity: 5,
        price: 7.50,
      );

      expect(receiptMatch.productId, 'const_prod');
      expect(receiptMatch.productName, 'Const Product');
      expect(receiptMatch.quantity, 5);
      expect(receiptMatch.price, 7.50);
    });

    test('two instances with same values are equal (const)', () {
      const match1 = ReceiptMatch(
        productId: 'same',
        productName: 'Same',
        quantity: 1,
        price: 1.0,
      );
      const match2 = ReceiptMatch(
        productId: 'same',
        productName: 'Same',
        quantity: 1,
        price: 1.0,
      );

      expect(identical(match1, match2), isTrue);
    });
  });
}
