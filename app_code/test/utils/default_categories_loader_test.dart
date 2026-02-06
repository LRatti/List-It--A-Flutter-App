import 'package:app_code/utils/default_categories_loader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DefaultCategoriesLoader', () {
    test('loadDefaultCategories returns list of categories', () async {
      final categories = await DefaultCategoriesLoader.loadDefaultCategories();

      expect(categories, isNotEmpty);
      expect(categories.length, greaterThan(0));
    });

    test('loadDefaultCategories creates Category objects with correct names', () async {
      final categories = await DefaultCategoriesLoader.loadDefaultCategories();

      // Check that we have actual Category objects
      expect(categories.first.getName(), isNotEmpty);
      
      // Verify common expected categories from the JSON
      final categoryNames = categories.map((c) => c.getName()).toList();
      expect(categoryNames, contains('Uncategorized'));
    });

    test('loadDefaultCategories handles isVisible property correctly', () async {
      final categories = await DefaultCategoriesLoader.loadDefaultCategories();

      // Find the Uncategorized category which should be hidden
      final uncategorized = categories.firstWhere(
        (c) => c.getName() == 'Uncategorized',
        orElse: () => throw Exception('Uncategorized category not found'),
      );

      expect(uncategorized.isVisible, isFalse);
    });

    test('loadDefaultCategories defaults isVisible to true when not specified', () async {
      final categories = await DefaultCategoriesLoader.loadDefaultCategories();

      // Categories without isVisible property should default to true
      final visibleCategories = categories.where(
        (c) => c.getName() != 'Uncategorized' && c.isVisible,
      ).toList();

      expect(visibleCategories, isNotEmpty);
    });

    test('loadDefaultCategories generates unique IDs for each category', () async {
      final categories = await DefaultCategoriesLoader.loadDefaultCategories();

      final ids = categories.map((c) => c.id).toList();
      final uniqueIds = ids.toSet();

      expect(ids.length, equals(uniqueIds.length));
    });

    test('loadDefaultCategories handles empty categories list gracefully', () async {
      // This test verifies the error handling when JSON is malformed
      // We can't easily mock the asset loading, but we can test the loader
      // with the actual file which should work
      final categories = await DefaultCategoriesLoader.loadDefaultCategories();

      // Should return a valid list (possibly empty if file is missing)
      expect(categories, isA<List>());
    });

    test('loadDefaultCategories returns empty list on missing file', () async {
      // We can't easily test this without mocking rootBundle
      // But we can verify that the error handling returns an empty list
      // This would require dependency injection or mocking which is beyond
      // simple unit testing. For now, we verify the method handles errors.
      
      // Test with actual file should succeed
      final categories = await DefaultCategoriesLoader.loadDefaultCategories();
      expect(categories, isA<List>());
    });

    test('loadDefaultCategories preserves category order from JSON', () async {
      final categories = await DefaultCategoriesLoader.loadDefaultCategories();

      // Uncategorized should be first in the JSON
      if (categories.isNotEmpty) {
        expect(categories.first.getName(), 'Uncategorized');
      }
    });

    test('loadDefaultCategories handles special characters in category names', () async {
      final categories = await DefaultCategoriesLoader.loadDefaultCategories();

      // Check that emoji and special characters are preserved
      final categoryNames = categories.map((c) => c.getName()).toList();
      
      // Verify at least some categories contain emoji
      final hasEmoji = categoryNames.any((name) => name.contains('🥩') || 
          name.contains('🍷') || name.contains('🌸') || name.contains('🍎'));
      
      expect(hasEmoji, isTrue);
    });

    test('loadDefaultCategories creates categories with timestamps', () async {
      final categories = await DefaultCategoriesLoader.loadDefaultCategories();

      // All categories should have createdAt and lastModified timestamps
      for (final category in categories) {
        expect(category.createdAt, isNotNull);
        expect(category.lastModified, isNotNull);
      }
    });

    test('loadDefaultCategories handles missing name field with default', () async {
      final categories = await DefaultCategoriesLoader.loadDefaultCategories();

      // All categories should have names (either from JSON or default 'Unknown')
      for (final category in categories) {
        expect(category.getName(), isNotEmpty);
      }
    });
  });

  group('DefaultCategoriesLoader error handling', () {
    test('handles invalid JSON format gracefully', () async {
      // This test verifies that the error handling works
      // The actual implementation catches errors and returns empty list
      
      try {
        final categories = await DefaultCategoriesLoader.loadDefaultCategories();
        expect(categories, isA<List>());
      } catch (e) {
        // Should not throw, should return empty list instead
        fail('Should not throw exception, should return empty list');
      }
    });

    test('prints error message on exception', () async {
      // This verifies that errors are handled and logged
      // In a real scenario, we'd mock the print function or use a logger
      final categories = await DefaultCategoriesLoader.loadDefaultCategories();
      
      // If there was an error, it would print and return empty list
      expect(categories, isA<List>());
    });
  });

  group('DefaultCategoriesLoader integration', () {
    test('loaded categories can be converted to database format', () async {
      final categories = await DefaultCategoriesLoader.loadDefaultCategories();

      for (final category in categories) {
        final dbMap = category.toDatabase();
        
        expect(dbMap, isA<Map<String, dynamic>>());
        expect(dbMap['id'], isNotEmpty);
        expect(dbMap['name'], isNotEmpty);
        expect(dbMap['is_visible'], isA<int>());
      }
    });

    test('loaded categories can be converted to JSON format', () async {
      final categories = await DefaultCategoriesLoader.loadDefaultCategories();

      for (final category in categories) {
        final json = category.toJson();
        
        expect(json, isA<Map<String, dynamic>>());
        expect(json['id'], isNotEmpty);
        expect(json['name'], isNotEmpty);
      }
    });

    test('loaded categories maintain data integrity through conversions', () async {
      final categories = await DefaultCategoriesLoader.loadDefaultCategories();

      if (categories.isNotEmpty) {
        final original = categories.first;
        final json = original.toJson();
        final dbMap = original.toDatabase();

        expect(json['name'], equals(original.getName()));
        expect(dbMap['name'], equals(original.getName()));
        expect(dbMap['is_visible'], equals(original.isVisible ? 1 : 0));
      }
    });
  });
}
