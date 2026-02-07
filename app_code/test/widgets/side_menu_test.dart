import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/repositories/mock_repo/mock_shopping_list_repository.dart';
import 'package:app_code/widgets/side_menu.dart';
import 'package:app_code/screens/trash/trash_screen_mobile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_code/l10n/app_localizations.dart';

class _TestNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount++;
    super.didPush(route, previousRoute);
  }
}

void main() {
  group('SideMenu', () {
    Future<void> pumpMenu(
      WidgetTester tester, {
      required VoidCallback onClose,
      List<ShoppingList> lists = const [],
      _TestNavigatorObserver? observer,
    }) async {
      final mockRepo = MockShoppingListRepository();
      for (final list in lists) {
        await mockRepo.add(list);
      }

      final container = ProviderContainer(
        overrides: [
          shoppingListRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      container.read(shoppingListsProvider.notifier).state =
          AsyncValue.data(lists);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            navigatorObservers: observer != null ? [observer] : const [],
            home: Scaffold(
              body: SideMenu(onClose: onClose),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders all menu entries', (tester) async {
      await pumpMenu(tester, onClose: () {});
      final l10n = AppLocalizations.of(tester.element(find.byType(SideMenu)))!;

      expect(find.text(l10n.menuLabel), findsOneWidget);
      expect(find.text(l10n.profileLabel), findsOneWidget);
      expect(find.text(l10n.settingsTitle), findsOneWidget);
      expect(find.text(l10n.trashLabel), findsOneWidget);
    });

    testWidgets('close button triggers onClose', (tester) async {
      var closed = false;

      await pumpMenu(tester, onClose: () => closed = true);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets('tapping Trash closes menu and navigates', (tester) async {
      var closed = false;
      final observer = _TestNavigatorObserver();

      await pumpMenu(
        tester,
        onClose: () => closed = true,
        lists: [
          ShoppingList(
            id: 't1',
            name: 'Trashed',
            createdAt: DateTime(2024, 1, 1),
            isInTheTrash: true,
          ),
        ],
        observer: observer,
      );

      final l10n = AppLocalizations.of(tester.element(find.byType(SideMenu)))!;
      await tester.tap(find.text(l10n.trashLabel));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(observer.pushCount, greaterThanOrEqualTo(1));
      expect(find.byType(TrashScreenMobile), findsOneWidget);
    });
  });
}
