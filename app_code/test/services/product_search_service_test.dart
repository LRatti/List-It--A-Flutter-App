import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/repositories/abstract/gemini_repository.dart';
import 'package:app_code/services/database/sqlite/database_helper.dart';
import 'package:app_code/services/database/sqlite/manage_product.dart';
import 'package:app_code/services/product_search_service.dart';
import 'package:app_code/providers/real_app_providers/product/product_categorization_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Mock GeminiRepository for testing
class MockGeminiRepository extends Mock implements GeminiRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGeminiRepository mockGeminiRepository;
  late ProviderContainer container;
  late ProductSearchService service;

  // Test data
  late List<Category> testCategories;
  const testSupermarketId = 'supermarket-1';

  setUpAll(() {
    // Initialize FFI for sqflite testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Reset database
    final db = await DatabaseHelper.database;
    await db.delete('product');
    await db.delete('category');
    await db.delete('associations');

    // Setup test categories
    testCategories = [
      Category(id: 'cat-dairy', name: 'Dairy'),
      Category(id: 'cat-produce', name: 'Produce'),
      Category(id: 'cat-grains', name: 'Grains'),
      Category(id: 'cat-uncategorized', name: 'uncategorized'),
    ];

    // Create mock repository
    mockGeminiRepository = MockGeminiRepository();

    // Create provider container with overrides
    container = ProviderContainer(
      overrides: [
        productCategorizationRepositoryProvider
            .overrideWithValue(mockGeminiRepository),
      ],
    );

    // Create service instance from provider
    service = container.read(productSearchServiceProvider);
  });

  tearDown(() async {
    container.dispose();
  });

  group('ProductSearchService.searchAndCategorize()', () {
    test('returns existing product with existing association', () async {
      // Arrange - Create product with association
      final existingProduct = Product(
        id: 'prod-1',
        name: 'Milk',
        associations: {testSupermarketId: 'cat-dairy'},
      );
      await ManageProduct.addProduct(existingProduct);

      // Act
      final result = await service.searchAndCategorize(
        productName: 'Milk',
        supermarketId: testSupermarketId,
        availableCategories: testCategories,
      );

      // Assert
      expect(result.product.id, 'prod-1');
      expect(result.product.getName(), 'Milk');
      expect(result.category.id, 'cat-dairy');
      expect(result.category.getName(), 'Dairy');

      // Verify Gemini was never called
      verifyNever(() => mockGeminiRepository.categorizeProduct(
            productName: any(named: 'productName'),
            categories: any(named: 'categories'),
          ));
    });

    test('categorizes existing product without association using Gemini', () async {
      // Arrange - Product exists but no association for this supermarket
      final existingProduct = Product(
        id: 'prod-1',
        name: 'Eggs',
        associations: {}, // No associations yet
      );
      await ManageProduct.addProduct(existingProduct);

      when(() => mockGeminiRepository.categorizeProduct(
            productName: any(named: 'productName'),
            categories: any(named: 'categories'),
          )).thenAnswer((_) async => 'Dairy');

      // Act
      final result = await service.searchAndCategorize(
        productName: 'Eggs',
        supermarketId: testSupermarketId,
        availableCategories: testCategories,
      );

      // Assert
      expect(result.product.id, 'prod-1');
      expect(result.category.id, 'cat-dairy');
      expect(result.product.associations[testSupermarketId], 'cat-dairy');

      // Verify Gemini was called
      verify(() => mockGeminiRepository.categorizeProduct(
            productName: 'Eggs',
            categories: testCategories,
          )).called(1);
    });

    test('creates new product and categorizes it with Gemini', () async {
      // Arrange - Product doesn't exist
      when(() => mockGeminiRepository.categorizeProduct(
            productName: any(named: 'productName'),
            categories: any(named: 'categories'),
          )).thenAnswer((_) async => 'Produce');

      // Act
      final result = await service.searchAndCategorize(
        productName: 'Apple',
        supermarketId: testSupermarketId,
        availableCategories: testCategories,
      );

      // Assert
      expect(result.product.getName(), 'Apple');
      expect(result.category.id, 'cat-produce');
      expect(result.product.associations[testSupermarketId], 'cat-produce');

      // Verify Gemini was called
      verify(() => mockGeminiRepository.categorizeProduct(
            productName: 'Apple',
            categories: testCategories,
          )).called(1);
    });

    test('returns uncategorized when Gemini returns invalid category', () async {
      // Arrange
      when(() => mockGeminiRepository.categorizeProduct(
            productName: any(named: 'productName'),
            categories: any(named: 'categories'),
          )).thenAnswer((_) async => 'InvalidCategory');

      // Act
      final result = await service.searchAndCategorize(
        productName: 'NewProduct',
        supermarketId: testSupermarketId,
        availableCategories: testCategories,
      );

      // Assert
      expect(result.category.getName(), 'uncategorized');
      expect(result.product.associations[testSupermarketId], 'cat-uncategorized');
    });

    test('returns uncategorized when Gemini fails with exception', () async {
      // Arrange
      when(() => mockGeminiRepository.categorizeProduct(
            productName: any(named: 'productName'),
            categories: any(named: 'categories'),
          )).thenThrow(Exception('API error'));

      // Act
      final result = await service.searchAndCategorize(
        productName: 'FailProduct',
        supermarketId: testSupermarketId,
        availableCategories: testCategories,
      );

      // Assert
      expect(result.category.getName(), 'uncategorized');
    });

    test('handles case-insensitive category matching', () async {
      // Arrange
      when(() => mockGeminiRepository.categorizeProduct(
            productName: any(named: 'productName'),
            categories: any(named: 'categories'),
          )).thenAnswer((_) async => 'dairy'); // lowercase

      // Act
      final result = await service.searchAndCategorize(
        productName: 'Butter',
        supermarketId: testSupermarketId,
        availableCategories: testCategories,
      );

      // Assert
      expect(result.category.id, 'cat-dairy'); // Should match 'Dairy'
    });

    test('returns correct category for product with multiple supermarket associations', () async {
      // Arrange - Product with different associations for different supermarkets
      final existingProduct = Product(
        id: 'prod-multi',
        name: 'MultiProduct',
        associations: {
          'supermarket-1': 'cat-dairy',
          'supermarket-2': 'cat-produce', // Different category for different supermarket
        },
      );
      await ManageProduct.addProduct(existingProduct);

      // Act - Search in supermarket-2
      final result = await service.searchAndCategorize(
        productName: 'MultiProduct',
        supermarketId: 'supermarket-2',
        availableCategories: testCategories,
      );

      // Assert
      expect(result.category.id, 'cat-produce'); // Should use supermarket-2's category
    });

    test('adds new association to existing product with other supermarket associations', () async {
      // Arrange - Product exists with association for different supermarket
      final existingProduct = Product(
        id: 'prod-existing',
        name: 'ExistingProduct',
        associations: {'other-supermarket': 'cat-grains'},
      );
      await ManageProduct.addProduct(existingProduct);

      when(() => mockGeminiRepository.categorizeProduct(
            productName: any(named: 'productName'),
            categories: any(named: 'categories'),
          )).thenAnswer((_) async => 'Dairy');

      // Act - Search for new supermarket
      final result = await service.searchAndCategorize(
        productName: 'ExistingProduct',
        supermarketId: testSupermarketId,
        availableCategories: testCategories,
      );

      // Assert
      expect(result.product.associations, hasLength(2)); // Should have both associations
      expect(result.product.associations[testSupermarketId], 'cat-dairy');
      expect(result.product.associations['other-supermarket'], 'cat-grains');
    });

    test('handles empty product name gracefully', () async {
      // Arrange
      when(() => mockGeminiRepository.categorizeProduct(
            productName: any(named: 'productName'),
            categories: any(named: 'categories'),
          )).thenAnswer((_) async => 'uncategorized');

      // Act
      final result = await service.searchAndCategorize(
        productName: '',
        supermarketId: testSupermarketId,
        availableCategories: testCategories,
      );

      // Assert
      expect(result.product.getName(), '');
      expect(result.category.getName(), 'uncategorized');
    });

    test('handles whitespace-only product name', () async {
      // Arrange
      when(() => mockGeminiRepository.categorizeProduct(
            productName: any(named: 'productName'),
            categories: any(named: 'categories'),
          )).thenAnswer((_) async => 'uncategorized');

      // Act
      final result = await service.searchAndCategorize(
        productName: '   ',
        supermarketId: testSupermarketId,
        availableCategories: testCategories,
      );

      // Assert
      expect(result.category.getName(), 'uncategorized');
    });

    test('handles product name with special characters', () async {
      // Arrange
      const specialName = 'Café au Lait';
      when(() => mockGeminiRepository.categorizeProduct(
            productName: any(named: 'productName'),
            categories: any(named: 'categories'),
          )).thenAnswer((_) async => 'Dairy');

      // Act
      final result = await service.searchAndCategorize(
        productName: specialName,
        supermarketId: testSupermarketId,
        availableCategories: testCategories,
      );

      // Assert
      expect(result.product.getName(), specialName);
      expect(result.category.id, 'cat-dairy');
    });

    test('handles empty categories list', () async {
      // Arrange
      when(() => mockGeminiRepository.categorizeProduct(
            productName: any(named: 'productName'),
            categories: any(named: 'categories'),
          )).thenAnswer((_) async => 'uncategorized');

      // Act
      final result = await service.searchAndCategorize(
        productName: 'TestProduct',
        supermarketId: testSupermarketId,
        availableCategories: [], // Empty categories
      );

      // Assert - Should handle gracefully
      expect(result.product.getName(), 'TestProduct');
    });

    test('handles category not found in available categories', () async {
      // Arrange
      final limitedCategories = [
        Category(id: 'cat-dairy', name: 'Dairy'),
        Category(id: 'cat-uncategorized', name: 'uncategorized'),
      ];

      when(() => mockGeminiRepository.categorizeProduct(
            productName: any(named: 'productName'),
            categories: any(named: 'categories'),
          )).thenAnswer((_) async => 'Produce'); // Not in limitedCategories

      // Act
      final result = await service.searchAndCategorize(
        productName: 'TestProduct',
        supermarketId: testSupermarketId,
        availableCategories: limitedCategories,
      );

      // Assert - Should fallback to uncategorized
      expect(result.category.getName(), 'uncategorized');
    });

    test('handles Gemini timeout error', () async {
      // Arrange
      when(() => mockGeminiRepository.categorizeProduct(
            productName: any(named: 'productName'),
            categories: any(named: 'categories'),
          )).thenThrow(Exception('Timeout'));

      // Act
      final result = await service.searchAndCategorize(
        productName: 'TimeoutProduct',
        supermarketId: testSupermarketId,
        availableCategories: testCategories,
      );

      // Assert - Should fallback to uncategorized
      expect(result.category.getName(), 'uncategorized');
    });

    test('handles Gemini network error', () async {
      // Arrange
      when(() => mockGeminiRepository.categorizeProduct(
            productName: any(named: 'productName'),
            categories: any(named: 'categories'),
          )).thenThrow(Exception('Network error'));

      // Act
      final result = await service.searchAndCategorize(
        productName: 'NetworkErrorProduct',
        supermarketId: testSupermarketId,
        availableCategories: testCategories,
      );

      // Assert
      expect(result.category.getName(), 'uncategorized');
    });

    test('handles Gemini returning empty string', () async {
      // Arrange
      when(() => mockGeminiRepository.categorizeProduct(
            productName: any(named: 'productName'),
            categories: any(named: 'categories'),
          )).thenAnswer((_) async => '');

      // Act
      final result = await service.searchAndCategorize(
        productName: 'EmptyResponseProduct',
        supermarketId: testSupermarketId,
        availableCategories: testCategories,
      );

      // Assert - Empty string should not match any category
      expect(result.category.getName(), 'uncategorized');
    });

    test('preserves existing product associations when adding new one', () async {
      // Arrange - Product with existing associations
      final existingProduct = Product(
        id: 'prod-preserve',
        name: 'PreserveProduct',
        associations: {
          'supermarket-A': 'cat-dairy',
          'supermarket-B': 'cat-produce',
        },
      );
      await ManageProduct.addProduct(existingProduct);

      when(() => mockGeminiRepository.categorizeProduct(
            productName: any(named: 'productName'),
            categories: any(named: 'categories'),
          )).thenAnswer((_) async => 'Grains');

      // Act - Add association for new supermarket
      final result = await service.searchAndCategorize(
        productName: 'PreserveProduct',
        supermarketId: 'supermarket-C',
        availableCategories: testCategories,
      );

      // Assert - All associations should be preserved
      expect(result.product.associations, hasLength(3));
      expect(result.product.associations['supermarket-A'], 'cat-dairy');
      expect(result.product.associations['supermarket-B'], 'cat-produce');
      expect(result.product.associations['supermarket-C'], 'cat-grains');
    });

    test('handles very long product name', () async {
      // Arrange
      final longName = 'A' * 500;
      when(() => mockGeminiRepository.categorizeProduct(
            productName: any(named: 'productName'),
            categories: any(named: 'categories'),
          )).thenAnswer((_) async => 'Dairy');

      // Act
      final result = await service.searchAndCategorize(
        productName: longName,
        supermarketId: testSupermarketId,
        availableCategories: testCategories,
      );

      // Assert
      expect(result.product.getName(), longName);
      expect(result.category.id, 'cat-dairy');
    });
  });
}
