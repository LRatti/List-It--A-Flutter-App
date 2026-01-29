import 'package:flutter_test/flutter_test.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/utils/statistics_calculator.dart';

void main() {
  group('StatisticsCalculator.compute()', () {
    test('returns empty computation for empty list', () {
      final result = StatisticsCalculator.compute(
        [],
        (_) => true,
      );

      expect(result.filteredLists, isEmpty);
      expect(result.categoryEntries, isEmpty);
      expect(result.total, 0.0);
    });

    test('filters out unregistered lists', () {
      final category = Category(id: '1', name: 'Groceries');
      final product = Product(id: '1', name: 'Milk');
      final purchased = PurchasedProduct(
        id: '1',
        listId: 'list1',
        product: product,
        category: category,
        price: 2.5,
        quantity: 1,
      );

      final registeredList = ShoppingList(
        name: 'Registered',
        createdAt: DateTime(2024, 5, 15),
        isRegistered: true,
      )..addPurchasedProduct(purchased);

      final unregisteredList = ShoppingList(
        name: 'Unregistered',
        createdAt: DateTime(2024, 5, 15),
        isRegistered: false,
      )..addPurchasedProduct(purchased);

      final result = StatisticsCalculator.compute(
        [registeredList, unregisteredList],
        (_) => true,
      );

      expect(result.filteredLists.length, 1);
      expect(result.filteredLists.first.getName(), 'Registered');
    });

    test('filters out lists outside period', () {
      final category = Category(id: '1', name: 'Groceries');
      final product = Product(id: '1', name: 'Milk');
      final purchased = PurchasedProduct(
        id: '1',
        listId: 'list1',
        product: product,
        category: category,
        price: 2.5,
        quantity: 1,
      );

      final inPeriodList = ShoppingList(
        name: 'In Period',
        createdAt: DateTime(2024, 5, 15),
        isRegistered: true,
      )..addPurchasedProduct(purchased);

      final outOfPeriodList = ShoppingList(
        name: 'Out of Period',
        createdAt: DateTime(2024, 3, 15),
        isRegistered: true,
      )..addPurchasedProduct(purchased);

      final result = StatisticsCalculator.compute(
        [inPeriodList, outOfPeriodList],
        (date) => date.month == 5,
      );

      expect(result.filteredLists.length, 1);
      expect(result.filteredLists.first.getName(), 'In Period');
    });

    test('aggregates spending by category', () {
      final groceries = Category(id: '1', name: 'Groceries');
      final electronics = Category(id: '2', name: 'Electronics');

      final milk = Product(id: '1', name: 'Milk');
      final bread = Product(id: '2', name: 'Bread');
      final phone = Product(id: '3', name: 'Phone');

      final list1 = ShoppingList(
        name: 'List 1',
        createdAt: DateTime(2024, 5, 15),
        isRegistered: true,
      );
      list1.addPurchasedProduct(PurchasedProduct(
        id: '1',
        listId: list1.id,
        product: milk,
        category: groceries,
        price: 2.5,
        quantity: 1,
      ));
      list1.addPurchasedProduct(PurchasedProduct(
        id: '2',
        listId: list1.id,
        product: bread,
        category: groceries,
        price: 1.5,
        quantity: 2,
      ));

      final list2 = ShoppingList(
        name: 'List 2',
        createdAt: DateTime(2024, 5, 20),
        isRegistered: true,
      );
      list2.addPurchasedProduct(PurchasedProduct(
        id: '3',
        listId: list2.id,
        product: phone,
        category: electronics,
        price: 500.0,
        quantity: 1,
      ));

      final result = StatisticsCalculator.compute(
        [list1, list2],
        (_) => true,
      );

      expect(result.categoryEntries.length, 2);
      expect(result.total, 504.0);

      // Electronics should be first (highest spend)
      expect(result.categoryEntries[0].key, 'Electronics');
      expect(result.categoryEntries[0].value, 500.0);

      expect(result.categoryEntries[1].key, 'Groceries');
      expect(result.categoryEntries[1].value, 4.0);
    });

    test('returns entries sorted by spending descending', () {
      final cat1 = Category(id: '1', name: 'Category A');
      final cat2 = Category(id: '2', name: 'Category B');
      final cat3 = Category(id: '3', name: 'Category C');

      final prod1 = Product(id: '1', name: 'Prod1');
      final prod2 = Product(id: '2', name: 'Prod2');
      final prod3 = Product(id: '3', name: 'Prod3');

      final list1 = ShoppingList(
        name: 'List 1',
        createdAt: DateTime(2024, 5, 15),
        isRegistered: true,
      );
      list1.addPurchasedProduct(PurchasedProduct(
        id: '1',
        listId: list1.id,
        product: prod1,
        category: cat1,
        price: 10.0,
        quantity: 1,
      ));
      list1.addPurchasedProduct(PurchasedProduct(
        id: '2',
        listId: list1.id,
        product: prod2,
        category: cat2,
        price: 50.0,
        quantity: 1,
      ));
      list1.addPurchasedProduct(PurchasedProduct(
        id: '3',
        listId: list1.id,
        product: prod3,
        category: cat3,
        price: 30.0,
        quantity: 1,
      ));

      final result = StatisticsCalculator.compute(
        [list1],
        (_) => true,
      );

      expect(result.categoryEntries[0].value, 50.0);
      expect(result.categoryEntries[1].value, 30.0);
      expect(result.categoryEntries[2].value, 10.0);
    });
  });

  group('StatisticsCalculator.aggregateCategoryProducts()', () {
    test('returns empty list when category has no products', () {
      final category = Category(id: '1', name: 'Groceries');
      final list1 = ShoppingList(
        name: 'List 1',
        createdAt: DateTime(2024, 5, 15),
        isRegistered: true,
      );

      final result = StatisticsCalculator.aggregateCategoryProducts(
        'NonExistent',
        [list1],
      );

      expect(result, isEmpty);
    });

    test('aggregates products within a category', () {
      final groceries = Category(id: '1', name: 'Groceries');
      final milk = Product(id: '1', name: 'Milk');
      final bread = Product(id: '2', name: 'Bread');

      final list1 = ShoppingList(
        name: 'List 1',
        createdAt: DateTime(2024, 5, 15),
        isRegistered: true,
      );
      list1.addPurchasedProduct(PurchasedProduct(
        id: '1',
        listId: list1.id,
        product: milk,
        category: groceries,
        price: 2.0,
        quantity: 2,
      ));
      list1.addPurchasedProduct(PurchasedProduct(
        id: '2',
        listId: list1.id,
        product: bread,
        category: groceries,
        price: 1.5,
        quantity: 3,
      ));

      final result = StatisticsCalculator.aggregateCategoryProducts(
        'Groceries',
        [list1],
      );

      expect(result.length, 2);
      expect(result[0].name, 'Milk');
      expect(result[0].price, 2.0);
      expect(result[0].quantity, 2);

      expect(result[1].name, 'Bread');
      expect(result[1].price, 1.5);
      expect(result[1].quantity, 3);
    });

    test('sums duplicate products across lists', () {
      final groceries = Category(id: '1', name: 'Groceries');
      final milk = Product(id: '1', name: 'Milk');

      final list1 = ShoppingList(
        name: 'List 1',
        createdAt: DateTime(2024, 5, 15),
        isRegistered: true,
      );
      list1.addPurchasedProduct(PurchasedProduct(
        id: '1',
        listId: list1.id,
        product: milk,
        category: groceries,
        price: 2.0,
        quantity: 1,
      ));

      final list2 = ShoppingList(
        name: 'List 2',
        createdAt: DateTime(2024, 5, 20),
        isRegistered: true,
      );
      list2.addPurchasedProduct(PurchasedProduct(
        id: '2',
        listId: list2.id,
        product: milk,
        category: groceries,
        price: 2.5,
        quantity: 2,
      ));

      final result = StatisticsCalculator.aggregateCategoryProducts(
        'Groceries',
        [list1, list2],
      );

      expect(result.length, 1);
      expect(result[0].name, 'Milk');
      expect(result[0].price, 4.5);
      expect(result[0].quantity, 3);
    });

    test('returns products sorted by price descending', () {
      final groceries = Category(id: '1', name: 'Groceries');
      final apple = Product(id: '1', name: 'Apple');
      final banana = Product(id: '2', name: 'Banana');
      final orange = Product(id: '3', name: 'Orange');

      final list1 = ShoppingList(
        name: 'List 1',
        createdAt: DateTime(2024, 5, 15),
        isRegistered: true,
      );
      list1.addPurchasedProduct(PurchasedProduct(
        id: '1',
        listId: list1.id,
        product: apple,
        category: groceries,
        price: 5.0,
        quantity: 1,
      ));
      list1.addPurchasedProduct(PurchasedProduct(
        id: '2',
        listId: list1.id,
        product: banana,
        category: groceries,
        price: 2.0,
        quantity: 1,
      ));
      list1.addPurchasedProduct(PurchasedProduct(
        id: '3',
        listId: list1.id,
        product: orange,
        category: groceries,
        price: 3.5,
        quantity: 1,
      ));

      final result = StatisticsCalculator.aggregateCategoryProducts(
        'Groceries',
        [list1],
      );

      expect(result[0].name, 'Apple');
      expect(result[0].price, 5.0);
      expect(result[1].name, 'Orange');
      expect(result[1].price, 3.5);
      expect(result[2].name, 'Banana');
      expect(result[2].price, 2.0);
    });
  });
}
