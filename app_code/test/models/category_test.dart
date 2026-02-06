import 'package:app_code/models/category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Category', () {
    test('generates id when not provided', () {
      final category = Category(name: 'Fruit');

      expect(category.id.isNotEmpty, true);
      expect(category.getName(), 'Fruit');
      expect(category.isVisible, true);
    });

    test('toDatabase and fromDatabase roundtrip', () {
      final category = Category(id: 'cat1', name: 'Dairy', isVisible: true);

      final dbMap = category.toDatabase();
      final restored = Category.fromDatabase(dbMap);

      expect(restored.id, 'cat1');
      expect(restored.getName(), 'Dairy');
      expect(restored.isVisible, true);
    });

    test('toJson and fromJson roundtrip', () {
      final category = Category(id: 'cat2', name: 'Bakery');

      final json = category.toJson();
      final restored = Category.fromJson(json);

      expect(restored.id, 'cat2');
      expect(restored.getName(), 'Bakery');
      expect(restored.isVisible, true);
    });
  });
}
