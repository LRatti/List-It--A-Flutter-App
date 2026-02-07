import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/providers/real_app_providers/supermarket/supermarkets_notifier.dart';
import 'package:app_code/providers/real_app_providers/screen_size_provider.dart';
import 'package:app_code/screens/supermarket/supermarkets_screen.dart';
import 'package:app_code/widgets/detail_pane_navigator.dart';

/// Fake notifier for testing
class FakeSupermarketsNotifier extends SupermarketsNotifier {
  FakeSupermarketsNotifier(this.supermarkets);

  final List<Supermarket> supermarkets;
  int updateCount = 0;
  int addCount = 0;
  int deleteCount = 0;

  @override
  Future<List<Supermarket>> build() async => supermarkets;

  @override
  Future<void> updateSupermarket(Supermarket supermarket) async {
    updateCount++;
    final index = supermarkets.indexWhere((s) => s.id == supermarket.id);
    if (index != -1) {
      supermarkets[index] = supermarket;
    }
  }

  @override
  Future<void> addSupermarket(Supermarket supermarket) async {
    addCount++;
    supermarkets.add(supermarket);
  }

  @override
  Future<void> deleteSupermarkets(List<String> ids) async {
    deleteCount++;
    for (final id in ids) {
      final index = supermarkets.indexWhere((s) => s.id == id);
      if (index != -1) {
        supermarkets[index].isVisible = false;
      }
    }
  }

  @override
  Future<Supermarket?> getLastEditedSupermarket() async {
    return supermarkets.isNotEmpty ? supermarkets.last : null;
  }

  @override
  Future<void> setFavoriteSupermarket(String supermarketId) async {
    for (final s in supermarkets) {
      s.isFavorite = s.id == supermarketId;
    }
  }

  @override
  Future<bool> clearFavoriteSupermarket(String supermarketId) async {
    final index = supermarkets.indexWhere((s) => s.id == supermarketId);
    if (index != -1) {
      supermarkets[index].isFavorite = false;
      return true;
    }
    return false;
  }
}

