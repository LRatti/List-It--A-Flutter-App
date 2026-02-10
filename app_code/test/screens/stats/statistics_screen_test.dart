import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/repositories/mock_repo/mock_shopping_list_repository.dart';
import 'package:app_code/screens/stats/statistics_screen.dart';
import 'package:app_code/widgets/period_selector.dart';
import 'package:app_code/widgets/statistics_pie_chart.dart';

class _DelayedShoppingListRepository extends MockShoppingListRepository {
  final Completer<List<ShoppingList>> completer = Completer<List<ShoppingList>>();

  @override
  Future<List<ShoppingList>> getAll() async {
    return completer.future;
  }
}

Category _category(String id, String name) {
  return Category(id: id, name: name);
}

Product _product(String id, String name) {
  return Product(id: id, name: name);
}

PurchasedProduct _purchasedProduct({
  required String listId,
  required String productId,
  required String productName,
  required String categoryId,
  required String categoryName,
  required double price,
  required int quantity,
}) {
  return PurchasedProduct(
    listId: listId,
    product: _product(productId, productName),
    category: _category(categoryId, categoryName),
    price: price,
    quantity: quantity,
  );
}

ShoppingList _list(
  String id,
  String name, {
  required DateTime createdAt,
  List<PurchasedProduct>? products,
  bool registered = true,
  bool inTrash = false,
}) {
  final list = ShoppingList(
    id: id,
    name: name,
    createdAt: createdAt,
    products: products,
  );
  list.setIsRegistered(registered);
  list.setIsInTheTrash(inTrash);
  return list;
}

Future<void> _pumpStats(
  WidgetTester tester, {
  required MockShoppingListRepository repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        shoppingListRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: StatisticsScreenMobile(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows loading indicator while lists load', (tester) async {
    final repository = _DelayedShoppingListRepository();

    await _pumpStats(tester, repository: repository);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.completer.complete(<ShoppingList>[]);
    await tester.pumpAndSettle();
  });

  testWidgets('renders chart and category breakdown for registered lists',
      (tester) async {
    final repository = MockShoppingListRepository();

    final products = [
      _purchasedProduct(
        listId: 'list-1',
        productId: 'p1',
        productName: 'Apple',
        categoryId: 'cat-1',
        categoryName: 'Food',
        price: 10.0,
        quantity: 2,
      ),
      _purchasedProduct(
        listId: 'list-1',
        productId: 'p2',
        productName: 'Soap',
        categoryId: 'cat-2',
        categoryName: 'Home',
        price: 5.0,
        quantity: 1,
      ),
    ];

    await repository.add(
      _list(
        'list-1',
        'Weekly',
        createdAt: DateTime(2024, 5, 10),
        products: products,
      ),
    );

    await _pumpStats(tester, repository: repository);
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(StatisticsScreenMobile)),
    )!;

    expect(find.byType(PeriodSelector), findsOneWidget);
    expect(find.byType(StatisticsPieChart), findsOneWidget);
    expect(find.text(l10n.categoryBreakdownTitle), findsOneWidget);
    expect(find.textContaining(l10n.totalLabel), findsOneWidget);
    expect(find.textContaining('EUR 15.00'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('shows empty state when no registered lists match',
      (tester) async {
    final repository = MockShoppingListRepository();

    await repository.add(
      _list(
        'list-1',
        'Draft',
        createdAt: DateTime(2024, 5, 10),
        registered: false,
        products: [
          _purchasedProduct(
            listId: 'list-1',
            productId: 'p1',
            productName: 'Apple',
            categoryId: 'cat-1',
            categoryName: 'Food',
            price: 10.0,
            quantity: 1,
          ),
        ],
      ),
    );

    await _pumpStats(tester, repository: repository);
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(StatisticsScreenMobile)),
    )!;

    expect(find.text(l10n.noDataForSelectedPeriod), findsOneWidget);
  });

  testWidgets('opens category details sheet on category tap',
      (tester) async {
    final repository = MockShoppingListRepository();

    final products = [
      _purchasedProduct(
        listId: 'list-1',
        productId: 'p1',
        productName: 'Apple',
        categoryId: 'cat-1',
        categoryName: 'Food',
        price: 12.0,
        quantity: 2,
      ),
      _purchasedProduct(
        listId: 'list-1',
        productId: 'p2',
        productName: 'Bread',
        categoryId: 'cat-1',
        categoryName: 'Food',
        price: 3.0,
        quantity: 1,
      ),
    ];

    await repository.add(
      _list(
        'list-1',
        'Weekly',
        createdAt: DateTime(2024, 5, 10),
        products: products,
      ),
    );

    await _pumpStats(tester, repository: repository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(StatisticsScreenMobile)),
    )!;

    expect(find.text('Food'), findsWidgets);
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Bread'), findsOneWidget);
    expect(find.text(l10n.quantityLabel(2)), findsOneWidget);
  });
}
