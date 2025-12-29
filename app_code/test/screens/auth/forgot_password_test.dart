import 'package:app_code/models/user.dart';
import 'package:app_code/providers/real_app_providers/auth_provider.dart';
import 'package:app_code/repositories/abstract/auth_repository.dart';
import 'package:app_code/screens/auth/forgot_password.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingAuthRepository implements AuthRepository {
  int resetCount = 0;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetCount += 1;
    // Simulate network delay so loading state is visible
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  // Unused in these tests
  @override
  bool canUpdateCredentials() => true;
  @override
  Future<User?> ensureAuthenticated() async => null;
  @override
  User? getCurrentUser() => null;
  @override
  Future<User?> linkAnonymousWithEmailPassword(
    String email,
    String password,
    String username,
  ) async => null;
  @override
  Future<void> signOut() async {}
  @override
  Future<User?> signIn(String email, String password) async => null;
  @override
  Future<User?> signInAnonymously() async => null;
  @override
  Future<User?> signInWithGoogle() async => null;
  @override
  Future<User?> signUp(String email, String password) async => null;
  @override
  Future<void> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {}
  @override
  Future<void> updatePassword({
    required String newPassword,
    required String currentPassword,
  }) async {}
  @override
  Future<void> abortEmailVerification({required bool isNewSignup}) async {}
}

class _ThrowingAuthRepository extends _RecordingAuthRepository {
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetCount += 1;
    throw Exception('fail');
  }
}

Future<void> _pumpForgotPassword(
  WidgetTester tester,
  _RecordingAuthRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: const ForgotPasswordScreen(),
        routes: {
          '/signin': (_) => const Scaffold(body: Text('Sign In Screen')),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows validation errors for empty and mismatched emails', (
    tester,
  ) async {
    final repo = _RecordingAuthRepository();
    await _pumpForgotPassword(tester, repo);

    // Submit empty form
    await tester.tap(find.text('Send recovery email'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please confirm your email'), findsOneWidget);

    // Enter mismatched emails
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'a@b.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm Email'),
      'c@d.com',
    );
    await tester.tap(find.text('Send recovery email'));
    await tester.pumpAndSettle();

    expect(find.text('Emails do not match'), findsOneWidget);
    expect(repo.resetCount, 0);
  });

  testWidgets('sends reset email and shows success message', (tester) async {
    final repo = _RecordingAuthRepository();
    await _pumpForgotPassword(tester, repo);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'me@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm Email'),
      'me@example.com',
    );

    await tester.tap(find.text('Send recovery email'));
    await tester.pumpAndSettle();

    expect(repo.resetCount, 1);
    expect(
      find.text('If an account exists, a reset link has been sent.'),
      findsOneWidget,
    );
  });

  testWidgets('shows error message when sending fails', (tester) async {
    final repo = _ThrowingAuthRepository();
    await _pumpForgotPassword(tester, repo);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'me@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm Email'),
      'me@example.com',
    );

    await tester.tap(find.text('Send recovery email'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not send reset email. Please try again later.'),
      findsOneWidget,
    );
    expect(repo.resetCount, 1);
  });

  testWidgets('disables button and shows loader when submitting', (tester) async {
    final repo = _RecordingAuthRepository();
    await _pumpForgotPassword(tester, repo);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'me@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm Email'),
      'me@example.com',
    );

    // Button should be enabled
    expect(find.byType(ElevatedButton), findsOneWidget);

    // Tap the button
    await tester.tap(find.text('Send recovery email'));
    // Pump a small duration to catch the loading state
    await tester.pump(const Duration(milliseconds: 50));

    // Button disabled and loader shown
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Let the async operation complete to avoid pending timers
    await tester.pumpAndSettle();
  });

  testWidgets('allows retry after successful submission', (tester) async {
    final repo = _RecordingAuthRepository();
    await _pumpForgotPassword(tester, repo);

    // First submission
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'me@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm Email'),
      'me@example.com',
    );

    await tester.tap(find.text('Send recovery email'));
    await tester.pumpAndSettle();

    expect(repo.resetCount, 1);
    expect(
      find.text('If an account exists, a reset link has been sent.'),
      findsOneWidget,
    );

    // Clear the fields
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      '',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm Email'),
      '',
    );

    // Second submission with different email
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'other@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm Email'),
      'other@example.com',
    );

    await tester.tap(find.text('Send recovery email'));
    await tester.pumpAndSettle();

    expect(repo.resetCount, 2);
  });
}
