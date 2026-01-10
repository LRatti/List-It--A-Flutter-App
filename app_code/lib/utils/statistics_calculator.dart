/// Helper models and utilities to compute statistics from shopping lists.
class StatisticsComputation {
  StatisticsComputation({
    required this.filteredLists,
    required this.categoryEntries,
    required this.total,
  });

  final List<dynamic> filteredLists;
  final List<MapEntry<String, double>> categoryEntries;
  final double total;
}

class CategoryProductSummary {
  CategoryProductSummary({
    required this.name,
    required this.price,
    required this.quantity,
  });

  final String name;
  final double price;
  final int quantity;
}

class StatisticsCalculator {
  /// Filters lists by registration and period, then aggregates spend by category.
  static StatisticsComputation compute(
    List<dynamic> lists,
    bool Function(DateTime date) isWithinPeriod,
  ) {
    // Keep only registered lists first.
    final registered = lists.where((l) => l.getIsRegistered()).toList();

    // Apply period filter.
    final filtered = registered
        .where((l) => l.getCreatedAt() != null && isWithinPeriod(l.getCreatedAt()!))
        .toList();

    // Aggregate by category.
    final categoryTotals = <String, double>{};
    for (final list in filtered) {
      for (final product in list.getProducts()) {
        final key = product.category.getName();
        final value = product.price as double;
        categoryTotals.update(key, (old) => old + value, ifAbsent: () => value);
      }
    }

    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final entries = categoryTotals.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return StatisticsComputation(
      filteredLists: filtered,
      categoryEntries: entries,
      total: total,
    );
  }

  /// Aggregates products for a single category, grouped by product name.
  static List<CategoryProductSummary> aggregateCategoryProducts(
    String categoryName,
    List<dynamic> lists,
  ) {
    final categoryProducts = <String, Map<String, dynamic>>{};

    for (final list in lists) {
      for (final product in list.getProducts()) {
        if (product.category.getName() == categoryName) {
          final productName = product.product.getName();
          if (categoryProducts.containsKey(productName)) {
            categoryProducts[productName]!['price'] += product.price;
            categoryProducts[productName]!['quantity'] += product.quantity;
          } else {
            categoryProducts[productName] = {
              'price': product.price,
              'quantity': product.quantity,
            };
          }
        }
      }
    }

    final sortedEntries = categoryProducts.entries.toList()
      ..sort((a, b) => b.value['price'].compareTo(a.value['price']));

    return sortedEntries
        .map((entry) => CategoryProductSummary(
              name: entry.key,
              price: (entry.value['price'] as num).toDouble(),
              quantity: entry.value['quantity'] as int,
            ))
        .toList();
  }
}
