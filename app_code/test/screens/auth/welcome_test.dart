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
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  AppLocalizations l10n(WidgetTester tester) {
    return AppLocalizations.of(tester.element(find.byType(WelcomeScreen)))!;
  }

  testWidgets('renders welcome screen with initial sign up form', (
    tester,
  ) async {
    await pumpWelcomeScreen(tester);
    final strings = l10n(tester);

    expect(find.text(strings.authTitle), findsOneWidget);
    expect(find.text(strings.welcomeMessage), findsOneWidget);
    expect(find.byKey(const Key('sign_up_section')), findsOneWidget);
    expect(find.text(strings.signUpIntro), findsOneWidget);
    expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);
  });

  testWidgets('switches from sign up to sign in form', (tester) async {
    await pumpWelcomeScreen(tester);

    // Verify starting with sign up form
    expect(find.byKey(const Key('sign_up_section')), findsOneWidget);
    expect(find.byKey(const Key('sign_in_section')), findsNothing);

    // Tap switch to sign in button
    await tapVisible(tester, find.byKey(const Key('switch_to_sign_in')));
    final strings = l10n(tester);

    // Verify switched to sign in form
    expect(find.byKey(const Key('sign_in_section')), findsOneWidget);
    expect(find.byKey(const Key('sign_up_section')), findsNothing);
    expect(find.text(strings.signInIntro), findsOneWidget);
  });

  testWidgets('switches from sign in to sign up form', (tester) async {
    await pumpWelcomeScreen(tester);

    // Switch to sign in form first
    await tapVisible(tester, find.byKey(const Key('switch_to_sign_in')));
    expect(find.byKey(const Key('sign_in_section')), findsOneWidget);

    // Tap switch to sign up button
    await tapVisible(tester, find.byKey(const Key('switch_to_sign_up')));

    // Verify switched back to sign up form
    expect(find.byKey(const Key('sign_up_section')), findsOneWidget);
    expect(find.byKey(const Key('sign_in_section')), findsNothing);
  });

  testWidgets('shows correct toggle text for each form', (tester) async {
    await pumpWelcomeScreen(tester);
    final strings = l10n(tester);

    // Sign up form shows "Already have an account?"
    expect(find.text(strings.alreadyHaveAccount), findsOneWidget);
    expect(find.text(strings.signInInstead), findsOneWidget);

    // Switch to sign in
    await tapVisible(tester, find.byKey(const Key('switch_to_sign_in')));

    // Sign in form shows "Need an account?"
    expect(find.text(strings.needAccount), findsOneWidget);
    expect(find.text(strings.signUpInstead), findsOneWidget);
  });

  testWidgets('Google sign in button is always visible', (tester) async {
    await pumpWelcomeScreen(tester);
    final strings = l10n(tester);

    // Visible on sign up form
    expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);
    expect(find.text(strings.signInWithGoogle), findsOneWidget);

    // Switch to sign in form
    await tapVisible(tester, find.byKey(const Key('switch_to_sign_in')));

    // Still visible on sign in form
    expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);
    expect(find.text(strings.signInWithGoogle), findsOneWidget);
  });

  testWidgets('Google sign in links anonymous user', (tester) async {
    // Verify starting with anonymous user
    final initialUser = repository.getCurrentUser();
    expect(initialUser, isNotNull);
    expect(initialUser!.isAnonymous, true);

    await pumpWelcomeScreen(tester);

    // Tap Google sign in button
    await tapVisible(tester, find.byKey(const Key('google_sign_in_button')));

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
    await tapVisible(tester, find.byKey(const Key('google_sign_in_button')));

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
    await tapVisible(tester, find.byKey(const Key('sign_up_button')));

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
    await tapVisible(tester, find.byKey(const Key('switch_to_sign_in')));

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
    await tapVisible(tester, find.byKey(const Key('sign_in_button')));

    // Verify user is signed in
    final user = repository.getCurrentUser();
    expect(user, isNotNull);
    expect(user!.email, 'signedin@example.com');
  });

  testWidgets('app bar is displayed correctly', (tester) async {
    await pumpWelcomeScreen(tester);
    final strings = l10n(tester);

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text(strings.authTitle), findsOneWidget);
  });

  testWidgets('app bar has back button', (tester) async {
    await pumpWelcomeScreen(tester);

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('back button allows aborting authentication', (tester) async {
    await pumpWelcomeScreen(tester);
    final strings = l10n(tester);

    // Verify we're on the welcome screen
    expect(find.text(strings.welcomeMessage), findsOneWidget);

    // Tap back button
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Should navigate back to home screen
    expect(find.text('Home Screen'), findsOneWidget);
    expect(find.text(strings.welcomeMessage), findsNothing);
  });

  testWidgets('Google sign in failure keeps user on welcome screen', (
    tester,
  ) async {
    repository.setGoogleSignInFailure(true);

    await pumpWelcomeScreen(tester);

    await tapVisible(tester, find.byKey(const Key('google_sign_in_button')));

    expect(find.text('Home Screen'), findsNothing);
    expect(find.text('Welcome.'), findsOneWidget);
  });

  testWidgets('screen is scrollable', (tester) async {
    await pumpWelcomeScreen(tester);

    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
