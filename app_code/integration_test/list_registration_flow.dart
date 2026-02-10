import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/models/user.dart';
import 'package:app_code/providers/real_app_providers/auth/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/nearest-supermarket/map_launcher_service_provider.dart';
import 'package:app_code/providers/real_app_providers/nearest-supermarket/nearest_supermarket_provider.dart';
import 'package:app_code/providers/real_app_providers/supermarket/supermarkets_notifier.dart';
import 'package:app_code/repositories/mock_repo/mock_auth_repository.dart';
import 'package:app_code/screens/home/home_screen.dart';
import 'package:app_code/screens/lists/list_detail_screen_mobile.dart';
import 'package:app_code/screens/lists/register-list/register_shopping_list_screen_mobile.dart';
import 'package:app_code/services/map_launcher_service.dart';
import 'package:app_code/widgets/shopping_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class FakeSupermarketDatabaseManager implements SupermarketDatabaseManager {
  @override
  Future<Supermarket?> getFavoriteSupermarket() async {
    return null;
  }

  @override
  Future<void> setFavoriteSupermarket(String supermarketId) async {}

  @override
  Future<void> clearFavoriteSupermarket(String supermarketId) async {}

  @override
  Future<List<Category>> getSupermarketCategories(String supermarketId) async {
    return [];
  }

  @override
  Future<void> replaceCategoriesOrder(
    String supermarketId,
    List<Category> categories,
  ) async {}
}

class IntegrationTestAuthNotifier extends AuthNotifier {
  IntegrationTestAuthNotifier(this.repository);

  final MockAuthRepository repository;

  @override
  Future<User?> build() async {
    return repository.getCurrentUser();
  }

  @override
  Future<void> ensureAuthenticated() async {
    final user = await repository.ensureAuthenticated();
    state = AsyncData(user);
  }

  @override
  Future<void> signInAnonymously() async {
    final user = await repository.signInAnonymously();
    state = AsyncData(user);
  }

  @override
  Future<void> signUp(String email, String password) async {
    final user = await repository.signUp(email, password);
    state = AsyncData(user);
  }

  @override
  Future<void> signIn(String email, String password) async {
    final user = await repository.signIn(email, password);
    state = AsyncData(user);
  }

  @override
  Future<void> signOut() async {
    await repository.signOut();
    state = AsyncData(repository.getCurrentUser());
  }
}

class TestNearestSupermarketNotifier extends NearestSupermarketNotifier {
  @override
  NearestSupermarketState build() {
    return const NearestSupermarketState(
      isLoading: false,
      errorType: null,
    );
  }
}

class TestSupermarketsNotifier extends SupermarketsNotifier {
  @override
  Future<List<Supermarket>> build() async {
    return [];
  }
}

class FakeMapLauncherService extends MapLauncherService {
  @override
  Future<bool> openMap({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    return false;
  }

  @override
  Future<bool> openDirections({
    required double destinationLat,
    required double destinationLon,
    String? destinationLabel,
  }) async {
    return false;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'register list persists price and quantity after reopen',
    (tester) async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final listName = 'Register List $timestamp';
      final productName = 'Tomatoes $timestamp';
      const quantityValue = '2';
      const priceValue = '3.50';

      final authRepository = MockAuthRepository();

      Widget buildTestApp() {
        return ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepository),
            authProvider.overrideWith(
              () => IntegrationTestAuthNotifier(authRepository),
            ),
            nearestSupermarketProvider.overrideWith(
              () => TestNearestSupermarketNotifier(),
            ),
            mapLauncherServiceProvider.overrideWithValue(
              FakeMapLauncherService(),
            ),
            supermarketsProvider.overrideWith(
              () => TestSupermarketsNotifier(),
            ),
            supermarketDatabaseManagerProvider.overrideWithValue(
              FakeSupermarketDatabaseManager(),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            initialRoute: '/home',
            routes: {
              '/home': (context) => const HomeScreenMobileView(),
            },
          ),
        );
      }

      Finder checkboxForProduct(String name) {
        final productText = find.text(name);
        final tile =
            find.ancestor(of: productText, matching: find.byType(ListTile));
        return find.descendant(of: tile, matching: find.byType(Checkbox));
      }

      Finder registerProductTile(String name) {
        final productText = find.text(name);
        return find.ancestor(
          of: productText,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.margin == const EdgeInsets.only(bottom: 12.0),
          ),
        );
      }

      Finder quantityFieldForProduct(String name) {
        final tile = registerProductTile(name);
        return find.descendant(of: tile, matching: find.byType(TextField)).at(0);
      }

      Finder priceFieldForProduct(String name) {
        final tile = registerProductTile(name);
        return find.descendant(of: tile, matching: find.byType(TextField)).at(1);
      }

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final addListFab = find.byWidgetPredicate(
        (widget) =>
            widget is FloatingActionButton &&
            widget.heroTag == 'addShoppingListFAB_mobile_view',
      );
      expect(addListFab, findsOneWidget);
      await tester.tap(addListFab);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, listName);
      final homeL10n =
          AppLocalizations.of(tester.element(find.byType(HomeScreenMobileView)))!;
      await tester.tap(find.text(homeL10n.addLabel));
      await tester.pumpAndSettle();

      final detailL10n = AppLocalizations.of(
        tester.element(find.byType(ListDetailScreenMobile)),
      )!;
      final productField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == detailL10n.addProductHint,
      );
      expect(productField, findsOneWidget);
      await tester.enterText(productField, productName);
      await tester.tap(find.byTooltip(detailL10n.addProductTooltip));
      await tester.pumpAndSettle();

      await tester.tap(checkboxForProduct(productName));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(detailL10n.registerListTooltip));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterShoppingListScreenMobile), findsOneWidget);
      await tester.enterText(quantityFieldForProduct(productName), quantityValue);
      await tester.enterText(priceFieldForProduct(productName), priceValue);
      await tester.pumpAndSettle();

      final registerL10n = AppLocalizations.of(
        tester.element(find.byType(RegisterShoppingListScreenMobile)),
      )!;
      await tester.tap(find.byTooltip(registerL10n.registerListTooltip));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final reopenedL10n =
          AppLocalizations.of(tester.element(find.byType(HomeScreenMobileView)))!;
      await tester.tap(find.text(reopenedL10n.historyTabLabel));
      await tester.pumpAndSettle();

      final listCard = find.byWidgetPredicate(
        (widget) =>
            widget is ShoppingListCard &&
            widget.shoppingList.getName() == listName,
      );
      expect(listCard, findsOneWidget);
      final cardInkWell = find.descendant(
        of: listCard,
        matching: find.byWidgetPredicate(
          (widget) => widget is InkWell && widget.child is ClipRRect,
        ),
      );
      expect(cardInkWell, findsOneWidget);
      await tester.tap(cardInkWell);
      await tester.pumpAndSettle();

      final quantityField = quantityFieldForProduct(productName);
      final priceField = priceFieldForProduct(productName);
      final TextField quantityWidget = tester.widget(quantityField);
      final TextField priceWidget = tester.widget(priceField);

      expect(quantityWidget.controller?.text, quantityValue);
      expect(priceWidget.controller?.text, priceValue);
    },
  );
}
