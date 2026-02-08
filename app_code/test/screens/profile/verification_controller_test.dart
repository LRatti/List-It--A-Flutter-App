import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_code/screens/profile/verification_screen.dart';
import 'package:app_code/providers/real_app_providers/auth/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/auth/email_verification_provider.dart';
import 'package:app_code/repositories/mock_repo/mock_auth_repository.dart';

/// Comprehensive widget tests for VerificationController
/// These tests verify email verification screen behavior, especially abort operations
/// that correctly handle new signup vs email update flows
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpScreen(
    WidgetTester tester, {
    required EmailVerificationSession session,
    required MockAuthRepository repo,
  }) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          emailVerificationSessionProvider.overrideWith((ref) => session),
        ],
        child: MaterialApp(
          routes: {
            '/': (context) => const Scaffold(body: Text('Home')),
            '/signin': (context) => const Scaffold(body: Text('SignIn')),
            '/verification': (context) => const VerificationScreen(),
          },
          initialRoute: '/verification',
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('VerificationController - New Signup Abort', () {
    testWidgets('navigates to signin when aborting new signup', (tester) async {
      final repo = MockAuthRepository();
      final session = EmailVerificationSession(
        isNewSignup: true,
        email: 'newsignup@example.com',
      );

      await repo.signUp('newsignup@example.com', 'password123');
      await pumpScreen(tester, session: session, repo: repo);

      await tester.tap(find.text('Abort Operation'));
      await tester.pumpAndSettle();

      expect(find.text('SignIn'), findsOneWidget);
    });

    testWidgets('converts authenticated user to anonymous', (tester) async {
      final repo = MockAuthRepository();
      final session = EmailVerificationSession(
        isNewSignup: true,
        email: 'signup@example.com',
      );

      await repo.signUp('signup@example.com', 'password123');
      final userBeforeAbort = repo.getCurrentUser();
      expect(userBeforeAbort!.isAnonymous, isFalse);

      await pumpScreen(tester, session: session, repo: repo);
      await tester.tap(find.text('Abort Operation'));
      await tester.pumpAndSettle();

      final userAfterAbort = repo.getCurrentUser();
      expect(userAfterAbort!.isAnonymous, isTrue);
    });

    testWidgets('shows signup cancellation message', (tester) async {
      final repo = MockAuthRepository();
      final session = EmailVerificationSession(
        isNewSignup: true,
        email: 'cancel@example.com',
      );

      await repo.signUp('cancel@example.com', 'password123');
      await pumpScreen(tester, session: session, repo: repo);

      await tester.tap(find.text('Abort Operation'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Account creation cancelled'), findsOneWidget);
    });
  });

  group('VerificationController - Email Update Abort', () {
    testWidgets('pops back to home when aborting email update', (tester) async {
      final repo = MockAuthRepository();
      final session = EmailVerificationSession(
        isNewSignup: false,
        email: 'newemail@example.com',
      );

      await repo.signUp('original@example.com', 'password123');
      await pumpScreen(tester, session: session, repo: repo);

      await tester.tap(find.text('Abort Operation'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('keeps user authenticated with original email', (tester) async {
      final repo = MockAuthRepository();
      final session = EmailVerificationSession(
        isNewSignup: false,
        email: 'update@example.com',
      );

      await repo.signUp('original@example.com', 'password123');
      expect(repo.getCurrentUser()!.email, 'original@example.com');

      await pumpScreen(tester, session: session, repo: repo);
      await tester.tap(find.text('Abort Operation'));
      await tester.pumpAndSettle();

      final currentUser = repo.getCurrentUser();
      expect(currentUser, isNotNull);
      expect(currentUser!.isAnonymous, isFalse);
      expect(currentUser!.email, 'original@example.com');
    });

    testWidgets('shows email update cancellation message', (tester) async {
      final repo = MockAuthRepository();
      final session = EmailVerificationSession(
        isNewSignup: false,
        email: 'newemail@example.com',
      );

      await repo.signUp('original@example.com', 'password123');
      await pumpScreen(tester, session: session, repo: repo);

      await tester.tap(find.text('Abort Operation'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Email verification cancelled'), findsOneWidget);
    });
  });

  group('VerificationController - Email Display', () {
    testWidgets('displays email in session for new signup', (tester) async {
      final repo = MockAuthRepository();
      final email = 'test.user@example.com';
      final session = EmailVerificationSession(
        isNewSignup: true,
        email: email,
      );

      await pumpScreen(tester, session: session, repo: repo);

      expect(find.text(email), findsOneWidget);
    });

    testWidgets('displays email in session for email update', (tester) async {
      final repo = MockAuthRepository();
      final email = 'newemail@example.com';
      final session = EmailVerificationSession(
        isNewSignup: false,
        email: email,
      );

      await pumpScreen(tester, session: session, repo: repo);

      expect(find.text(email), findsOneWidget);
    });

    testWidgets('handles complex email addresses', (tester) async {
      final complexEmails = [
        'user.name+tag@example.co.uk',
        'simple@test.com',
      ];

      for (final email in complexEmails) {
        final repo = MockAuthRepository();
        final session = EmailVerificationSession(
          isNewSignup: true,
          email: email,
        );

        await pumpScreen(tester, session: session, repo: repo);

        expect(find.text(email), findsOneWidget);

        // Cleanup for next iteration
        await tester.pumpWidget(Container());
        await tester.pump();
      }
    });
  });

  group('VerificationController - Context Differentiation', () {
    testWidgets('correctly identifies new signup flow', (tester) async {
      final repo = MockAuthRepository();
      final session = EmailVerificationSession(
        isNewSignup: true,
        email: 'newuser@example.com',
      );

      await repo.signUp('newuser@example.com', 'password');
      await pumpScreen(tester, session: session, repo: repo);

      await tester.tap(find.text('Abort Operation'));
      await tester.pumpAndSettle();

      // Navigates to signin for new signup flow
      expect(find.text('SignIn'), findsOneWidget);
    });

    testWidgets('correctly identifies email update flow', (tester) async {
      final repo = MockAuthRepository();
      final session = EmailVerificationSession(
        isNewSignup: false,
        email: 'updatedmail@example.com',
      );

      await repo.signUp('currentmail@example.com', 'password');
      await pumpScreen(tester, session: session, repo: repo);

      await tester.tap(find.text('Abort Operation'));
      await tester.pumpAndSettle();

      // Pops to home for email update flow
      expect(find.text('Home'), findsOneWidget);
    });
  });

  group('VerificationController - Integration Scenarios', () {
    testWidgets('complete new signup abort scenario', (tester) async {
      final repo = MockAuthRepository();
      await repo.signUp('fulltest@example.com', 'password');

      final session = EmailVerificationSession(
        isNewSignup: true,
        email: 'fulltest@example.com',
      );

      await pumpScreen(tester, session: session, repo: repo);

      // Verify email displayed
      expect(find.text('fulltest@example.com'), findsOneWidget);
      // Abort button present
      expect(find.text('Abort Operation'), findsOneWidget);

      // Perform abort
      await tester.tap(find.text('Abort Operation'));
      await tester.pumpAndSettle();

      // Verify final state
      expect(find.text('SignIn'), findsOneWidget);
      expect(repo.getCurrentUser()!.isAnonymous, isTrue);
    });

    testWidgets('complete email update abort scenario', (tester) async {
      final repo = MockAuthRepository();
      await repo.signUp('original@example.com', 'password');

      final session = EmailVerificationSession(
        isNewSignup: false,
        email: 'updated@example.com',
      );

      await pumpScreen(tester, session: session, repo: repo);

      // Verify updated email displayed
      expect(find.text('updated@example.com'), findsOneWidget);

      // Perform abort
      await tester.tap(find.text('Abort Operation'));
      await tester.pumpAndSettle();

      // Verify final state
      expect(find.text('Home'), findsOneWidget);
      final user = repo.getCurrentUser()!;
      expect(user.isAnonymous, isFalse);
      expect(user.email, 'original@example.com');
    });
  });
}
