import 'package:app_code/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Product', () {
    test('generates id when not provided and defaults', () {
      final product = Product(name: 'Pasta');

      expect(product.id.isNotEmpty, true);
      expect(product.getName(), 'Pasta');
      expect(product.associations, isEmpty);
      expect(product.isVisible, true);
    });

    test('setters update fields', () {
      final product = Product(id: 'prod1', name: 'Old', isVisible: false);

      product.setName('New');
      product.setVisibility(true);
      product.setAssociations({'sup1': 'cat1'});
      product.addAssociation('sup2', 'cat2');

      expect(product.getName(), 'New');
      expect(product.isVisible, true);
      expect(product.associations['sup1'], 'cat1');
      expect(product.associations['sup2'], 'cat2');
    });

    test('toDatabase and fromDatabase roundtrip with associations', () {
      final product = Product(id: 'p1', name: 'Milk', associations: {'s1': 'c1'}, isVisible: true);

      final dbMap = product.toDatabase();
      final restored = Product.fromDatabase(dbMap, associations: {'s1': 'c1'});

      expect(restored.id, 'p1');
      expect(restored.getName(), 'Milk');
      expect(restored.associations['s1'], 'c1');
      expect(restored.isVisible, true);
    });

    test('toJson and fromJson roundtrip with associations', () {
      final product = Product(id: 'p2', name: 'Bread', associations: {'s2': 'c2'}, isVisible: false);

      final json = product.toJson();
      json['associations'] = {'s2': 'c2'}; // include associations for fromJson
      final restored = Product.fromJson(json);

      expect(restored.id, 'p2');
      expect(restored.getName(), 'Bread');
      expect(restored.associations['s2'], 'c2');
      expect(restored.isVisible, false);
    });
  });
}
