import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/widgets/searchable_supermarkets_view.dart';
import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/providers/real_app_providers/navigation_provider.dart';
import 'package:app_code/providers/real_app_providers/supermarket/supermarkets_notifier.dart';
import 'package:app_code/repositories/mock_repo/mock_supermarket_repository.dart';

void main() {
  group('SearchableSupermarketsView', () {
    late List<Supermarket> testSupermarkets;
    Supermarket? capturedSupermarket;
    late int tapCount;

    setUp(() {
      testSupermarkets = [
        Supermarket(id: '1', name: 'Walmart', createdAt: DateTime(2024, 1, 1)),
        Supermarket(id: '2', name: 'Target Store', createdAt: DateTime(2024, 1, 1)),
        Supermarket(id: '3', name: 'Whole Foods', createdAt: DateTime(2024, 1, 1)),
      ];
      tapCount = 0;
      capturedSupermarket = null;
    });

    // Helper to pump the widget with ProviderScope
    Future<void> pumpSearchableView(
      WidgetTester tester, {
      List<Supermarket>? supermarkets,
      String? emptyMessage,
      void Function(BuildContext, Supermarket)? onSupermarketTap,
      Widget? floatingActionButton,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supermarketRepositoryProvider.overrideWithValue(MockSupermarketRepository()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: SearchableSupermarketsView(
              supermarkets: supermarkets ?? testSupermarkets,
              emptyMessage: emptyMessage ?? 'No supermarkets available',
              onSupermarketTap: onSupermarketTap ??
                  (context, supermarket) {
                    capturedSupermarket = supermarket;
                    tapCount++;
                  },
              floatingActionButton: floatingActionButton,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders with normal AppBar initially', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('displays all supermarkets initially', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      expect(find.text('Walmart'), findsOneWidget);
      expect(find.text('Target Store'), findsOneWidget);
      expect(find.text('Whole Foods'), findsOneWidget);
    });

    testWidgets('shows empty message when no supermarkets provided', (WidgetTester tester) async {
      await pumpSearchableView(
        tester,
        supermarkets: [],
        emptyMessage: 'No supermarkets found',
      );

      expect(find.text('No supermarkets found'), findsOneWidget);
    });

    testWidgets('starts search mode when search icon is tapped', (WidgetTester tester) async {
      await pumpSearchableView(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(SearchableSupermarketsView)))!;

      // Tap search icon
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Should show search TextField
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text(l10n.searchSupermarketsHint), findsOneWidget);
    });

    testWidgets('filters supermarkets based on search query', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      // Start search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'walmart');
      await tester.pumpAndSettle();

      // Should only show Walmart
      expect(find.text('Walmart'), findsOneWidget);
      expect(find.text('Target Store'), findsNothing);
      expect(find.text('Whole Foods'), findsNothing);
    });

    testWidgets('search is case-insensitive', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Search with different cases
      await tester.enterText(find.byType(TextField), 'TARGET');
      await tester.pumpAndSettle();

      expect(find.text('Target Store'), findsOneWidget);
      expect(find.text('Walmart'), findsNothing);
    });

    testWidgets('shows custom empty message when no search results', (WidgetTester tester) async {
      await pumpSearchableView(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(SearchableSupermarketsView)))!;

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pumpAndSettle();

      expect(find.text(l10n.noSupermarketsFoundMatching('nonexistent')), findsOneWidget);
    });

    testWidgets('clears search when clear icon is tapped', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'walmart');
      await tester.pumpAndSettle();

      // Tap clear icon
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Should show all supermarkets again
      expect(find.text('Walmart'), findsOneWidget);
      expect(find.text('Target Store'), findsOneWidget);
      expect(find.text('Whole Foods'), findsOneWidget);
    });

    testWidgets('stops search when back arrow is tapped', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'walmart');
      await tester.pumpAndSettle();

      // Tap back arrow
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should exit search mode and show all supermarkets
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Walmart'), findsOneWidget);
      expect(find.text('Target Store'), findsOneWidget);
      expect(find.text('Whole Foods'), findsOneWidget);
    });

    testWidgets('calls onSupermarketTap when a supermarket is tapped', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      // Find and tap the InkWell widget for the first supermarket
      final inkWells = find.byType(InkWell);
      expect(inkWells, findsWidgets);

      await tester.tap(inkWells.first);
      await tester.pumpAndSettle();

      expect(tapCount, 1);
      expect(capturedSupermarket?.getName(), 'Walmart');
    });

    testWidgets('renders floating action button when provided', (WidgetTester tester) async {
      final fab = FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      );

      await pumpSearchableView(tester, floatingActionButton: fab);

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('updates filtered supermarkets when widget updates', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      expect(find.text('Walmart'), findsOneWidget);

      // Update with new supermarkets
      final newSupermarkets = [
        Supermarket(id: '4', name: 'Costco', createdAt: DateTime(2024, 1, 1)),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supermarketRepositoryProvider.overrideWithValue(MockSupermarketRepository()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: SearchableSupermarketsView(
              supermarkets: newSupermarkets,
              emptyMessage: 'No supermarkets available',
              onSupermarketTap: (context, supermarket) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Costco'), findsOneWidget);
      expect(find.text('Walmart'), findsNothing);
    });

    testWidgets('maintains search filter when widget updates', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      // Start search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'target');
      await tester.pumpAndSettle();

      // Update supermarkets
      final updatedSupermarkets = [
        Supermarket(id: '2', name: 'Target Store', createdAt: DateTime(2024, 1, 1)),
        Supermarket(id: '5', name: 'Target Express', createdAt: DateTime(2024, 1, 1)),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supermarketRepositoryProvider.overrideWithValue(MockSupermarketRepository()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: SearchableSupermarketsView(
              supermarkets: updatedSupermarkets,
              emptyMessage: 'No supermarkets available',
              onSupermarketTap: (context, supermarket) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should still be filtering with 'target'
      expect(find.text('Target Store'), findsOneWidget);
      expect(find.text('Target Express'), findsOneWidget);
    });

    testWidgets('hides AppBar in deletion mode', (WidgetTester tester) async {
      await pumpSearchableView(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(SearchableSupermarketsView)))!;

      // Initial AppBar should exist
      expect(find.byType(AppBar), findsOneWidget);

      // Long press on InkWell to enter deletion mode
      final inkWells = find.byType(InkWell);
      await tester.longPress(inkWells.first);
      await tester.pumpAndSettle();

      // Should show the selection mode AppBar
      expect(find.text(l10n.selectedItemsCount(1)), findsOneWidget);
    });

    testWidgets('stops search when entering deletion mode', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      // Start search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'walmart');
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      // Enter deletion mode via long press on InkWell
      final inkWells = find.byType(InkWell);
      await tester.longPress(inkWells.first);
      await tester.pumpAndSettle();

      // Search should be stopped
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('resets state when navigation signal changes', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          supermarketRepositoryProvider.overrideWithValue(MockSupermarketRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: SearchableSupermarketsView(
              supermarkets: testSupermarkets,
              emptyMessage: 'No supermarkets available',
              onSupermarketTap: (context, supermarket) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'walmart');
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      // Trigger navigation signal
      container.read(appNavigationSignalProvider.notifier).state++;
      await tester.pumpAndSettle();

      // Search should be stopped
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('search query filters partial matches', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Search for partial word
      await tester.enterText(find.byType(TextField), 'tore');
      await tester.pumpAndSettle();

      // Should match 'Target Store'
      expect(find.text('Target Store'), findsOneWidget);
      expect(find.text('Walmart'), findsNothing);
      expect(find.text('Whole Foods'), findsNothing);
    });

    testWidgets('search returns empty when query does not match', (WidgetTester tester) async {
      await pumpSearchableView(tester);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'xyz123');
      await tester.pumpAndSettle();

      expect(find.text('Walmart'), findsNothing);
      expect(find.text('Target Store'), findsNothing);
      expect(find.text('Whole Foods'), findsNothing);
    });

    testWidgets('onDeletionModeChanged callback is called', (WidgetTester tester) async {
      bool? deletionModeState;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supermarketRepositoryProvider.overrideWithValue(MockSupermarketRepository()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: SearchableSupermarketsView(
              supermarkets: testSupermarkets,
              emptyMessage: 'No supermarkets available',
              onDeletionModeChanged: (isDeleting) {
                deletionModeState = isDeleting;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter deletion mode
      final inkWells = find.byType(InkWell);
      await tester.longPress(inkWells.first);
      await tester.pumpAndSettle();

      expect(deletionModeState, true);
    });
  });
}
