import 'package:app_code/widgets/statistics_pie_chart.dart';
import 'package:app_code/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StatisticsPieChart', () {
    testWidgets('renders total text and wires painter with data', (tester) async {
      final entries = [
        const MapEntry('Food', 10.0),
        const MapEntry('Home', 20.0),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: StatisticsPieChart(
                  entries: entries,
                  total: 30,
                  onCategoryTap: (_) => null,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      expect(find.textContaining(l10n.totalLabel), findsOneWidget);
      expect(find.textContaining('EUR 30.00'), findsOneWidget);

      final painted = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where((cp) => cp.painter is PieChartPainter)
        .toList();

      expect(painted.length, 1);

      final painter = painted.first.painter as PieChartPainter;

      expect(painter.entries, entries);
      expect(painter.total, 30);
      expect(painter.backgroundColor, ThemeData().colorScheme.surface);
    });

    test('shouldRepaint always returns true', () {
      final colorScheme = ThemeData().colorScheme;

      final painter = PieChartPainter(
        entries: const [MapEntry('Food', 10)],
        total: 10,
        backgroundColor: colorScheme.surface,
        colorScheme: colorScheme,
      );

      final other = PieChartPainter(
        entries: const [MapEntry('Other', 5)],
        total: 5,
        backgroundColor: colorScheme.surface,
        colorScheme: colorScheme,
      );

      expect(painter.shouldRepaint(other), isTrue);
    });
  });
}
