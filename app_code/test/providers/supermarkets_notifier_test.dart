import 'package:app_code/models/supermarket.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/providers/real_app_providers/supermarket/supermarkets_notifier.dart';
import 'package:app_code/repositories/mock_repo/mock_supermarket_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock implementation of SupermarketDatabaseManager for testing
class MockSupermarketDatabaseManager implements SupermarketDatabaseManager {
  Supermarket? _favoriteSupermarket;
  final Map<String, List<Category>> _supermarketCategories = {};
  
  /// Track calls for verification
  int getFavoriteCalls = 0;
  int setFavoriteCalls = 0;
  int clearFavoriteCalls = 0;
  int getCategoriesCalls = 0;
  int replaceCategoriesCalls = 0;

  void reset() {
    _favoriteSupermarket = null;
    _supermarketCategories.clear();
    getFavoriteCalls = 0;
    setFavoriteCalls = 0;
    clearFavoriteCalls = 0;
    getCategoriesCalls = 0;
    replaceCategoriesCalls = 0;
  }

  @override
  Future<Supermarket?> getFavoriteSupermarket() async {
    getFavoriteCalls++;
    return _favoriteSupermarket;
  }

  @override
  Future<void> setFavoriteSupermarket(String supermarketId) async {
    setFavoriteCalls++;
    // Set as favorite (in real app, this would update database)
  }

  @override
  Future<void> clearFavoriteSupermarket(String supermarketId) async {
    clearFavoriteCalls++;
    // Clear favorite (in real app, this would update database)
  }

  @override
  Future<List<Category>> getSupermarketCategories(String supermarketId) async {
    getCategoriesCalls++;
    return _supermarketCategories[supermarketId] ?? [];
  }

  @override
  Future<void> replaceCategoriesOrder(
    String supermarketId,
    List<Category> categories,
  ) async {
    replaceCategoriesCalls++;
    _supermarketCategories[supermarketId] = categories;
  }

  // Test helper methods
  void setFavoriteSupermarketForTest(Supermarket? supermarket) {
    _favoriteSupermarket = supermarket;
  }

  void setSupermarketCategoriesForTest(
    String supermarketId,
    List<Category> categories,
  ) {
    _supermarketCategories[supermarketId] = categories;
  }
}

