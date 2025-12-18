import 'package:app_code/models/user.dart';
import 'package:app_code/repositories/abstract/auth_repository.dart';

/// Controller for authentication operations.
/// Uses dependency injection to allow for both Firebase and mock implementations.
class AuthController {
  final AuthRepository _repository;

  AuthController(this._repository);

  /// Ensure a user is authenticated, sign in anonymously if not
  Future<User?> ensureAuthenticated() {
    return _repository.ensureAuthenticated();
  }

  /// Sign in anonymously without email and password
  Future<User?> signInAnonymously() {
    return _repository.signInAnonymously();
  }

  /// Sign up a new user with email and password
  Future<User?> signUp(String email, String password) {
    return _repository.signUp(email, password);
  }

  /// Sign in with email and password
  Future<User?> signIn(String email, String password) {
    return _repository.signIn(email, password);
  }

  /// Sign in with Google
  Future<User?> signInWithGoogle() {
    return _repository.signInWithGoogle();
  }

  /// Convert anonymous user to permanent account with email/password
  Future<User?> linkAnonymousWithEmailPassword(
      String email, String password, String username) {
    return _repository.linkAnonymousWithEmailPassword(email, password, username);
  }

  /// Convert anonymous user to permanent account with Google
  Future<User?> linkAnonymousWithGoogle() {
    return _repository.linkAnonymousWithGoogle();
  }

  /// Sign out and transition to anonymous authentication
  Future<void> signOut() {
    return _repository.signOut();
  }

  /// Get the current user if authenticated
  User? getCurrentUser() {
    return _repository.getCurrentUser();
  }
}
