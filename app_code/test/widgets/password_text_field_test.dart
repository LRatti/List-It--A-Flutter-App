import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_code/widgets/password_text_field.dart';
import 'package:app_code/l10n/app_localizations.dart';

void main() {
  group('PasswordTextField', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    Future<void> pumpPasswordTextField(
      WidgetTester tester, {
      String? labelText,
      FormFieldValidator<String>? validator,
      bool enabled = true,
      TextInputAction? textInputAction,
      void Function(String)? onFieldSubmitted,
      FocusNode? focusNode,
      Iterable<String>? autofillHints,
      InputDecoration? decoration,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: PasswordTextField(
              controller: controller,
              labelText: labelText,
              validator: validator,
              enabled: enabled,
              textInputAction: textInputAction,
              onFieldSubmitted: onFieldSubmitted,
              focusNode: focusNode,
              autofillHints: autofillHints,
              decoration: decoration,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders with default label', (tester) async {
      await pumpPasswordTextField(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(PasswordTextField)))!;

      expect(find.text(l10n.passwordLabel), findsOneWidget);
    });

    testWidgets('renders with custom label', (tester) async {
      await pumpPasswordTextField(tester, labelText: 'Custom Password');

      expect(find.text('Custom Password'), findsOneWidget);
    });

    testWidgets('initially obscures text', (tester) async {
      await pumpPasswordTextField(tester);

      final editableText = tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.obscureText, isTrue);
    });

    testWidgets('shows visibility_off icon initially', (tester) async {
      await pumpPasswordTextField(tester);

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);
    });

    testWidgets('toggles password visibility when icon is tapped', (tester) async {
      await pumpPasswordTextField(tester);

      // Initially obscured
      var editableText = tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.obscureText, isTrue);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Tap to show password
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      editableText = tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.obscureText, isFalse);
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Tap to hide password again
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      editableText = tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.obscureText, isTrue);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('shows correct tooltip for visibility toggle', (tester) async {
      await pumpPasswordTextField(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(PasswordTextField)))!;

      // Check show password tooltip
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, equals(l10n.showPasswordTooltip));

      // Toggle to visible
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      // Check hide password tooltip
      final iconButtonAfter = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButtonAfter.tooltip, equals(l10n.hidePasswordTooltip));
    });

    testWidgets('accepts text input through controller', (tester) async {
      await pumpPasswordTextField(tester);

      await tester.enterText(find.byType(TextFormField), 'password123');
      await tester.pumpAndSettle();

      expect(controller.text, equals('password123'));
    });

    testWidgets('runs validator when form is validated', (tester) async {
      String? validationError;
      await pumpPasswordTextField(
        tester,
        validator: (value) {
          if (value == null || value.isEmpty) {
            validationError = 'Password is required';
            return validationError;
          }
          return null;
        },
      );

      final formState = tester.state<FormFieldState>(find.byType(TextFormField));
      
      // Validate empty field
      formState.validate();
      await tester.pumpAndSettle();
      expect(validationError, equals('Password is required'));

      // Enter valid text
      await tester.enterText(find.byType(TextFormField), 'password123');
      formState.validate();
      await tester.pumpAndSettle();
      expect(formState.hasError, isFalse);
    });

    testWidgets('respects enabled property', (tester) async {
      await pumpPasswordTextField(tester, enabled: false);

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('calls onFieldSubmitted when submitted', (tester) async {
      String? submittedValue;
      await pumpPasswordTextField(
        tester,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (value) {
          submittedValue = value;
        },
      );

      await tester.enterText(find.byType(TextFormField), 'password123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(submittedValue, equals('password123'));
    });

    testWidgets('uses provided focus node', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpPasswordTextField(tester, focusNode: focusNode);

      expect(focusNode.hasFocus, isFalse);

      // Focus the field
      focusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('sets autofill hints', (tester) async {
      await pumpPasswordTextField(
        tester,
        autofillHints: [AutofillHints.password],
      );

      final editableText = tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.autofillHints, equals([AutofillHints.password]));
    });

    testWidgets('disables suggestions and autocorrect', (tester) async {
      await pumpPasswordTextField(tester);

      final editableText = tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.enableSuggestions, isFalse);
      expect(editableText.autocorrect, isFalse);
    });

    testWidgets('merges custom decoration with default', (tester) async {
      await pumpPasswordTextField(
        tester,
        labelText: 'Custom Label',
        decoration: const InputDecoration(
          helperText: 'Helper text',
          prefixIcon: Icon(Icons.lock),
        ),
      );

      expect(find.text('Custom Label'), findsOneWidget);
      expect(find.text('Helper text'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });
  });
}