void main() {
  group('SupermarketsNotifier', () {
    late MockSupermarketRepository mockRepo;
    late MockSupermarketDatabaseManager mockDbManager;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockSupermarketRepository();
      mockDbManager = MockSupermarketDatabaseManager();

      container = ProviderContainer(
        overrides: [
          supermarketRepositoryProvider.overrideWithValue(mockRepo),
          supermarketDatabaseManagerProvider.overrideWithValue(mockDbManager),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    /// Helper to get the notifier
    SupermarketsNotifier getNotifier() =>
        container.read(supermarketsProvider.notifier);

    /// Helper to get current state as a list
    Future<List<Supermarket>> getState() async {
      return await container.read(supermarketsProvider.future);
    }

    /// Helper to create a supermarket
    Supermarket createSupermarket(
      String id,
      String name, {
      bool isVisible = true,
      bool isFavorite = false,
      bool isDefault = false,
      List<Category>? categories,
    }) =>
        Supermarket(
          id: id,
          name: name,
          isVisible: isVisible,
          isFavorite: isFavorite,
          isDefault: isDefault,
          categories: categories,
        );

    /// Helper to create a category
    Category createCategory(String id, String name) => Category(
          id: id,
          name: name,
        );

    // ============= build() tests =============
    group('build()', () {
      test('initial state loads empty list', () async {
        final state = await getState();
        expect(state, isEmpty);
      });

      test('loads supermarkets from repository', () async {
        final sm1 = createSupermarket('sm-1', 'Market A');
        final sm2 = createSupermarket('sm-2', 'Market B');
        await mockRepo.add(sm1);
        await mockRepo.add(sm2);

        // Create new container to trigger build()
        final newContainer = ProviderContainer(
          overrides: [
            supermarketRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        final state = await newContainer.read(supermarketsProvider.future);
        expect(state.length, 2);
        expect(state[0].id, 'sm-1');
        expect(state[1].id, 'sm-2');

        newContainer.dispose();
      });

      test('loads visible and invisible supermarkets', () async {
        final visible = createSupermarket('sm-1', 'Visible', isVisible: true);
        final invisible = createSupermarket('sm-2', 'Invisible', isVisible: false);
        await mockRepo.add(visible);
        await mockRepo.add(invisible);

        final newContainer = ProviderContainer(
          overrides: [
            supermarketRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        final state = await newContainer.read(supermarketsProvider.future);
        expect(state.length, 2);
        expect(state[0].isVisible, isTrue);
        expect(state[1].isVisible, isFalse);

        newContainer.dispose();
      });

      test('loads favorite status correctly', () async {
        final favorite = createSupermarket('sm-1', 'Favorite', isFavorite: true);
        final notFavorite =
            createSupermarket('sm-2', 'Not Favorite', isFavorite: false);
        await mockRepo.add(favorite);
        await mockRepo.add(notFavorite);

        final newContainer = ProviderContainer(
          overrides: [
            supermarketRepositoryProvider.overrideWithValue(mockRepo),
          ],
        );

        final state = await newContainer.read(supermarketsProvider.future);
        expect(state[0].isFavorite, isTrue);
        expect(state[1].isFavorite, isFalse);

        newContainer.dispose();
      });
    });

    // ============= addSupermarket() tests =============
    group('addSupermarket()', () {
      test('adds to repository and invalidates state', () async {
        final notifier = getNotifier();
        final newSupermarket = createSupermarket('sm-1', 'New Market');

        await notifier.addSupermarket(newSupermarket);

        // Verify it was added to repository
        final repoSupermarkets = await mockRepo.getAll();
        expect(repoSupermarkets.length, 1);
        expect(repoSupermarkets[0].id, 'sm-1');
        expect(repoSupermarkets[0].getName(), 'New Market');

        // Verify state was invalidated and reloaded
        final state = await getState();
        expect(state.length, 1);
        expect(state[0].id, 'sm-1');
      });

      test('handles multiple additions correctly', () async {
        final notifier = getNotifier();
        await notifier.addSupermarket(createSupermarket('sm-1', 'First'));
        await notifier.addSupermarket(createSupermarket('sm-2', 'Second'));
        await notifier.addSupermarket(createSupermarket('sm-3', 'Third'));

        final state = await getState();
        expect(state.length, 3);
        expect(state.map((s) => s.id).toList(), ['sm-1', 'sm-2', 'sm-3']);
      });

      test('preserves supermarket properties during add', () async {
        final notifier = getNotifier();
        final supermarket = Supermarket(
          id: 'sm-1',
          name: 'Custom Market',
          isVisible: false,
          isFavorite: true,
          isDefault: false,
        );

        await notifier.addSupermarket(supermarket);

        final state = await getState();
        final added = state.first;
        expect(added.getName(), 'Custom Market');
        expect(added.isVisible, isFalse);
        expect(added.isFavorite, isTrue);
      });

      test('calls repository add method', () async {
        mockRepo.resetSpies();
        final notifier = getNotifier();
        final supermarket = createSupermarket('sm-1', 'Test');

        await notifier.addSupermarket(supermarket);

        expect(mockRepo.addCallCount, 1);
      });

      test('persists empty categories list', () async {
        final notifier = getNotifier();
        final supermarket = createSupermarket('sm-1', 'Market', categories: []);

        await notifier.addSupermarket(supermarket);

        final state = await getState();
        expect(state.first.getCategories(), isEmpty);
      });
    });

    // ============= updateSupermarket() tests =============
    group('updateSupermarket()', () {
      test('updates in repository and invalidates state', () async {
        final notifier = getNotifier();
        final original = createSupermarket('sm-1', 'Original Name');
        await notifier.addSupermarket(original);

        final updated = createSupermarket('sm-1', 'Updated Name');
        await notifier.updateSupermarket(updated);

        final state = await getState();
        expect(state.length, 1);
        expect(state[0].getName(), 'Updated Name');

        // Verify repository was updated
        final repoSupermarkets = await mockRepo.getAll();
        expect(repoSupermarkets[0].getName(), 'Updated Name');
      });

      test('updates visibility flag correctly', () async {
        final notifier = getNotifier();
        final supermarket = createSupermarket('sm-1', 'Test', isVisible: true);
        await notifier.addSupermarket(supermarket);

        supermarket.setVisibility(false);
        await notifier.updateSupermarket(supermarket);

        final state = await getState();
        expect(state[0].isVisible, isFalse);
      });

      test('updates favorite flag correctly', () async {
        final notifier = getNotifier();
        final supermarket = createSupermarket('sm-1', 'Test', isFavorite: false);
        await notifier.addSupermarket(supermarket);

        final updated = createSupermarket('sm-1', 'Test', isFavorite: true);
        await notifier.updateSupermarket(updated);

        final state = await getState();
        expect(state[0].isFavorite, isTrue);
      });

      test('handles updating non-existent supermarket gracefully', () async {
        final notifier = getNotifier();
        final nonExistent = createSupermarket('sm-999', 'Does Not Exist');

        // Should not throw
        await notifier.updateSupermarket(nonExistent);

        final state = await getState();
        expect(state, isEmpty);
      });

      test('calls repository update method', () async {
        mockRepo.resetSpies();
        final notifier = getNotifier();
        final supermarket = createSupermarket('sm-1', 'Test');
        await notifier.addSupermarket(supermarket);

        mockRepo.resetSpies();
        await notifier.updateSupermarket(supermarket);

        expect(mockRepo.updateCallCount, 1);
      });

      test('updates supermarket with categories', () async {
        final notifier = getNotifier();
        final cat1 = createCategory('cat-1', 'Fruits');
        final supermarket = createSupermarket('sm-1', 'Market', categories: [cat1]);
        await notifier.addSupermarket(supermarket);

        final cat2 = createCategory('cat-2', 'Vegetables');
        supermarket.setCategories([cat1, cat2]);
        await notifier.updateSupermarket(supermarket);

        final state = await getState();
        expect(state[0].getCategories().length, 2);
      });
    });

    // ============= deleteSupermarket() tests =============
    // NOTE: Methods that call sqlite_supermarket.ManageSupermarket directly
    // cannot be fully tested in unit tests without initializing the database.
    // These tests are simplified to avoid database init calls.
    group('deleteSupermarket()', () {
      test('handles deleting non-existent supermarket gracefully', () async {
        final notifier = getNotifier();

        // Should not throw
        await notifier.deleteSupermarket('non-existent-id');

        final state = await getState();
        expect(state, isEmpty);
      });
    });

    // ============= getSupermarketById() tests =============
    group('getSupermarketById()', () {
      test('retrieves existing supermarket', () async {
        final notifier = getNotifier();
        final supermarket = createSupermarket('sm-1', 'Test Market');
        await notifier.addSupermarket(supermarket);

        final retrieved = await notifier.getSupermarketById('sm-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.id, 'sm-1');
        expect(retrieved.getName(), 'Test Market');
      });

      test('returns null for non-existent ID', () async {
        final notifier = getNotifier();

        final retrieved = await notifier.getSupermarketById('non-existent');

        expect(retrieved, isNull);
      });

      test('retrieves invisible supermarket', () async {
        final notifier = getNotifier();
        final supermarket =
            createSupermarket('sm-1', 'Invisible', isVisible: false);
        await notifier.addSupermarket(supermarket);

        final retrieved = await notifier.getSupermarketById('sm-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.isVisible, isFalse);
      });

      test('retrieves supermarket with correct categories', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final supermarket =
            createSupermarket('sm-1', 'Market', categories: [cat]);
        await notifier.addSupermarket(supermarket);

        final retrieved = await notifier.getSupermarketById('sm-1');

        expect(retrieved!.getCategories().length, 1);
        expect(retrieved.getCategories()[0].id, 'cat-1');
      });

      test('calls repository getById', () async {
        mockRepo.resetSpies();
        final notifier = getNotifier();
        final supermarket = createSupermarket('sm-1', 'Test');
        await notifier.addSupermarket(supermarket);

        mockRepo.resetSpies();
        await notifier.getSupermarketById('sm-1');

        expect(mockRepo.getByIdCallCount, 1);
      });
    });

    // ============= getLastCreatedSupermarket() tests =============
    group('getLastCreatedSupermarket()', () {
      test('returns empty list when no supermarkets exist', () async {
        final notifier = getNotifier();

        final last = await notifier.getLastCreatedSupermarket();

        expect(last, isNull);
      });

      test('returns the most recently created supermarket', () async {
        final notifier = getNotifier();
        final older = Supermarket(
          id: 'sm-1',
          name: 'Older',
          createdAt: DateTime(2025, 1, 1),
        );
        final newer = Supermarket(
          id: 'sm-2',
          name: 'Newer',
          createdAt: DateTime(2025, 1, 10),
        );

        await notifier.addSupermarket(older);
        await notifier.addSupermarket(newer);

        final last = await notifier.getLastCreatedSupermarket();

        expect(last!.id, 'sm-2');
        expect(last.getName(), 'Newer');
      });

      test('ignores visibility status', () async {
        final notifier = getNotifier();
        await notifier.addSupermarket(
          Supermarket(
            id: 'sm-1',
            name: 'Invisible',
            isVisible: false,
            createdAt: DateTime(2025, 1, 10),
          ),
        );
        await notifier.addSupermarket(
          Supermarket(
            id: 'sm-2',
            name: 'Visible',
            isVisible: true,
            createdAt: DateTime(2025, 1, 1),
          ),
        );

        final last = await notifier.getLastCreatedSupermarket();

        expect(last!.id, 'sm-1');
      });

      test('returns single supermarket when only one exists', () async {
        final notifier = getNotifier();
        final single = createSupermarket('sm-1', 'Only One');
        await notifier.addSupermarket(single);

        final last = await notifier.getLastCreatedSupermarket();

        expect(last!.id, 'sm-1');
      });
    });

    // ============= getLastEditedSupermarket() tests =============
    group('getLastEditedSupermarket()', () {
      test('returns null when no visible supermarkets exist', () async {
        final notifier = getNotifier();

        final last = await notifier.getLastEditedSupermarket();

        expect(last, isNull);
      });

      test('ignores invisible supermarkets', () async {
        final notifier = getNotifier();
        await notifier.addSupermarket(
          Supermarket(
            id: 'sm-1',
            name: 'Invisible',
            isVisible: false,
            lastModified: DateTime(2025, 1, 10),
          ),
        );
        await notifier.addSupermarket(
          Supermarket(
            id: 'sm-2',
            name: 'Visible',
            isVisible: true,
            lastModified: DateTime(2025, 1, 1),
          ),
        );

        final last = await notifier.getLastEditedSupermarket();

        expect(last!.id, 'sm-2');
      });

      test('returns most recently modified visible supermarket', () async {
        final notifier = getNotifier();
        const baseTime = 0;
        await notifier.addSupermarket(
          Supermarket(
            id: 'sm-1',
            name: 'First',
            lastModified: DateTime(2025, 1, 1),
          ),
        );
        await notifier.addSupermarket(
          Supermarket(
            id: 'sm-2',
            name: 'Second',
            lastModified: DateTime(2025, 1, 10),
          ),
        );

        final last = await notifier.getLastEditedSupermarket();

        expect(last!.id, 'sm-2');
      });

      test('uses createdAt as fallback when lastModified is null', () async {
        final notifier = getNotifier();
        await notifier.addSupermarket(
          Supermarket(
            id: 'sm-1',
            name: 'No Modification',
            lastModified: null,
            createdAt: DateTime(2025, 1, 15),
          ),
        );
        await notifier.addSupermarket(
          Supermarket(
            id: 'sm-2',
            name: 'With Modification',
            lastModified: DateTime(2025, 1, 10),
            createdAt: DateTime(2025, 1, 1),
          ),
        );

        final last = await notifier.getLastEditedSupermarket();

        expect(last!.id, 'sm-1');
      });

      test('returns single visible supermarket', () async {
        final notifier = getNotifier();
        final single = createSupermarket('sm-1', 'Only One');
        await notifier.addSupermarket(single);

        final last = await notifier.getLastEditedSupermarket();

        expect(last!.id, 'sm-1');
      });
    });

    // ============= setFavoriteSupermarket() tests =============
    group('setFavoriteSupermarket()', () {
      test('sets supermarket as favorite in repository', () async {
        final notifier = getNotifier();
        final sm = createSupermarket('sm-1', 'Market');
        await notifier.addSupermarket(sm);

        await notifier.setFavoriteSupermarket('sm-1');

        expect(mockDbManager.setFavoriteCalls, 1);
        final state = await getState();
        final updated = state.firstWhere((s) => s.id == 'sm-1');
        expect(updated.isFavorite, true);
      });

      test('clears previous favorite', () async {
        final notifier = getNotifier();
        final sm1 = createSupermarket('sm-1', 'Market 1');
        final sm2 = createSupermarket('sm-2', 'Market 2');
        
        final prevFavorite = createSupermarket('sm-prev', 'Previous Favorite', isFavorite: true);
        mockDbManager.setFavoriteSupermarketForTest(prevFavorite);
        
        await notifier.addSupermarket(sm1);
        await notifier.addSupermarket(sm2);

        await notifier.setFavoriteSupermarket('sm-1');

        expect(mockDbManager.setFavoriteCalls, 1);
      });

      test('handles favorite on non-existent supermarket gracefully', () async {
        final notifier = getNotifier();

        // Should not throw
        await notifier.setFavoriteSupermarket('non-existent');
      });
    });

    // ============= clearFavoriteSupermarket() tests =============
    group('clearFavoriteSupermarket()', () {
      test('clears favorite when not the only supermarket', () async {
        final notifier = getNotifier();
        final sm1 = createSupermarket('sm-1', 'Market 1', isFavorite: true);
        final sm2 = createSupermarket('sm-2', 'Market 2');
        
        mockDbManager.setFavoriteSupermarketForTest(sm1);
        
        await notifier.addSupermarket(sm1);
        await notifier.addSupermarket(sm2);

        final result = await notifier.clearFavoriteSupermarket('sm-1');

        expect(result, true);
        expect(mockDbManager.clearFavoriteCalls, 0); // Auto-switches instead of clearing
      });

      test('cannot clear favorite if is only supermarket', () async {
        final notifier = getNotifier();
        final sm1 = createSupermarket('sm-1', 'Only Market', isFavorite: true);
        mockDbManager.setFavoriteSupermarketForTest(sm1);
        await notifier.addSupermarket(sm1);

        final result = await notifier.clearFavoriteSupermarket('sm-1');

        expect(result, false);
      });

      test('handles non-existent supermarket gracefully', () async {
        final notifier = getNotifier();

        final result = await notifier.clearFavoriteSupermarket('non-existent');

        expect(result, true);
      });
    });

    // ============= getFavoriteSupermarket() tests =============
    group('getFavoriteSupermarket()', () {
      test('returns null when no favorite is set', () async {
        final notifier = getNotifier();

        final favorite = await notifier.getFavoriteSupermarket();

        expect(favorite, isNull);
      });

      test('returns favorite supermarket when set', () async {
        final notifier = getNotifier();
        final favSm = createSupermarket('sm-1', 'Favorite Market');
        mockDbManager.setFavoriteSupermarketForTest(favSm);

        final favorite = await notifier.getFavoriteSupermarket();

        expect(favorite!.id, 'sm-1');
        expect(favorite.getName(), 'Favorite Market');
      });
    });

    // ============= Category operations tests =============
    group('addCategoryToSupermarket()', () {
      test('adds category to existing supermarket', () async {
        final notifier = getNotifier();
        final supermarket = createSupermarket('sm-1', 'Market');
        await notifier.addSupermarket(supermarket);

        final category = createCategory('cat-1', 'Fruits');
        await notifier.addCategoryToSupermarket('sm-1', category);

        final state = await getState();
        expect(state[0].getCategories().length, 1);
        expect(state[0].getCategories()[0].id, 'cat-1');
      });

      test('adds multiple categories to supermarket', () async {
        final notifier = getNotifier();
        final supermarket = createSupermarket('sm-1', 'Market');
        await notifier.addSupermarket(supermarket);

        final cat1 = createCategory('cat-1', 'Fruits');
        final cat2 = createCategory('cat-2', 'Vegetables');
        await notifier.addCategoryToSupermarket('sm-1', cat1);
        await notifier.addCategoryToSupermarket('sm-1', cat2);

        final state = await getState();
        expect(state[0].getCategories().length, 2);
      });

      test('handles adding category to non-existent supermarket gracefully',
          () async {
        final notifier = getNotifier();
        final category = createCategory('cat-1', 'Fruits');

        // Should not throw
        await notifier.addCategoryToSupermarket('non-existent', category);

        final state = await getState();
        expect(state, isEmpty);
      });

      test('updates repository after adding category', () async {
        mockRepo.resetSpies();
        final notifier = getNotifier();
        final supermarket = createSupermarket('sm-1', 'Market');
        await notifier.addSupermarket(supermarket);

        mockRepo.resetSpies();
        final category = createCategory('cat-1', 'Fruits');
        await notifier.addCategoryToSupermarket('sm-1', category);

        expect(mockRepo.updateCallCount, 1);
      });

      test('invalidates state after adding category', () async {
        final notifier = getNotifier();
        final supermarket = createSupermarket('sm-1', 'Market');
        await notifier.addSupermarket(supermarket);

        final category = createCategory('cat-1', 'Fruits');
        await notifier.addCategoryToSupermarket('sm-1', category);

        // Verify state was invalidated by checking it reloads
        final state = await getState();
        expect(state[0].getCategories(), isNotEmpty);
      });
    });

    group('removeCategoryFromSupermarket()', () {
      test('removes category from supermarket', () async {
        final notifier = getNotifier();
        final cat1 = createCategory('cat-1', 'Fruits');
        final cat2 = createCategory('cat-2', 'Vegetables');
        final supermarket = createSupermarket('sm-1', 'Market',
            categories: [cat1, cat2]);
        await notifier.addSupermarket(supermarket);

        await notifier.removeCategoryFromSupermarket('sm-1', 'cat-1');

        final state = await getState();
        expect(state[0].getCategories().length, 1);
        expect(state[0].getCategories()[0].id, 'cat-2');
      });

      test('handles removing non-existent category gracefully', () async {
        final notifier = getNotifier();
        final cat1 = createCategory('cat-1', 'Fruits');
        final supermarket =
            createSupermarket('sm-1', 'Market', categories: [cat1]);
        await notifier.addSupermarket(supermarket);

        await notifier.removeCategoryFromSupermarket('sm-1', 'non-existent');

        final state = await getState();
        expect(state[0].getCategories().length, 1);
      });

      test('handles removing category from non-existent supermarket gracefully',
          () async {
        final notifier = getNotifier();

        // Should not throw
        await notifier.removeCategoryFromSupermarket('non-existent', 'cat-1');

        final state = await getState();
        expect(state, isEmpty);
      });

      test('updates repository after removing category', () async {
        mockRepo.resetSpies();
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Fruits');
        final supermarket =
            createSupermarket('sm-1', 'Market', categories: [cat]);
        await notifier.addSupermarket(supermarket);

        mockRepo.resetSpies();
        await notifier.removeCategoryFromSupermarket('sm-1', 'cat-1');

        expect(mockRepo.updateCallCount, 1);
      });

      test('removes all categories one by one', () async {
        final notifier = getNotifier();
        final cat1 = createCategory('cat-1', 'Fruits');
        final cat2 = createCategory('cat-2', 'Vegetables');
        final cat3 = createCategory('cat-3', 'Meat');
        final supermarket = createSupermarket('sm-1', 'Market',
            categories: [cat1, cat2, cat3]);
        await notifier.addSupermarket(supermarket);

        await notifier.removeCategoryFromSupermarket('sm-1', 'cat-1');
        await notifier.removeCategoryFromSupermarket('sm-1', 'cat-2');
        await notifier.removeCategoryFromSupermarket('sm-1', 'cat-3');

        final state = await getState();
        expect(state[0].getCategories().length, 0);
      });
    });

    group('reorderCategories()', () {
      test('calls database manager to reorder categories', () async {
        final notifier = getNotifier();
        final cat1 = createCategory('cat-1', 'Fruits');
        final cat2 = createCategory('cat-2', 'Vegetables');
        final supermarket = createSupermarket('sm-1', 'Market',
            categories: [cat1, cat2]);
        await notifier.addSupermarket(supermarket);

        final reorderedCats = [cat2, cat1];
        await notifier.reorderCategories('sm-1', reorderedCats);

        expect(mockDbManager.replaceCategoriesCalls, 1);
      });

      test('updates supermarket in repository after reordering', () async {
        final notifier = getNotifier();
        final cat1 = createCategory('cat-1', 'Fruits');
        final cat2 = createCategory('cat-2', 'Vegetables');
        final supermarket = createSupermarket('sm-1', 'Market',
            categories: [cat1, cat2]);
        await notifier.addSupermarket(supermarket);

        mockRepo.resetSpies();
        final reorderedCats = [cat2, cat1];
        await notifier.reorderCategories('sm-1', reorderedCats);

        expect(mockRepo.updateCallCount, 1);
      });

      test('handles non-existent supermarket gracefully', () async {
        final notifier = getNotifier();
        final cat = createCategory('cat-1', 'Test');

        // Should not throw
        await notifier.reorderCategories('non-existent', [cat]);

        final state = await getState();
        expect(state, isEmpty);
      });

      test('invalidates state after reordering', () async {
        final notifier = getNotifier();
        final cat1 = createCategory('cat-1', 'Fruits');
        final supermarket = createSupermarket('sm-1', 'Market',
            categories: [cat1]);
        await notifier.addSupermarket(supermarket);

        var state = await getState();
        expect(state.length, 1);

        final reorderedCats = [cat1];
        await notifier.reorderCategories('sm-1', reorderedCats);

        // Verify state is reloaded
        state = await getState();
        expect(state.length, 1);
      });
    });

    // ============= State invalidation tests =============
    group('State invalidation', () {
      test('invalidates state after add and update operations', () async {
        final notifier = getNotifier();
        final sm1 = createSupermarket('sm-1', 'First');
        await notifier.addSupermarket(sm1);

        var state = await getState();
        expect(state.length, 1);

        final sm2 = createSupermarket('sm-2', 'Second');
        await notifier.addSupermarket(sm2);

        state = await getState();
        expect(state.length, 2);

        // Update one
        final updated = createSupermarket('sm-2', 'Second Updated');
        await notifier.updateSupermarket(updated);

        state = await getState();
        expect(state.length, 2);
        expect(state[1].getName(), 'Second Updated');
      });

      test('handles rapid successive additions', () async {
        final notifier = getNotifier();

        // Add multiple supermarkets rapidly
        await notifier.addSupermarket(createSupermarket('sm-1', 'Market 1'));
        await notifier.addSupermarket(createSupermarket('sm-2', 'Market 2'));
        await notifier.addSupermarket(createSupermarket('sm-3', 'Market 3'));

        final state = await getState();
        expect(state.length, 3);
      });
    });

    // ============= Edge cases tests =============
    group('Edge cases', () {
      test('handles null lastModified gracefully', () async {
        final notifier = getNotifier();
        final supermarket =
            Supermarket(id: 'sm-1', name: 'Test', lastModified: null);
        await notifier.addSupermarket(supermarket);

        final state = await getState();
        expect(state, isNotEmpty);
      });

      test('handles supermarket with empty name', () async {
        final notifier = getNotifier();
        final supermarket = createSupermarket('sm-1', '');
        await notifier.addSupermarket(supermarket);

        final state = await getState();
        expect(state[0].getName(), '');
      });

      test('handles supermarket with very long name', () async {
        final notifier = getNotifier();
        final longName = 'A' * 500;
        final supermarket = createSupermarket('sm-1', longName);
        await notifier.addSupermarket(supermarket);

        final state = await getState();
        expect(state[0].getName(), longName);
      });

      test('handles duplicate IDs correctly (overwrites previous)', () async {
        final notifier = getNotifier();
        await notifier.addSupermarket(createSupermarket('sm-1', 'First'));

        // Adding same ID should not create duplicate
        await notifier.addSupermarket(createSupermarket('sm-1', 'Second'));

        final state = await getState();
        expect(state.length, 1);
      });

      test('handles rapid successive operations', () async {
        final notifier = getNotifier();

        // Execute many operations rapidly
        for (int i = 0; i < 10; i++) {
          await notifier.addSupermarket(
              createSupermarket('sm-$i', 'Market $i'));
        }

        final state = await getState();
        expect(state.length, 10);
      });
    });
  });
}