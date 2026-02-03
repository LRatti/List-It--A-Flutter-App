import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/utils/statistics_calculator.dart';
import 'package:app_code/widgets/period_selector.dart';
import 'package:app_code/widgets/statistics_pie_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Statistics screen that displays spending data grouped by category
/// Shows a pie chart and list of categories with percentages and amounts
class StatisticsScreenMobile extends ConsumerStatefulWidget {
  const StatisticsScreenMobile({super.key});

  @override
  ConsumerState<StatisticsScreenMobile> createState() => _StatisticsScreenMobileState();
}

class _StatisticsScreenMobileState extends ConsumerState<StatisticsScreenMobile> {
  // Selected period type (all, week, month, year, or custom)
  StatsPeriodType _period = StatsPeriodType.all;
  
  // Selected year for year/month filtering
  int? _selectedYear;
  
  // Selected month (1-12) for month filtering
  int? _selectedMonth;
  
  // Custom date range selected by user
  DateTimeRange? _customRange;
  
  // Current week range (Monday to Sunday)
  DateTimeRange? _weekRange;

  /// Checks if a date falls within the currently selected period
  bool _isWithinPeriod(DateTime date) {
    switch (_period) {
      case StatsPeriodType.all:
        return true;
      case StatsPeriodType.week:
        if (_weekRange == null) return true;
        return !_isBefore(date, _weekRange!.start) && !_isAfter(date, _weekRange!.end);
      case StatsPeriodType.month:
        if (_selectedYear == null || _selectedMonth == null) return true;
        return date.year == _selectedYear && date.month == _selectedMonth;
      case StatsPeriodType.year:
        if (_selectedYear == null) return true;
        return date.year == _selectedYear;
      case StatsPeriodType.custom:
        if (_customRange == null) return true;
        return !_isBefore(date, _customRange!.start) && !_isAfter(date, _customRange!.end);
    }
  }

  /// Checks if date a is before date b (comparing only dates, not time)
  bool _isBefore(DateTime a, DateTime b) => a.isBefore(DateTime(b.year, b.month, b.day));
  
  /// Checks if date a is after date b (comparing only dates, not time)
  bool _isAfter(DateTime a, DateTime b) => a.isAfter(DateTime(b.year, b.month, b.day, 23, 59, 59));

  /// Shows a bottom sheet with products for the selected category
  void _showCategoryDetails(BuildContext context, String categoryName, List<dynamic> allLists) {
    final products = StatisticsCalculator.aggregateCategoryProducts(categoryName, allLists);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    categoryName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Product list
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: products.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = products[index];
                  
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text('Quantity: ${product.quantity}'),
                    trailing: Text(
                      _formatCurrency(product.price),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(shoppingListsProvider);

    return Scaffold(
      body: listsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text("Error occurring: please reload the app.\n")),
        data: (lists) {
          final computation = StatisticsCalculator.compute(lists, _isWithinPeriod);
          final filtered = computation.filteredLists;
          final entries = computation.categoryEntries;
          final total = computation.total;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PeriodSelector(
                    onPeriodChanged: (period, month, year, weekRange, customRange) {
                      setState(() {
                        _period = period;
                        _selectedMonth = month;
                        _selectedYear = year;
                        _weekRange = weekRange;
                        _customRange = customRange;
                      });
                    },
                  ),
                  if (total == 0)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Center(child: Text('No data for the selected period.')),
                    )
                  else ...[
                    const SizedBox(height: 12),
                    // Pie chart
                    SizedBox(
                      height: 200,
                      child: StatisticsPieChart(entries: entries, total: total),
                    ),
                    const SizedBox(height: 12),
                    // "By category" title
                    Text(
                      'By category',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // Category list - not expanded, just normal height
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final e = entries[index];
                        final percent = total == 0 ? 0 : (e.value / total) * 100;
                        final color = _colorForIndex(index);
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(backgroundColor: color, radius: 8),
                          title: Text(e.key, style: Theme.of(context).textTheme.titleSmall),
                          subtitle: Text('${percent.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.labelSmall),
                          trailing: Text(_formatCurrency(e.value), style: Theme.of(context).textTheme.labelSmall),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                          onTap: () => _showCategoryDetails(context, e.key, filtered),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Returns a color for the given index using the Colors.primaries list
  Color _colorForIndex(int index) {
    return Colors.primaries[index % Colors.primaries.length];
  }

  /// Formats a double value as currency (e.g., €12.34)
  String _formatCurrency(double value) {
    return '€${value.toStringAsFixed(2)}';
  }
}
