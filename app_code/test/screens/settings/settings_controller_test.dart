import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_code/models/user.dart';
import 'package:app_code/screens/settings/settings_screen.dart';
import 'package:app_code/providers/real_app_providers/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/email_verification_provider.dart';
import 'package:app_code/providers/real_app_providers/user_details_provider.dart';
import 'package:app_code/repositories/abstract/auth_repository.dart';
import 'package:app_code/repositories/real_app_repo/database_manager_repository/manage_user.dart';

class _FakeUserManager extends UserDatabaseManager {
  _FakeUserManager(this.user);
  final User user;
  User? _currentUser;

  @override
  Future<User?> getUserData() async => _currentUser ?? user;

  @override
  Future<void> setUserData(User user) async {
    _currentUser = user;
  }
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

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

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

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this.user, this.repository);
  final User user;
  final AuthRepository repository;

  @override
  Future<User?> build() async {
    // Don't call super.build() as it tries to access Firebase
    // Just return our test user
    return user;
  }

  @override
  bool canUpdateCredentials() => repository.canUpdateCredentials();

  @override
  Future<void> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) => repository.updateEmail(
    newEmail: newEmail,
    currentPassword: currentPassword,
  );

  @override
  Future<void> updatePassword({
    required String newPassword,
    required String currentPassword,
  }) => repository.updatePassword(
    newPassword: newPassword,
    currentPassword: currentPassword,
  );
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
    required User user,
    NavigatorObserver? observer,
    AuthRepository? authRepository,
    UserDatabaseManager? userManager,
  }) {
    final repo = authRepository ?? _RecordingAuthRepository();
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        if (userManager != null)
          userManagerProvider.overrideWithValue(userManager),
        // Provide auth state so userDetailsProvider can work
        authProvider.overrideWith(() => _FakeAuthNotifier(user, repo)),
      ],
      child: MaterialApp(
        routes: {
          '/verification': (context) =>
              const Scaffold(body: Text('Verification')),
          '/signin': (context) => const Scaffold(body: Text('Sign In Screen')),
        },
        home: const SettingsScreen(),
        navigatorObservers: [if (observer != null) observer],
      ),
    );
  }

  testWidgets('updates email and navigates to verification with session set', (
    tester,
  ) async {
    final user = User(uid: 'u1', email: 'old@example.com', userName: 'User');
    final repo = _RecordingAuthRepository();
    final userManager = _FakeUserManager(user);

    await tester.pumpWidget(
      _buildApp(
        user: user,
        authRepository: repo,
        userManager: userManager,
      ),
    );

    await tester.pumpAndSettle();

    // Enter new email
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New Email'),
      'new@example.com',
    );
    // Confirm email
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm New Email'),
      'new@example.com',
    );
    // Current password
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter Current Password to Confirm Changes'),
      'currentPass',
    );

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
    final userManager = _FakeUserManager(user);

    await tester.pumpWidget(
      _buildApp(
        user: user,
        authRepository: repo,
        userManager: userManager,
      ),
    );

    await tester.pumpAndSettle();

    // Enter new password
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New Password'),
      'newPassword123',
    );
    // Confirm new password
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm New Password'),
      'newPassword123',
    );
    // Current password
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter Current Password to Confirm Changes'),
      'currentPass',
    );

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

    // Verify navigation to sign in after password update
    expect(find.text('Sign In Screen'), findsOneWidget);
  });

  testWidgets('prevents simultaneous email and password updates', (
    tester,
  ) async {
    final user = User(uid: 'u1', email: 'me@example.com', userName: 'User');
    final repo = _RecordingAuthRepository();
    final userManager = _FakeUserManager(user);

    await tester.pumpWidget(
      _buildApp(
        user: user,
        authRepository: repo,
        userManager: userManager,
      ),
    );

    await tester.pumpAndSettle();

    // Enter both email and password fields
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New Email'),
      'new@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm New Email'),
      'new@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New Password'),
      'newPassword123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm New Password'),
      'newPassword123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter Current Password to Confirm Changes'),
      'currentPass',
    );

    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update Security Settings'));
    await tester.pumpAndSettle();

    // Should show error message about updating separately
    expect(
      find.text('Please update email and password separately.'),
      findsOneWidget,
    );
  });

  testWidgets('shows error when email fields do not match', (tester) async {
    final user = User(uid: 'u1', email: 'me@example.com', userName: 'User');
    final repo = _RecordingAuthRepository();
    final userManager = _FakeUserManager(user);

    await tester.pumpWidget(
      _buildApp(
        user: user,
        authRepository: repo,
        userManager: userManager,
      ),
    );

    await tester.pumpAndSettle();

    // Enter mismatched emails
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New Email'),
      'new@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm New Email'),
      'different@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter Current Password to Confirm Changes'),
      'currentPass',
    );

    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update Security Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Email addresses do not match.'), findsOneWidget);
  });

  testWidgets('shows error when password is too short', (tester) async {
    final user = User(uid: 'u1', email: 'me@example.com', userName: 'User');
    final repo = _RecordingAuthRepository();
    final userManager = _FakeUserManager(user);

    await tester.pumpWidget(
      _buildApp(
        user: user,
        authRepository: repo,
        userManager: userManager,
      ),
    );

    await tester.pumpAndSettle();

    // Enter short password
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New Password'),
      'short',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm New Password'),
      'short',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter Current Password to Confirm Changes'),
      'currentPass',
    );

    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update Security Settings'));
    await tester.pumpAndSettle();

    expect(
      find.text('Password must be at least 6 characters.'),
      findsOneWidget,
    );
  });

  testWidgets('shows error when current password is missing', (tester) async {
    final user = User(uid: 'u1', email: 'me@example.com', userName: 'User');
    final repo = _RecordingAuthRepository();
    final userManager = _FakeUserManager(user);

    await tester.pumpWidget(
      _buildApp(
        user: user,
        authRepository: repo,
        userManager: userManager,
      ),
    );

    await tester.pumpAndSettle();

    // Enter new password but no current password
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New Password'),
      'newPassword123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm New Password'),
      'newPassword123',
    );

    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -800),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update Security Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Enter current password to proceed.'), findsOneWidget);
  });

  testWidgets('shows error when canEditCredentials is false', (tester) async {
    final user = User(uid: 'u1', email: 'me@example.com', userName: 'User');
    final repo = _RecordingAuthRepository();
    repo.canEdit = false;
    final userManager = _FakeUserManager(user);

    await tester.pumpWidget(
      _buildApp(
        user: user,
        authRepository: repo,
        userManager: userManager,
      ),
    );

    await tester.pumpAndSettle();
    // Verify that the Google-managed banner is shown
    expect(
      find.text(
        'Email and password are managed via your Google account. Changes are disabled.',
      ),
      findsOneWidget,
    );

    // Verify that credential fields and update button are not present
    expect(find.widgetWithText(TextFormField, 'New Email'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Confirm New Email'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'New Password'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Confirm New Password'), findsNothing);
    expect(
      find.widgetWithText(TextFormField, 'Enter Current Password to Confirm Changes'),
      findsNothing,
    );
    expect(find.text('Update Security Settings'), findsNothing);
  });
}
