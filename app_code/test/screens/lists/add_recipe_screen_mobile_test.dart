import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_code/screens/lists/add_recipe_screen_mobile.dart';
import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/recipe_response.dart';
import 'package:app_code/providers/real_app_providers/recipe/recipe_provider.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/repositories/mock_repo/mock_recipe_cache_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_gemini_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_shopping_list_repository.dart';

/// ------------------------------------------------------------
/// TEST UTILITIES
/// ------------------------------------------------------------

ShoppingList createShoppingList() {
  return ShoppingList(
    id: 'list-1',
    name: 'My List',
    createdAt: DateTime.now(),
    products: <PurchasedProduct>[],
  );
}

List<Category> createCategories() {
  return [
    Category(name: 'Vegetables'),
    Category(name: 'Meat'),
  ];
}

BackgroundRecipeSearch createSearch({
  required String listId,
  required AsyncValue<RecipeData> result,
  String recipeName = '',
  bool isCompleted = true,
}) {
  return BackgroundRecipeSearch(
    listId: listId,
    recipeName: recipeName,
    result: result,
    isCompleted: isCompleted,
  );
}

/// ------------------------------------------------------------
/// (Removed fake notifiers) We'll override providers with real
/// notifiers backed by in-memory mock repositories.
/// ------------------------------------------------------------

/// ------------------------------------------------------------
/// WIDGET WRAPPER
/// ------------------------------------------------------------

Widget createTestWidget({
  required ShoppingList list,
  required List<Category> categories,
  Map<String, BackgroundRecipeSearch>? backgroundSearches,
}) {
  return ProviderScope(
    overrides: [
      // Use in-memory repositories
      geminiRepositoryProvider.overrideWith((ref) => MockGeminiRepository()),
      recipeCacheRepositoryProvider.overrideWith((ref) => MockRecipeCacheRepository()),
      shoppingListRepositoryProvider.overrideWith((ref) => MockShoppingListRepository()),
      // Seed background search state if provided
      backgroundRecipeProvider.overrideWith((ref) {
        final notifier = BackgroundRecipeNotifier(
          ref.read(geminiRepositoryProvider),
          ref.read(recipeCacheRepositoryProvider),
        );
        if (backgroundSearches != null) {
          notifier.state = backgroundSearches;
        }
        return notifier;
      }),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: AddRecipeScreen(
        shoppingList: list,
        availableCategories: categories,
      ),
    ),
  );
}

/// ------------------------------------------------------------
/// TESTS
/// ------------------------------------------------------------

void main() {
  testWidgets(
    'renders initial empty state correctly',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          list: createShoppingList(),
          categories: createCategories(),
        ),
      );

      // Wait for the background cache loading and animations to finish
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(AddRecipeScreen)))!;

      expect(find.text(l10n.addRecipeTitle), findsOneWidget);
      expect(
        find.text(l10n.enterRecipeAndSearch),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(l10n.searchRecipeLabel), findsOneWidget);
    },
  );

  testWidgets(
    'shows snackbar when searching with empty input',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          list: createShoppingList(),
          categories: createCategories(),
        ),
      );
      final l10n = AppLocalizations.of(tester.element(find.byType(AddRecipeScreen)))!;

      await tester.tap(find.text(l10n.searchRecipeLabel));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.enterRecipeNameError),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'renders recipe result with ingredients',
    (tester) async {
      final recipe = RecipeData(
        recipeName: 'Pasta',
        products: [Product(name: 'Tomato')],
        quantities: ['2'],
        productCategories: ['Vegetables'],
        error: 'noError',
      );

      await tester.pumpWidget(
        createTestWidget(
          list: createShoppingList(),
          categories: createCategories(),
          backgroundSearches: {
            'list-1': createSearch(
              listId: 'list-1',
              result: AsyncValue.data(recipe),
            ),
          },
        ),
      );

      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(AddRecipeScreen)))!;

      expect(find.text('Pasta'), findsOneWidget);
      expect(find.text('Tomato'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Vegetables'), findsOneWidget);
      expect(find.text(l10n.addToListLabel), findsOneWidget);
    },
  );

  testWidgets(
    'opens edit ingredient dialog and saves edited name',
    (tester) async {
      // Arrange: create a recipe with one ingredient
      final recipe = RecipeData(
        recipeName: 'Salad',
        products: [Product(name: 'Lettuce')],
        quantities: ['1'],
        productCategories: ['Vegetables'],
        error: 'noError',
      );

      await tester.pumpWidget(
        createTestWidget(
          list: createShoppingList(),
          categories: createCategories(),
          backgroundSearches: {
            'list-1': createSearch(
              listId: 'list-1',
              result: AsyncValue.data(recipe),
            ),
          },
        ),
      );

      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(AddRecipeScreen)))!;

      // Act: open edit dialog by tapping the ingredient
      await tester.tap(find.text('Lettuce'));
      await tester.pumpAndSettle();

      // Assert: dialog is shown
      expect(find.text(l10n.editIngredientTitle), findsOneWidget);

      // Enter new text in the TextField inside the dialog
      final dialogField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(dialogField, 'Iceberg');

      await tester.tap(find.text(l10n.saveLabel));
      await tester.pump(); // trigger Navigator.pop
      await tester.pumpAndSettle(); // wait for overlay animation and rebuild


      // Assert: old name is gone, new name is displayed
      expect(find.text('Lettuce'), findsNothing);
      expect(find.text('Iceberg'), findsOneWidget);
    },
  );


  testWidgets(
    'deleting ingredient updates visible count',
    (tester) async {
      final recipe = RecipeData(
        recipeName: 'Soup',
        products: [Product(name: 'Carrot')],
        quantities: ['3'],
        productCategories: ['Vegetables'],
        error: 'noError',
      );

      await tester.pumpWidget(
        createTestWidget(
          list: createShoppingList(),
          categories: createCategories(),
          backgroundSearches: {
            'list-1': createSearch(
              listId: 'list-1',
              result: AsyncValue.data(recipe),
            ),
          },
        ),
      );

      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(AddRecipeScreen)))!;

      expect(find.textContaining(l10n.ingredientsCount(1, 1)), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      expect(find.textContaining(l10n.ingredientsCount(0, 1)), findsOneWidget);
    },
  );

  testWidgets(
    'shows error UI when recipe has error',
    (tester) async {
      final recipe = RecipeData(
        recipeName: '',
        products: const [],
        quantities: const [],
        productCategories: const [],
        error: 'Recipe not found',
      );

      await tester.pumpWidget(
        createTestWidget(
          list: createShoppingList(),
          categories: createCategories(),
          backgroundSearches: {
            'list-1': createSearch(
              listId: 'list-1',
              result: AsyncValue.data(recipe),
            ),
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Recipe not found'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    },
  );
}
