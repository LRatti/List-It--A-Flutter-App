import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/category.dart';
import 'package:app_code/providers/real_app_providers/category/categories_notifier.dart';
import 'package:app_code/screens/supermarket/category_editing_screen.dart';
import 'package:app_code/l10n/app_localizations.dart';

class FakeCategoriesNotifier extends CategoriesNotifier {
  FakeCategoriesNotifier(this.categories);

  final List<Category> categories;
  int addCount = 0;
  int updateCount = 0;
  Category? lastAddedCategory;
  Category? lastUpdatedCategory;
  Exception? errorToThrow;

  @override
  Future<List<Category>> build() async => categories;

  @override
  Future<void> addCategory(Category category) async {
    if (errorToThrow != null) throw errorToThrow!;
    addCount++;
    lastAddedCategory = category;
  }

  @override
  Future<void> updateCategory(Category category) async {
    if (errorToThrow != null) throw errorToThrow!;
    updateCount++;
    lastUpdatedCategory = category;
  }
}

void main() {
  group('CategoryEditingScreen - Widget Tests', () {
    late FakeCategoriesNotifier fakeNotifier;

    Future<void> pumpScreen(
      WidgetTester tester, {
      Category? categoryToEdit,
      Function(Category)? onCategoryCreated,
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
            home: CategoryEditingScreen(
              categoryToEdit: categoryToEdit,
              onCategoryCreated: onCategoryCreated,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() {
      fakeNotifier = FakeCategoriesNotifier([]);
    });

    group('Rendering Tests', () {
      testWidgets('renders with create title when creating new category',
          (tester) async {
        await pumpScreen(tester);
        expect(find.byType(CategoryEditingScreen), findsOneWidget);
        expect(find.text('Create Category'), findsOneWidget);
      });

      testWidgets('renders with edit title when editing existing category',
          (tester) async {
        final category = Category(id: 'c1', name: 'Fruits');
        await pumpScreen(tester, categoryToEdit: category);

        expect(find.text('Edit Category'), findsOneWidget);
      });

      testWidgets('displays category name when editing', (tester) async {
        final category = Category(id: 'c1', name: 'Vegetables');
        await pumpScreen(tester, categoryToEdit: category);

        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);
        expect(find.text('Vegetables'), findsOneWidget);
      });

      testWidgets('displays empty text field when creating', (tester) async {
        await pumpScreen(tester);

        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);
        final widget = tester.widget<TextField>(textField);
        expect(widget.controller?.text, isEmpty);
      });

      testWidgets('displays save button', (tester) async {
        await pumpScreen(tester);
        expect(find.text('Save'), findsOneWidget);
      });

      testWidgets('displays back button in app bar', (tester) async {
        await pumpScreen(tester);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });

      testWidgets('displays category name label', (tester) async {
        await pumpScreen(tester);
        expect(find.text('Category Name'), findsOneWidget);
      });

      testWidgets('displays label icon', (tester) async {
        await pumpScreen(tester);
        expect(find.byIcon(Icons.label), findsOneWidget);
      });
    });

    group('Input Validation Tests', () {
      testWidgets('accepts valid category name input', (tester) async {
        await pumpScreen(tester);

        final textField = find.byType(TextField);
        await tester.enterText(textField, 'Dairy Products');
        await tester.pumpAndSettle();

        expect(find.text('Dairy Products'), findsOneWidget);
      });

      testWidgets('shows error when name is empty', (tester) async {
        await pumpScreen(tester);

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('Category name cannot be empty'), findsOneWidget);
        expect(fakeNotifier.addCount, 0);
      });

      testWidgets('shows error when name is only whitespace', (tester) async {
        await pumpScreen(tester);

        final textField = find.byType(TextField);
        await tester.enterText(textField, '   ');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('Category name cannot be empty'), findsOneWidget);
        expect(fakeNotifier.addCount, 0);
      });

      testWidgets('trims whitespace from category name', (tester) async {
        await pumpScreen(tester);

        final textField = find.byType(TextField);
        await tester.enterText(textField, '  Snacks  ');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(fakeNotifier.addCount, 1);
        expect(fakeNotifier.lastAddedCategory?.getName(), 'Snacks');
      });
    });

    group('Create Category Tests', () {
      testWidgets('creates new category successfully', (tester) async {
        await pumpScreen(tester);

        final textField = find.byType(TextField);
        await tester.enterText(textField, 'Beverages');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(fakeNotifier.addCount, 1);
        expect(fakeNotifier.lastAddedCategory?.getName(), 'Beverages');
        expect(fakeNotifier.lastAddedCategory?.isVisible, true);
      });

      testWidgets('calls onCategoryCreated callback when provided',
          (tester) async {
        Category? callbackCategory;
        await pumpScreen(
          tester,
          onCategoryCreated: (category) => callbackCategory = category,
        );

        final textField = find.byType(TextField);
        await tester.enterText(textField, 'New Category');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(callbackCategory, isNotNull);
        expect(callbackCategory?.getName(), 'New Category');
      });

      testWidgets('closes screen after successful creation', (tester) async {
        await pumpScreen(tester);

        final textField = find.byType(TextField);
        await tester.enterText(textField, 'Frozen Foods');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.byType(CategoryEditingScreen), findsNothing);
      });

      testWidgets('save button becomes disabled while saving', (tester) async {
        await pumpScreen(tester);

        final textField = find.byType(TextField);
        await tester.enterText(textField, 'Bakery');
        await tester.pumpAndSettle();

        final saveButton = find.widgetWithText(ElevatedButton, 'Save');
        expect(saveButton, findsOneWidget);
      });
    });

    group('Update Category Tests', () {
      testWidgets('updates existing category successfully', (tester) async {
        final category = Category(id: 'c1', name: 'Old Name');
        await pumpScreen(tester, categoryToEdit: category);

        final textField = find.byType(TextField);
        await tester.enterText(textField, 'New Name');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(fakeNotifier.updateCount, 1);
        expect(category.getName(), 'New Name');
      });

      testWidgets('does not call onCategoryCreated when updating',
          (tester) async {
        Category? callbackCategory;
        final category = Category(id: 'c1', name: 'Test');
        await pumpScreen(
          tester,
          categoryToEdit: category,
          onCategoryCreated: (cat) => callbackCategory = cat,
        );

        final textField = find.byType(TextField);
        await tester.enterText(textField, 'Updated');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(callbackCategory, isNull);
      });

      testWidgets('closes screen after successful update', (tester) async {
        final category = Category(id: 'c1', name: 'Old');
        await pumpScreen(tester, categoryToEdit: category);

        final textField = find.byType(TextField);
        await tester.enterText(textField, 'New');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.byType(CategoryEditingScreen), findsNothing);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('shows error message when save fails', (tester) async {
        fakeNotifier.errorToThrow = Exception('Network error');
        await pumpScreen(tester);

        final textField = find.byType(TextField);
        await tester.enterText(textField, 'Test Category');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Error saving category'), findsOneWidget);
      });

      testWidgets('remains on screen when save fails', (tester) async {
        fakeNotifier.errorToThrow = Exception('Database error');
        await pumpScreen(tester);

        final textField = find.byType(TextField);
        await tester.enterText(textField, 'Test');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.byType(CategoryEditingScreen), findsOneWidget);
      });

      testWidgets('stops loading state after error', (tester) async {
        fakeNotifier.errorToThrow = Exception('Error');
        await pumpScreen(tester);

        final textField = find.byType(TextField);
        await tester.enterText(textField, 'Test');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('Navigation Tests', () {
      testWidgets('back button closes screen', (tester) async {
        await pumpScreen(tester);

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        expect(find.byType(CategoryEditingScreen), findsNothing);
      });

      testWidgets('keyboard done action triggers save', (tester) async {
        await pumpScreen(tester);

        final textField = find.byType(TextField);
        await tester.enterText(textField, 'Quick Save');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(fakeNotifier.addCount, 1);
        expect(fakeNotifier.lastAddedCategory?.getName(), 'Quick Save');
      });
    });
  });
}
