import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/widgets/supermarkets_grid_view.dart';
import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/providers/real_app_providers/navigation_provider.dart';
import 'package:app_code/providers/real_app_providers/supermarket/supermarkets_notifier.dart';
import 'package:app_code/repositories/mock_repo/mock_supermarket_repository.dart';

void main() {
  group('SupermarketsGridView', () {
    late List<Supermarket> testSupermarkets;
    Supermarket? capturedSupermarket;
    late int tapCount;
    late bool deletionMode;

    setUp(() {
      testSupermarkets = [
        Supermarket(id: '1', name: 'Walmart', createdAt: DateTime(2024, 1, 1)),
        Supermarket(id: '2', name: 'Target', isFavorite: true, createdAt: DateTime(2024, 1, 2)),
        Supermarket(id: '3', name: 'Costco', createdAt: DateTime(2024, 1, 3)),
      ];
      tapCount = 0;
      capturedSupermarket = null;
      deletionMode = false;
    });

    // Helper to pump the widget with ProviderScope
    Future<void> pumpGridView(
      WidgetTester tester, {
      List<Supermarket>? supermarkets,
      String? emptyMessage,
      void Function(BuildContext, Supermarket)? onSupermarketTap,
      void Function(bool)? onDeletionModeChanged,
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
            home: SupermarketsGridView(
              supermarkets: supermarkets ?? testSupermarkets,
              emptyMessage: emptyMessage ?? 'No supermarkets available',
              onSupermarketTap: onSupermarketTap ??
                  (context, supermarket) {
                    capturedSupermarket = supermarket;
                    tapCount++;
                  },
              onDeletionModeChanged: onDeletionModeChanged ??
                  (isActive) {
                    deletionMode = isActive;
                  },
              floatingActionButton: floatingActionButton,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('displays empty message when no supermarkets provided', (WidgetTester tester) async {
      await pumpGridView(
        tester,
        supermarkets: [],
        emptyMessage: 'No supermarkets found',
      );

      expect(find.text('No supermarkets found'), findsOneWidget);
      expect(find.byIcon(Icons.store_outlined), findsOneWidget);
    });

    testWidgets('displays all supermarkets in list', (WidgetTester tester) async {
      await pumpGridView(tester);

      expect(find.text('Walmart'), findsOneWidget);
      expect(find.text('Target'), findsOneWidget);
      expect(find.text('Costco'), findsOneWidget);
    });

    testWidgets('renders floating action button when provided', (WidgetTester tester) async {
      final fab = FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      );

      await pumpGridView(tester, floatingActionButton: fab);

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows favorite icon for favorite supermarket', (WidgetTester tester) async {
      await pumpGridView(tester);

      final starIcons = find.byIcon(Icons.star);
      expect(starIcons, findsOneWidget);
    });

    testWidgets('shows edit button for each supermarket', (WidgetTester tester) async {
      await pumpGridView(tester);

      final editIcons = find.byIcon(Icons.edit_outlined);
      expect(editIcons, findsNWidgets(3));
    });

    testWidgets('calls onSupermarketTap when card is tapped', (WidgetTester tester) async {
      await pumpGridView(tester);

      final inkWells = find.byType(InkWell);
      await tester.tap(inkWells.first);
      await tester.pumpAndSettle();

      expect(tapCount, 1);
      expect(capturedSupermarket?.getName(), 'Walmart');
    });

    testWidgets('calls onSupermarketTap when edit button is tapped', (WidgetTester tester) async {
      await pumpGridView(tester);

      final editButtons = find.byIcon(Icons.edit_outlined);
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      expect(tapCount, 1);
      expect(capturedSupermarket?.getName(), 'Walmart');
    });

    testWidgets('enters selection mode on long press', (WidgetTester tester) async {
      await pumpGridView(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(SupermarketsGridView)))!;

      final inkWells = find.byType(InkWell);
      await tester.longPress(inkWells.first);
      await tester.pumpAndSettle();

      expect(find.text(l10n.selectedItemsCount(1)), findsOneWidget);
      expect(find.byType(Checkbox), findsNWidgets(3));
      expect(deletionMode, true);
    });

    testWidgets('checkbox can toggle selection in selection mode', (WidgetTester tester) async {
      await pumpGridView(tester);

      // Enter selection mode
      final inkWells = find.byType(InkWell);
      await tester.longPress(inkWells.first);
      await tester.pumpAndSettle();

      // Should have checkboxes
      expect(find.byType(Checkbox), findsNWidgets(3));

      // Tap checkbox directly
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      // Second checkbox should now be checked
      final secondCheckbox = tester.widget<Checkbox>(checkboxes.at(1));
      expect(secondCheckbox.value, true);
    });

    testWidgets('shows delete FAB in selection mode', (WidgetTester tester) async {
      await pumpGridView(tester);

      // Enter selection mode
      final inkWells = find.byType(InkWell);
      await tester.longPress(inkWells.first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('cancels selection on back button press', (WidgetTester tester) async {
      await pumpGridView(tester);

      // Enter selection mode
      final inkWells = find.byType(InkWell);
      await tester.longPress(inkWells.first);
      await tester.pumpAndSettle();

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      expect(deletionMode, false);
    });

    testWidgets('shows delete confirmation dialog', (WidgetTester tester) async {
      await pumpGridView(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(SupermarketsGridView)))!;

      // Enter selection mode
      final inkWells = find.byType(InkWell);
      await tester.longPress(inkWells.first);
      await tester.pumpAndSettle();

      // Tap delete FAB
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(l10n.deleteSelectedSupermarketsConfirm(1)), findsOneWidget);
      expect(find.text(l10n.deleteLabel), findsOneWidget);
      expect(find.text(l10n.cancelLabel), findsOneWidget);
    });

    testWidgets('cancels delete on dialog cancel', (WidgetTester tester) async {
      await pumpGridView(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(SupermarketsGridView)))!;

      // Enter selection mode
      final inkWells = find.byType(InkWell);
      await tester.longPress(inkWells.first);
      await tester.pumpAndSettle();

      // Tap delete FAB
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Cancel deletion
      await tester.tap(find.text(l10n.cancelLabel));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Walmart'), findsOneWidget);
    });

    testWidgets('exits selection mode after cancel delete', (WidgetTester tester) async {
      await pumpGridView(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(SupermarketsGridView)))!;

      // Enter selection mode
      final inkWells = find.byType(InkWell);
      await tester.longPress(inkWells.first);
      await tester.pumpAndSettle();

      // Tap delete FAB
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Cancel deletion
      await tester.tap(find.text(l10n.cancelLabel));
      await tester.pumpAndSettle();

      // Should still be in selection mode since we cancelled
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(Checkbox), findsNWidgets(3));
    });

    testWidgets('highlights selected items in selection mode', (WidgetTester tester) async {
      await pumpGridView(tester);

      // Enter selection mode
      final inkWells = find.byType(InkWell);
      await tester.longPress(inkWells.first);
      await tester.pumpAndSettle();

      // Find the first card
      final cards = find.byType(Card);
      final firstCard = tester.widget<Card>(cards.first);

      // Should have elevated elevation
      expect(firstCard.elevation, 8);
    });

    testWidgets('non-selected items have normal elevation', (WidgetTester tester) async {
      await pumpGridView(tester);

      // Enter selection mode on first item only
      final inkWells = find.byType(InkWell);
      await tester.longPress(inkWells.first);
      await tester.pumpAndSettle();

      // Second card should have normal elevation
      final cards = find.byType(Card);
      final secondCard = tester.widget<Card>(cards.at(1));

      expect(secondCard.elevation, 2);
    });

    testWidgets('shows checkbox for all items in selection mode', (WidgetTester tester) async {
      await pumpGridView(tester);

      // Enter selection mode
      final inkWells = find.byType(InkWell);
      await tester.longPress(inkWells.first);
      await tester.pumpAndSettle();

      // Should have 3 checkboxes (one per supermarket)
      expect(find.byType(Checkbox), findsNWidgets(3));
    });

    testWidgets('hides trailing buttons in selection mode', (WidgetTester tester) async {
      await pumpGridView(tester);

      // Initially should have edit icons
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(3));

      // Enter selection mode
      final inkWells = find.byType(InkWell);
      await tester.longPress(inkWells.first);
      await tester.pumpAndSettle();

      // Edit icons should still be present but not visible in leading position
      // The Row with edit/favorite buttons is replaced by null in selection mode
      final listTiles = find.byType(ListTile);
      final firstListTile = tester.widget<ListTile>(listTiles.first);
      expect(firstListTile.trailing, null);
    });

    testWidgets('displays empty state with create message', (WidgetTester tester) async {
      await pumpGridView(
        tester,
        supermarkets: [],
        emptyMessage: 'Custom empty message',
      );
      final l10n = AppLocalizations.of(tester.element(find.byType(SupermarketsGridView)))!;

      expect(find.text('Custom empty message'), findsOneWidget);
      expect(find.text(l10n.createFirstSupermarketMessage), findsOneWidget);
    });

    testWidgets('shows FAB in empty state', (WidgetTester tester) async {
      final fab = FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      );

      await pumpGridView(
        tester,
        supermarkets: [],
        floatingActionButton: fab,
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('selection mode displays correct AppBar title', (WidgetTester tester) async {
      await pumpGridView(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(SupermarketsGridView)))!;

      // Enter selection mode
      final inkWells = find.byType(InkWell);
      await tester.longPress(inkWells.first);
      await tester.pumpAndSettle();

      // Should show selected count (starts with 1)
      expect(find.text(l10n.selectedItemsCount(1)), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('calls onDeletionModeChanged callback', (WidgetTester tester) async {
      bool? callbackValue;
      int callbackCount = 0;

      await pumpGridView(
        tester,
        onDeletionModeChanged: (isActive) {
          callbackValue = isActive;
          callbackCount++;
        },
      );

      // Enter selection mode
      final inkWells = find.byType(InkWell);
      await tester.longPress(inkWells.first);
      await tester.pumpAndSettle();

      expect(callbackValue, true);
      expect(callbackCount, 1);

      // Cancel selection
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(callbackValue, false);
      expect(callbackCount, 2);
    });
  });
}
