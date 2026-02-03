import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/providers/real_app_providers/supermarket/supermarkets_notifier.dart';
import 'package:app_code/screens/supermarket/supermarkets_screen_mobile.dart';
import 'package:app_code/screens/supermarket/supermarket_customization_screen.dart';

class FakeSupermarketsNotifier extends SupermarketsNotifier {
  FakeSupermarketsNotifier(this.supermarkets);

  final List<Supermarket> supermarkets;
  int updateCount = 0;
  int setFavoriteCount = 0;
  int clearFavoriteCount = 0;
  int addCount = 0;

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
  Future<void> clearFavoriteSupermarket(String supermarketId) async {
    clearFavoriteCount++;
  }

  @override
  Future<void> addSupermarket(Supermarket supermarket) async {
    addCount++;
  }
}

void main() {
  group('Favorite supermarket behavior', () {
    testWidgets('favorite supermarket appears first in list', (tester) async {
      final testSupermarkets = [
        Supermarket(id: 'a', name: 'Alpha'),
        Supermarket(id: 'b', name: 'Bravo', isFavorite: true),
        Supermarket(id: 'c', name: 'Charlie'),
      ];

      final fakeNotifier = FakeSupermarketsNotifier(testSupermarkets);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supermarketsProvider.overrideWith(() => fakeNotifier),
          ],
          child: const MaterialApp(
            home: SupermarketsScreenMobile(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect(tiles, isNotEmpty);

      final firstTitle = tiles.first.title as Text;
      expect(firstTitle.data, 'Bravo');
    });

    testWidgets('favorite toggle persists only on save', (tester) async {
      final supermarket = Supermarket(id: 's1', name: 'My Market');
      final fakeNotifier = FakeSupermarketsNotifier([supermarket]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supermarketsProvider.overrideWith(() => fakeNotifier),
          ],
          child: MaterialApp(
            home: SupermarketCustomizationScreen(
              supermarket: supermarket,
              isCreationMode: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Toggle favorite locally
      await tester.tap(find.byIcon(Icons.star_outline));
      await tester.pumpAndSettle();

      // Navigate back without saving
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(fakeNotifier.updateCount, 0);
      expect(fakeNotifier.setFavoriteCount, 0);
      expect(fakeNotifier.clearFavoriteCount, 0);
    });

    testWidgets('check button persists favorite change', (tester) async {
      final supermarket = Supermarket(id: 's1', name: 'My Market');
      final fakeNotifier = FakeSupermarketsNotifier([supermarket]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supermarketsProvider.overrideWith(() => fakeNotifier),
          ],
          child: MaterialApp(
            home: SupermarketCustomizationScreen(
              supermarket: supermarket,
              isCreationMode: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Toggle favorite locally
      await tester.tap(find.byIcon(Icons.star_outline));
      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(fakeNotifier.updateCount, 1);
      expect(fakeNotifier.setFavoriteCount, 1);
      expect(fakeNotifier.clearFavoriteCount, 0);
    });
  });
}
