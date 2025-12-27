import 'package:app_code/models/user.dart';

/// Abstract repository for authentication operations.
/// This allows for both Firebase and mock implementations.
abstract class AuthRepository {
  /// Ensure a user is authenticated, sign in anonymously if not
  Future<User?> ensureAuthenticated();

  /// Sign in anonymously without email and password
  Future<User?> signInAnonymously();

  /// Sign up a new user with email and password
  Future<User?> signUp(String email, String password);

  /// Sign in with email and password
  Future<User?> signIn(String email, String password);

  /// Sign in with Google
  Future<User?> signInWithGoogle();

  /// Convert anonymous user to permanent account with email/password
  Future<User?> linkAnonymousWithEmailPassword(String email, String password, String username);

  /// Sign out and transition to anonymous authentication
  Future<void> signOut();

  /// Get the current user if authenticated
  User? getCurrentUser();

  /// Whether current user can update email/password (non-Google, non-anonymous)
  bool canUpdateCredentials();

  /// Update the user's email in FirebaseAuth and Firestore.
  /// Must reauthenticate using the current password before updating.
  Future<void> updateEmail({required String newEmail, required String currentPassword});

  /// Update the user's password in FirebaseAuth.
  /// Must reauthenticate using the current password before updating.
  Future<void> updatePassword({required String newPassword, required String currentPassword});

  /// Abort the email verification process
  /// If [isNewSignup] is true, deletes the user account and signs in anonymously
  /// If [isNewSignup] is false, just returns to app without signing out
  Future<void> abortEmailVerification({required bool isNewSignup});
}
