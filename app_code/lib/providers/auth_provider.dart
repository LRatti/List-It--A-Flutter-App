import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/user.dart';
import 'package:app_code/repositories/abstract/auth_repository.dart';
import 'package:app_code/repositories/real_app_repo/firebase_auth_repository.dart';
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
    
    // Listen to Firebase auth state changes
    // Use userChanges() instead of authStateChanges() to detect credential linking
    // userChanges() emits when user properties change (like isAnonymous, email, etc.)
    firebase_auth.FirebaseAuth.instance.userChanges().listen((firebaseUser) {
      if (firebaseUser != null) {
        state = AsyncData(User(
          uid: firebaseUser.uid,
          isAnonymous: firebaseUser.isAnonymous,
          email: firebaseUser.email,
        ));
      } else {
        state = AsyncData(null);
      }
    });
    
    // Return the current user on initial load
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      return User(
        uid: currentUser.uid,
        isAnonymous: currentUser.isAnonymous,
        email: currentUser.email,
      );
    }
    return null;
  }

  /// Ensure a user is authenticated, sign in anonymously if not
  Future<void> ensureAuthenticated() async {
    final user = await _repository.ensureAuthenticated();
    if (user != null) {
      state = AsyncData(user);
    }
  }

  /// Sign in anonymously without email and password
  Future<void> signInAnonymously() async {
    final user = await _repository.signInAnonymously();
    if (user != null) {
      state = AsyncData(user);
    }
  }

  /// Sign up a new user with email and password
  Future<void> signUp(String email, String password) async {
    final user = await _repository.signUp(email, password);
    if (user != null) {
      state = AsyncData(user);
    }
  }

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    final user = await _repository.signIn(email, password);
    if (user != null) {
      state = AsyncData(user);
    } else {
      // Surface an error so callers can avoid navigating on failed login
      throw Exception('Invalid email or password');
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    final user = await _repository.signInWithGoogle();
    if (user != null) {
      state = AsyncData(user);
    }
  }

  /// Convert anonymous user to permanent account with email/password
  Future<void> linkAnonymousWithEmailPassword(
      String email, String password, String username) async {
    final user = await _repository.linkAnonymousWithEmailPassword(email, password, username);
    if (user != null) {
      state = AsyncData(user);
    } else {
      throw Exception('Failed to link anonymous user');
    }
  }

  /// Sign out and transition to anonymous authentication
  Future<void> signOut() async {
    await _repository.signOut();
    // signOut() signs in anonymously inside the repository; refresh state accordingly
    final user = _repository.getCurrentUser();
    state = AsyncData(user);
  }

  /// Abort email verification process
  /// If [isNewSignup] is true, deletes the account and signs in anonymously
  /// If [isNewSignup] is false, just stays signed in with original email
  Future<void> abortEmailVerification({required bool isNewSignup}) async {
    await _repository.abortEmailVerification(isNewSignup: isNewSignup);
    
    if (isNewSignup) {
      // After deleting account and signing in anonymously
      final user = _repository.getCurrentUser();
      state = AsyncData(user);
    }
    // For email updates, user state remains unchanged
  }
}