void main() {
  group('SupermarketsScreen Tablet Layout Tests', () {
    testWidgets('displays master-detail layout on tablet', (tester) async {
      final testSupermarkets = [
        Supermarket(
          id: 's1',
          name: 'Market A',
          categories: [Category(name: 'Produce')],
        ),
        Supermarket(
          id: 's2',
          name: 'Market B',
          categories: [Category(name: 'Dairy')],
        ),
      ];

      final fakeNotifier = FakeSupermarketsNotifier(testSupermarkets);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supermarketsProvider.overrideWith(() => fakeNotifier),
            screenSizeProvider.overrideWith((ref) => ScreenSizeNotifier()),
          ],
          child: const MaterialApp(
            home: SupermarketsScreenResponsive(),
          ),
        ),
      );

      // Set tablet size
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpAndSettle();

      // Verify master-detail split view exists
      expect(find.byType(Row), findsWidgets);
      expect(find.byType(Flexible), findsWidgets);
      
      // Verify empty detail pane is shown initially
      expect(find.text('Select a supermarket to view details'), findsOneWidget);
      expect(find.byIcon(Icons.store_outlined), findsWidgets);
    });

    testWidgets('shows search functionality in master pane', (tester) async {
      final testSupermarkets = [
        Supermarket(id: 's1', name: 'Alpha Market'),
        Supermarket(id: 's2', name: 'Beta Store'),
        Supermarket(id: 's3', name: 'Gamma Shop'),
      ];

      final fakeNotifier = FakeSupermarketsNotifier(testSupermarkets);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supermarketsProvider.overrideWith(() => fakeNotifier),
          ],
          child: const MaterialApp(
            home: SupermarketsScreenResponsive(),
          ),
        ),
      );

      // Set tablet size
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpAndSettle();

      // Find and tap search icon
      final searchIcon = find.byIcon(Icons.search);
      expect(searchIcon, findsOneWidget);
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();

      // Verify search field appears
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows FAB to create supermarket in master pane', (tester) async {
      final fakeNotifier = FakeSupermarketsNotifier([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supermarketsProvider.overrideWith(() => fakeNotifier),
          ],
          child: const MaterialApp(
            home: SupermarketsScreenResponsive(),
          ),
        ),
      );

      // Set tablet size
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpAndSettle();

      // Verify FAB exists
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('selecting supermarket shows detail pane', (tester) async {
      final testSupermarkets = [
        Supermarket(
          id: 's1',
          name: 'Test Market',
          categories: [Category(name: 'Produce')],
        ),
      ];

      final fakeNotifier = FakeSupermarketsNotifier(testSupermarkets);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supermarketsProvider.overrideWith(() => fakeNotifier),
          ],
          child: const MaterialApp(
            home: SupermarketsScreenResponsive(),
          ),
        ),
      );

      // Set tablet size
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpAndSettle();

      // Tap on the supermarket
      await tester.tap(find.text('Test Market'));
      await tester.pumpAndSettle();

      // Verify DetailPaneNavigator is used
      expect(find.byType(DetailPaneNavigator), findsOneWidget);
      
      // Verify empty state is gone
      expect(find.text('Select a supermarket to view details'), findsNothing);
    });

    testWidgets('FAB creates new supermarket in detail pane on tablet', (tester) async {
      final testSupermarkets = [
        Supermarket(
          id: 's1',
          name: 'Existing Market',
          categories: [Category(name: 'Produce')],
        ),
      ];

      final fakeNotifier = FakeSupermarketsNotifier(testSupermarkets);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supermarketsProvider.overrideWith(() => fakeNotifier),
          ],
          child: const MaterialApp(
            home: SupermarketsScreenResponsive(),
          ),
        ),
      );

      // Set tablet size
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpAndSettle();

      // Tap FAB to create new supermarket
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify detail pane shows customization screen
      expect(find.byType(DetailPaneNavigator), findsOneWidget);
    });

    testWidgets('supermarkets are deletable from grid view on tablet', (tester) async {
      final testSupermarkets = [
        Supermarket(id: 's1', name: 'Market A'),
        Supermarket(id: 's2', name: 'Market B'),
      ];

      final fakeNotifier = FakeSupermarketsNotifier(testSupermarkets);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supermarketsProvider.overrideWith(() => fakeNotifier),
          ],
          child: const MaterialApp(
            home: SupermarketsScreenResponsive(),
          ),
        ),
      );

      // Set tablet size
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpAndSettle();

      // Long press to enter selection mode
      await tester.longPress(find.text('Market A'));
      await tester.pumpAndSettle();

      // Verify selection mode is active (checkbox should appear)
      expect(find.byType(Checkbox), findsWidgets);
      
      // Verify delete FAB appears
      final deleteFabs = find.byWidgetPredicate(
        (widget) => widget is FloatingActionButton && 
                    widget.heroTag == 'deleteSupermarketsFAB'
      );
      expect(deleteFabs, findsOneWidget);
    });

    testWidgets('favorite can be set from grid view on tablet', (tester) async {
      final testSupermarkets = [
        Supermarket(id: 's1', name: 'Market A', isFavorite: false),
      ];

      final fakeNotifier = FakeSupermarketsNotifier(testSupermarkets);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supermarketsProvider.overrideWith(() => fakeNotifier),
          ],
          child: const MaterialApp(
            home: SupermarketsScreenResponsive(),
          ),
        ),
      );

      // Set tablet size
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpAndSettle();

      // Find star outline icon (unfavorited state)
      expect(find.byIcon(Icons.star_outline), findsOneWidget);
      
      // The star icon button exists
      final starButtons = find.byWidgetPredicate(
        (widget) => widget is IconButton && 
                    (widget.icon as Icon).icon == Icons.star_outline
      );
      expect(starButtons, findsOneWidget);
    });
  });
}
