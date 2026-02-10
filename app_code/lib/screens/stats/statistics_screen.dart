import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/utils/statistics_calculator.dart';
import 'package:app_code/widgets/period_selector.dart';
import 'package:app_code/widgets/statistics_pie_chart.dart';
import 'package:app_code/utils/screen_size_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/utils/category_localizer.dart';

/// Mobile statistics screen: vertical stacking of period selector, chart, and list.
class StatisticsScreenMobile extends ConsumerStatefulWidget {
  const StatisticsScreenMobile({super.key});

  @override
  ConsumerState<StatisticsScreenMobile> createState() =>
      _StatisticsScreenMobileViewState();
}

/// Tablet statistics screen: side-by-side chart and category list.
class StatisticsScreenTablet extends ConsumerStatefulWidget {
  const StatisticsScreenTablet({super.key});

  @override
  ConsumerState<StatisticsScreenTablet> createState() =>
      _StatisticsScreenTabletViewState();
}

abstract class _StatisticsScreenBaseState<T extends ConsumerStatefulWidget>
    extends ConsumerState<T> {
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
    // Changed to EUR to match your screenshot
    return 'EUR ${amount.toStringAsFixed(2)}';
  }

  void _showCategoryDetails(BuildContext context, String categoryName, List<dynamic> allLists) {
    final products = StatisticsCalculator.aggregateCategoryProducts(categoryName, allLists);
    final l10n = AppLocalizations.of(context)!;

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
                    CategoryLocalizer.localize(context, categoryName),
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
                    subtitle: Text(l10n.quantityLabel(product.quantity)),
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
    final listsAsync = ref.watch(shoppingListsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: listsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(l10n.statsLoadError),
        ),
        data: (lists) {
          final computation = StatisticsCalculator.compute(lists, _isWithinPeriod);
          final filtered = computation.filteredLists;
          final entries = computation.categoryEntries;
          final total = computation.total;
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveSpacing.getHorizontalPadding(context)),
            child: buildLayout(context, entries, filtered, total),
          );
        },
      ),
    );
  }

  Widget buildLayout(
    BuildContext context,
    List<MapEntry<String, double>> entries,
    List<dynamic> filteredLists,
    double total,
  );

  Widget _buildMobileLayout(
    BuildContext context,
    List<MapEntry<String, double>> entries,
    List<dynamic> filteredLists,
    double total,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPeriodSelector(),
        const SizedBox(height: 24),
        // Center the chart and give it a fixed constraint to avoid collapsing
        Center(
          child: SizedBox(
            width: 300,
            height: 300,
            child: _buildStatisticsChart(entries, total),
          ),
        ),
        const SizedBox(height: 24),
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
      children: [
        _buildPeriodSelector(),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 40,
              child: Center(
                child: SizedBox(
                  width: 400,
                  height: 400,
                  child: _buildStatisticsChart(entries, total),
                ),
              ),
            ),
            const SizedBox(width: 24),
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
    // FIX: Wrapping with AspectRatio ensures the CustomPaint knows its dimensions
    // and doesn't collapse, which was causing the overlapping text in your image.
    return AspectRatio(
      aspectRatio: 1, 
      child: StatisticsPieChart(
        entries: entries,
        total: total,
        onCategoryTap: (categoryName) {
          // Handle category tap if needed
        },
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    List<MapEntry<String, double>> entries,
    List<dynamic> filteredLists,
    double total,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

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
                l10n.noDataForSelectedPeriod,
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
          l10n.categoryBreakdownTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final categoryName = entry.key;
            final amount = entry.value;
            final percentage = total == 0 ? 0 : (amount / total) * 100;
            final color = _colorForIndex(context, index);

            return ListTile(
              dense: true,
              leading: CircleAvatar(
                backgroundColor: color,
                radius: 8,
              ),
              title: Text(
                CategoryLocalizer.localize(context, categoryName),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              subtitle: Text(
                '${percentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatCurrency(amount),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
              onTap: () => _showCategoryDetails(context, categoryName, filteredLists),
            );
          },
        ),
      ],
    );
  }

  Color _colorForIndex(BuildContext context, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeColors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary ?? colorScheme.primaryContainer,
      colorScheme.error,
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer ?? colorScheme.secondaryContainer,
    ];

    return themeColors[index % themeColors.length];
  }
}

class _StatisticsScreenMobileViewState
    extends _StatisticsScreenBaseState<StatisticsScreenMobile> {
  @override
  Widget buildLayout(
    BuildContext context,
    List<MapEntry<String, double>> entries,
    List<dynamic> filteredLists,
    double total,
  ) {
    return _buildMobileLayout(context, entries, filteredLists, total);
  }
}

class _StatisticsScreenTabletViewState
    extends _StatisticsScreenBaseState<StatisticsScreenTablet> {
  @override
  Widget buildLayout(
    BuildContext context,
    List<MapEntry<String, double>> entries,
    List<dynamic> filteredLists,
    double total,
  ) {
    return _buildTabletDesktopLayout(context, entries, filteredLists, total);
  }
}