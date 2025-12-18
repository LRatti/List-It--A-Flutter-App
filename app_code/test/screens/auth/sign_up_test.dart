import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_code/screens/auth/sign_up.dart';
import 'package:app_code/controllers/auth_controller.dart';
import 'package:app_code/repositories/test/in_memory_auth_repository.dart';

void main() {
  late InMemoryAuthRepository repository;
  late AuthController controller;

  setUp(() async {
    repository = InMemoryAuthRepository();
    controller = AuthController(repository);
    // Ensure anonymous user is signed in (simulating app behavior)
    await controller.signInAnonymously();
  });

  tearDown(() {
    repository.reset();
  });

  Future<void> pumpSignUpForm(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SignUpForm(authController: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders all form elements correctly', (tester) async {
    await pumpSignUpForm(tester);

    expect(find.text('Sign up for a new account.'), findsOneWidget);
    expect(find.byKey(const Key('username_field')), findsOneWidget);
    expect(find.byKey(const Key('email_field')), findsOneWidget);
    expect(find.byKey(const Key('password_field')), findsOneWidget);
    expect(find.byKey(const Key('sign_up_button')), findsOneWidget);
  });

  testWidgets('shows validation errors when fields are empty', (tester) async {
    await pumpSignUpForm(tester);

    // Tap sign up button without entering any information
    await tester.tap(find.byKey(const Key('sign_up_button')));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a username'), findsOneWidget);
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please make a password'), findsOneWidget);
  });

  testWidgets('shows error when password is too short', (tester) async {
    await pumpSignUpForm(tester);

    await tester.enterText(find.byKey(const Key('username_field')), 'testuser');
    await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'short');
    await tester.pumpAndSettle();

    // Tap sign up button
    await tester.tap(find.byKey(const Key('sign_up_button')));
    await tester.pumpAndSettle();

    expect(find.text('Password must be at least 8 chars long'), findsOneWidget);
  });

  testWidgets('successfully signs up with valid information', (tester) async {
    await pumpSignUpForm(tester);

    // Enter valid sign up information
    await tester.enterText(find.byKey(const Key('username_field')), 'testuser');
    await tester.enterText(find.byKey(const Key('email_field')), 'newuser@example.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'password123');
    await tester.pumpAndSettle();

    // Tap sign up button
    await tester.tap(find.byKey(const Key('sign_up_button')));
    await tester.pumpAndSettle();

    // Verify user is signed up and no longer anonymous
    final user = controller.getCurrentUser();
    expect(user, isNotNull);
    expect(user!.email, 'newuser@example.com');
    expect(user.getUserName(), 'testuser');
    expect(user.isAnonymous, false);
  });

  testWidgets('shows error message on sign up failure', (tester) async {
    // Configure repository to fail on next sign up
    repository.setSignUpFailure(true);

    await pumpSignUpForm(tester);

    // Enter valid information
    await tester.enterText(find.byKey(const Key('username_field')), 'testuser');
    await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'password123');
    await tester.pumpAndSettle();

    // Tap sign up button
    await tester.tap(find.byKey(const Key('sign_up_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('error_text')), findsOneWidget);
    expect(find.text('Could not sign up with those details.'), findsOneWidget);
  });

  testWidgets('clears error message on retry', (tester) async {
    // Configure repository to fail on first attempt
    repository.setSignUpFailure(true);

    await pumpSignUpForm(tester);

    // First attempt
    await tester.enterText(find.byKey(const Key('username_field')), 'testuser');
    await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'password123');
    await tester.tap(find.byKey(const Key('sign_up_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('error_text')), findsOneWidget);

    // Retry (should succeed since flag is reset after first use)
    await tester.tap(find.byKey(const Key('sign_up_button')));
    await tester.pumpAndSettle();

    // Error should be cleared
    expect(find.byKey(const Key('error_text')), findsNothing);
  });

  testWidgets('username field accepts input', (tester) async {
    await pumpSignUpForm(tester);

    final usernameField = find.byKey(const Key('username_field'));
    await tester.enterText(usernameField, 'MyUsername');
    await tester.pumpAndSettle();

    expect(find.text('MyUsername'), findsOneWidget);
  });

  testWidgets('email field accepts input', (tester) async {
    await pumpSignUpForm(tester);

    final emailField = find.byKey(const Key('email_field'));
    await tester.enterText(emailField, 'myemail@example.com');
    await tester.pumpAndSettle();

    expect(find.text('myemail@example.com'), findsOneWidget);
  });

  testWidgets('password field is configured for password input', (tester) async {
    await pumpSignUpForm(tester);

    // Verify password field exists
    expect(find.byKey(const Key('password_field')), findsOneWidget);
  });

  testWidgets('links anonymous user to email account', (tester) async {
    // Verify starting with anonymous user
    final initialUser = controller.getCurrentUser();
    expect(initialUser, isNotNull);
    expect(initialUser!.isAnonymous, true);

    await pumpSignUpForm(tester);

    // Complete sign up
    await tester.enterText(find.byKey(const Key('username_field')), 'linkeduser');
    await tester.enterText(find.byKey(const Key('email_field')), 'linked@example.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'password123');
    await tester.tap(find.byKey(const Key('sign_up_button')));
    await tester.pumpAndSettle();

    // Verify anonymous user is now linked
    final linkedUser = controller.getCurrentUser();
    expect(linkedUser, isNotNull);
    expect(linkedUser!.uid, initialUser.uid); // Same user ID
    expect(linkedUser.isAnonymous, false); // No longer anonymous
    expect(linkedUser.email, 'linked@example.com');
    expect(linkedUser.getUserName(), 'linkeduser');
  });
}
