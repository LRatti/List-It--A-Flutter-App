import 'package:app_code/models/category.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Supermarket', () {
    test('generates id and defaults', () {
      final market = Supermarket(name: 'Local');

      expect(market.id.isNotEmpty, true);
      expect(market.getName(), 'Local');
      expect(market.getCategories(), isEmpty);
      expect(market.isVisible, true);
    });

    test('setters and addCategory', () {
      final market = Supermarket(id: 'sup1', name: 'Old', categories: [], isVisible: false);
      final cat = Category(id: 'cat1', name: 'Veg');

      market.setName('New');
      market.setVisibility(true);
      market.addCategory(cat);

      expect(market.getName(), 'New');
      expect(market.isVisible, true);
      expect(market.getCategories().length, 1);
      expect(market.getCategories().first.id, 'cat1');
    });

    test('toDatabase and fromDatabase roundtrip', () {
      final market = Supermarket(id: 'sup2', name: 'Market', categories: [Category(id: 'c1', name: 'Fruit')], isVisible: true);

      final db = market.toDatabase();
      final restored = Supermarket.fromDatabase(db);

      expect(restored.id, 'sup2');
      expect(restored.getName(), 'Market');
      expect(restored.isVisible, true);
    });

    test('toJson and fromJson roundtrip', () {
      final market = Supermarket(id: 'sup3', name: 'Store', categories: [Category(id: 'c2', name: 'Bakery')], isVisible: false);

      final json = market.toJson();
      final restored = Supermarket.fromJson(json);

      expect(restored.id, 'sup3');
      expect(restored.getName(), 'Store');
      expect(restored.getCategories().first.getName(), 'Bakery');
      expect(restored.isVisible, false);
    });
  });
}
