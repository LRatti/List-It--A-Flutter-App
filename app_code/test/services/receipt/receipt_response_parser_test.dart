import 'package:app_code/services/receipt/receipt_response_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReceiptResponseParser.parse()', () {
    test('successfully parses valid JSON with matches field', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "product_id": "prod-1",
            "product_name": "Milk",
            "quantity": 2,
            "price": 3.50
          },
          {
            "product_id": "prod-2",
            "product_name": "Bread",
            "quantity": 1,
            "price": 2.00
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(2));
      expect(result[0].productId, 'prod-1');
      expect(result[0].productName, 'Milk');
      expect(result[0].quantity, 2);
      expect(result[0].price, 3.50);
      expect(result[1].productId, 'prod-2');
      expect(result[1].productName, 'Bread');
      expect(result[1].quantity, 1);
      expect(result[1].price, 2.00);
    });

    test('successfully parses valid JSON with items field', () {
      // Arrange
      const content = '''
      {
        "items": [
          {
            "productId": "p123",
            "productName": "Eggs",
            "quantity": 3,
            "price": 4.25
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].productId, 'p123');
      expect(result[0].productName, 'Eggs');
      expect(result[0].quantity, 3);
      expect(result[0].price, 4.25);
    });

    test('successfully parses valid JSON with products field', () {
      // Arrange
      const content = '''
      {
        "products": [
          {
            "id": "abc",
            "name": "Cheese",
            "quantity": 1,
            "price": 5.99
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].productId, 'abc');
      expect(result[0].productName, 'Cheese');
      expect(result[0].quantity, 1);
      expect(result[0].price, 5.99);
    });

    test('throws FormatException when no JSON is found', () {
      // Arrange
      const content = 'This is plain text without any JSON';

      // Act & Assert
      expect(
        () => ReceiptResponseParser.parse(content),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException with correct message when JSON is missing', () {
      // Arrange
      const content = 'No JSON here';

      // Act & Assert
      expect(
        () => ReceiptResponseParser.parse(content),
        throwsA(
          predicate((e) =>
              e is FormatException &&
              e.message == 'Receipt service returned an invalid response.'),
        ),
      );
    });

    test('returns empty list when items field is not a list', () {
      // Arrange
      const content = '''
      {
        "matches": "not a list"
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, isEmpty);
    });

    test('returns empty list when items field is missing', () {
      // Arrange
      const content = '''
      {
        "other_field": "value"
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, isEmpty);
    });

    test('skips items with missing quantity', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "product_id": "p1",
            "product_name": "Item1",
            "price": 1.00
          },
          {
            "product_id": "p2",
            "product_name": "Item2",
            "quantity": 2,
            "price": 2.00
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].productId, 'p2');
    });

    test('skips items with missing price', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "product_id": "p1",
            "product_name": "Item1",
            "quantity": 1
          },
          {
            "product_id": "p2",
            "product_name": "Item2",
            "quantity": 2,
            "price": 2.00
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].productId, 'p2');
    });

    test('skips items that are not maps', () {
      // Arrange
      const content = '''
      {
        "matches": [
          "not a map",
          {
            "product_id": "p1",
            "product_name": "ValidItem",
            "quantity": 1,
            "price": 1.50
          },
          123
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].productName, 'ValidItem');
    });

    test('parses integer quantity correctly', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "quantity": 5,
            "price": 1.00
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].quantity, 5);
    });

    test('parses double quantity and rounds it', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "quantity": 3.7,
            "price": 1.00
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].quantity, 4); // 3.7 rounded to 4
    });

    test('parses string quantity with digits', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "quantity": "7 items",
            "price": 1.00
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].quantity, 7);
    });

    test('skips item with invalid quantity string', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "quantity": "abc",
            "price": 1.00
          },
          {
            "quantity": 1,
            "price": 2.00
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].price, 2.00);
    });

    test('parses price from number', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "quantity": 1,
            "price": 9.99
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].price, 9.99);
    });

    test('parses price from integer', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "quantity": 1,
            "price": 10
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].price, 10.0);
    });

    test('parses price from string with comma decimal separator', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "quantity": 1,
            "price": "3,50"
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].price, 3.50);
    });

    test('parses price from string with currency symbol', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "quantity": 1,
            "price": "\$12.99"
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].price, 12.99);
    });

    test('skips item with invalid price string', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "quantity": 1,
            "price": "free"
          },
          {
            "quantity": 2,
            "price": 5.00
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].quantity, 2);
    });

    test('handles null productId gracefully', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "product_id": null,
            "product_name": "Unknown",
            "quantity": 1,
            "price": 1.00
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].productId, isNull);
      expect(result[0].productName, 'Unknown');
    });

    test('handles null productName gracefully', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "product_id": "p1",
            "product_name": null,
            "quantity": 1,
            "price": 1.00
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].productId, 'p1');
      expect(result[0].productName, isNull);
    });

    test('handles empty string productId', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "product_id": "",
            "product_name": "Item",
            "quantity": 1,
            "price": 1.00
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].productId, isNull); // Empty strings are converted to null
    });

    test('handles whitespace-only productName', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "product_id": "p1",
            "product_name": "   ",
            "quantity": 1,
            "price": 1.00
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].productName, isNull); // Whitespace-only is converted to null
    });

    test('extracts JSON embedded in text with prefix and suffix', () {
      // Arrange
      const content = '''
      Some text before
      {
        "matches": [
          {
            "quantity": 1,
            "price": 1.00
          }
        ]
      }
      Some text after
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
    });

    test('handles nested JSON structures', () {
      // Arrange
      const content = '''
      {
        "data": {
          "matches": [
            {
              "quantity": 1,
              "price": 1.00
            }
          ]
        }
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, isEmpty); // matches is not at top level
    });

    test('parses zero quantity and price', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "quantity": 0,
            "price": 0.00
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].quantity, 0);
      expect(result[0].price, 0.00);
    });

    test('parses negative price values', () {
      // Arrange - could represent discounts
      const content = '''
      {
        "matches": [
          {
            "quantity": 1,
            "price": -5.00
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].price, -5.00);
    });

    test('handles very large numbers', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "quantity": 999999,
            "price": 999999.99
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].quantity, 999999);
      expect(result[0].price, 999999.99);
    });

    test('parses multiple items correctly', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {"quantity": 1, "price": 1.00},
          {"quantity": 2, "price": 2.00},
          {"quantity": 3, "price": 3.00},
          {"quantity": 4, "price": 4.00},
          {"quantity": 5, "price": 5.00}
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(5));
      for (int i = 0; i < 5; i++) {
        expect(result[i].quantity, i + 1);
        expect(result[i].price, (i + 1).toDouble());
      }
    });

    test('handles malformed JSON after valid JSON start', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "quantity": 1,
            "price": 1.00
          }
        ]
      } invalid text
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1)); // Should still parse the valid JSON part
    });

    test('handles price with multiple decimal points', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "quantity": 1,
            "price": "1.2.3"
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert - invalid format, should skip this item
      expect(result, isEmpty);
    });

    test('trims whitespace from string values', () {
      // Arrange
      const content = '''
      {
        "matches": [
          {
            "product_id": "  p123  ",
            "product_name": "  Milk  ",
            "quantity": 1,
            "price": 1.00
          }
        ]
      }
      ''';

      // Act
      final result = ReceiptResponseParser.parse(content);

      // Assert
      expect(result, hasLength(1));
      expect(result[0].productId, 'p123');
      expect(result[0].productName, 'Milk');
    });
  });
}
