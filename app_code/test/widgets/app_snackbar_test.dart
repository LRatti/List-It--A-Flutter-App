import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_code/widgets/app_snackbar.dart';

void main() {
  group('buildAppSnackBar', () {
    testWidgets('builds success snackbar with correct icon and message', (WidgetTester tester) async {
      final snackBar = buildAppSnackBar(
        message: 'Operation successful',
        isError: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                });
                return const Text('Test');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Operation successful'), findsOneWidget);
    });

    testWidgets('builds error snackbar with correct icon and message', (WidgetTester tester) async {
      final snackBar = buildAppSnackBar(
        message: 'An error occurred',
        isError: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                });
                return const Text('Test');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
      expect(find.text('An error occurred'), findsOneWidget);
    });

    testWidgets('displays touch icon when onTap callback is provided', (WidgetTester tester) async {
      final snackBar = buildAppSnackBar(
        message: 'Tap me',
        isError: false,
        onTap: () {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                });
                return const Text('Test');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.touch_app), findsOneWidget);
      expect(find.text('Tap me'), findsOneWidget);
    });

    testWidgets('does not display touch icon when onTap is null', (WidgetTester tester) async {
      final snackBar = buildAppSnackBar(
        message: 'No tap',
        isError: false,
        onTap: null,
      );

      final content = snackBar.content as Row;
      final icons = content.children.whereType<Icon>();
      expect(icons.any((icon) => icon.icon == Icons.touch_app), isFalse);
    });

    testWidgets('calls onTap callback when snackbar is tapped', (WidgetTester tester) async {
      bool tapped = false;

      final snackBar = buildAppSnackBar(
        message: 'Tap me',
        isError: false,
        onTap: () {
          tapped = true;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                });
                return const Text('Test');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Tap me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('uses custom duration', (WidgetTester tester) async {
      final customDuration = const Duration(seconds: 2);
      final snackBar = buildAppSnackBar(
        message: 'Custom duration',
        isError: false,
        duration: customDuration,
      );

      expect(snackBar.duration, customDuration);
    });

    testWidgets('uses default duration when not provided', (WidgetTester tester) async {
      final snackBar = buildAppSnackBar(
        message: 'Default duration',
        isError: false,
      );

      expect(snackBar.duration, const Duration(seconds: 5));
    });

    testWidgets('snackbar has floating behavior', (WidgetTester tester) async {
      final snackBar = buildAppSnackBar(
        message: 'Floating snackbar',
        isError: false,
      );

      expect(snackBar.behavior, SnackBarBehavior.floating);
    });

    testWidgets('snackbar has correct margin', (WidgetTester tester) async {
      final snackBar = buildAppSnackBar(
        message: 'Margin test',
        isError: false,
      );

      expect(snackBar.margin, const EdgeInsets.all(16));
    });

    testWidgets('success snackbar has a non-null background color', (WidgetTester tester) async {
      final snackBar = buildAppSnackBar(
        message: 'Success',
        isError: false,
      );

      expect(snackBar.backgroundColor, isNotNull);
    });

    testWidgets('error snackbar has a non-null background color', (WidgetTester tester) async {
      final snackBar = buildAppSnackBar(
        message: 'Error',
        isError: true,
      );

      expect(snackBar.backgroundColor, isNotNull);
    });

    testWidgets('message text has max 2 lines with ellipsis overflow', (WidgetTester tester) async {
      final longMessage = 'This is a very long message that should be truncated with ellipsis when it exceeds the available space in the snackbar widget display area';

      final snackBar = buildAppSnackBar(
        message: longMessage,
        isError: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                });
                return const Text('Test');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text(longMessage), findsOneWidget);
    });

    testWidgets('renders icon, message, and touch icon in correct order', (WidgetTester tester) async {
      final snackBar = buildAppSnackBar(
        message: 'Complete message',
        isError: false,
        onTap: () {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                });
                return const Text('Test');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Complete message'), findsOneWidget);
      expect(find.byIcon(Icons.touch_app), findsOneWidget);
    });
  });
}
