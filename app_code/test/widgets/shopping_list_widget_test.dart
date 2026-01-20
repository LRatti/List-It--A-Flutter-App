import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_code/widgets/shopping_list_widget.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/category.dart';

void main() {
  group('ShoppingListCard', () {
    late ShoppingList testList;
    late int tapCount;
    late int longPressCount;
    String? capturedName;
    late int deleteCount;

    setUp(() {
      testList = ShoppingList(
        id: '1',
        name: 'Test List',
        createdAt: DateTime(2024, 1, 15),
      );
      tapCount = 0;
      longPressCount = 0;
      capturedName = null;
      deleteCount = 0;
    });

    // Helper to pump the widget
    Future<void> pumpCard(
      WidgetTester tester, {
      ShoppingList? list,
      bool isSelected = false,
      VoidCallback? onTap,
      VoidCallback? onLongPress,
      ValueChanged<String>? onNameChanged,
      VoidCallback? onDelete,
      ThemeData? theme,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: ShoppingListCard(
              shoppingList: list ?? testList,
              isSelected: isSelected,
              onTap: onTap ?? () => tapCount++,
              onLongPress: onLongPress ?? () => longPressCount++,
              onNameChanged: onNameChanged ?? (name) => capturedName = name,
              onDelete: onDelete ?? () => deleteCount++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // Helper to enter edit mode
    Future<void> enterEditMode(WidgetTester tester) async {
      await tester.tap(find.byType(InkWell).last);
      await tester.pumpAndSettle();
    }

    // Helper to get first Material widget
    Material getCardMaterial(WidgetTester tester) {
      return tester.widget<Material>(
        find.descendant(
          of: find.byType(ShoppingListCard),
          matching: find.byType(Material),
        ).first,
      );
    }

    testWidgets('renders list name and date', (WidgetTester tester) async {
      await pumpCard(tester);

      expect(find.text('Test List'), findsOneWidget);
      expect(find.text('15 Jan 2024'), findsOneWidget);
    });

    testWidgets('shows "No items" when list is empty', (WidgetTester tester) async {
      await pumpCard(tester);

      expect(find.text('No items'), findsOneWidget);
    });

    testWidgets('displays products when list has items', (WidgetTester tester) async {
      final category = Category(id: 'cat1', name: 'Food');
      final product1 = Product(id: 'p1', name: 'Apple');
      final product2 = Product(id: 'p2', name: 'Banana');
      
      final listWithProducts = ShoppingList(
        id: '1',
        name: 'Test List',
        createdAt: DateTime(2024, 1, 15),
        products: [
          PurchasedProduct(
            listId: '1',
            product: product1,
            category: category,
            quantity: 2,
            price: 1.5,
          ),
          PurchasedProduct(
            listId: '1',
            product: product2,
            category: category,
            quantity: 1,
            price: 0.8,
          ),
        ],
      );

      await pumpCard(tester, list: listWithProducts);

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('No items'), findsNothing);
    });

    testWidgets('calls onTap when card is tapped', (WidgetTester tester) async {
      await pumpCard(tester);

      expect(tapCount, 0);

      // Tap the first InkWell (main card, not the name edit InkWell)
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(tapCount, 1);
    });

    testWidgets('calls onLongPress when card is long pressed', (WidgetTester tester) async {
      await pumpCard(tester);

      expect(longPressCount, 0);

      // Long press the first InkWell (main card)
      await tester.longPress(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(longPressCount, 1);
    });

    testWidgets('shows or hides selection indicator based on isSelected', (WidgetTester tester) async {
      await pumpCard(tester, isSelected: false);
      expect(find.byIcon(Icons.check), findsNothing);

      await pumpCard(tester, isSelected: true);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('enters edit mode when name is tapped', (WidgetTester tester) async {
      await pumpCard(tester);
      await enterEditMode(tester);

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('saves new name when submitted in edit mode', (WidgetTester tester) async {
      await pumpCard(tester);
      await enterEditMode(tester);

      await tester.enterText(find.byType(TextField), 'New List Name');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(capturedName, 'New List Name');
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('saves name when tapping outside edit field', (WidgetTester tester) async {
      await pumpCard(tester);
      await enterEditMode(tester);

      await tester.enterText(find.byType(TextField), 'Updated Name');
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(capturedName, 'Updated Name');
    });

    testWidgets('does not save empty name', (WidgetTester tester) async {
      await pumpCard(tester);
      await enterEditMode(tester);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(capturedName, isNull);
    });

    testWidgets('applies correct color scheme in both light and dark mode', (WidgetTester tester) async {
      // Test light mode
      await pumpCard(tester, theme: ThemeData.light());
      expect(getCardMaterial(tester).color, isNotNull);

      // Test dark mode
      await pumpCard(tester, theme: ThemeData.dark());
      expect(getCardMaterial(tester).color, isNotNull);
    });

    testWidgets('changes background color when selected', (WidgetTester tester) async {
      await pumpCard(tester, isSelected: false);
      final unselectedColor = getCardMaterial(tester).color;

      await pumpCard(tester, isSelected: true);
      final selectedColor = getCardMaterial(tester).color;

      expect(selectedColor, isNot(equals(unselectedColor)));
    });

    testWidgets('displays formatted date correctly', (WidgetTester tester) async {
      final dates = [
        (DateTime(2024, 1, 15), '15 Jan 2024'),
        (DateTime(2024, 12, 25), '25 Dec 2024'),
        (DateTime(2024, 7, 4), '4 Jul 2024'),
      ];

      for (final (date, expected) in dates) {
        final list = ShoppingList(
          id: '1',
          name: 'Test',
          createdAt: date,
        );

        await pumpCard(tester, list: list);
        expect(find.text(expected), findsOneWidget);
      }
    });

    testWidgets('shows placeholder when date is null', (WidgetTester tester) async {
      final listWithoutDate = ShoppingList(
        id: '1',
        name: 'Test List',
        createdAt: null,
      );

      await pumpCard(tester, list: listWithoutDate);

      expect(find.text('--/--/----'), findsOneWidget);
    });

    testWidgets('accent color changes based on name length', (WidgetTester tester) async {
      // Create lists with different name lengths
      final list1 = ShoppingList(id: '1', name: 'A'); // length 1
      final list2 = ShoppingList(id: '2', name: 'AB'); // length 2
      final list3 = ShoppingList(id: '3', name: 'ABC'); // length 3
      final list4 = ShoppingList(id: '4', name: 'ABCD'); // length 4
      final list5 = ShoppingList(id: '5', name: 'ABCDE'); // length 5 (should wrap to first color)

      await pumpCard(tester, list: list1);
      final container1 = tester.widget<Container>(
        find.descendant(
          of: find.byType(ShoppingListCard),
          matching: find.byType(Container),
        ).first,
      );

      await pumpCard(tester, list: list5);
      final container5 = tester.widget<Container>(
        find.descendant(
          of: find.byType(ShoppingListCard),
          matching: find.byType(Container),
        ).first,
      );

      // List with length 1 and length 5 should have the same color (5 % 4 = 1)
      expect(container1.color, equals(container5.color));
    });

    testWidgets('handles multiple products correctly', (WidgetTester tester) async {
      final category = Category(id: 'cat1', name: 'Food');
      final products = List.generate(
        5,
        (i) => PurchasedProduct(
          listId: '1',
          product: Product(id: 'p$i', name: 'Product $i'),
          category: category,
        ),
      );

      final listWithManyProducts = ShoppingList(
        id: '1',
        name: 'Test List',
        createdAt: DateTime(2024, 1, 15),
        products: products,
      );

      await pumpCard(tester, list: listWithManyProducts);

      // Check all products are displayed
      for (int i = 0; i < 5; i++) {
        expect(find.text('Product $i'), findsOneWidget);
      }
    });

    testWidgets('card has proper elevation and rounded corners', (WidgetTester tester) async {
      await pumpCard(tester);
      final material = getCardMaterial(tester);

      expect(material.elevation, 2.0);
      expect(material.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('name text has correct styling', (WidgetTester tester) async {
      await pumpCard(tester);

      final textWidget = tester.widget<Text>(find.text('Test List'));
      
      expect(textWidget.style?.fontWeight, FontWeight.bold);
      expect(textWidget.maxLines, 1);
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.textAlign, TextAlign.center);
    });

    testWidgets('long name is truncated with ellipsis', (WidgetTester tester) async {
      final longList = ShoppingList(
        id: '1',
        name: 'This is a very long shopping list name that should be truncated',
        createdAt: DateTime(2024, 1, 15),
      );

      await pumpCard(tester, list: longList);

      final textWidget = tester.widget<Text>(
        find.text('This is a very long shopping list name that should be truncated'),
      );

      expect(textWidget.maxLines, 1);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('edit mode TextField is autofocused and has no border', (WidgetTester tester) async {
      await pumpCard(tester);
      await enterEditMode(tester);

      final textField = tester.widget<TextField>(find.byType(TextField));
      
      expect(textField.autofocus, true);
      expect(textField.decoration?.border, InputBorder.none);
    });
  });
}
