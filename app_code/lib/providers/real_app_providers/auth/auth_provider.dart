import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/user.dart';
import 'package:app_code/repositories/abstract/auth_repository.dart';
import 'package:app_code/repositories/real_app_repo/firebase_auth_repository.dart';
import 'package:app_code/utils/auth_logger.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Exposes a Riverpod AsyncNotifier that manages authentication state.
final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);

/// Provides the concrete repository implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Manages authentication state and delegates operations to the repository.
class AuthNotifier extends AsyncNotifier<User?> {
  late final AuthRepository _repository;

  /// Initializes the repository and listens to auth state changes.
  @override
  Future<User?> build() async {
    _repository = ref.read(authRepositoryProvider);
    AuthLogger.info('Auth notifier build started');

    // Listen to Firebase auth state changes
    // Use userChanges() instead of authStateChanges() to detect credential linking
    // userChanges() emits when user properties change (like isAnonymous, email, etc.)
    firebase_auth.FirebaseAuth.instance.userChanges().listen((firebaseUser) {
      if (firebaseUser != null) {
        AuthLogger.debug(
          'Auth state updated',
        );
        state = AsyncData(
          User(
            uid: firebaseUser.uid,
            isAnonymous: firebaseUser.isAnonymous,
            email: firebaseUser.email,
          ),
        );
      } else {
        AuthLogger.debug('Auth state cleared (no user)');
        state = AsyncData(null);
      }
    });

    // Return the current user on initial load
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      AuthLogger.info('Current user found during build');
      return User(
        uid: currentUser.uid,
        isAnonymous: currentUser.isAnonymous,
        email: currentUser.email,
      );
    }
    AuthLogger.info('No current user during build');
    return null;
  }

  /// Ensure a user is authenticated, sign in anonymously if not
  Future<void> ensureAuthenticated() async {
    AuthLogger.info('Ensuring user is authenticated');
    try {
      final user = await _repository.ensureAuthenticated();
      if (user != null) {
        AuthLogger.info('User authenticated');
        state = AsyncData(user);
      } else {
        AuthLogger.warning('Ensure authenticated returned null user');
      }
    } catch (e, stackTrace) {
      AuthLogger.error(
        'Ensure authenticated failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Sign in anonymously without email and password
  Future<void> signInAnonymously() async {
    AuthLogger.info('Starting anonymous sign-in');
    try {
      final user = await _repository.signInAnonymously();
      if (user != null) {
        AuthLogger.info('Anonymous sign-in succeeded');
        state = AsyncData(user);
      } else {
        AuthLogger.warning('Anonymous sign-in returned null user');
      }
    } catch (e, stackTrace) {
      AuthLogger.error(
        'Anonymous sign-in failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Sign up a new user with email and password
  Future<void> signUp(String email, String password) async {
    AuthLogger.info(
      'Starting sign-up',
      data: {'email': AuthLogger.maskEmail(email)},
    );
    try {
      final user = await _repository.signUp(email, password);
      if (user != null) {
        AuthLogger.info('Sign-up succeeded');
        state = AsyncData(user);
      } else {
        AuthLogger.warning('Sign-up returned null user');
      }
    } catch (e, stackTrace) {
      AuthLogger.error('Sign-up failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    AuthLogger.info(
      'Starting sign-in',
      data: {'email': AuthLogger.maskEmail(email)},
    );
    try {
      final user = await _repository.signIn(email, password);
      if (user != null) {
        AuthLogger.info('Sign-in succeeded');
        state = AsyncData(user);
      } else {
        AuthLogger.warning('Sign-in returned null user');
        // Surface an error so callers can avoid navigating on failed login
        throw Exception('Invalid email or password');
      }
    } catch (e, stackTrace) {
      AuthLogger.error('Sign-in failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    AuthLogger.info('Starting Google sign-in');
    try {
      final user = await _repository.signInWithGoogle();
      if (user != null) {
        AuthLogger.info('Google sign-in succeeded');
        state = AsyncData(user);
      } else {
        AuthLogger.warning('Google sign-in returned null user');
        // Surface an error so callers can avoid navigating on failed/cancelled login
        throw Exception('Google sign-in failed or was cancelled');
      }
    } catch (e, stackTrace) {
      AuthLogger.error(
        'Google sign-in failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Send a password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    AuthLogger.info(
      'Sending password reset email',
      data: {'email': AuthLogger.maskEmail(email)},
    );
    try {
      await _repository.sendPasswordResetEmail(email);
      AuthLogger.info('Password reset email sent');
    } catch (e, stackTrace) {
      AuthLogger.error(
        'Failed to send password reset email',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Convert anonymous user to permanent account with email/password
  Future<void> linkAnonymousWithEmailPassword(
    String email,
    String password,
    String username,
  ) async {
    AuthLogger.info(
      'Linking anonymous user with email and password',
      data: {'email': AuthLogger.maskEmail(email)},
    );
    try {
      final user = await _repository.linkAnonymousWithEmailPassword(
        email,
        password,
        username,
      );
      if (user != null) {
        AuthLogger.info('Anonymous user linked successfully');
        state = AsyncData(user);
      } else {
        AuthLogger.warning('Anonymous linking returned null user');
        throw Exception('Failed to link anonymous user');
      }
    } catch (e, stackTrace) {
      AuthLogger.error(
        'Anonymous user linking failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Sign out and transition to anonymous authentication
  Future<void> signOut() async {
    AuthLogger.info('Signing out');
    await _repository.signOut();
    AuthLogger.info('Sign-out completed');
    // signOut() signs in anonymously inside the repository; refresh state accordingly
    final user = _repository.getCurrentUser();
    state = AsyncData(user);
  }

  /// Abort email verification process
  /// If [isNewSignup] is true, deletes the account and signs in anonymously
  /// If [isNewSignup] is false, just stays signed in with original email
  Future<void> abortEmailVerification({required bool isNewSignup}) async {
    AuthLogger.info(
      'Aborting email verification',
      data: {'isNewSignup': isNewSignup},
    );
    await _repository.abortEmailVerification(isNewSignup: isNewSignup);

    if (isNewSignup) {
      // After deleting account and signing in anonymously
      final user = _repository.getCurrentUser();
      state = AsyncData(user);
    }
    // For email updates, user state remains unchanged
  }

  /// Whether current user can update email/password (non-Google, non-anonymous)
  bool canUpdateCredentials() {
    return _repository.canUpdateCredentials();
  }

  /// Update the user's email in FirebaseAuth and Firestore.
  /// Must reauthenticate using the current password before updating.
  Future<void> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    await _repository.updateEmail(
      newEmail: newEmail,
      currentPassword: currentPassword,
    );
    // State will be updated by userChanges() listener
  }

  /// Update the user's password in FirebaseAuth.
  /// Must reauthenticate using the current password before updating.
  Future<void> updatePassword({
    required String newPassword,
    required String currentPassword,
  }) async {
    await _repository.updatePassword(
      newPassword: newPassword,
      currentPassword: currentPassword,
    );
  }
}
