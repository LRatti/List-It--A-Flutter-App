import 'package:app_code/models/category.dart';
import 'package:app_code/models/recipe_response.dart';
import 'package:app_code/services/gemini/gemini_client.dart';
import 'package:app_code/services/gemini/gemini_exception_handler.dart';
import 'package:app_code/services/gemini/gemini_prompt_builder.dart';
import 'package:app_code/services/gemini/gemini_response_parser.dart';
import 'package:app_code/services/gemini/gemini_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Fake Gemini client for testing without real API calls
class FakeGeminiClient implements GeminiClient {
  final String responseToReturn;

  FakeGeminiClient({required this.responseToReturn});

  @override
  Future<String> generateText(String prompt) async {
    return responseToReturn;
  }
}

/// Gemini client that throws exceptions for error testing
class _ThrowingGeminiClient implements GeminiClient {
  final Exception exception;

  _ThrowingGeminiClient({Exception? exception})
      : exception = exception ?? Exception('Test exception');

  @override
  Future<String> generateText(String prompt) async {
    throw exception;
  }
}

void main() {
  group('GeminiPromptBuilder', () {
    test('buildRecipePrompt includes recipe name and categories', () {
      final prompt = GeminiPromptBuilder.buildRecipePrompt('Pasta', 'Dairy, Grains');

      expect(prompt, contains('Pasta'));
      expect(prompt, contains('Dairy, Grains'));
      expect(prompt, contains('JSON'));
    });

    test('buildCategorizationPrompt includes product and categories', () {
      final prompt =
          GeminiPromptBuilder.buildCategorizationPrompt('Milk', 'Dairy, Produce');

      expect(prompt, contains('Milk'));
      expect(prompt, contains('Dairy, Produce'));
    });
  });

  group('GeminiResponseParser', () {
    test('parse extracts valid JSON and creates RecipeData', () {
      final json = '''{
        "products": [
          {"name": "eggs", "category": "Dairy", "quantity": "3"}
        ],
        "recipe_name": "Omelette",
        "error": "noError"
      }''';

      final result = GeminiResponseParser.parse(json);

      expect(result.products, hasLength(1));
      expect(result.products.first.getName(), 'eggs');
      expect(result.quantities.first, '3');
      expect(result.productCategories.first, 'Dairy');
      expect(result.recipeName, 'Omelette');
    });

    test('parse handles missing JSON gracefully', () {
      final invalid = 'This is not JSON at all';

      final result = GeminiResponseParser.parse(invalid);

      expect(result.error, isNotEmpty);
      expect(result.error, contains('unexpected response'));
    });

    test('parse detects recipe not found error', () {
      final json = '''{
        "products": [],
        "recipe_name": "FakeRecipe",
        "error": "Recipe not found"
      }''';

      final result = GeminiResponseParser.parse(json);

      expect(result.error, contains('FakeRecipe'));
      expect(result.error, contains('not found'));
    });
  });

  group('GeminiService', () {
    test('queryRecipe uses injected client and parses response', () async {
      final fakeResponse = '''{
        "products": [
          {"name": "flour", "category": "Grains", "quantity": "2 cups"}
        ],
        "recipe_name": "Bread",
        "error": "noError"
      }''';

      final service = GeminiService.withClient(
        FakeGeminiClient(responseToReturn: fakeResponse),
      );

      final result = await service.queryRecipe(
        recipeName: 'Bread',
        categories: [Category(id: '1', name: 'Grains')],
      );

      expect(result.products, hasLength(1));
      expect(result.products.first.getName(), 'flour');
      expect(result.recipeName, 'Bread');
    });

    test('queryRecipe handles empty response from client', () async {
      final service = GeminiService.withClient(
        FakeGeminiClient(responseToReturn: ''),
      );

      final result = await service.queryRecipe(
        recipeName: 'Test',
        categories: [Category(id: '1', name: 'Test')],
      );

      expect(result.error, isNotEmpty);
      expect(result.error, contains('did not return a response'));
    });

    test('categorizeProduct validates response against available categories',
        () async {
      final service = GeminiService.withClient(
        FakeGeminiClient(responseToReturn: 'Dairy'),
      );

      final result = await service.categorizeProduct(
        productName: 'Milk',
        categories: [
          Category(id: '1', name: 'Dairy'),
          Category(id: '2', name: 'Produce'),
        ],
      );

      expect(result, 'Dairy');
    });

    test('categorizeProduct returns uncategorized for invalid response',
        () async {
      final service = GeminiService.withClient(
        FakeGeminiClient(responseToReturn: 'InvalidCategory'),
      );

      final result = await service.categorizeProduct(
        productName: 'Unknown',
        categories: [
          Category(id: '1', name: 'Dairy'),
          Category(id: '2', name: 'Produce'),
        ],
      );

      expect(result, 'uncategorized');
    });

    test('categorizeProduct handles empty response', () async {
      final service = GeminiService.withClient(
        FakeGeminiClient(responseToReturn: ''),
      );

      final result = await service.categorizeProduct(
        productName: 'Test',
        categories: [Category(id: '1', name: 'Test')],
      );

      expect(result, 'uncategorized');
    });

    test('categorizeProduct handles case-insensitive category matching', () async {
      final service = GeminiService.withClient(
        FakeGeminiClient(responseToReturn: 'dairy'),
      );

      final result = await service.categorizeProduct(
        productName: 'Milk',
        categories: [
          Category(id: '1', name: 'Dairy'),
          Category(id: '2', name: 'Produce'),
        ],
      );

      expect(result, 'Dairy');
    });

    test('categorizeProduct returns uncategorized on exception', () async {
      final service = GeminiService.withClient(
        _ThrowingGeminiClient(),
      );

      final result = await service.categorizeProduct(
        productName: 'Test',
        categories: [Category(id: '1', name: 'Test')],
      );

      expect(result, 'uncategorized');
    });
  });

  group('GeminiService.extractReceiptMatches()', () {
    test('successfully extracts receipt matches from valid response', () async {
      final fakeResponse = '''{
        "matches": [
          {
            "product_id": "prod-1",
            "product_name": "Milk",
            "quantity": 2,
            "price": 3.50
          },
          {
            "product_id": "prod-2",
            "product_name": "Bread",
            "quantity": 1,
            "price": 2.00
          }
        ]
      }''';

      final service = GeminiService.withClient(
        FakeGeminiClient(responseToReturn: fakeResponse),
      );

      final result = await service.extractReceiptMatches(
        receiptText: r'Receipt: Milk $3.50, Bread $2.00',
        purchasedProducts: [],
      );

      expect(result, hasLength(2));
      expect(result[0].productId, 'prod-1');
      expect(result[0].productName, 'Milk');
      expect(result[0].quantity, 2);
      expect(result[0].price, 3.50);
    });

    test('throws exception when response is empty', () async {
      final service = GeminiService.withClient(
        FakeGeminiClient(responseToReturn: ''),
      );

      expect(
        () async => await service.extractReceiptMatches(
          receiptText: 'test',
          purchasedProducts: [],
        ),
        throwsException,
      );
    });

    test('handles quota exceeded error', () async {
      final service = GeminiService.withClient(
        _ThrowingGeminiClient(
          exception: GenerativeAIException('Rate limit exceeded'),
        ),
      );

      expect(
        () async => await service.extractReceiptMatches(
          receiptText: 'test',
          purchasedProducts: [],
        ),
        throwsA(
          predicate((e) =>
              e is Exception &&
              e.toString().contains('temporarily unavailable')),
        ),
      );
    });

    test('handles connection error', () async {
      final service = GeminiService.withClient(
        _ThrowingGeminiClient(
          exception: GenerativeAIException('Socket exception'),
        ),
      );

      expect(
        () async => await service.extractReceiptMatches(
          receiptText: 'test',
          purchasedProducts: [],
        ),
        throwsA(
          predicate((e) =>
              e is Exception &&
              e.toString().contains('Connection error')),
        ),
      );
    });

    test('handles timeout error', () async {
      final service = GeminiService.withClient(
        _ThrowingGeminiClient(
          exception: GenerativeAIException('timeout'),
        ),
      );

      expect(
        () async => await service.extractReceiptMatches(
          receiptText: 'test',
          purchasedProducts: [],
        ),
        throwsA(
          predicate((e) =>
              e is Exception &&
              e.toString().contains('Connection error')),
        ),
      );
    });

    test('handles generic GenerativeAIException', () async {
      final service = GeminiService.withClient(
        _ThrowingGeminiClient(
          exception: GenerativeAIException('Some other error'),
        ),
      );

      expect(
        () async => await service.extractReceiptMatches(
          receiptText: 'test',
          purchasedProducts: [],
        ),
        throwsA(
          predicate((e) =>
              e is Exception &&
              e.toString().contains('Receipt service failed')),
        ),
      );
    });

    test('handles generic Exception', () async {
      final service = GeminiService.withClient(
        _ThrowingGeminiClient(
          exception: Exception('Generic error'),
        ),
      );

      expect(
        () async => await service.extractReceiptMatches(
          receiptText: 'test',
          purchasedProducts: [],
        ),
        throwsA(
          predicate((e) =>
              e is Exception &&
              e.toString().contains('Receipt processing failed')),
        ),
      );
    });
  });

  group('GeminiService.queryRecipe() error handling', () {
    test('handles GenerativeAIException', () async {
      final service = GeminiService.withClient(
        _ThrowingGeminiClient(
          exception: GenerativeAIException('API error'),
        ),
      );

      final result = await service.queryRecipe(
        recipeName: 'Test',
        categories: [Category(id: '1', name: 'Test')],
      );

      expect(result.error, isNotEmpty);
    });

    test('handles generic Exception', () async {
      final service = GeminiService.withClient(
        _ThrowingGeminiClient(
          exception: Exception('Unknown error'),
        ),
      );

      final result = await service.queryRecipe(
        recipeName: 'Test',
        categories: [Category(id: '1', name: 'Test')],
      );

      expect(result.error, isNotEmpty);
    });
  });

  group('GeminiExceptionHandler', () {
    test('handleGenerativeAIException detects not found error', () {
      final exception = GenerativeAIException('Recipe not found in database');

      final result = GeminiExceptionHandler.handleGenerativeAIException(exception);

      expect(result.error, isNotEmpty);
      expect(result.error, contains('does not exist'));
    });

    test('handleGenerativeAIException detects quota exceeded error', () {
      final exception = GenerativeAIException('Rate limit exceeded');

      final result = GeminiExceptionHandler.handleGenerativeAIException(exception);

      expect(result.error, contains('temporarily unavailable'));
    });

    test('handleGenerativeAIException detects connection error', () {
      final exception = GenerativeAIException('Socket exception: Connection timeout');

      final result = GeminiExceptionHandler.handleGenerativeAIException(exception);

      expect(result.error, contains('Connection error'));
      expect(result.error, contains('internet connection'));
    });

    test('handleGenerativeAIException provides default error message', () {
      final exception = GenerativeAIException('Some random error');

      final result = GeminiExceptionHandler.handleGenerativeAIException(exception);

      expect(result.error, contains('Something went wrong'));
    });

    test('handleGenericException detects network errors', () {
      final exception = Exception('SocketException: connection refused');

      final result = GeminiExceptionHandler.handleGenericException(exception);

      expect(result.error, contains('Connection error'));
    });

    test('handleGenericException handles timeout errors', () {
      final exception = Exception('TimeoutException: operation timed out');

      final result = GeminiExceptionHandler.handleGenericException(exception);

      expect(result.error, contains('Connection error'));
    });

    test('handleGenericException provides generic fallback', () {
      final exception = Exception('Unknown error occurred');

      final result = GeminiExceptionHandler.handleGenericException(exception);

      expect(result.error, 'Something went wrong. Please try again.');
    });
  });
}
