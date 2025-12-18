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

  /// Convert anonymous user to permanent account with Google
  Future<User?> linkAnonymousWithGoogle();

  /// Sign out and transition to anonymous authentication
  Future<void> signOut();

  /// Get the current user if authenticated
  User? getCurrentUser();
}
