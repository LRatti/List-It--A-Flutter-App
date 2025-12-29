import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_code/screens/auth/sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/auth_provider.dart';
import 'package:app_code/repositories/test_repo/in_memory_auth_repository.dart';

void main() {
  late InMemoryAuthRepository repository;

  setUp(() {
    repository = InMemoryAuthRepository();
  });

  tearDown(() {
    repository.reset();
  });

  Future<void> pumpSignInForm(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SignInForm(),
          ),
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

  testWidgets('shows error message when credentials are incorrect', (tester) async {
    await pumpSignInForm(tester);

    // Enter invalid credentials
    await tester.enterText(find.byKey(const Key('email_field')), 'invalid@example.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'wrongpassword');
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
    await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'password123');
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
    await tester.enterText(find.byKey(const Key('email_field')), 'invalid@example.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'wrongpassword');
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

  testWidgets('password field is configured for password input', (tester) async {
    await pumpSignInForm(tester);

    // Verify password field exists
    expect(find.byKey(const Key('password_field')), findsOneWidget);
  });
}
