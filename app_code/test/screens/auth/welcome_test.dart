import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_code/screens/auth/welcome.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/auth/auth_provider.dart';
import 'package:app_code/repositories/mock_repo/mock_auth_repository.dart';
import 'package:app_code/l10n/app_localizations.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() async {
    repository = MockAuthRepository();
    // Ensure anonymous user is signed in (simulating app behavior)
    await repository.signInAnonymously();
  });

  tearDown(() {
    repository.reset();
  });

  Future<void> pumpWelcomeScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WelcomeScreen(),
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home Screen')),
            '/signin': (context) =>
                const Scaffold(body: Text('Welcome Screen')),
            '/verification': (context) =>
                const Scaffold(body: Text('Verification Screen')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders welcome screen with initial sign up form', (
    tester,
  ) async {
    await pumpWelcomeScreen(tester);

    expect(find.text('Authentication'), findsOneWidget);
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
    final initialUser = repository.getCurrentUser();
    expect(initialUser, isNotNull);
    expect(initialUser!.isAnonymous, true);

    await pumpWelcomeScreen(tester);

    // Tap Google sign in button
    await tester.tap(find.byKey(const Key('google_sign_in_button')));
    await tester.pumpAndSettle();

    // Verify user is signed in with Google account (new UID)
    final linkedUser = repository.getCurrentUser();
    expect(linkedUser, isNotNull);
    expect(
      linkedUser!.uid,
      isNot(equals(initialUser.uid)),
    ); // Different user ID
    expect(linkedUser.isAnonymous, false);
    expect(linkedUser.email, 'testuser@gmail.com');
  });

  testWidgets('Google sign in works for non-anonymous user', (tester) async {
    // Sign out to clear anonymous user
    await repository.signOut();
    // Create a non-anonymous user
    await repository.signUp('existing@example.com', 'password123');

    await pumpWelcomeScreen(tester);

    // Tap Google sign in button
    await tester.tap(find.byKey(const Key('google_sign_in_button')));
    await tester.pumpAndSettle();

    // Verify Google sign in succeeded
    final user = repository.getCurrentUser();
    expect(user, isNotNull);
    expect(user!.isAnonymous, false);
    expect(user.email, 'testuser@gmail.com');
  });

  testWidgets('sign up form submission works through welcome screen', (
    tester,
  ) async {
    await pumpWelcomeScreen(tester);

    // Fill in sign up form
    await tester.enterText(
      find.byKey(const Key('username_field')),
      'welcomeuser',
    );
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'welcome@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'password123',
    );
    await tester.pumpAndSettle();

    // Submit form
    await tester.tap(find.byKey(const Key('sign_up_button')));
    await tester.pumpAndSettle();

    // Verify user is signed up
    final user = repository.getCurrentUser();
    expect(user, isNotNull);
    expect(user!.email, 'welcome@example.com');
    expect(user.getUserName(), 'welcomeuser');
  });

  testWidgets('sign in form submission works through welcome screen', (
    tester,
  ) async {
    // Register a test user
    repository.registerTestUser('signedin@example.com', 'password123');

    await pumpWelcomeScreen(tester);

    // Switch to sign in form
    await tester.tap(find.byKey(const Key('switch_to_sign_in')));
    await tester.pumpAndSettle();

    // Fill in sign in form
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'signedin@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'password123',
    );
    await tester.pumpAndSettle();

    // Submit form
    await tester.tap(find.byKey(const Key('sign_in_button')));
    await tester.pumpAndSettle();

    // Verify user is signed in
    final user = repository.getCurrentUser();
    expect(user, isNotNull);
    expect(user!.email, 'signedin@example.com');
  });

  testWidgets('app bar is displayed correctly', (tester) async {
    await pumpWelcomeScreen(tester);

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Authentication'), findsOneWidget);
  });

  testWidgets('app bar has back button', (tester) async {
    await pumpWelcomeScreen(tester);

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('back button allows aborting authentication', (tester) async {
    await pumpWelcomeScreen(tester);

    // Verify we're on the welcome screen
    expect(find.text('Welcome.'), findsOneWidget);

    // Tap back button
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Should navigate back to home screen
    expect(find.text('Home Screen'), findsOneWidget);
    expect(find.text('Welcome.'), findsNothing);
  });

  testWidgets('Google sign in failure keeps user on welcome screen', (
    tester,
  ) async {
    repository.setGoogleSignInFailure(true);

    await pumpWelcomeScreen(tester);

    await tester.tap(find.byKey(const Key('google_sign_in_button')));
    await tester.pumpAndSettle();

    expect(find.text('Home Screen'), findsNothing);
    expect(find.text('Welcome.'), findsOneWidget);
  });

  testWidgets('screen is scrollable', (tester) async {
    await pumpWelcomeScreen(tester);

    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
