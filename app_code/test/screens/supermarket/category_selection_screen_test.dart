import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/providers/real_app_providers/category/categories_notifier.dart';
import 'package:app_code/screens/supermarket/category_selection_screen.dart';
import 'package:app_code/screens/supermarket/category_editing_screen.dart';
import 'package:app_code/l10n/app_localizations.dart';

class FakeCategoriesNotifier extends CategoriesNotifier {
  FakeCategoriesNotifier(this.categories);

  final List<Category> categories;
  int deleteCount = 0;
  List<String> deletedIds = [];
  Exception? errorToThrow;

  @override
  Future<List<Category>> build() async => categories;

  @override
  Future<List<Category>> getVisibleCategories() async {
    return categories.where((cat) => cat.isVisible).toList();
  }

  @override
  Future<int> deleteCategories(List<String> categoryIds) async {
    if (errorToThrow != null) throw errorToThrow!;
    deleteCount++;
    deletedIds = categoryIds;
    categories.removeWhere((cat) => categoryIds.contains(cat.id));
    return categoryIds.length;
  }
}

void main() {
  group('CategorySelectionScreen - Widget Tests', () {
    late FakeCategoriesNotifier fakeNotifier;

    Future<void> pumpScreen(
      WidgetTester tester, {
      required String supermarketId,
      List<Category> currentCategories = const [],
      Function(List<Category>)? onCategoriesSelected,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesProvider.overrideWith(() => fakeNotifier),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: CategorySelectionScreen(
              supermarketId: supermarketId,
              currentCategories: currentCategories,
              onCategoriesSelected: onCategoriesSelected ?? (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() {
      fakeNotifier = FakeCategoriesNotifier([
        Category(id: 'c1', name: 'Fruits'),
        Category(id: 'c2', name: 'Vegetables'),
        Category(id: 'c3', name: 'Dairy'),
      ]);
    });

    group('Rendering Tests', () {
      testWidgets('renders screen with app bar elements', (tester) async {
        await pumpScreen(tester, supermarketId: 's1');
        expect(find.byType(CategorySelectionScreen), findsOneWidget);
        expect(find.text('Add Categories'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('displays available categories in list', (tester) async {
        await pumpScreen(tester, supermarketId: 's1');
        
        expect(find.text('Fruits'), findsOneWidget);
        expect(find.text('Vegetables'), findsOneWidget);
        expect(find.text('Dairy'), findsOneWidget);
      });

      testWidgets('displays empty state when no categories available',
          (tester) async {
        fakeNotifier = FakeCategoriesNotifier([]);
        await pumpScreen(
          tester,
          supermarketId: 's1',
          currentCategories: [],
        );

        expect(find.byIcon(Icons.done_all), findsOneWidget);
        expect(find.text('All categories added'), findsOneWidget);
      });

      testWidgets('filters out current categories from available list',
          (tester) async {
        final current = [Category(id: 'c1', name: 'Fruits')];
        await pumpScreen(
          tester,
          supermarketId: 's1',
          currentCategories: current,
        );

        expect(find.text('Fruits'), findsNothing);
        expect(find.text('Vegetables'), findsOneWidget);
        expect(find.text('Dairy'), findsOneWidget);
      });

      testWidgets('does not display bottom navigation bar initially',
          (tester) async {
        await pumpScreen(tester, supermarketId: 's1');
        expect(find.text('Delete'), findsNothing);
        expect(find.text('Add'), findsNothing);
      });

      testWidgets('displays checkboxes for each category', (tester) async {
        await pumpScreen(tester, supermarketId: 's1');
        expect(find.byType(CheckboxListTile), findsNWidgets(3));
      });
    });

    group('Selection Tests', () {
      testWidgets('selects category when checkbox tapped', (tester) async {
        await pumpScreen(tester, supermarketId: 's1');

        final checkbox = find.byType(CheckboxListTile).first;
        await tester.tap(checkbox);
        await tester.pumpAndSettle();

        final checkboxWidget = tester.widget<CheckboxListTile>(checkbox);
        expect(checkboxWidget.value, true);
      });

      testWidgets('deselects category when tapped again', (tester) async {
        await pumpScreen(tester, supermarketId: 's1');

        final checkbox = find.byType(CheckboxListTile).first;
        await tester.tap(checkbox);
        await tester.pumpAndSettle();

        await tester.tap(checkbox);
        await tester.pumpAndSettle();

        final checkboxWidget = tester.widget<CheckboxListTile>(checkbox);
        expect(checkboxWidget.value, false);
      });

      testWidgets('shows bottom navigation bar when category selected',
          (tester) async {
        await pumpScreen(tester, supermarketId: 's1');

        await tester.tap(find.byType(CheckboxListTile).first);
        await tester.pumpAndSettle();

        expect(find.text('Delete'), findsOneWidget);
        expect(find.text('Add'), findsOneWidget);
      });

      testWidgets('hides bottom navigation bar when all deselected',
          (tester) async {
        await pumpScreen(tester, supermarketId: 's1');

        final checkbox = find.byType(CheckboxListTile).first;
        await tester.tap(checkbox);
        await tester.pumpAndSettle();

        await tester.tap(checkbox);
        await tester.pumpAndSettle();

        expect(find.text('Delete'), findsNothing);
        expect(find.text('Add'), findsNothing);
      });

      testWidgets('supports multiple category selection', (tester) async {
        await pumpScreen(tester, supermarketId: 's1');

        await tester.tap(find.byType(CheckboxListTile).at(0));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(CheckboxListTile).at(1));
        await tester.pumpAndSettle();

        final checkbox1 = tester.widget<CheckboxListTile>(
          find.byType(CheckboxListTile).at(0),
        );
        final checkbox2 = tester.widget<CheckboxListTile>(
          find.byType(CheckboxListTile).at(1),
        );
        expect(checkbox1.value, true);
        expect(checkbox2.value, true);
      });
    });

    group('Add Categories Tests', () {
      testWidgets('adds selected categories successfully', (tester) async {
        List<Category>? addedCategories;
        await pumpScreen(
          tester,
          supermarketId: 's1',
          onCategoriesSelected: (cats) => addedCategories = cats,
        );

        await tester.tap(find.byType(CheckboxListTile).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        expect(addedCategories, isNotNull);
        expect(addedCategories!.length, 1);
        expect(addedCategories!.first.getName(), 'Dairy');
      });

      testWidgets('closes screen after adding categories', (tester) async {
        await pumpScreen(tester, supermarketId: 's1');

        await tester.tap(find.byType(CheckboxListTile).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        expect(find.byType(CategorySelectionScreen), findsNothing);
      });

      testWidgets('adds multiple selected categories', (tester) async {
        List<Category>? addedCategories;
        await pumpScreen(
          tester,
          supermarketId: 's1',
          onCategoriesSelected: (cats) => addedCategories = cats,
        );

        await tester.tap(find.byType(CheckboxListTile).at(0));
        await tester.tap(find.byType(CheckboxListTile).at(1));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        expect(addedCategories!.length, 2);
      });

      testWidgets('sorts categories alphabetically when adding',
          (tester) async {
        List<Category>? addedCategories;
        await pumpScreen(
          tester,
          supermarketId: 's1',
          currentCategories: [Category(id: 'c4', name: 'Meat')],
          onCategoriesSelected: (cats) => addedCategories = cats,
        );

        await tester.tap(find.byType(CheckboxListTile).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        expect(addedCategories!.length, 2);
        expect(addedCategories!.first.getName(), 'Dairy');
      });
    });

    group('Delete Categories Tests', () {
      testWidgets('shows error when deleting without selection',
          (tester) async {
        await pumpScreen(tester, supermarketId: 's1');

        await tester.tap(find.byType(CheckboxListTile).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('shows confirmation dialog before deletion', (tester) async {
        await pumpScreen(tester, supermarketId: 's1');

        await tester.tap(find.byType(CheckboxListTile).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.textContaining('Fruits'), findsOneWidget);
      });

      testWidgets('deletes category after confirmation', (tester) async {
        await pumpScreen(tester, supermarketId: 's1');

        await tester.tap(find.byType(CheckboxListTile).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete').last);
        await tester.pumpAndSettle();

        expect(fakeNotifier.deleteCount, 1);
        // First item in sorted list is Dairy (c3)
        expect(fakeNotifier.deletedIds, contains('c3'));
      });

      testWidgets('cancels deletion when dialog dismissed', (tester) async {
        await pumpScreen(tester, supermarketId: 's1');

        await tester.tap(find.byType(CheckboxListTile).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(fakeNotifier.deleteCount, 0);
      });

      testWidgets('clears selection after successful deletion',
          (tester) async {
        await pumpScreen(tester, supermarketId: 's1');

        await tester.tap(find.byType(CheckboxListTile).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete').last);
        await tester.pumpAndSettle();

        expect(find.text('Add'), findsNothing);
      });

      testWidgets('handles deletion error gracefully', (tester) async {
        fakeNotifier.errorToThrow = Exception('Network error');
        await pumpScreen(tester, supermarketId: 's1');

        await tester.tap(find.byType(CheckboxListTile).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete').last);
        await tester.pumpAndSettle();

        expect(find.textContaining('Failed to delete categories'),
            findsOneWidget);
      });
    });

    group('Navigation Tests', () {
      testWidgets('back button closes screen', (tester) async {
        await pumpScreen(tester, supermarketId: 's1');

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        expect(find.byType(CategorySelectionScreen), findsNothing);
      });

      testWidgets('add button navigates to category editing', (tester) async {
        await pumpScreen(tester, supermarketId: 's1');

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        expect(find.byType(CategoryEditingScreen), findsOneWidget);
      });
    });
  });
}
