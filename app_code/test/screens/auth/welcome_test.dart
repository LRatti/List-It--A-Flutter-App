import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_code/screens/auth/welcome.dart';
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

  Future<void> pumpWelcomeScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WelcomeScreen(authController: controller),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders welcome screen with initial sign up form', (tester) async {
    await pumpWelcomeScreen(tester);

    expect(find.text('Flutter Auth'), findsOneWidget);
    expect(find.text('Welcome.'), findsOneWidget);
    expect(find.byKey(const Key('sign_up_section')), findsOneWidget);
    expect(find.text('Sign up for a new account.'), findsOneWidget);
    expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);
  });

  testWidgets('switches from sign up to sign in form', (tester) async {
    await pumpWelcomeScreen(tester);

    // Verify starting with sign up form
    expect(find.byKey(const Key('sign_up_section')), findsOneWidget);
    expect(find.byKey(const Key('sign_in_section')), findsNothing);

    // Tap switch to sign in button
    await tester.tap(find.byKey(const Key('switch_to_sign_in')));
    await tester.pumpAndSettle();

    // Verify switched to sign in form
    expect(find.byKey(const Key('sign_in_section')), findsOneWidget);
    expect(find.byKey(const Key('sign_up_section')), findsNothing);
    expect(find.text('Sign in to your account.'), findsOneWidget);
  });

  testWidgets('switches from sign in to sign up form', (tester) async {
    await pumpWelcomeScreen(tester);

    // Switch to sign in form first
    await tester.tap(find.byKey(const Key('switch_to_sign_in')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sign_in_section')), findsOneWidget);

    // Tap switch to sign up button
    await tester.tap(find.byKey(const Key('switch_to_sign_up')));
    await tester.pumpAndSettle();

    // Verify switched back to sign up form
    expect(find.byKey(const Key('sign_up_section')), findsOneWidget);
    expect(find.byKey(const Key('sign_in_section')), findsNothing);
  });

  testWidgets('shows correct toggle text for each form', (tester) async {
    await pumpWelcomeScreen(tester);

    // Sign up form shows "Already have an account?"
    expect(find.text('Already have an account?'), findsOneWidget);
    expect(find.text('Sign in instead'), findsOneWidget);

    // Switch to sign in
    await tester.tap(find.byKey(const Key('switch_to_sign_in')));
    await tester.pumpAndSettle();

    // Sign in form shows "Need an account?"
    expect(find.text('Need an account?'), findsOneWidget);
    expect(find.text('Sign up instead'), findsOneWidget);
  });

  testWidgets('Google sign in button is always visible', (tester) async {
    await pumpWelcomeScreen(tester);

    // Visible on sign up form
    expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);

    // Switch to sign in form
    await tester.tap(find.byKey(const Key('switch_to_sign_in')));
    await tester.pumpAndSettle();

    // Still visible on sign in form
    expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets('Google sign in links anonymous user', (tester) async {
    // Verify starting with anonymous user
    final initialUser = controller.getCurrentUser();
    expect(initialUser, isNotNull);
    expect(initialUser!.isAnonymous, true);

    await pumpWelcomeScreen(tester);

    // Tap Google sign in button
    await tester.tap(find.byKey(const Key('google_sign_in_button')));
    await tester.pumpAndSettle();

    // Verify user is linked with Google account
    final linkedUser = controller.getCurrentUser();
    expect(linkedUser, isNotNull);
    expect(linkedUser!.uid, initialUser.uid); // Same user ID (linked)
    expect(linkedUser.isAnonymous, false);
    expect(linkedUser.email, 'testuser@gmail.com');
  });

  testWidgets('Google sign in works for non-anonymous user', (tester) async {
    // Sign out to clear anonymous user
    await controller.signOut();
    // Create a non-anonymous user
    await controller.signUp('existing@example.com', 'password123');

    await pumpWelcomeScreen(tester);

    // Tap Google sign in button
    await tester.tap(find.byKey(const Key('google_sign_in_button')));
    await tester.pumpAndSettle();

    // Verify Google sign in succeeded
    final user = controller.getCurrentUser();
    expect(user, isNotNull);
    expect(user!.isAnonymous, false);
    expect(user.email, 'testuser@gmail.com');
  });

  testWidgets('sign up form submission works through welcome screen', (tester) async {
    await pumpWelcomeScreen(tester);

    // Fill in sign up form
    await tester.enterText(find.byKey(const Key('username_field')), 'welcomeuser');
    await tester.enterText(find.byKey(const Key('email_field')), 'welcome@example.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'password123');
    await tester.pumpAndSettle();

    // Submit form
    await tester.tap(find.byKey(const Key('sign_up_button')));
    await tester.pumpAndSettle();

    // Verify user is signed up
    final user = controller.getCurrentUser();
    expect(user, isNotNull);
    expect(user!.email, 'welcome@example.com');
    expect(user.getUserName(), 'welcomeuser');
  });

  testWidgets('sign in form submission works through welcome screen', (tester) async {
    // Register a test user
    repository.registerTestUser('signedin@example.com', 'password123');

    await pumpWelcomeScreen(tester);

    // Switch to sign in form
    await tester.tap(find.byKey(const Key('switch_to_sign_in')));
    await tester.pumpAndSettle();

    // Fill in sign in form
    await tester.enterText(find.byKey(const Key('email_field')), 'signedin@example.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'password123');
    await tester.pumpAndSettle();

    // Submit form
    await tester.tap(find.byKey(const Key('sign_in_button')));
    await tester.pumpAndSettle();

    // Verify user is signed in
    final user = controller.getCurrentUser();
    expect(user, isNotNull);
    expect(user!.email, 'signedin@example.com');
  });

  testWidgets('app bar is displayed correctly', (tester) async {
    await pumpWelcomeScreen(tester);

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Flutter Auth'), findsOneWidget);
  });

  testWidgets('screen is scrollable', (tester) async {
    await pumpWelcomeScreen(tester);

    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
