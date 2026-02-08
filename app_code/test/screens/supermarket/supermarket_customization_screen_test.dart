import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/providers/real_app_providers/supermarket/supermarkets_notifier.dart';
import 'package:app_code/screens/supermarket/supermarket_customization_screen.dart';
import 'package:app_code/l10n/app_localizations.dart';

class FakeSupermarketsNotifier extends SupermarketsNotifier {
  FakeSupermarketsNotifier(this.supermarkets);

  final List<Supermarket> supermarkets;
  int updateCount = 0;
  int setFavoriteCount = 0;
  int clearFavoriteCount = 0;
  int addCount = 0;
  int deleteCount = 0;
  String? lastDeletedId;

  @override
  Future<List<Supermarket>> build() async => supermarkets;

  @override
  Future<void> updateSupermarket(Supermarket supermarket) async {
    updateCount++;
  }

  @override
  Future<void> setFavoriteSupermarket(String supermarketId) async {
    setFavoriteCount++;
  }

  @override
  Future<bool> clearFavoriteSupermarket(String supermarketId) async {
    clearFavoriteCount++;
    return true;
  }

  @override
  Future<void> addSupermarket(Supermarket supermarket) async {
    addCount++;
  }

  @override
  Future<void> deleteSupermarket(String id) async {
    deleteCount++;
    lastDeletedId = id;
  }
}

