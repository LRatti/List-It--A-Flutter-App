import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_code/widgets/period_selector.dart';
import 'package:app_code/l10n/app_localizations.dart';

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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
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
      final l10n = AppLocalizations.of(tester.element(find.byType(PeriodSelector)))!;

      expect(find.byType(DropdownButton<StatsPeriodType>), findsOneWidget);
      expect(find.text(l10n.periodAll), findsWidgets);

      // Check default captured values
      expect(capturedPeriod, StatsPeriodType.all);
      expect(capturedMonth, isNull);
      expect(capturedYear, isNull);
      expect(capturedWeekRange, isNull);
      expect(capturedCustomRange, isNull);
    });

    for (final period in StatsPeriodType.values.where((p) => p != StatsPeriodType.all)) {
      testWidgets('changes period to $period', (WidgetTester tester) async {
        await pumpSelector(tester);
        final l10n = AppLocalizations.of(tester.element(find.byType(PeriodSelector)))!;
        final label = switch (period) {
          StatsPeriodType.week => l10n.periodWeek,
          StatsPeriodType.month => l10n.periodMonth,
          StatsPeriodType.year => l10n.periodYear,
          StatsPeriodType.custom => l10n.periodCustom,
          StatsPeriodType.all => l10n.periodAll,
        };

        await selectPeriod(tester, label);

        expect(capturedPeriod, period);

        // Additional checks for Month and Year
        if (period == StatsPeriodType.month) {
          expect(capturedMonth, isNotNull);
          expect(capturedYear, isNotNull);
          expect(find.byType(DropdownButton<int>), findsWidgets);
          expect(find.byType(TextField), findsWidgets);
        } else if (period == StatsPeriodType.year) {
          expect(capturedMonth, isNull);
          expect(capturedYear, isNotNull);
          expect(find.byType(TextField), findsWidgets);
        } else if (period == StatsPeriodType.week) {
          expect(capturedWeekRange, isNotNull);
          expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
          expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
          expect(find.byType(GestureDetector), findsWidgets);
        } else if (period == StatsPeriodType.custom) {
          expect(find.byIcon(Icons.date_range), findsOneWidget);
        }
      });
    }

    testWidgets('navigates week forward and backward', (WidgetTester tester) async {
      DateTimeRange? firstRange;
      DateTimeRange? secondRange;

      await pumpSelector(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(PeriodSelector)))!;
      await selectPeriod(tester, l10n.periodWeek);

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
      final l10n = AppLocalizations.of(tester.element(find.byType(PeriodSelector)))!;
      await selectPeriod(tester, l10n.periodYear);

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
