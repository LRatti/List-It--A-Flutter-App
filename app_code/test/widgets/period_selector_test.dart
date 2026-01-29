import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_code/widgets/period_selector.dart';

void main() {
  group('PeriodSelector', () {
    late StatsPeriodType capturedPeriod;
    late int? capturedMonth;
    late int? capturedYear;
    late DateTimeRange? capturedWeekRange;
    late DateTimeRange? capturedCustomRange;

    // Helper to pump PeriodSelector
    Future<void> pumpSelector(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeriodSelector(
              onPeriodChanged: (period, month, year, weekRange, customRange) {
                capturedPeriod = period;
                capturedMonth = month;
                capturedYear = year;
                capturedWeekRange = weekRange;
                capturedCustomRange = customRange;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // Helper to select period from dropdown
    Future<void> selectPeriod(WidgetTester tester, String periodLabel) async {
      await tester.tap(find.byType(DropdownButton<StatsPeriodType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(periodLabel).last);
      await tester.pumpAndSettle();
    }

    testWidgets('renders dropdown and defaults to All', (WidgetTester tester) async {
      await pumpSelector(tester);

      expect(find.byType(DropdownButton<StatsPeriodType>), findsOneWidget);
      expect(find.text('All'), findsWidgets);

      // Check default captured values
      expect(capturedPeriod, StatsPeriodType.all);
      expect(capturedMonth, isNull);
      expect(capturedYear, isNull);
      expect(capturedWeekRange, isNull);
      expect(capturedCustomRange, isNull);
    });

    final periodTests = [
      {'label': 'Week', 'type': StatsPeriodType.week},
      {'label': 'Month', 'type': StatsPeriodType.month},
      {'label': 'Year', 'type': StatsPeriodType.year},
      {'label': 'Custom', 'type': StatsPeriodType.custom},
    ];

    for (var testCase in periodTests) {
      testWidgets('changes period to ${testCase['label']}', (WidgetTester tester) async {
        await pumpSelector(tester);
        await selectPeriod(tester, testCase['label'] as String);

        expect(capturedPeriod, testCase['type']);

        // Additional checks for Month and Year
        if (testCase['type'] == StatsPeriodType.month) {
          expect(capturedMonth, isNotNull);
          expect(capturedYear, isNotNull);
          expect(find.byType(DropdownButton<int>), findsWidgets);
          expect(find.byType(TextField), findsWidgets);
        } else if (testCase['type'] == StatsPeriodType.year) {
          expect(capturedMonth, isNull);
          expect(capturedYear, isNotNull);
          expect(find.byType(TextField), findsWidgets);
        } else if (testCase['type'] == StatsPeriodType.week) {
          expect(capturedWeekRange, isNotNull);
          expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
          expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
          expect(find.byType(GestureDetector), findsWidgets);
        } else if (testCase['type'] == StatsPeriodType.custom) {
          expect(find.byIcon(Icons.date_range), findsOneWidget);
        }
      });
    }

    testWidgets('navigates week forward and backward', (WidgetTester tester) async {
      DateTimeRange? firstRange;
      DateTimeRange? secondRange;

      await pumpSelector(tester);
      await selectPeriod(tester, 'Week');

      // First range
      firstRange = capturedWeekRange;
      expect(firstRange, isNotNull);

      // Forward
      await tester.tap(find.byIcon(Icons.arrow_forward_ios));
      await tester.pumpAndSettle();
      secondRange = capturedWeekRange;
      expect(secondRange, isNotNull);
      expect(secondRange!.start.difference(firstRange!.start).inDays.abs(), 7);

      // Backward
      await tester.tap(find.byIcon(Icons.arrow_back_ios));
      await tester.pumpAndSettle();
      expect(capturedWeekRange!.start.difference(secondRange.start).inDays.abs(), 7);
    });

    testWidgets('clamps year input to valid range', (WidgetTester tester) async {
      await pumpSelector(tester);
      await selectPeriod(tester, 'Year');

      final textField = find.byType(TextField);

      // Minimum clamp
      await tester.enterText(textField, '1800');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(capturedYear, 1900);

      // Maximum clamp
      await tester.enterText(textField, '2500');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(capturedYear, 2100);
    });

    testWidgets('no extra controls for All period', (WidgetTester tester) async {
      await pumpSelector(tester);

      expect(find.byType(DropdownButton<int>), findsNothing);
      expect(find.byIcon(Icons.arrow_back_ios), findsNothing);
      expect(find.byIcon(Icons.arrow_forward_ios), findsNothing);
    });
  });
}
