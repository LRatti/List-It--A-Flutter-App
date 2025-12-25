import 'package:app_code/models/user.dart';
import 'package:app_code/repositories/abstract/auth_repository.dart';
import 'package:app_code/services/auth_service.dart';

/// Firebase implementation of AuthRepository.
/// Wraps the existing AuthService static methods.
class FirebaseAuthRepository implements AuthRepository {
  @override
  Future<User?> ensureAuthenticated() {
    return AuthService.ensureAuthenticated();
  }

  @override
  Future<User?> signInAnonymously() {
    return AuthService.signInAnonymously();
  }

  @override
  Future<User?> signUp(String email, String password) {
    return AuthService.signUp(email, password);
  }

  @override
  Future<User?> signIn(String email, String password) {
    return AuthService.signIn(email, password);
  }

  @override
  Future<User?> signInWithGoogle() {
    return AuthService.signInWithGoogle();
  }

  @override
  Future<User?> linkAnonymousWithEmailPassword(
      String email, String password, String username) {
    return AuthService.linkAnonymousWithEmailPassword(email, password, username);
  }

  @override
  Future<User?> linkAnonymousWithGoogle() {
    return AuthService.linkAnonymousWithGoogle();
  }

  @override
  Future<void> signOut() {
    return AuthService.signOut();
  }

  @override
  User? getCurrentUser() {
    // AuthService doesn't have a getCurrentUser method, so return null
    // In production, you might want to add this to AuthService
    return null;
  }
}
