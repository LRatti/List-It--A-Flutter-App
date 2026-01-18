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

    test('setCategories replaces entire category list', () {
      final cat1 = Category(id: 'c1', name: 'Cat1');
      final cat2 = Category(id: 'c2', name: 'Cat2');
      final cat3 = Category(id: 'c3', name: 'Cat3');
      
      final market = Supermarket(name: 'Market', categories: [cat1, cat2]);

      expect(market.getCategories().length, 2);

      market.setCategories([cat3]);

      expect(market.getCategories().length, 1);
      expect(market.getCategories().first.id, 'c3');
    });

    test('setCategories with empty list clears categories', () {
      final cat1 = Category(id: 'c1', name: 'Cat1');
      final market = Supermarket(name: 'Market', categories: [cat1]);

      market.setCategories([]);

      expect(market.getCategories(), isEmpty);
    });

    test('setVisibility updates visibility flag', () {
      final market = Supermarket(name: 'Market', isVisible: true);

      expect(market.isVisible, true);

      market.setVisibility(false);
      expect(market.isVisible, false);

      market.setVisibility(true);
      expect(market.isVisible, true);
    });

    test('fromDatabase handles is_visible correctly', () {
      final dbVisible = {'id': 's1', 'name': 'Visible', 'is_visible': true};
      final dbHidden = {'id': 's2', 'name': 'Hidden', 'is_visible': false};

      final visibleMarket = Supermarket.fromDatabase(dbVisible);
      final hiddenMarket = Supermarket.fromDatabase(dbHidden);

      expect(visibleMarket.isVisible, true);
      expect(hiddenMarket.isVisible, false);
    });

    test('toDatabase includes all required fields', () {
      final market = Supermarket(id: 'test-id', name: 'Test Market', isVisible: true);
      final db = market.toDatabase();

      expect(db.containsKey('id'), true);
      expect(db.containsKey('name'), true);
      expect(db.containsKey('is_visible'), true);
      expect(db['id'], 'test-id');
      expect(db['name'], 'Test Market');
      expect(db['is_visible'], isNotNull);
    });

    test('addCategory adds to existing categories', () {
      final cat1 = Category(id: 'c1', name: 'Cat1');
      final cat2 = Category(id: 'c2', name: 'Cat2');
      
      final market = Supermarket(name: 'Market', categories: [cat1]);

      market.addCategory(cat2);

      expect(market.getCategories().length, 2);
      expect(market.getCategories()[0].id, 'c1');
      expect(market.getCategories()[1].id, 'c2');
    });

    test('multiple addCategory calls maintain order', () {
      final market = Supermarket(name: 'Market');
      
      final cat1 = Category(id: 'c1', name: 'First');
      final cat2 = Category(id: 'c2', name: 'Second');
      final cat3 = Category(id: 'c3', name: 'Third');

      market.addCategory(cat1);
      market.addCategory(cat2);
      market.addCategory(cat3);

      expect(market.getCategories().length, 3);
      expect(market.getCategories()[0].getName(), 'First');
      expect(market.getCategories()[1].getName(), 'Second');
      expect(market.getCategories()[2].getName(), 'Third');
    });

    test('fromJson with empty categories list', () {
      final json = {
        'id': 's1',
        'name': 'Empty Market',
        'is_visible': true,
        'categories': [],
      };

      final market = Supermarket.fromJson(json);

      expect(market.getCategories(), isEmpty);
    });

    test('toJson includes categories array', () {
      final cat = Category(id: 'c1', name: 'Cat');
      final market = Supermarket(name: 'Market', categories: [cat]);

      final json = market.toJson();

      expect(json['categories'], isNotNull);
      expect(json['categories'], isList);
      expect((json['categories'] as List).length, 1);
    });

    test('supermarket with special characters in name', () {
      final market = Supermarket(name: 'Café & Tëä Store');

      expect(market.getName(), 'Café & Tëä Store');
      expect(market.toDatabase()['name'], 'Café & Tëä Store');
    });

    test('handles very long name', () {
      final longName = 'A' * 200;
      final market = Supermarket(name: longName);

      expect(market.getName(), longName);
    });
  });
}
