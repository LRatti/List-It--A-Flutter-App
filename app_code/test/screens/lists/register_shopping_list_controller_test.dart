import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/receipt_match.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/real_app_providers/purchased_products/purchased_products_notifier.dart';
import 'package:app_code/providers/real_app_providers/receipt/receipt_processing_provider.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/repositories/abstract/gemini_repository.dart';
import 'package:app_code/repositories/abstract/shopping_list_repository.dart';
import 'package:app_code/screens/lists/register-list/register_shopping_list_controller.dart';
import 'package:app_code/screens/lists/register-list/register_shopping_list_controller_provider.dart';
import 'package:app_code/services/receipt/receipt_ocr_service.dart';

class MockShoppingListRepository extends Mock implements ShoppingListRepository {}
class MockReceiptOcrService extends Mock implements ReceiptOcrService {}
class MockGeminiRepository extends Mock implements GeminiRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockShoppingListRepository mockShoppingListRepo;
  late MockReceiptOcrService mockOcrService;
  late MockGeminiRepository mockGeminiRepo;

  // Test data
  final category = Category(id: 'cat1', name: 'Fruits');
  final product1 = Product(id: 'p1', name: 'Apple');
  final product2 = Product(id: 'p2', name: 'Banana');

  setUpAll(() {
    // Initialize sqflite_ffi for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    registerFallbackValue(
      ShoppingList(
        id: 'fallback',
        name: 'Fallback',
        createdAt: DateTime.now(),
      ),
    );
    registerFallbackValue(File('fallback.jpg'));
  });

  setUp(() {
    mockShoppingListRepo = MockShoppingListRepository();
    mockOcrService = MockReceiptOcrService();
    mockGeminiRepo = MockGeminiRepository();

    when(() => mockShoppingListRepo.update(any())).thenAnswer((_) async {});
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        shoppingListRepositoryProvider.overrideWithValue(mockShoppingListRepo),
        receiptOcrServiceProvider.overrideWithValue(mockOcrService),
        receiptGeminiRepositoryProvider.overrideWithValue(mockGeminiRepo),
      ],
    );
  }

  RegisterShoppingListController getController(
    ProviderContainer container,
    ShoppingList shoppingList,
  ) {
    return container.read(
      registerShoppingListControllerProvider(shoppingList),
    );
  }

  group('RegisterShoppingListController', () {
    test('initializes with correct data', () {
      final container = createContainer();
      final shoppingList = ShoppingList(
        id: 'list1',
        name: 'Test List',
        createdAt: DateTime.now(),
      );

      final controller = getController(container, shoppingList);

      expect(controller.listId, 'list1');
      expect(controller.listName, 'Test List');
      expect(controller.hasChanges, false);
      
      container.dispose();
    });

    test('getBoughtProducts returns only bought products', () {
      final container = createContainer();
      final pp1 = PurchasedProduct(
        id: 'pp1',
        listId: 'list1',
        product: product1,
        category: category,
        isBought: true,
      );
      final pp2 = PurchasedProduct(
        id: 'pp2',
        listId: 'list1',
        product: product2,
        category: category,
        isBought: false,
      );

      final shoppingList = ShoppingList(
        id: 'list1',
        name: 'Test List',
        createdAt: DateTime.now(),
        products: [pp1, pp2],
      );

      final controller = getController(container, shoppingList);

      final boughtProducts = controller.getBoughtProducts();
      expect(boughtProducts.length, 1);
      expect(boughtProducts.first.id, 'pp1');
      
      container.dispose();
    });

    test('getQuantity returns original quantity', () {
      final container = createContainer();
      final pp1 = PurchasedProduct(
        id: 'pp1',
        listId: 'list1',
        product: product1,
        category: category,
        quantity: 5,
        isBought: true,
      );

      final shoppingList = ShoppingList(
        id: 'list1',
        name: 'Test List',
        createdAt: DateTime.now(),
        products: [pp1],
      );

      final controller = getController(container, shoppingList);

      expect(controller.getQuantity('pp1'), 5);
      
      container.dispose();
    });

    test('updateQuantity updates value and sets hasChanges', () {
      final container = createContainer();
      final pp1 = PurchasedProduct(
        id: 'pp1',
        listId: 'list1',
        product: product1,
        category: category,
        quantity: 5,
        isBought: true,
      );

      final shoppingList = ShoppingList(
        id: 'list1',
        name: 'Test List',
        createdAt: DateTime.now(),
        products: [pp1],
      );

      final controller = getController(container, shoppingList);

      controller.updateQuantity('pp1', 10);

      expect(controller.getQuantity('pp1'), 10);
      expect(controller.hasChanges, true);
      
      container.dispose();
    });

    test('updateQuantity ignores negative values', () {
      final container = createContainer();
      final pp1 = PurchasedProduct(
        id: 'pp1',
        listId: 'list1',
        product: product1,
        category: category,
        quantity: 5,
        isBought: true,
      );

      final shoppingList = ShoppingList(
        id: 'list1',
        name: 'Test List',
        createdAt: DateTime.now(),
        products: [pp1],
      );

      final controller = getController(container, shoppingList);

      controller.updateQuantity('pp1', -3);
      expect(controller.getQuantity('pp1'), 5);
      
      container.dispose();
    });

    test('updatePrice updates value and sets hasChanges', () {
      final container = createContainer();
      final pp1 = PurchasedProduct(
        id: 'pp1',
        listId: 'list1',
        product: product1,
        category: category,
        price: 2.5,
        isBought: true,
      );

      final shoppingList = ShoppingList(
        id: 'list1',
        name: 'Test List',
        createdAt: DateTime.now(),
        products: [pp1],
      );

      final controller = getController(container, shoppingList);

      controller.updatePrice('pp1', 3.0);

      expect(controller.getPrice('pp1'), 3.0);
      expect(controller.hasChanges, true);
      
      container.dispose();
    });

    test('persistChanges updates bought products', () async {
      final container = createContainer();
      final pp1 = PurchasedProduct(
        id: 'pp1',
        listId: 'list1',
        product: product1,
        category: category,
        quantity: 1,
        price: 2.0,
        isBought: true,
      );

      final shoppingList = ShoppingList(
        id: 'list1',
        name: 'Test List',
        createdAt: DateTime.now(),
        products: [pp1],
      );

      final controller = getController(container, shoppingList);

      controller.updateQuantity('pp1', 5);
      controller.updatePrice('pp1', 3.5);

      await controller.persistChanges();

      expect(pp1.quantity, 5);
      expect(pp1.price, 3.5);
      
      container.dispose();
    });

    test('applyReceiptFromImage matches products', () async {
      final container = createContainer();
      final pp1 = PurchasedProduct(
        id: 'pp1',
        listId: 'list1',
        product: product1,
        category: category,
        quantity: 0,
        price: 0.0,
        isBought: true,
      );

      final shoppingList = ShoppingList(
        id: 'list1',
        name: 'Test List',
        createdAt: DateTime.now(),
        products: [pp1],
      );

      final controller = getController(container, shoppingList);

      final testFile = File('test_receipt.jpg');
      
      when(() => mockOcrService.extractText(any())).thenAnswer((_) async => 'Receipt text');
      when(() => mockGeminiRepo.extractReceiptMatches(
        receiptText: any(named: 'receiptText'),
        purchasedProducts: any(named: 'purchasedProducts'),
      )).thenAnswer((_) async => [
        const ReceiptMatch(
          productId: 'pp1',
          productName: 'Apple',
          quantity: 3,
          price: 4.5,
        ),
      ]);

      final matches = await controller.applyReceiptFromImage(testFile);

      expect(matches.length, 1);
      expect(controller.hasChanges, true);
      expect(pp1.quantity, 3);
      expect(pp1.price, 4.5);
      
      container.dispose();
    });

    test('applyReceiptFromImage throws on empty receipt text', () async {
      final container = createContainer();
      final pp1 = PurchasedProduct(
        id: 'pp1',
        listId: 'list1',
        product: product1,
        category: category,
        isBought: true,
      );

      final shoppingList = ShoppingList(
        id: 'list1',
        name: 'Test List',
        createdAt: DateTime.now(),
        products: [pp1],
      );

      final controller = getController(container, shoppingList);

      final testFile = File('test_receipt.jpg');
      
      when(() => mockOcrService.extractText(any())).thenAnswer((_) async => '   ');

      expect(
        () => controller.applyReceiptFromImage(testFile),
        throwsA(isA<Exception>()),
      );
      
      container.dispose();
    });

    test('registerList marks list as registered', () async {
      final container = createContainer();
      final pp1 = PurchasedProduct(
        id: 'pp1',
        listId: 'list1',
        product: product1,
        category: category,
        quantity: 2,
        isBought: true,
      );

      final shoppingList = ShoppingList(
        id: 'list1',
        name: 'Test List',
        createdAt: DateTime.now(),
        products: [pp1],
      );

      final controller = getController(container, shoppingList);

      await controller.registerList();

      expect(shoppingList.getIsRegistered(), true);
      verify(() => mockShoppingListRepo.update(shoppingList)).called(greaterThanOrEqualTo(1));
      
      container.dispose();
    });

    test('registerList auto-fills quantity for zero quantity products', () async {
      final container = createContainer();
      final pp1 = PurchasedProduct(
        id: 'pp1',
        listId: 'list1',
        product: product1,
        category: category,
        quantity: 0,
        isBought: true,
      );

      final shoppingList = ShoppingList(
        id: 'list1',
        name: 'Test List',
        createdAt: DateTime.now(),
        products: [pp1],
      );

      final controller = getController(container, shoppingList);

      await controller.registerList();

      expect(pp1.quantity, 1);
      
      container.dispose();
    });

    test('unregisterList marks list as not registered', () async {
      final container = createContainer();
      final shoppingList = ShoppingList(
        id: 'list1',
        name: 'Test List',
        createdAt: DateTime.now(),
        isRegistered: true,
      );

      final controller = getController(container, shoppingList);

      await controller.unregisterList();

      expect(shoppingList.getIsRegistered(), false);
      verify(() => mockShoppingListRepo.update(shoppingList)).called(greaterThanOrEqualTo(1));
      
      container.dispose();
    });

    test('unregisterList persists pending changes', () async {
      final container = createContainer();
      final pp1 = PurchasedProduct(
        id: 'pp1',
        listId: 'list1',
        product: product1,
        category: category,
        quantity: 1,
        isBought: true,
      );

      final shoppingList = ShoppingList(
        id: 'list1',
        name: 'Test List',
        createdAt: DateTime.now(),
        products: [pp1],
        isRegistered: true,
      );

      final controller = getController(container, shoppingList);

      controller.updateQuantity('pp1', 5);
      await controller.unregisterList();

      expect(pp1.quantity, 5);
      expect(shoppingList.getIsRegistered(), false);
      
      container.dispose();
    });
  });
}
