import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_code/screens/profile/verification_screen.dart';
import 'package:app_code/providers/real_app_providers/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/email_verification_provider.dart';
import 'package:app_code/repositories/test_repo/in_memory_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpScreen(
    WidgetTester tester, {
    required EmailVerificationSession session,
    required InMemoryAuthRepository repo,
    String initialRoute = '/',
  }) async {
    // Set a larger test surface size to avoid overflow issues
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          // Initialize session provider with given value
          emailVerificationSessionProvider.overrideWith((ref) => session),
        ],
        child: MaterialApp(
          initialRoute: initialRoute,
          routes: {
            '/': (context) => const Scaffold(body: Text('Home')),
            '/signin': (context) => const Scaffold(body: Text('SignIn')),
            '/verification': (context) => const VerificationScreen(),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Abort on new signup deletes account and redirects to signin', (tester) async {
    final repo = InMemoryAuthRepository();
    // Simulate new signup session
    final session = EmailVerificationSession(isNewSignup: true, email: 'new@example.com');

    // Ensure a non-anonymous user to validate deletion behavior
    await repo.signUp('new@example.com', 'password123');

    await pumpScreen(tester, session: session, repo: repo, initialRoute: '/verification');

    // Find and tap the Abort Operation button
    final abortButton = find.text('Abort Operation');
    expect(abortButton, findsOneWidget);
    await tester.tap(abortButton);
    await tester.pumpAndSettle();

    // Should navigate to signin
    expect(find.text('SignIn'), findsOneWidget);
    // Repository should now have an anonymous user
    final current = repo.getCurrentUser();
    expect(current, isNotNull);
    expect(current!.isAnonymous, isTrue);
  });

  testWidgets('Abort on email update cancels and pops', (tester) async {
    final repo = InMemoryAuthRepository();
    // Simulate email update session
    final session = EmailVerificationSession(isNewSignup: false, email: 'update@example.com');

    await repo.signUp('old@example.com', 'password123');

    await pumpScreen(tester, session: session, repo: repo, initialRoute: '/verification');

    // Find and tap the Abort Operation button
    final abortButton = find.text('Abort Operation');
    expect(abortButton, findsOneWidget);
    await tester.tap(abortButton);
    await tester.pumpAndSettle();

    // Should pop back to Home
    expect(find.text('Home'), findsOneWidget);
    // User remains signed in
    final current = repo.getCurrentUser();
    expect(current, isNotNull);
    expect(current!.isAnonymous, isFalse);
  });
}
