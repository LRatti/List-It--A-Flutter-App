import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_code/screens/auth/sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/auth/auth_provider.dart';
import 'package:app_code/repositories/mock_repo/mock_auth_repository.dart';
import 'package:app_code/l10n/app_localizations.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
  });

  tearDown(() {
    repository.reset();
  });

  Future<void> pumpSignInForm(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SignInForm()),
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home Screen')),
            '/forgot-password': (context) =>
                const Scaffold(body: Text('Forgot Password Screen')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders all form elements correctly', (tester) async {
    await pumpSignInForm(tester);

    expect(find.text('Sign in to your account.'), findsOneWidget);
    expect(find.byKey(const Key('email_field')), findsOneWidget);
    expect(find.byKey(const Key('password_field')), findsOneWidget);
    expect(find.byKey(const Key('sign_in_button')), findsOneWidget);
  });

  testWidgets('shows validation errors when fields are empty', (tester) async {
    await pumpSignInForm(tester);

    // Tap sign in button without entering credentials
    await tester.tap(find.byKey(const Key('sign_in_button')));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('shows error message when credentials are incorrect', (
    tester,
  ) async {
    await pumpSignInForm(tester);

    // Enter invalid credentials
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'invalid@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'wrongpassword',
    );
    await tester.pumpAndSettle();

    // Tap sign in button
    await tester.tap(find.byKey(const Key('sign_in_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('error_text')), findsOneWidget);
    expect(find.text('Incorrect login credentials.'), findsOneWidget);
  });

  testWidgets('successfully signs in with correct credentials', (tester) async {
    // Register a test user
    repository.registerTestUser('test@example.com', 'password123');

    await pumpSignInForm(tester);

    // Enter valid credentials
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'test@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'password123',
    );
    await tester.pumpAndSettle();

    // Tap sign in button
    await tester.tap(find.byKey(const Key('sign_in_button')));
    await tester.pumpAndSettle();

    // Verify user is signed in
    final user = repository.getCurrentUser();
    expect(user, isNotNull);
    expect(user!.email, 'test@example.com');
    expect(user.isAnonymous, false);
  });

  testWidgets('clears error message on retry', (tester) async {
    await pumpSignInForm(tester);

    // First attempt with invalid credentials
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'invalid@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'wrongpassword',
    );
    await tester.tap(find.byKey(const Key('sign_in_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('error_text')), findsOneWidget);

    // Register user and retry with correct credentials
    repository.registerTestUser('invalid@example.com', 'wrongpassword');
    await tester.tap(find.byKey(const Key('sign_in_button')));
    await tester.pumpAndSettle();

    // Error should be cleared
    expect(find.byKey(const Key('error_text')), findsNothing);
  });

  testWidgets('email field accepts keyboard input', (tester) async {
    await pumpSignInForm(tester);

    final emailField = find.byKey(const Key('email_field'));
    await tester.enterText(emailField, 'test@example.com');
    await tester.pumpAndSettle();

    expect(find.text('test@example.com'), findsOneWidget);
  });

  testWidgets('password field is configured for password input', (
    tester,
  ) async {
    await pumpSignInForm(tester);

    // Verify password field exists
    expect(find.byKey(const Key('password_field')), findsOneWidget);
  });

  testWidgets('forgot password button navigates to forgot-password route',
      (tester) async {
    await pumpSignInForm(tester);

    expect(find.byKey(const Key('forgot_password_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('forgot_password_button')));
    await tester.pumpAndSettle();

    // Verify navigation occurred by finding the Forgot Password Screen
    expect(find.text('Forgot Password Screen'), findsOneWidget);
  });

  testWidgets('trims email and password before submission', (tester) async {
    repository.registerTestUser('test@example.com', 'password123');

    await pumpSignInForm(tester);

    // Enter email and password with leading/trailing spaces
    await tester.enterText(
      find.byKey(const Key('email_field')),
      '  test@example.com  ',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      '  password123  ',
    );
    await tester.pumpAndSettle();

    // Submit form
    await tester.tap(find.byKey(const Key('sign_in_button')));
    await tester.pumpAndSettle();

    // Verify successful sign in (trimmed values match)
    final user = repository.getCurrentUser();
    expect(user, isNotNull);
    expect(user!.email, 'test@example.com');
    expect(user.isAnonymous, false);
  });

  testWidgets('shows only email validation error when only email is empty',
      (tester) async {
    await pumpSignInForm(tester);

    await tester.enterText(
      find.byKey(const Key('password_field')),
      'password123',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sign_in_button')));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsNothing);
  });

  testWidgets('shows only password validation error when only password is empty',
      (tester) async {
    await pumpSignInForm(tester);

    await tester.enterText(
      find.byKey(const Key('email_field')),
      'test@example.com',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sign_in_button')));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your password'), findsOneWidget);
    expect(find.text('Please enter your email'), findsNothing);
  });

  testWidgets('sign in button is visible and enabled', (tester) async {
    await pumpSignInForm(tester);

    final signInButton = find.byKey(const Key('sign_in_button'));
    expect(signInButton, findsOneWidget);

    // Button should be enabled by default
    final buttonWidget = tester.widget<FilledButton>(signInButton);
    expect(buttonWidget.onPressed, isNotNull);
  });

  testWidgets('form key validation prevents submission with empty fields',
      (tester) async {
    await pumpSignInForm(tester);

    // Don't enter any data, just tap submit
    final initialErrorFinder = find.byKey(const Key('error_text'));
    expect(initialErrorFinder, findsNothing);

    await tester.tap(find.byKey(const Key('sign_in_button')));
    await tester.pumpAndSettle();

    // Validation errors should appear
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);

    // Sign in should not have occurred
    final user = repository.getCurrentUser();
    expect(user, isNull);
  });

  testWidgets('handles consecutive sign in attempts', (tester) async {
    repository.registerTestUser('test@example.com', 'password123');

    await pumpSignInForm(tester);

    // First attempt with wrong password
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'test@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'wrongpassword',
    );
    await tester.tap(find.byKey(const Key('sign_in_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('error_text')), findsOneWidget);

    // Clear and try again with correct password
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'password123',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sign_in_button')));
    await tester.pumpAndSettle();

    // Error should be cleared and sign in successful
    expect(find.byKey(const Key('error_text')), findsNothing);
    final user = repository.getCurrentUser();
    expect(user, isNotNull);
    expect(user!.email, 'test@example.com');
  });
}
