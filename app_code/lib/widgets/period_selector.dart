import 'package:flutter/material.dart';

/// Enum defining the available time period filter types
enum StatsPeriodType { all, week, month, year, custom }

/// A widget that allows users to select and navigate through different time periods
/// Supports filtering by all time, specific weeks, months, years, or custom ranges
/// Manages its own state for period selection and date ranges
class PeriodSelector extends StatefulWidget {
  const PeriodSelector({
    super.key,
    required this.onPeriodChanged,
  });

  /// Callback when any period parameter changes
  /// Returns the selected period type and relevant date ranges
  final void Function(StatsPeriodType period, int? month, int? year, DateTimeRange? weekRange, DateTimeRange? customRange) onPeriodChanged;

  @override
  State<PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<PeriodSelector> {
  /// Currently selected period type
  StatsPeriodType _period = StatsPeriodType.all;
  
  /// Currently selected month (1-12, used when period is month)
  int _selectedMonth = DateTime.now().month;
  
  /// Currently selected year (used for month and year periods)
  int _selectedYear = DateTime.now().year;
  
  /// Current week range (Monday to Sunday)
  DateTimeRange? _weekRange;
  
  /// Current custom date range
  DateTimeRange? _customRange;
  
  /// Controller for year text input
  final TextEditingController _yearController = TextEditingController();

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    // Set initial year in controller
    _yearController.text = _selectedYear.toString();
    // Initialize week range to current week
    _weekRange = _currentWeek();
    // Notify parent of initial state after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyChange();
    });
  }
  
  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  /// Notifies parent widget of period changes
  void _notifyChange() {
    // Only pass month when period is month
    final month = _period == StatsPeriodType.month ? _selectedMonth : null;
    // Only pass year when period is month or year
    final year = (_period == StatsPeriodType.month || _period == StatsPeriodType.year) ? _selectedYear : null;
    // Only pass weekRange when period is week
    final weekRange = _period == StatsPeriodType.week ? _weekRange : null;
    // Only pass customRange when period is custom
    final customRange = _period == StatsPeriodType.custom ? _customRange : null;
    
    widget.onPeriodChanged(_period, month, year, weekRange, customRange);
  }

  /// Returns the current week range (Monday to Sunday)
  DateTimeRange _currentWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return DateTimeRange(start: monday, end: sunday);
  }

  /// Opens date picker for selecting a custom date range
  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initial = _customRange ?? DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initial,
    );
    if (picked != null) {
      setState(() => _customRange = picked);
      _notifyChange();
    }
  }

  /// Advances the week range by 7 days (to next week)
  void _goToNextWeek() {
    final current = _weekRange ?? _currentWeek();
    final nextMonday = current.start.add(const Duration(days: 7));
    final nextSunday = nextMonday.add(const Duration(days: 6));
    setState(() => _weekRange = DateTimeRange(start: nextMonday, end: nextSunday));
    _notifyChange();
  }

  /// Moves the week range back by 7 days (to previous week)
  void _goToPreviousWeek() {
    final current = _weekRange ?? _currentWeek();
    final previousMonday = current.start.subtract(const Duration(days: 7));
    final previousSunday = previousMonday.add(const Duration(days: 6));
    setState(() => _weekRange = DateTimeRange(start: previousMonday, end: previousSunday));
    _notifyChange();
  }

  /// Validates and updates year from text input
  /// Automatically corrects invalid input to reasonable bounds
  void _updateYearFromInput(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      // Empty input - reset to current year
      final currentYear = DateTime.now().year;
      setState(() => _selectedYear = currentYear);
      _yearController.text = currentYear.toString();
      _notifyChange();
      return;
    }
    
    final parsed = int.tryParse(trimmed);
    if (parsed == null) {
      // Invalid number - reset to current selected year
      _yearController.text = _selectedYear.toString();
      return;
    }
    
    // Validate year range (1900-2100)
    int correctedYear = parsed;
    if (parsed < 1900) {
      correctedYear = 1900;
    } else if (parsed > 2100) {
      correctedYear = 2100;
    }
    
    // Update if different
    if (correctedYear != _selectedYear) {
      setState(() => _selectedYear = correctedYear);
      _yearController.text = correctedYear.toString();
      _notifyChange();
    } else if (correctedYear != parsed) {
      // Just update the text field if correction happened
      _yearController.text = correctedYear.toString();
    }
  }
  
  /// Opens date picker for selecting a specific week
  /// User selects a single date, and the week containing that date is selected
  Future<void> _pickWeek() async {
    final now = DateTime.now();
    final initial = _weekRange?.start ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      helpText: 'Select any day in the week',
    );
    if (picked != null) {
      // Calculate the Monday-Sunday week containing the picked date
      final monday = picked.subtract(Duration(days: picked.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      setState(() => _weekRange = DateTimeRange(start: monday, end: sunday));
      _notifyChange();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate list of years (current year and 5 previous years)
    final years = List<int>.generate(6, (i) => DateTime.now().year - i);

    // Use SingleChildScrollView to allow horizontal scrolling if content is too wide
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dropdown to select the period type
          DropdownButton<StatsPeriodType>(
            value: _period,
            onChanged: (value) {
              if (value != null) {
                setState(() => _period = value);
                _notifyChange();
              }
            },
            items: const [
              DropdownMenuItem(value: StatsPeriodType.all, child: Text('All')),
              DropdownMenuItem(value: StatsPeriodType.week, child: Text('Week')),
              DropdownMenuItem(value: StatsPeriodType.month, child: Text('Month')),
              DropdownMenuItem(value: StatsPeriodType.year, child: Text('Year')),
              DropdownMenuItem(value: StatsPeriodType.custom, child: Text('Custom')),
            ],
          ),
          const SizedBox(width: 12),
          if (_period == StatsPeriodType.month) ...[
            DropdownButton<int>(
              value: _selectedMonth,
              onChanged: (v) {
                if (v != null) {
                  setState(() => _selectedMonth = v);
                  _notifyChange();
                }
              },
              items: List.generate(12, (i) => i + 1)
                  .map((m) => DropdownMenuItem(value: m, child: Text(_monthNames[m - 1])))
                  .toList(),
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      border: OutlineInputBorder(),
                      hintText: 'Year',
                    ),
                    onSubmitted: _updateYearFromInput,
                    onTapOutside: (_) => _updateYearFromInput(_yearController.text),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                  tooltip: 'Select year',
                  onSelected: (year) {
                    setState(() => _selectedYear = year);
                    _yearController.text = year.toString();
                    _notifyChange();
                  },
                  itemBuilder: (context) => years
                      .map((y) => PopupMenuItem(value: y, child: Text(y.toString())))
                      .toList(),
                ),
              ],
            ),
          ],
          if (_period == StatsPeriodType.year)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      border: OutlineInputBorder(),
                      hintText: 'Year',
                    ),
                    onSubmitted: _updateYearFromInput,
                    onTapOutside: (_) => _updateYearFromInput(_yearController.text),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                  tooltip: 'Select year',
                  onSelected: (year) {
                    setState(() => _selectedYear = year);
                    _yearController.text = year.toString();
                    _notifyChange();
                  },
                  itemBuilder: (context) => years
                      .map((y) => PopupMenuItem(value: y, child: Text(y.toString())))
                      .toList(),
                ),
              ],
            ),
          if (_period == StatsPeriodType.week) ...[
            // Previous week button
            IconButton(
              onPressed: _goToPreviousWeek,
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              tooltip: 'Previous week',
            ),
            // Week range display (clickable to open date picker)
            GestureDetector(
              onTap: _pickWeek,
              child: Container(
                // Dynamic sizing with constraints to prevent overflow
                constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatRange(_weekRange),
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Next week button
            IconButton(
              onPressed: _goToNextWeek,
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              tooltip: 'Next week',
            ),
          ],
          if (_period == StatsPeriodType.custom)
            TextButton.icon(
              onPressed: _pickCustomRange,
              icon: const Icon(Icons.date_range),
              label: Text(_formatRange(_customRange)),
            ),
        ],
      ),
    );
  }

  /// Formats a date range for display
  /// Shows "Select range" if range is null
  String _formatRange(DateTimeRange? range) {
    if (range == null) return 'Select range';
    return '${_fmt(range.start)} - ${_fmt(range.end)}';
  }

  /// Formats a single date as "day/month/year"
  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
