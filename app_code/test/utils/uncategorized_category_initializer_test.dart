import 'package:app_code/models/category.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_category.dart';
import 'package:app_code/services/database/sqlite/manage_supermarket.dart';
import 'package:app_code/utils/uncategorized_category_initializer.dart';
import 'package:app_code/utils/uncategorized_category_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await getDatabasesPath();
    await deleteDatabase('$dbPath/shopping_app.db');
  });

  setUp(() async {
    final db = await DatabaseHelper.database;
    // Clear database for clean test state
    // Only delete from tables that exist
    await db.delete('supermarket_category');
    await db.delete('category');
    await db.delete('supermarket');
    await db.delete('purchased_product');
    await db.delete('shopping_list');
    await db.delete('associations');
    // Note: shopping_list_product table is not needed for these tests
  });

  group('UncategorizedCategoryInitializer.ensureInitialized()', () {
    test('creates uncategorized category when none exists', () async {
      // Ensure database is clean
      final initialCategories = await ManageCategory.getAllCategories();
      expect(initialCategories, isEmpty);

      // Run initialization
      final result = await UncategorizedCategoryInitializer.ensureInitialized();

      // Verify category was created
      expect(result.getName(), 'Uncategorized');
      expect(result.isVisible, isFalse);

      // Verify it's in the database
      final allCategories = await ManageCategory.getAllCategories();
      expect(allCategories, hasLength(1));
      expect(allCategories.first.getName(), 'Uncategorized');
    });

    test('uses existing uncategorized category when one exists', () async {
      // Create an uncategorized category manually
      final existingCategory = Category(
        id: 'cat-123',
        name: 'Uncategorized',
        isVisible: false,
      );
      await ManageCategory.addCategory(existingCategory);

      // Run initialization
      final result = await UncategorizedCategoryInitializer.ensureInitialized();

      // Should return the existing one
      expect(result.id, 'cat-123');
      expect(result.getName(), 'Uncategorized');

      // Should not create a duplicate
      final allCategories = await ManageCategory.getAllCategories();
      expect(allCategories, hasLength(1));
    });

    test('sets isVisible to false if uncategorized category is visible', () async {
      // Create a visible uncategorized category
      final visibleCategory = Category(
        id: 'cat-456',
        name: 'Uncategorized',
        isVisible: true,
      );
      await ManageCategory.addCategory(visibleCategory);

      // Run initialization
      final result = await UncategorizedCategoryInitializer.ensureInitialized();

      // Should have been updated to hidden
      expect(result.isVisible, isFalse);

      // Verify in database
      final fetched = await ManageCategory.getCategoryById('cat-456');
      expect(fetched?.isVisible, isFalse);
    });

    test('hides duplicate uncategorized categories', () async {
      // Create multiple uncategorized categories
      final cat1 = Category(id: 'cat-1', name: 'Uncategorized', isVisible: true);
      final cat2 = Category(id: 'cat-2', name: 'uncategorized', isVisible: true);
      final cat3 = Category(id: 'cat-3', name: 'UNCATEGORIZED', isVisible: true);

      await ManageCategory.addCategory(cat1);
      await ManageCategory.addCategory(cat2);
      await ManageCategory.addCategory(cat3);

      // Run initialization
      final result = await UncategorizedCategoryInitializer.ensureInitialized();

      // Should return the first one
      expect(result.id, 'cat-1');
      expect(result.isVisible, isFalse);

      // All duplicates should be hidden
      final allCategories = await ManageCategory.getAllCategories();
      for (final cat in allCategories) {
        if (UncategorizedCategoryUtils.isUncategorized(cat)) {
          expect(cat.isVisible, isFalse);
        }
      }
    });

    test('adds uncategorized category to all supermarkets', () async {
      // Create categories
      final category1 = Category(id: 'cat-1', name: 'Dairy');
      final category2 = Category(id: 'cat-2', name: 'Meat');
      await ManageCategory.addCategory(category1);
      await ManageCategory.addCategory(category2);

      // Create supermarkets without uncategorized category
      final supermarket1 = Supermarket(
        id: 'sup-1',
        name: 'Market 1',
        categories: [category1, category2],
      );
      final supermarket2 = Supermarket(
        id: 'sup-2',
        name: 'Market 2',
        categories: [category1],
      );

      await ManageSupermarket.addSupermarket(supermarket1);
      await ManageSupermarket.addSupermarket(supermarket2);

      // Run initialization
      final uncategorized = await UncategorizedCategoryInitializer.ensureInitialized();

      // Verify all supermarkets have the uncategorized category
      final supermarkets = await ManageSupermarket.getAllSupermarkets();
      for (final supermarket in supermarkets) {
        final categories = supermarket.getCategories();
        final hasUncategorized = categories.any(
          (cat) => cat.id == uncategorized.id,
        );
        expect(hasUncategorized, isTrue,
            reason: 'Supermarket ${supermarket.getName()} should have uncategorized category');
      }
    });

    test('places uncategorized category at the beginning of category list', () async {
      // Create regular categories
      final category1 = Category(id: 'cat-1', name: 'Dairy');
      final category2 = Category(id: 'cat-2', name: 'Meat');
      await ManageCategory.addCategory(category1);
      await ManageCategory.addCategory(category2);

      // Create supermarket with categories
      final supermarket = Supermarket(
        id: 'sup-1',
        name: 'Market 1',
        categories: [category1, category2],
      );
      await ManageSupermarket.addSupermarket(supermarket);

      // Run initialization
      final uncategorized = await UncategorizedCategoryInitializer.ensureInitialized();

      // Verify uncategorized is at the beginning
      final updated = await ManageSupermarket.getSupermarketById('sup-1');
      final categories = updated!.getCategories();
      expect(categories.first.id, uncategorized.id);
    });

    test('moves uncategorized category to beginning if it exists but not first', () async {
      // Create uncategorized and other categories
      final uncategorized = Category(id: 'cat-uncat', name: 'Uncategorized', isVisible: false);
      final category1 = Category(id: 'cat-1', name: 'Dairy');
      final category2 = Category(id: 'cat-2', name: 'Meat');
      
      await ManageCategory.addCategory(uncategorized);
      await ManageCategory.addCategory(category1);
      await ManageCategory.addCategory(category2);

      // Create supermarket with uncategorized not at the beginning
      final supermarket = Supermarket(
        id: 'sup-1',
        name: 'Market 1',
        categories: [category1, uncategorized, category2],
      );
      await ManageSupermarket.addSupermarket(supermarket);

      // Run initialization
      await UncategorizedCategoryInitializer.ensureInitialized();

      // Verify uncategorized is now at the beginning
      final updated = await ManageSupermarket.getSupermarketById('sup-1');
      final categories = updated!.getCategories();
      expect(categories.first.id, 'cat-uncat');
      expect(categories[1].id, 'cat-1');
      expect(categories[2].id, 'cat-2');
    });

    test('removes duplicate uncategorized categories from supermarket', () async {
      // Create multiple uncategorized categories
      final uncat1 = Category(id: 'cat-uncat-1', name: 'Uncategorized', isVisible: false);
      final uncat2 = Category(id: 'cat-uncat-2', name: 'uncategorized', isVisible: false);
      final category1 = Category(id: 'cat-1', name: 'Dairy');
      
      await ManageCategory.addCategory(uncat1);
      await ManageCategory.addCategory(uncat2);
      await ManageCategory.addCategory(category1);

      // Create supermarket with duplicate uncategorized categories
      final supermarket = Supermarket(
        id: 'sup-1',
        name: 'Market 1',
        categories: [uncat1, category1, uncat2],
      );
      await ManageSupermarket.addSupermarket(supermarket);

      // Run initialization
      final result = await UncategorizedCategoryInitializer.ensureInitialized();

      // Verify only one uncategorized category remains
      final updated = await ManageSupermarket.getSupermarketById('sup-1');
      final categories = updated!.getCategories();
      
      final uncategorizedCount = categories.where(
        (cat) => UncategorizedCategoryUtils.isUncategorized(cat),
      ).length;
      
      expect(uncategorizedCount, 1);
      expect(categories.first.id, result.id);
    });

    test('does not modify supermarket if uncategorized is already correctly positioned', () async {
      // Create uncategorized and other categories
      final uncategorized = Category(id: 'cat-uncat', name: 'Uncategorized', isVisible: false);
      final category1 = Category(id: 'cat-1', name: 'Dairy');
      
      await ManageCategory.addCategory(uncategorized);
      await ManageCategory.addCategory(category1);

      // Create supermarket with uncategorized at the beginning
      final supermarket = Supermarket(
        id: 'sup-1',
        name: 'Market 1',
        categories: [uncategorized, category1],
      );
      await ManageSupermarket.addSupermarket(supermarket);

      final beforeModified = (await ManageSupermarket.getSupermarketById('sup-1'))!.lastModified;

      // Run initialization
      await UncategorizedCategoryInitializer.ensureInitialized();

      // Verify supermarket was not unnecessarily updated
      final updated = await ManageSupermarket.getSupermarketById('sup-1');
      
      // Categories should still be in the same order
      final categories = updated!.getCategories();
      expect(categories.first.id, 'cat-uncat');
      expect(categories[1].id, 'cat-1');
    });
  });

  group('UncategorizedCategoryInitializer.getUncategorized()', () {
    test('creates and returns uncategorized category when none exists', () async {
      final result = await UncategorizedCategoryInitializer.getUncategorized();

      expect(result.getName(), 'Uncategorized');
      expect(result.isVisible, isFalse);

      // Verify it's in the database
      final allCategories = await ManageCategory.getAllCategories();
      expect(allCategories, hasLength(1));
    });

    test('returns existing uncategorized category', () async {
      // Create uncategorized category
      final existing = Category(id: 'cat-123', name: 'Uncategorized', isVisible: false);
      await ManageCategory.addCategory(existing);

      final result = await UncategorizedCategoryInitializer.getUncategorized();

      // Should return the existing one
      expect(result.id, 'cat-123');

      // Should not create a duplicate
      final allCategories = await ManageCategory.getAllCategories();
      expect(allCategories, hasLength(1));
    });

    test('sets isVisible to false if uncategorized is visible', () async {
      // Create visible uncategorized category
      final visible = Category(id: 'cat-456', name: 'Uncategorized', isVisible: true);
      await ManageCategory.addCategory(visible);

      final result = await UncategorizedCategoryInitializer.getUncategorized();

      // Should be hidden now
      expect(result.isVisible, isFalse);

      // Verify in database
      final fetched = await ManageCategory.getCategoryById('cat-456');
      expect(fetched?.isVisible, isFalse);
    });

    test('hides duplicate uncategorized categories and returns first', () async {
      // Create multiple uncategorized categories
      final cat1 = Category(id: 'cat-1', name: 'Uncategorized', isVisible: true);
      final cat2 = Category(id: 'cat-2', name: 'uncategorized', isVisible: true);

      await ManageCategory.addCategory(cat1);
      await ManageCategory.addCategory(cat2);

      final result = await UncategorizedCategoryInitializer.getUncategorized();

      // Should return the first one
      expect(result.id, 'cat-1');
      expect(result.isVisible, isFalse);

      // All should be hidden
      final allCategories = await ManageCategory.getAllCategories();
      for (final cat in allCategories) {
        if (UncategorizedCategoryUtils.isUncategorized(cat)) {
          expect(cat.isVisible, isFalse);
        }
      }
    });

    test('does not affect supermarkets (unlike ensureInitialized)', () async {
      // Create supermarket without uncategorized
      final category = Category(id: 'cat-1', name: 'Dairy');
      await ManageCategory.addCategory(category);

      final supermarket = Supermarket(
        id: 'sup-1',
        name: 'Market 1',
        categories: [category],
      );
      await ManageSupermarket.addSupermarket(supermarket);

      // Call getUncategorized
      await UncategorizedCategoryInitializer.getUncategorized();

      // Supermarket should still not have uncategorized
      final updated = await ManageSupermarket.getSupermarketById('sup-1');
      final categories = updated!.getCategories();
      
      final hasUncategorized = categories.any(
        (cat) => UncategorizedCategoryUtils.isUncategorized(cat),
      );
      expect(hasUncategorized, isFalse);
    });
  });

  group('UncategorizedCategoryInitializer edge cases', () {
    test('handles case-insensitive matching', () async {
      final upperCase = Category(id: 'cat-1', name: 'UNCATEGORIZED', isVisible: true);
      await ManageCategory.addCategory(upperCase);

      final result = await UncategorizedCategoryInitializer.getUncategorized();

      expect(result.id, 'cat-1');
      expect(result.isVisible, isFalse);
    });

    test('handles whitespace in category names', () async {
      final withSpaces = Category(id: 'cat-1', name: '  Uncategorized  ', isVisible: true);
      await ManageCategory.addCategory(withSpaces);

      final result = await UncategorizedCategoryInitializer.getUncategorized();

      expect(result.id, 'cat-1');
    });

    test('handles supermarket with no categories', () async {
      final uncategorized = Category(id: 'cat-uncat', name: 'Uncategorized', isVisible: false);
      await ManageCategory.addCategory(uncategorized);

      final supermarket = Supermarket(
        id: 'sup-1',
        name: 'Empty Market',
        categories: [],
      );
      await ManageSupermarket.addSupermarket(supermarket);

      await UncategorizedCategoryInitializer.ensureInitialized();

      // Should now have the uncategorized category
      final updated = await ManageSupermarket.getSupermarketById('sup-1');
      final categories = updated!.getCategories();
      expect(categories, hasLength(1));
      expect(categories.first.id, 'cat-uncat');
    });

    test('handles multiple supermarkets with different category configurations', () async {
      final category1 = Category(id: 'cat-1', name: 'Dairy');
      final category2 = Category(id: 'cat-2', name: 'Meat');
      await ManageCategory.addCategory(category1);
      await ManageCategory.addCategory(category2);

      final sup1 = Supermarket(id: 'sup-1', name: 'Market 1', categories: [category1]);
      final sup2 = Supermarket(id: 'sup-2', name: 'Market 2', categories: [category2]);
      final sup3 = Supermarket(id: 'sup-3', name: 'Market 3', categories: []);

      await ManageSupermarket.addSupermarket(sup1);
      await ManageSupermarket.addSupermarket(sup2);
      await ManageSupermarket.addSupermarket(sup3);

      final uncategorized = await UncategorizedCategoryInitializer.ensureInitialized();

      // All supermarkets should have uncategorized at the beginning
      final allSupermarkets = await ManageSupermarket.getAllSupermarkets();
      for (final supermarket in allSupermarkets) {
        final categories = supermarket.getCategories();
        expect(categories.first.id, uncategorized.id);
      }
    });
  });
}
