import 'package:app_code/providers/shopping_lists_notifier.dart';
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

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(shoppingListsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: listsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (lists) {
          // Filter to only show completed (registered) shopping lists
          final registered = lists.where((l) => l.getIsRegistered()).toList();
          
          // Further filter by selected time period
          final filtered = registered
              .where((l) => l.getCreatedAt() != null && _isWithinPeriod(l.getCreatedAt()!))
              .toList();

          // Aggregate spending by category
          final categoryTotals = <String, double>{};
          for (final list in filtered) {
            for (final product in list.getProducts()) {
              final key = product.category.getName();
              final value = product.price;
              categoryTotals.update(key, (old) => old + value, ifAbsent: () => value);
            }
          }

          // Calculate total spending and sort categories by amount (descending)
          final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
          final entries = categoryTotals.entries
              .where((e) => e.value > 0)
              .toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          if (total == 0) {
            return const Center(child: Text('No data for the selected period.'));
          }

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
                  const SizedBox(height: 12),
                  // Pie chart - fixed height
                  SizedBox(
                    height: 200,
                    child: StatisticsPieChart(entries: entries, total: total),
                  ),
                  const SizedBox(height: 12),
                  // "By category" title
                  const Text(
                    'By category',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                        title: Text(e.key, style: const TextStyle(fontSize: 15)),
                        subtitle: Text('${percent.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12)),
                        trailing: Text(_formatCurrency(e.value), style: const TextStyle(fontSize: 12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                      );
                    },
                  ),
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
