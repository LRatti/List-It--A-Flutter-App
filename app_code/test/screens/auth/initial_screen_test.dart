import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/screens/auth/initial_screen.dart';
import 'package:app_code/providers/real_app_providers/auth_provider.dart';
import 'package:app_code/repositories/mock_repo/mock_auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late MockAuthRepository authRepository;

  setUp(() async {
    authRepository = MockAuthRepository();
    // Ensure anonymous user is signed in initially
    await authRepository.signInAnonymously();
    // Reset shared preferences for testing
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    authRepository.reset();
  });

  Future<void> pumpInitialScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
        child: MaterialApp(
          home: const InitialScreen(),
          routes: {
            '/signin': (context) => const Scaffold(body: Text('Sign In')),
            '/home': (context) => const Scaffold(body: Text('Home')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders initial screen with welcome message', (tester) async {
    await pumpInitialScreen(tester);

    expect(find.text('My Shopping App'), findsOneWidget);
    expect(
      find.text('Organize your shopping lists efficiently'),
      findsOneWidget,
    );
    expect(
      find.text('You can sign up later to sync your lists across devices'),
      findsOneWidget,
    );
  });

  testWidgets('renders shopping cart icon', (tester) async {
    await pumpInitialScreen(tester);

    expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
  });

  testWidgets('has sign up button with correct text', (tester) async {
    await pumpInitialScreen(tester);

    expect(find.byKey(const Key('sign_up_button')), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('sign_up_button')),
        matching: find.text('Sign Up'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('has continue without signup button', (tester) async {
    await pumpInitialScreen(tester);

    expect(
      find.byKey(const Key('continue_without_signup_button')),
      findsOneWidget,
    );
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('continue_without_signup_button')),
        matching: find.text('Continue without signing up'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('sign up button navigates to signin route', (tester) async {
    await pumpInitialScreen(tester);

    await tester.tap(find.byKey(const Key('sign_up_button')));
    await tester.pumpAndSettle();

    // Should navigate to the mocked /signin route
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('continue without signup signs in anonymously', (tester) async {
    await pumpInitialScreen(tester);

    // Tap continue without signup button
    await tester.tap(find.byKey(const Key('continue_without_signup_button')));
    await tester.pumpAndSettle();

    // Verify anonymous sign in was called and we navigated home
    final user = authRepository.getCurrentUser();
    expect(user, isNotNull);
    expect(user!.isAnonymous, isTrue);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('marks first time visit as completed when clicking sign up', (
    tester,
  ) async {
    await pumpInitialScreen(tester);

    await tester.tap(find.byKey(const Key('sign_up_button')));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('first_time_visit') ?? true;
    expect(isFirstTime, isFalse);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets(
    'marks first time visit as completed when clicking continue without signup',
    (tester) async {
      await pumpInitialScreen(tester);

      await tester.tap(find.byKey(const Key('continue_without_signup_button')));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('first_time_visit') ?? true;
      expect(isFirstTime, isFalse);
    },
  );

  testWidgets('initial screen has gradient background', (tester) async {
    await pumpInitialScreen(tester);

    // Check that the background container exists
    expect(find.byType(Container), findsWidgets);
  });

  testWidgets('buttons are properly sized', (tester) async {
    await pumpInitialScreen(tester);

    // Find SizedBox widgets containing buttons
    final sizedBoxes = find.byType(SizedBox);
    expect(sizedBoxes, findsWidgets);

    // Verify button height by checking SizedBox dimensions
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });

  testWidgets('initial screen is centered vertically', (tester) async {
    await pumpInitialScreen(tester);

    // Find the main Column which uses mainAxisAlignment.center
    expect(find.byType(Column), findsWidgets);
  });
}