void main() {
  group('SupermarketCustomizationScreen - Widget Tests', () {
    late FakeSupermarketsNotifier fakeNotifier;

    Future<void> pumpScreen(
      WidgetTester tester, {
      required Supermarket supermarket,
      bool isCreationMode = false,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supermarketsProvider.overrideWith(() => fakeNotifier),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: SupermarketCustomizationScreen(
              supermarket: supermarket,
              isCreationMode: isCreationMode,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() {
      fakeNotifier = FakeSupermarketsNotifier([]);
    });

    testWidgets('renders with supermarket name in creation mode',
        (tester) async {
      final supermarket = Supermarket(id: 's1', name: 'Test Market');
      await pumpScreen(tester, supermarket: supermarket, isCreationMode: true);

      expect(find.byType(SupermarketCustomizationScreen), findsOneWidget);
      expect(find.text('Test Market'), findsWidgets);
    });

    testWidgets('displays empty state when no categories', (tester) async {
      final supermarket = Supermarket(id: 's1', name: 'Market');
      await pumpScreen(tester, supermarket: supermarket);

      expect(find.byIcon(Icons.category_outlined), findsOneWidget);
    });

    testWidgets('displays categories in list when present', (tester) async {
      final categories = [
        Category(id: 'c1', name: 'Fruits'),
        Category(id: 'c2', name: 'Vegetables'),
      ];
      final supermarket =
          Supermarket(id: 's1', name: 'Market', categories: categories);
      await pumpScreen(tester, supermarket: supermarket);

      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('updates supermarket name in text field', (tester) async {
      final supermarket = Supermarket(id: 's1', name: 'Old Name');
      await pumpScreen(tester, supermarket: supermarket);

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'New Name');
      await tester.pumpAndSettle();

      expect(find.text('New Name'), findsOneWidget);
    });

    testWidgets('toggles favorite star icon', (tester) async {
      final supermarket = Supermarket(id: 's1', name: 'Market');
      await pumpScreen(tester, supermarket: supermarket);

      // Initially should be outline (not favorite)
      expect(find.byIcon(Icons.star_outline), findsOneWidget);

      // Tap to toggle favorite
      await tester.tap(find.byIcon(Icons.star_outline));
      await tester.pumpAndSettle();

      // Should now be filled star
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('favorite state persists when toggled', (tester) async {
      final supermarket = Supermarket(id: 's1', name: 'Market', isFavorite: false);
      await pumpScreen(tester, supermarket: supermarket, isCreationMode: false);

      // Initially outline
      expect(find.byIcon(Icons.star_outline), findsOneWidget);

      // Toggle to favorite
      await tester.tap(find.byIcon(Icons.star_outline));
      await tester.pumpAndSettle();

      // Should now be star
      expect(find.byIcon(Icons.star), findsOneWidget);

      // Toggle again
      await tester.tap(find.byIcon(Icons.star));
      await tester.pumpAndSettle();

      // Back to outline
      expect(find.byIcon(Icons.star_outline), findsOneWidget);
    });

    testWidgets('cancels without saving in creation mode', (tester) async {
      final supermarket = Supermarket(id: 's1', name: 'Market');
      await pumpScreen(tester, supermarket: supermarket, isCreationMode: true);

      // Tap delete/cancel button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(fakeNotifier.addCount, 0);
    });

    testWidgets('shows delete confirmation in edit mode', (tester) async {
      final supermarket = Supermarket(id: 's1', name: 'Market');
      fakeNotifier = FakeSupermarketsNotifier([supermarket]);
      await pumpScreen(tester, supermarket: supermarket, isCreationMode: false);

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('deletes supermarket after confirmation', (tester) async {
      final supermarket = Supermarket(id: 's1', name: 'Market');
      fakeNotifier = FakeSupermarketsNotifier([supermarket]);
      await pumpScreen(tester, supermarket: supermarket, isCreationMode: false);

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Confirm delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(fakeNotifier.deleteCount, 1);
      expect(fakeNotifier.lastDeletedId, 's1');
    });

    testWidgets('cancels delete operation', (tester) async {
      final supermarket = Supermarket(id: 's1', name: 'Market');
      fakeNotifier = FakeSupermarketsNotifier([supermarket]);
      await pumpScreen(tester, supermarket: supermarket, isCreationMode: false);

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Cancel delete
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(fakeNotifier.deleteCount, 0);
    });

    testWidgets('deletes category from list', (tester) async {
      final categories = [
        Category(id: 'c1', name: 'Fruits'),
        Category(id: 'c2', name: 'Vegetables'),
      ];
      final supermarket = Supermarket(
        id: 's1',
        name: 'Market',
        categories: categories,
      );
      await pumpScreen(tester, supermarket: supermarket);

      // Find and tap delete for first category
      final deleteButtons = find.byIcon(Icons.remove_circle_outline);
      expect(deleteButtons, findsWidgets);

      final initialCards = find.byType(Card);
      final cardCount = tester.widgetList(initialCards).length;

      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      final newCards = find.byType(Card);
      final newCardCount = tester.widgetList(newCards).length;

      expect(newCardCount, cardCount - 1);
    });

    testWidgets('displays add categories button', (tester) async {
      final supermarket = Supermarket(id: 's1', name: 'Market');
      await pumpScreen(tester, supermarket: supermarket);

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text('Add Categories'), findsOneWidget);
    });

    testWidgets('displays favorite button', (tester) async {
      final supermarket = Supermarket(id: 's1', name: 'Market');
      await pumpScreen(tester, supermarket: supermarket);

      final starButtons = find.byIcon(Icons.star_outline);
      expect(starButtons, findsWidgets);
    });

    testWidgets('displays app bar with correct title in creation mode',
        (tester) async {
      final supermarket = Supermarket(id: 's1', name: 'Market');
      await pumpScreen(tester, supermarket: supermarket, isCreationMode: true);

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('displays app bar with correct title in edit mode', (tester) async {
      final supermarket = Supermarket(id: 's1', name: 'Market');
      await pumpScreen(tester, supermarket: supermarket, isCreationMode: false);

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('category tile shows edit and drag handle', (tester) async {
      final categories = [Category(id: 'c1', name: 'Fruits')];
      final supermarket = Supermarket(
        id: 's1',
        name: 'Market',
        categories: categories,
      );
      await pumpScreen(tester, supermarket: supermarket);

      // Find edit button in the trailing section
      final editButtons = find.byIcon(Icons.edit_outlined);
      expect(editButtons, findsWidgets);

      final dragHandles = find.byIcon(Icons.drag_handle);
      expect(dragHandles, findsWidgets);
    });

    testWidgets('category tile is tappable for editing', (tester) async {
      final categories = [Category(id: 'c1', name: 'Fruits')];
      final supermarket = Supermarket(
        id: 's1',
        name: 'Market',
        categories: categories,
      );
      await pumpScreen(tester, supermarket: supermarket);

      final cards = find.byType(Card);
      expect(cards, findsOneWidget);

      // Card should be tappable (has ListTile)
      final listTiles = find.byType(ListTile);
      expect(listTiles, findsWidgets);
    });

    testWidgets('displays text field with supermarket name', (tester) async {
      final supermarket = Supermarket(id: 's1', name: 'My Supermarket');
      await pumpScreen(tester, supermarket: supermarket);

      final textField = find.byType(TextField).first;
      expect(textField, findsOneWidget);

      // Find the TextField widget and check its controller value
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.controller?.text, 'My Supermarket');
    });

    testWidgets('action buttons are present in bottom row', (tester) async {
      final supermarket = Supermarket(id: 's1', name: 'Market');
      await pumpScreen(tester, supermarket: supermarket);

      // Delete/Cancel button
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      // Add Categories button
      expect(find.byType(OutlinedButton), findsOneWidget);

      // Favorite button
      expect(find.byIcon(Icons.star_outline), findsWidgets);
    });

    testWidgets('back button navigates without saving', (tester) async {
      final supermarket = Supermarket(id: 's1', name: 'Market');
      await pumpScreen(tester, supermarket: supermarket);

      // Change name
      await tester.enterText(find.byType(TextField), 'Changed Name');
      await tester.pumpAndSettle();

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should not have updated
      expect(fakeNotifier.updateCount, 0);
    });

    testWidgets('initially displays correct favorite state', (tester) async {
      final favoriteMarket = Supermarket(
        id: 's1',
        name: 'Favorite Market',
        isFavorite: true,
      );
      await pumpScreen(tester, supermarket: favoriteMarket);

      // Should show filled star
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('initially displays correct non-favorite state', (tester) async {
      final nonFavoriteMarket = Supermarket(
        id: 's1',
        name: 'Regular Market',
        isFavorite: false,
      );
      await pumpScreen(tester, supermarket: nonFavoriteMarket);

      // Should show outline star
      expect(find.byIcon(Icons.star_outline), findsOneWidget);
    });

    testWidgets('hidden categories are not displayed', (tester) async {
      final visibleCategory = Category(id: 'c1', name: 'Fruits', isVisible: true);
      final hiddenCategory = Category(id: 'c2', name: 'Hidden', isVisible: false);

      final supermarket = Supermarket(
        id: 's1',
        name: 'Market',
        categories: [visibleCategory, hiddenCategory],
      );
      await pumpScreen(tester, supermarket: supermarket);

      // Should only display visible category
      final cards = find.byType(Card);
      expect(cards, findsOneWidget);
    });
  });
}

