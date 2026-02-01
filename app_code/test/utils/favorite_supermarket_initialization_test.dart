import 'package:app_code/models/category.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_supermarket.dart';
import 'package:app_code/services/mock/mock_data_seed.dart';
import 'package:app_code/utils/favorite_supermarket_initializer.dart';
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
    await db.delete('supermarket_category');
    await db.delete('category');
    await db.delete('supermarket');
    await db.delete('shopping_list_product');
    await db.delete('purchased_product');
    await db.delete('shopping_list');
  });

  group('Favorite Supermarket Initialization', () {
    test(
        'seedMockDataIfEmpty sets default supermarket as favorite on first install',
        () async {
      // Verify database is empty before seeding
      final initialLists =
          await ManageSupermarket.getAllSupermarkets();
      expect(initialLists, isEmpty);

      // Seed mock data
      await seedMockDataIfEmpty();

      // Verify supermarkets were created
      final supermarkets = await ManageSupermarket.getAllSupermarkets();
      expect(supermarkets, isNotEmpty);

      // Verify exactly one is marked as favorite
      final favorites = supermarkets.where((s) => s.isFavorite).toList();
      expect(favorites, hasLength(1),
          reason: 'Should have exactly one favorite supermarket');

      // Verify the favorite is the default supermarket
      final favorite = favorites.first;
      expect(favorite.getName(), 'Supermarket',
          reason: 'Default supermarket should be marked as favorite');

      // Verify getFavoriteSupermarket returns the correct one
      final queriedFavorite =
          await ManageSupermarket.getFavoriteSupermarket();
      expect(queriedFavorite, isNotNull);
      expect(queriedFavorite!.id, favorite.id);
      expect(queriedFavorite.getName(), 'Supermarket');
    });

    test(
        'seedMockDataIfEmpty skips seeding if database already has data',
        () async {
      // Create initial supermarket
      final initialSupermarket = Supermarket(
        id: 'sup-initial',
        name: 'Initial Market',
        isVisible: true,
        isFavorite: true,
      );
      await ManageSupermarket.addSupermarket(initialSupermarket);

      // Verify initial state
      var supermarkets = await ManageSupermarket.getAllSupermarkets();
      expect(supermarkets, hasLength(1));

      // Call seed (should not add more data)
      await seedMockDataIfEmpty();

      // Verify no additional data was added
      supermarkets = await ManageSupermarket.getAllSupermarkets();
      expect(supermarkets, hasLength(1),
          reason: 'Should not seed if database has existing data');
      expect(supermarkets.first.id, 'sup-initial');
    });

    test('ensureFavoriteInitialized finds existing favorite without changes',
        () async {
      // Create a supermarket with favorite status
      final supermarket = Supermarket(
        id: 'sup-1',
        name: 'Market One',
        isVisible: true,
        isFavorite: true,
      );
      await ManageSupermarket.addSupermarket(supermarket);

      // Verify favorite exists
      var favorite = await ManageSupermarket.getFavoriteSupermarket();
      expect(favorite, isNotNull);
      expect(favorite!.id, 'sup-1');

      // Call initializer
      final result = await FavoriteSupermarketInitializer
          .ensureFavoriteInitialized();

      // Should return true (favorite was already initialized)
      expect(result, isTrue);

      // Favorite should remain unchanged
      favorite = await ManageSupermarket.getFavoriteSupermarket();
      expect(favorite!.id, 'sup-1');
    });

    test('ensureFavoriteInitialized auto-selects first visible on upgrade',
        () async {
      // Create multiple supermarkets without favorite status
      final market1 = Supermarket(
        id: 'sup-1',
        name: 'Market One',
        isVisible: true,
        isFavorite: false,
      );
      final market2 = Supermarket(
        id: 'sup-2',
        name: 'Market Two',
        isVisible: true,
        isFavorite: false,
      );
      final market3 = Supermarket(
        id: 'sup-3',
        name: 'Market Three',
        isVisible: false, // Hidden
        isFavorite: false,
      );

      await ManageSupermarket.addSupermarket(market1);
      await ManageSupermarket.addSupermarket(market2);
      await ManageSupermarket.addSupermarket(market3);

      // Verify no favorite exists
      var favorite = await ManageSupermarket.getFavoriteSupermarket();
      expect(favorite, isNull);

      // Call initializer
      final result = await FavoriteSupermarketInitializer
          .ensureFavoriteInitialized();

      // Should return true (favorite was initialized)
      expect(result, isTrue);

      // Verify a favorite was selected
      favorite = await ManageSupermarket.getFavoriteSupermarket();
      expect(favorite, isNotNull);

      // Should be the first visible supermarket (market1)
      expect(favorite!.id, 'sup-1',
          reason: 'Should select first visible supermarket as favorite');
      expect(favorite.isVisible, isTrue);
    });

    test('ensureFavoriteInitialized handles empty database gracefully',
        () async {
      // Database is empty (setUp clears it)
      var supermarkets = await ManageSupermarket.getAllSupermarkets();
      expect(supermarkets, isEmpty);

      // Call initializer on empty database
      final result = await FavoriteSupermarketInitializer
          .ensureFavoriteInitialized();

      // Should return false (no supermarkets to set as favorite)
      expect(result, isFalse);
    });

    test(
        'favorite supermarket can be queried after first app usage',
        () async {
      // Simulate first app usage: seed data
      await seedMockDataIfEmpty();

      // Verify we can query the favorite supermarket
      final favorite = await ManageSupermarket.getFavoriteSupermarket();
      expect(favorite, isNotNull,
          reason: 'Should always find a favorite after first use');

      // Verify it has the expected properties
      expect(favorite!.getName(), 'Supermarket');
      expect(favorite.isVisible, isTrue);
      expect(favorite.isFavorite, isTrue);
      expect(favorite.getCategories(), isNotEmpty,
          reason: 'Default supermarket should have categories');
    });

    test('exactly one supermarket is marked as favorite after seed',
        () async {
      // Seed mock data
      await seedMockDataIfEmpty();

      // Get all supermarkets
      final supermarkets = await ManageSupermarket.getAllSupermarkets();

      // Count favorites
      final favorites = supermarkets.where((s) => s.isFavorite).toList();

      // Verify invariant: exactly one favorite
      expect(favorites, hasLength(1),
          reason: 'Invariant: exactly one supermarket must be favorite');
    });

    test(
        'default supermarket includes default categories',
        () async {
      // Seed mock data
      await seedMockDataIfEmpty();

      // Get the favorite supermarket
      final favorite =
          await ManageSupermarket.getFavoriteSupermarket();
      expect(favorite, isNotNull);

      // Verify it has categories
      final categories = favorite!.getCategories();
      expect(categories, isNotEmpty,
          reason: 'Default supermarket should have default categories');

      // Verify categories are properly loaded
      final categoryIds = categories.map((c) => c.id).toSet();
      expect(categoryIds, isNotEmpty);

      // Verify we can query categories by supermarket ID
      final queriedCategories = await ManageSupermarket
          .getSupermarketCategories(favorite.id);
      expect(queriedCategories, hasLength(categories.length));
    });

    test(
        'setFavoriteSupermarket maintains single favorite invariant',
        () async {
      // Create multiple supermarkets
      final market1 = Supermarket(
        id: 'sup-1',
        name: 'Market One',
        isVisible: true,
        isFavorite: true,
      );
      final market2 = Supermarket(
        id: 'sup-2',
        name: 'Market Two',
        isVisible: true,
        isFavorite: false,
      );

      await ManageSupermarket.addSupermarket(market1);
      await ManageSupermarket.addSupermarket(market2);

      // Verify first is favorite
      var favorite = await ManageSupermarket.getFavoriteSupermarket();
      expect(favorite!.id, 'sup-1');

      // Change favorite to second market
      await ManageSupermarket.setFavoriteSupermarket('sup-2');

      // Verify new favorite is set
      favorite = await ManageSupermarket.getFavoriteSupermarket();
      expect(favorite!.id, 'sup-2');

      // Verify exactly one favorite exists
      final supermarkets = await ManageSupermarket.getAllSupermarkets();
      final favorites = supermarkets.where((s) => s.isFavorite).toList();
      expect(favorites, hasLength(1),
          reason: 'Should always have exactly one favorite');
      expect(favorites.first.id, 'sup-2');
    });
  });

  group('First App Usage Workflow', () {
    test('complete workflow: fresh install → favorite available', () async {
      // Step 1: Verify database is clean
      var supermarkets = await ManageSupermarket.getAllSupermarkets();
      expect(supermarkets, isEmpty);

      // Step 2: Seed mock data (simulating first app startup)
      await seedMockDataIfEmpty();

      // Step 3: Verify data was seeded
      supermarkets = await ManageSupermarket.getAllSupermarkets();
      expect(supermarkets, isNotEmpty);

      // Step 4: Verify favorite is available
      final favorite = await ManageSupermarket.getFavoriteSupermarket();
      expect(favorite, isNotNull);

      // Step 5: Verify app can use favorite for shopping list creation
      expect(favorite!.getName(), isNotEmpty);
      expect(favorite.id, isNotEmpty);
      expect(favorite.isVisible, isTrue);
      expect(favorite.isFavorite, isTrue);

      // Step 6: Verify invariant is maintained
      final favoritesCount = supermarkets.where((s) => s.isFavorite).length;
      expect(favoritesCount, 1);
    });

    test('complete workflow: upgrade → favorite auto-initialized', () async {
      // Step 1: Create old database with supermarkets (no favorite)
      final oldMarket = Supermarket(
        id: 'sup-legacy',
        name: 'Legacy Market',
        isVisible: true,
        isFavorite: false,
      );
      await ManageSupermarket.addSupermarket(oldMarket);

      // Verify no favorite
      var favorite = await ManageSupermarket.getFavoriteSupermarket();
      expect(favorite, isNull);

      // Step 2: New version startup triggers initialization
      await seedMockDataIfEmpty(); // Skipped because DB has data
      final initialized =
          await FavoriteSupermarketInitializer.ensureFavoriteInitialized();

      // Step 3: Verify favorite is now available
      expect(initialized, isTrue);
      favorite = await ManageSupermarket.getFavoriteSupermarket();
      expect(favorite, isNotNull);

      // Step 4: Verify app can use favorite
      expect(favorite!.id, isNotEmpty);
      expect(favorite.isVisible, isTrue);
    });
  });
}
