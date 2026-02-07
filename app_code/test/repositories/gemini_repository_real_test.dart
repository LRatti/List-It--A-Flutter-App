import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/receipt_match.dart';
import 'package:app_code/models/recipe_response.dart';
import 'package:app_code/repositories/real_app_repo/gemini_repository_real.dart';
import 'package:app_code/services/gemini/gemini_service.dart';

/// Mock class for GeminiService
class MockGeminiService extends Mock implements GeminiService {}

/// Test suite for GeminiRepositoryReal
/// Tests all public methods with success paths, error paths, and edge cases
void main() {
  late MockGeminiService mockGeminiService;
  late GeminiRepositoryReal repository;

  // Test data
  late List<Category> testCategories;
  late List<PurchasedProduct> testPurchasedProducts;

  setUp(() {
    mockGeminiService = MockGeminiService();
    repository = GeminiRepositoryReal(geminiService: mockGeminiService);

    // Initialize test data
    testCategories = [
      Category(id: 'cat1', name: 'Fruits'),
      Category(id: 'cat2', name: 'Vegetables'),
      Category(id: 'cat3', name: 'Dairy'),
    ];

    final testProduct1 = Product(id: 'p1', name: 'Apple');
    final testProduct2 = Product(id: 'p2', name: 'Carrot');

    testPurchasedProducts = [
      PurchasedProduct(
        id: 'pp1',
        listId: 'list1',
        product: testProduct1,
        category: testCategories[0],
        price: 1.99,
        quantity: 5,
        createdAt: DateTime.now(),
      ),
      PurchasedProduct(
        id: 'pp2',
        listId: 'list1',
        product: testProduct2,
        category: testCategories[1],
        price: 0.99,
        quantity: 3,
        createdAt: DateTime.now(),
      ),
    ];
  });

  group('GeminiRepositoryReal - queryRecipe', () {
    test('should return RecipeData when service call succeeds', () async {
      // Arrange
      final expectedRecipeData = RecipeData(
        products: [
          Product(name: 'Tomato'),
          Product(name: 'Onion'),
        ],
        quantities: ['2', '1'],
        productCategories: ['Vegetables', 'Vegetables'],
        recipeName: 'Pasta Sauce',
        error: 'noError',
      );

      when(
        () => mockGeminiService.queryRecipe(
          recipeName: any(named: 'recipeName'),
          categories: any(named: 'categories'),
        ),
      ).thenAnswer((_) async => expectedRecipeData);

      // Act
      final result = await repository.queryRecipe(
        recipeName: 'Pasta Sauce',
        categories: testCategories,
      );

      // Assert
      expect(result, equals(expectedRecipeData));
      expect(result.hasError, isFalse);
      expect(result.products.length, equals(2));
      expect(result.recipeName, equals('Pasta Sauce'));

      verify(
        () => mockGeminiService.queryRecipe(
          recipeName: 'Pasta Sauce',
          categories: testCategories,
        ),
      ).called(1);
    });

    test(
      'should return error RecipeData when service throws exception',
      () async {
        // Arrange
        when(
          () => mockGeminiService.queryRecipe(
            recipeName: any(named: 'recipeName'),
            categories: any(named: 'categories'),
          ),
        ).thenThrow(Exception('Network error'));

        // Act
        final result = await repository.queryRecipe(
          recipeName: 'Pasta Sauce',
          categories: testCategories,
        );

        // Assert
        expect(result.hasError, isTrue);
        expect(
          result.error,
          equals(
            'Something went wrong while searching for the recipe. Please try again.',
          ),
        );
        expect(result.products, isEmpty);
        expect(result.recipeName, isEmpty);

        verify(
          () => mockGeminiService.queryRecipe(
            recipeName: 'Pasta Sauce',
            categories: testCategories,
          ),
        ).called(1);
      },
    );

    test(
      'should return error RecipeData when service throws generic error',
      () async {
        // Arrange
        when(
          () => mockGeminiService.queryRecipe(
            recipeName: any(named: 'recipeName'),
            categories: any(named: 'categories'),
          ),
        ).thenThrow(Error());

        // Act
        final result = await repository.queryRecipe(
          recipeName: 'Invalid Recipe',
          categories: testCategories,
        );

        // Assert
        expect(result.hasError, isTrue);
        expect(result.products, isEmpty);
        verify(
          () => mockGeminiService.queryRecipe(
            recipeName: 'Invalid Recipe',
            categories: testCategories,
          ),
        ).called(1);
      },
    );

    test('should handle empty categories list', () async {
      // Arrange
      final emptyRecipeData = RecipeData.empty();
      when(
        () => mockGeminiService.queryRecipe(
          recipeName: any(named: 'recipeName'),
          categories: any(named: 'categories'),
        ),
      ).thenAnswer((_) async => emptyRecipeData);

      // Act
      final result = await repository.queryRecipe(
        recipeName: 'Simple Recipe',
        categories: [],
      );

      // Assert
      expect(result, equals(emptyRecipeData));
      verify(
        () => mockGeminiService.queryRecipe(
          recipeName: 'Simple Recipe',
          categories: [],
        ),
      ).called(1);
    });

    test('should handle empty recipe name', () async {
      // Arrange
      final errorRecipeData = RecipeData.error('Invalid recipe');
      when(
        () => mockGeminiService.queryRecipe(
          recipeName: any(named: 'recipeName'),
          categories: any(named: 'categories'),
        ),
      ).thenAnswer((_) async => errorRecipeData);

      // Act
      final result = await repository.queryRecipe(
        recipeName: '',
        categories: testCategories,
      );

      // Assert
      expect(result, equals(errorRecipeData));
      verify(
        () => mockGeminiService.queryRecipe(
          recipeName: '',
          categories: testCategories,
        ),
      ).called(1);
    });
  });

  group('GeminiRepositoryReal - categorizeProduct', () {
    test('should return category name when service call succeeds', () async {
      // Arrange
      const expectedCategory = 'Fruits';
      when(
        () => mockGeminiService.categorizeProduct(
          productName: any(named: 'productName'),
          categories: any(named: 'categories'),
        ),
      ).thenAnswer((_) async => expectedCategory);

      // Act
      final result = await repository.categorizeProduct(
        productName: 'Apple',
        categories: testCategories,
      );

      // Assert
      expect(result, equals(expectedCategory));
      verify(
        () => mockGeminiService.categorizeProduct(
          productName: 'Apple',
          categories: testCategories,
        ),
      ).called(1);
    });

    test(
      'should return "uncategorized" when service throws exception',
      () async {
        // Arrange
        when(
          () => mockGeminiService.categorizeProduct(
            productName: any(named: 'productName'),
            categories: any(named: 'categories'),
          ),
        ).thenThrow(Exception('API error'));

        // Act
        final result = await repository.categorizeProduct(
          productName: 'Unknown Product',
          categories: testCategories,
        );

        // Assert
        expect(result, equals('uncategorized'));
        verify(
          () => mockGeminiService.categorizeProduct(
            productName: 'Unknown Product',
            categories: testCategories,
          ),
        ).called(1);
      },
    );

    test(
      'should return "uncategorized" when service throws generic error',
      () async {
        // Arrange
        when(
          () => mockGeminiService.categorizeProduct(
            productName: any(named: 'productName'),
            categories: any(named: 'categories'),
          ),
        ).thenThrow(Error());

        // Act
        final result = await repository.categorizeProduct(
          productName: 'Error Product',
          categories: testCategories,
        );

        // Assert
        expect(result, equals('uncategorized'));
        verify(
          () => mockGeminiService.categorizeProduct(
            productName: 'Error Product',
            categories: testCategories,
          ),
        ).called(1);
      },
    );

    test('should handle empty categories list', () async {
      // Arrange
      const expectedCategory = 'General';
      when(
        () => mockGeminiService.categorizeProduct(
          productName: any(named: 'productName'),
          categories: any(named: 'categories'),
        ),
      ).thenAnswer((_) async => expectedCategory);

      // Act
      final result = await repository.categorizeProduct(
        productName: 'Generic Item',
        categories: [],
      );

      // Assert
      expect(result, equals(expectedCategory));
      verify(
        () => mockGeminiService.categorizeProduct(
          productName: 'Generic Item',
          categories: [],
        ),
      ).called(1);
    });

    test('should handle empty product name', () async {
      // Arrange
      when(
        () => mockGeminiService.categorizeProduct(
          productName: any(named: 'productName'),
          categories: any(named: 'categories'),
        ),
      ).thenAnswer((_) async => 'uncategorized');

      // Act
      final result = await repository.categorizeProduct(
        productName: '',
        categories: testCategories,
      );

      // Assert
      expect(result, equals('uncategorized'));
      verify(
        () => mockGeminiService.categorizeProduct(
          productName: '',
          categories: testCategories,
        ),
      ).called(1);
    });

    test('should handle special characters in product name', () async {
      // Arrange
      const expectedCategory = 'Vegetables';
      when(
        () => mockGeminiService.categorizeProduct(
          productName: any(named: 'productName'),
          categories: any(named: 'categories'),
        ),
      ).thenAnswer((_) async => expectedCategory);

      // Act
      final result = await repository.categorizeProduct(
        productName: 'Tomato&Basil!@#',
        categories: testCategories,
      );

      // Assert
      expect(result, equals(expectedCategory));
      verify(
        () => mockGeminiService.categorizeProduct(
          productName: 'Tomato&Basil!@#',
          categories: testCategories,
        ),
      ).called(1);
    });
  });

  group('GeminiRepositoryReal - extractReceiptMatches', () {
    test('should return receipt matches when service call succeeds', () async {
      // Arrange
      final expectedMatches = [
        const ReceiptMatch(
          productId: 'p1',
          productName: 'Apple',
          quantity: 5,
          price: 9.95,
        ),
        const ReceiptMatch(
          productId: 'p2',
          productName: 'Carrot',
          quantity: 3,
          price: 2.97,
        ),
      ];

      when(
        () => mockGeminiService.extractReceiptMatches(
          receiptText: any(named: 'receiptText'),
          purchasedProducts: any(named: 'purchasedProducts'),
        ),
      ).thenAnswer((_) async => expectedMatches);

      // Act
      final result = await repository.extractReceiptMatches(
        receiptText: 'Apple 5x 9.95\nCarrot 3x 2.97',
        purchasedProducts: testPurchasedProducts,
      );

      // Assert
      expect(result, equals(expectedMatches));
      expect(result.length, equals(2));
      expect(result[0].productName, equals('Apple'));
      expect(result[0].quantity, equals(5));
      expect(result[0].price, equals(9.95));

      verify(
        () => mockGeminiService.extractReceiptMatches(
          receiptText: 'Apple 5x 9.95\nCarrot 3x 2.97',
          purchasedProducts: testPurchasedProducts,
        ),
      ).called(1);
    });

    test('should rethrow exception when service throws exception', () async {
      // Arrange
      final expectedException = Exception('OCR parsing failed');
      when(
        () => mockGeminiService.extractReceiptMatches(
          receiptText: any(named: 'receiptText'),
          purchasedProducts: any(named: 'purchasedProducts'),
        ),
      ).thenThrow(expectedException);

      // Act & Assert
      expect(
        () => repository.extractReceiptMatches(
          receiptText: 'Invalid receipt text',
          purchasedProducts: testPurchasedProducts,
        ),
        throwsA(equals(expectedException)),
      );

      verify(
        () => mockGeminiService.extractReceiptMatches(
          receiptText: 'Invalid receipt text',
          purchasedProducts: testPurchasedProducts,
        ),
      ).called(1);
    });

    test('should rethrow error when service throws error', () async {
      // Arrange
      final expectedError = ArgumentError('Invalid format');
      when(
        () => mockGeminiService.extractReceiptMatches(
          receiptText: any(named: 'receiptText'),
          purchasedProducts: any(named: 'purchasedProducts'),
        ),
      ).thenThrow(expectedError);

      // Act & Assert
      expect(
        () => repository.extractReceiptMatches(
          receiptText: 'Malformed receipt',
          purchasedProducts: testPurchasedProducts,
        ),
        throwsA(equals(expectedError)),
      );

      verify(
        () => mockGeminiService.extractReceiptMatches(
          receiptText: 'Malformed receipt',
          purchasedProducts: testPurchasedProducts,
        ),
      ).called(1);
    });

    test('should return empty list when no matches found', () async {
      // Arrange
      when(
        () => mockGeminiService.extractReceiptMatches(
          receiptText: any(named: 'receiptText'),
          purchasedProducts: any(named: 'purchasedProducts'),
        ),
      ).thenAnswer((_) async => []);

      // Act
      final result = await repository.extractReceiptMatches(
        receiptText: 'No matching products',
        purchasedProducts: testPurchasedProducts,
      );

      // Assert
      expect(result, isEmpty);
      verify(
        () => mockGeminiService.extractReceiptMatches(
          receiptText: 'No matching products',
          purchasedProducts: testPurchasedProducts,
        ),
      ).called(1);
    });

    test('should handle empty receipt text', () async {
      // Arrange
      when(
        () => mockGeminiService.extractReceiptMatches(
          receiptText: any(named: 'receiptText'),
          purchasedProducts: any(named: 'purchasedProducts'),
        ),
      ).thenAnswer((_) async => []);

      // Act
      final result = await repository.extractReceiptMatches(
        receiptText: '',
        purchasedProducts: testPurchasedProducts,
      );

      // Assert
      expect(result, isEmpty);
      verify(
        () => mockGeminiService.extractReceiptMatches(
          receiptText: '',
          purchasedProducts: testPurchasedProducts,
        ),
      ).called(1);
    });

    test('should handle empty purchased products list', () async {
      // Arrange
      when(
        () => mockGeminiService.extractReceiptMatches(
          receiptText: any(named: 'receiptText'),
          purchasedProducts: any(named: 'purchasedProducts'),
        ),
      ).thenAnswer((_) async => []);

      // Act
      final result = await repository.extractReceiptMatches(
        receiptText: 'Some receipt text',
        purchasedProducts: [],
      );

      // Assert
      expect(result, isEmpty);
      verify(
        () => mockGeminiService.extractReceiptMatches(
          receiptText: 'Some receipt text',
          purchasedProducts: [],
        ),
      ).called(1);
    });

    test('should handle partial matches with null productId', () async {
      // Arrange
      final partialMatches = [
        const ReceiptMatch(
          productId: null,
          productName: 'Unknown Product',
          quantity: 1,
          price: 5.99,
        ),
      ];

      when(
        () => mockGeminiService.extractReceiptMatches(
          receiptText: any(named: 'receiptText'),
          purchasedProducts: any(named: 'purchasedProducts'),
        ),
      ).thenAnswer((_) async => partialMatches);

      // Act
      final result = await repository.extractReceiptMatches(
        receiptText: 'Unknown Product 1x 5.99',
        purchasedProducts: testPurchasedProducts,
      );

      // Assert
      expect(result.length, equals(1));
      expect(result[0].productId, isNull);
      expect(result[0].productName, equals('Unknown Product'));

      verify(
        () => mockGeminiService.extractReceiptMatches(
          receiptText: 'Unknown Product 1x 5.99',
          purchasedProducts: testPurchasedProducts,
        ),
      ).called(1);
    });
  });

  group('GeminiRepositoryReal - Constructor', () {
    test('should use provided GeminiService instance', () {
      // Arrange & Act
      final customService = MockGeminiService();
      final customRepository = GeminiRepositoryReal(
        geminiService: customService,
      );

      // Assert
      expect(customRepository, isNotNull);
    });

    test(
      'should throw exception when creating default service without API key',
      () {
        // The default constructor creates a GeminiService which requires
        // GEMINI_API_KEY to be set via --dart-define
        // This test verifies the expected behavior when API key is missing

        // Act & Assert
        expect(
          () => GeminiRepositoryReal(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('GEMINI_API_KEY environment variable is not set'),
            ),
          ),
        );
      },
    );
  });
}
