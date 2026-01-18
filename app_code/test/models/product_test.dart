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

    test('addAssociation adds new association without removing existing', () {
      final product = Product(name: 'Multi', associations: {'s1': 'c1'});

      product.addAssociation('s2', 'c2');
      product.addAssociation('s3', 'c3');

      expect(product.associations.length, 3);
      expect(product.associations['s1'], 'c1');
      expect(product.associations['s2'], 'c2');
      expect(product.associations['s3'], 'c3');
    });

    test('addAssociation overwrites existing association with same key', () {
      final product = Product(name: 'Override', associations: {'s1': 'c1'});

      product.addAssociation('s1', 'c2');

      expect(product.associations.length, 1);
      expect(product.associations['s1'], 'c2');
    });

    test('setAssociations completely replaces existing associations', () {
      final product = Product(name: 'Replace', associations: {'s1': 'c1', 's2': 'c2'});

      product.setAssociations({'s3': 'c3'});

      expect(product.associations.length, 1);
      expect(product.associations['s3'], 'c3');
      expect(product.associations.containsKey('s1'), false);
    });

    test('fromDatabase handles is_visible as 0 or 1', () {
      final productVisible = Product.fromDatabase({'id': 'p1', 'name': 'Visible', 'is_visible': 1});
      final productHidden = Product.fromDatabase({'id': 'p2', 'name': 'Hidden', 'is_visible': 0});

      expect(productVisible.isVisible, true);
      expect(productHidden.isVisible, false);
    });

    test('fromDatabase handles missing is_visible field with default', () {
      final product = Product.fromDatabase({'id': 'p1', 'name': 'Default'});

      expect(product.isVisible, true);
    });

    test('toDatabase correctly converts isVisible to 1 or 0', () {
      final visibleProduct = Product(name: 'Visible', isVisible: true);
      final hiddenProduct = Product(name: 'Hidden', isVisible: false);

      expect(visibleProduct.toDatabase()['is_visible'], 1);
      expect(hiddenProduct.toDatabase()['is_visible'], 0);
    });

    test('fromJson handles missing associations field', () {
      final json = {'id': 'p1', 'name': 'NoAssoc', 'isVisible': true};
      final product = Product.fromJson(json);

      expect(product.associations, isEmpty);
    });

    test('fromJson handles missing isVisible field with default', () {
      final json = {'id': 'p1', 'name': 'Default'};
      final product = Product.fromJson(json);

      expect(product.isVisible, true);
    });

    test('product with empty name is allowed', () {
      final product = Product(name: '');

      expect(product.getName(), '');
      product.setName('New Name');
      expect(product.getName(), 'New Name');
    });

    test('product with long name is handled', () {
      final longName = 'A' * 200;
      final product = Product(name: longName);

      expect(product.getName(), longName);
      expect(product.toDatabase()['name'], longName);
    });
  });
}
