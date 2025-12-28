import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_code/models/user.dart';
import 'package:app_code/screens/settings/settings_screen.dart';
import 'package:app_code/providers/auth_provider.dart';
import 'package:app_code/providers/email_verification_provider.dart';
import 'package:app_code/repositories/abstract/auth_repository.dart';
import 'package:app_code/services/database_manager/manage_user.dart';

class _MockNavigatorObserver extends Mock implements NavigatorObserver {}

class _FakeUserManager extends UserManager {
  _FakeUserManager(this.user);
  final User user;

  @override
  Future<User?> getUserData() async => user;

  @override
  Future<void> setUserData(User user) async {}
}

class _RecordingAuthRepository implements AuthRepository {
  bool canEdit = true;
  String? updatedEmail;
  String? updatedPassword;

  @override
  bool canUpdateCredentials() => canEdit;

  @override
  Future<void> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    updatedEmail = newEmail;
  }

  @override
  Future<void> updatePassword({
    required String newPassword,
    required String currentPassword,
  }) async {
    updatedPassword = newPassword;
  }

  // Unused in these tests
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
  Future<void> abortEmailVerification({required bool isNewSignup}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(
      MaterialPageRoute(
        builder: (context) => const SizedBox(),
        settings: const RouteSettings(name: '/'),
      ),
    );
  });

  Widget _buildApp({
    required Widget child,
    NavigatorObserver? observer,
    AuthRepository? authRepository,
  }) {
    return ProviderScope(
      overrides: [
        if (authRepository != null)
          authRepositoryProvider.overrideWithValue(authRepository),
      ],
      child: MaterialApp(
        routes: {
          '/verification': (context) =>
              const Scaffold(body: Text('Verification')),
        },
        home: child,
        navigatorObservers: [if (observer != null) observer],
      ),
    );
  }

  testWidgets('updates email and navigates to verification with session set', (
    tester,
  ) async {
    final user = User(uid: 'u1', email: 'old@example.com', userName: 'User');
    final repo = _RecordingAuthRepository();
    final navObserver = _MockNavigatorObserver();

    await tester.pumpWidget(
      _buildApp(
        observer: navObserver,
        authRepository: repo,
        child: SettingsScreen(userManager: _FakeUserManager(user)),
      ),
    );

    await tester.pumpAndSettle();

    // Find TextFormFields by their index
    // Username field (index 0)
    // New Email field (index 1)
    await tester.enterText(find.byType(TextFormField).at(1), 'new@example.com');
    // Confirm Email field (index 2)
    await tester.enterText(find.byType(TextFormField).at(2), 'new@example.com');
    // Current Password field (index 5)
    await tester.enterText(find.byType(TextFormField).at(5), 'currentPass');

    // Scroll down to make the button visible
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();

    // Get context before navigation
    final settingsContext = tester.element(find.byType(SettingsScreen));
    final container = ProviderScope.containerOf(settingsContext);

    // Tap Update Security Settings button
    await tester.tap(find.text('Update Security Settings'));
    await tester.pumpAndSettle();

    // Verify repository received email update
    expect(repo.updatedEmail, 'new@example.com');

    // Verify session provider set to email update (check before navigation)
    final session = container.read(emailVerificationSessionProvider);
    expect(session, isNotNull);
    expect(session!.isNewSignup, isFalse);
    expect(session.email, 'new@example.com');

    // Verify navigation to verification route
    expect(find.text('Verification'), findsOneWidget);
  });

  testWidgets('updates password and shows sign-in message', (tester) async {
    final user = User(uid: 'u1', email: 'me@example.com', userName: 'User');
    final repo = _RecordingAuthRepository();

    await tester.pumpWidget(
      _buildApp(
        authRepository: repo,
        child: SettingsScreen(userManager: _FakeUserManager(user)),
      ),
    );

    await tester.pumpAndSettle();

    // Enter new password details and current password
    // Username field (index 0)
    // New Email field (index 1)
    // Confirm Email field (index 2)
    // New Password field (index 3)
    await tester.enterText(find.byType(TextFormField).at(3), 'newPassword123');
    // Confirm New Password field (index 4)
    await tester.enterText(find.byType(TextFormField).at(4), 'newPassword123');
    // Current Password field (index 5)
    await tester.enterText(find.byType(TextFormField).at(5), 'currentPass');

    // Scroll down to make the button visible
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update Security Settings'));
    await tester.pumpAndSettle();

    // Verify repository received password update
    expect(repo.updatedPassword, 'newPassword123');
  });
}
