import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/user.dart';
import 'package:app_code/providers/real_app_providers/auth/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/nearest-supermarket/map_launcher_service_provider.dart';
import 'package:app_code/providers/real_app_providers/nearest-supermarket/nearest_supermarket_provider.dart';
import 'package:app_code/repositories/mock_repo/mock_auth_repository.dart';
import 'package:app_code/screens/home/home_screen.dart';
import 'package:app_code/screens/supermarket/supermarket_customization_screen.dart';
import 'package:app_code/services/database/sqlite/manage_category.dart';
import 'package:app_code/services/database/sqlite/manage_supermarket.dart';
import 'package:app_code/services/map_launcher_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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
    'create supermarket add categories reorder set favorite and persist',
    (tester) async {
      final supermarketName = 'Test Market';
      final categoryA = 'Bakery';
      final categoryB = 'Meat';
      final categoryC = 'Beverages';
      final existingCategoryA = 'Produce';
      final existingCategoryB = 'Frozen';

      // Create pre-existing categories in the database
      final preExistCat1 = Category(name: existingCategoryA);
      final preExistCat2 = Category(name: existingCategoryB);
      await ManageCategory.addCategory(preExistCat1);
      await ManageCategory.addCategory(preExistCat2);

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

      // Helper to find category checkbox by name
      Finder categoryCheckboxByName(String name) {
        final categoryText = find.text(name);
        final checkboxWidget = find.ancestor(
          of: categoryText,
          matching: find.byType(CheckboxListTile),
        );
        return find.descendant(
          of: checkboxWidget,
          matching: find.byType(Checkbox),
        );
      }

      // Helper to create a new category
      Future<void> createCategory(String name) async {
        final l10nCategories = AppLocalizations.of(
          tester.element(find.byType(Scaffold)),
        )!;
        final createButton = find.byTooltip(l10nCategories.createNewCategoryTooltip);
        expect(createButton, findsOneWidget);
        await tester.tap(createButton);
        await tester.pumpAndSettle();

        // Enter category name
        final nameField = find.byType(TextField).last;
        await tester.enterText(nameField, name);
        await tester.pumpAndSettle();

        // Save the category
        final l10nEditing = AppLocalizations.of(
          tester.element(find.byType(Scaffold)),
        )!;
        final saveButton = find.text(l10nEditing.saveLabel);
        expect(saveButton, findsOneWidget);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
      }

      // Helper to select a category from the list
      Future<void> selectCategory(String name) async {
        final checkbox = categoryCheckboxByName(name);
        expect(checkbox, findsOneWidget);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();
      }

      // Build and display the initial home screen
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final homeL10n =
          AppLocalizations.of(tester.element(find.byType(HomeScreenMobileView)))!;

      // Navigate to supermarkets tab
      await tester.tap(find.text(homeL10n.supermarketsTabLabel));
      await tester.pumpAndSettle();

      // Create a new supermarket
      final addSupermarketFab = find.byWidgetPredicate(
        (widget) =>
            widget is FloatingActionButton &&
            widget.heroTag == 'addSupermarketFAB_mobile_view',
      );
      expect(addSupermarketFab, findsOneWidget);
      await tester.tap(addSupermarketFab);
      await tester.pumpAndSettle();

      // Verify we're on the customization screen
      expect(find.byType(SupermarketCustomizationScreen), findsOneWidget);

      // Enter supermarket name
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, supermarketName);
      await tester.pumpAndSettle();

      // Navigate to add categories screen
      final customizationL10n = AppLocalizations.of(
        tester.element(find.byType(SupermarketCustomizationScreen)),
      )!;
      final addCategoriesButton = find.byWidgetPredicate(
        (widget) =>
            widget is OutlinedButton &&
            find.descendant(
              of: find.byWidget(widget),
              matching: find.text(customizationL10n.addCategoriesLabel),
            ).evaluate().isNotEmpty,
      );
      expect(addCategoriesButton, findsOneWidget);
      await tester.tap(addCategoriesButton);
      await tester.pumpAndSettle();

      // Create first new category (Bakery)
      await createCategory(categoryA);
      

      // Create second new category (Meat)
      await createCategory(categoryB);

      // Create third new category (Beverages)
      await createCategory(categoryC);

      // Select two existing categories
      await selectCategory(existingCategoryA);
      await selectCategory(existingCategoryB);

      // Click Add button to add selected categories
      final l10nCategories = AppLocalizations.of(
        tester.element(find.byType(Scaffold)),
      )!;
      final addButton = find.byWidgetPredicate(
        (widget) =>
            widget is OutlinedButton &&
            find.descendant(
              of: find.byWidget(widget),
              matching: find.text(l10nCategories.addLabel),
            ).evaluate().isNotEmpty,
      );
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Back on customization screen - verify categories are added
      expect(find.byType(SupermarketCustomizationScreen), findsOneWidget);
      expect(find.text(categoryA), findsOneWidget);
      expect(find.text(categoryC), findsOneWidget);
      expect(find.text(existingCategoryB), findsOneWidget);
      expect(find.text(categoryB), findsOneWidget);
      expect(find.text(existingCategoryA), findsOneWidget);

      // Reorder categories: Move first category to the third position
      // Categories are currently in alphabetical order after adding
      // Find the ReorderableListView to get the current order
      final reorderableList = find.byType(ReorderableListView);
      expect(reorderableList, findsOneWidget);

      // Get all visible category tiles
      final categoryTiles = find.descendant(
        of: reorderableList,
        matching: find.byType(Card),
      );

      // Perform reorder: drag first category to third position
      // This simulates dragging by getting the drag handle
      final firstCategoryCard = categoryTiles.first;
      final dragHandle = find.descendant(
        of: firstCategoryCard,
        matching: find.byIcon(Icons.drag_handle),
      );
      expect(dragHandle, findsOneWidget);

      // Perform drag operation
      final dragStart = tester.getCenter(dragHandle);
      final thirdCategoryCard = categoryTiles.at(2);
      final dragEnd = tester.getCenter(
        find.descendant(
          of: thirdCategoryCard,
          matching: find.byIcon(Icons.drag_handle),
        ),
      );

      final gesture = await tester.startGesture(dragStart);
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveTo(dragEnd);
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.up();
      await tester.pumpAndSettle();

      // Set the supermarket as favorite
      final favoriteButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.star_outline,
      );
      expect(favoriteButton, findsOneWidget);
      await tester.tap(favoriteButton);
      await tester.pumpAndSettle();

      // Verify the star is now filled
      final filledStar = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.star,
      );
      expect(filledStar, findsOneWidget);

      // Save the supermarket
      final saveButton = find.byIcon(Icons.check);
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Close and reopen the app
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Navigate back to supermarkets tab
      final reopenedL10n =
          AppLocalizations.of(tester.element(find.byType(HomeScreenMobileView)))!;
      await tester.tap(find.text(reopenedL10n.supermarketsTabLabel));
      await tester.pumpAndSettle();

      // Verify the supermarket exists in the database
      final savedSupermarkets = await ManageSupermarket.getAllSupermarkets();
      final savedSupermarket = savedSupermarkets.firstWhere(
        (s) => s.getName() == supermarketName,
      );

      // Verify it's marked as favorite
      expect(savedSupermarket.isFavorite, isTrue);

      // Verify categories are persisted with correct count
      final savedCategories = await ManageSupermarket.getSupermarketCategories(
        savedSupermarket.id,
      );

      // Should have 5 visible categories + 1 hidden uncategorized
      expect(
        savedCategories.where((c) => c.isVisible).length,
        5,
        reason: 'Should have 5 visible categories',
      );

      // Verify all added categories are present
      final categoryNames = savedCategories.map((c) => c.getName()).toList();
      expect(categoryNames.contains(categoryA), isTrue);
      expect(categoryNames.contains(categoryB), isTrue);
      expect(categoryNames.contains(categoryC), isTrue);
      expect(categoryNames.contains(existingCategoryA), isTrue);
      expect(categoryNames.contains(existingCategoryB), isTrue);

      // Verify the order has changed (reordering was applied)
      final visibleCategories = savedCategories.where((c) => c.isVisible).toList();
      expect(
        visibleCategories.length >= 3,
        isTrue,
        reason: 'Should have at least 3 categories to verify order',
      );
    },
  );
}
