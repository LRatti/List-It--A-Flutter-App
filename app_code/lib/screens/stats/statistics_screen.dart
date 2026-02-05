import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/utils/statistics_calculator.dart';
import 'package:app_code/widgets/period_selector.dart';
import 'package:app_code/widgets/statistics_pie_chart.dart';
import 'package:app_code/utils/screen_size_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Responsive statistics screen showing spending analytics.
/// 
/// Mobile: Vertical stacking of period selector, pie chart, and category list
/// Tablet: Side-by-side layout with chart on left, details on right
/// Desktop: Larger chart with more detailed category breakdown
class StatisticsScreenResponsive extends StatefulWidget {
  const StatisticsScreenResponsive({super.key});

  @override
  State<StatisticsScreenResponsive> createState() =>
      _StatisticsScreenResponsiveState();
}

class _StatisticsScreenResponsiveState
    extends State<StatisticsScreenResponsive> {
  StatsPeriodType _period = StatsPeriodType.all;
  int? _selectedYear;
  int? _selectedMonth;
  DateTimeRange? _customRange;
  DateTimeRange? _weekRange;

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

  bool _isBefore(DateTime a, DateTime b) =>
      a.isBefore(DateTime(b.year, b.month, b.day));

  bool _isAfter(DateTime a, DateTime b) =>
      a.isAfter(DateTime(b.year, b.month, b.day, 23, 59, 59));

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

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
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
    return Consumer(
      builder: (context, ref, _) {
        final listsAsync = ref.watch(shoppingListsProvider);
        final isMobile = ScreenSize.isMobile(context);
        final isTablet = ScreenSize.isTablet(context);

        return Scaffold(
        body: listsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text("Error occurring: please reload the app.\n"),
          ),
          data: (lists) {
            final computation = StatisticsCalculator.compute(lists, _isWithinPeriod);
            final filtered = computation.filteredLists;
            final entries = computation.categoryEntries;
            final total = computation.total;

            return SingleChildScrollView(
              padding: EdgeInsets.all(ResponsiveSpacing.getHorizontalPadding(context)),
              child: isMobile
                  ? _buildMobileLayout(context, entries, filtered, total)
                  : _buildTabletDesktopLayout(context, entries, filtered, total),
            );
          },
        )
      );
      },
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    List<MapEntry<String, double>> entries,
    List<dynamic> filteredLists,
    double total,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        _buildPeriodSelector(),
        _buildStatisticsChart(entries, total),
        _buildCategoryList(context, entries, filteredLists, total),
      ],
    );
  }

  Widget _buildTabletDesktopLayout(
    BuildContext context,
    List<MapEntry<String, double>> entries,
    List<dynamic> filteredLists,
    double total,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        _buildPeriodSelector(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 24,
          children: [
            Expanded(
              flex: 40,
              child: _buildStatisticsChart(entries, total),
            ),
            Expanded(
              flex: 60,
              child: _buildCategoryList(context, entries, filteredLists, total),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return PeriodSelector(
      onPeriodChanged: (period, month, year, weekRange, customRange) {
        setState(() {
          _period = period;
          _selectedMonth = month;
          _selectedYear = year;
          _weekRange = weekRange;
          _customRange = customRange;
        });
      },
    );
  }

  Widget _buildStatisticsChart(List<MapEntry<String, double>> entries, double total) {
    return StatisticsPieChart(
      entries: entries,
      total: total,
      onCategoryTap: (categoryName) {
        // Handle category tap if needed
      },
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    List<MapEntry<String, double>> entries,
    List<dynamic> filteredLists,
    double total,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No data available for this period',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Breakdown',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final categoryName = entry.key;
            final amount = entry.value;
            final percentage = total == 0 ? 0 : (amount / total) * 100;

            return InkWell(
              onTap: () => _showCategoryDetails(context, categoryName, filteredLists),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          Text(
                            categoryName,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      spacing: 4,
                      children: [
                        Text(
                          _formatCurrency(amount),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
