import 'package:app_code/models/user.dart';
import 'package:app_code/repositories/abstract/auth_repository.dart';

/// In-memory authentication repository used only for widget tests.
/// Simulates authentication operations without Firebase.
class InMemoryAuthRepository implements AuthRepository {
  User? _currentUser;
  final Map<String, String> _userCredentials = {}; // email -> password
  final Map<String, User> _registeredUsers = {}; // email -> User
  bool _shouldFailSignIn = false;
  bool _shouldFailSignUp = false;
  bool _shouldFailGoogleSignIn = false;

  /// Configure the mock to fail on next sign in attempt
  void setSignInFailure(bool shouldFail) {
    _shouldFailSignIn = shouldFail;
  }

  /// Configure the mock to fail on next sign up attempt
  void setSignUpFailure(bool shouldFail) {
    _shouldFailSignUp = shouldFail;
  }

  /// Configure the mock to fail on next Google sign in attempt
  void setGoogleSignInFailure(bool shouldFail) {
    _shouldFailGoogleSignIn = shouldFail;
  }

  /// Register a test user manually (for testing existing accounts)
  void registerTestUser(String email, String password, {String? username}) {
    final user = User(
      uid: 'test-uid-${email.hashCode}',
      email: email,
      userName: username ?? email.split('@').first,
      isAnonymous: false,
    );
    _userCredentials[email] = password;
    _registeredUsers[email] = user;
  }

  @override
  Future<User?> ensureAuthenticated() async {
    if (_currentUser != null) {
      return _currentUser;
    }
    return await signInAnonymously();
  }

  @override
  Future<User?> signInAnonymously() async {
    _currentUser = User(
      uid: 'anonymous-${DateTime.now().millisecondsSinceEpoch}',
      isAnonymous: true,
    );
    return _currentUser;
  }

  @override
  Future<User?> signUp(String email, String password) async {
    if (_shouldFailSignUp) {
      _shouldFailSignUp = false; // Reset after use
      return null;
    }

    if (_userCredentials.containsKey(email)) {
      return null; // User already exists
    }

    final user = User(
      uid: 'uid-${email.hashCode}',
      email: email,
      isAnonymous: false,
    );

    _userCredentials[email] = password;
    _registeredUsers[email] = user;
    _currentUser = user;

    return user;
  }

  @override
  Future<User?> signIn(String email, String password) async {
    if (_shouldFailSignIn) {
      _shouldFailSignIn = false; // Reset after use
      throw Exception('Sign in failed');
    }

    if (_userCredentials[email] == password) {
      _currentUser = _registeredUsers[email];
      return _currentUser;
    }

    throw Exception('Invalid credentials'); // Invalid credentials
  }

  @override
  Future<User?> signInWithGoogle() async {
    if (_shouldFailGoogleSignIn) {
      _shouldFailGoogleSignIn = false; // Reset after use
      return null;
    }

    final user = User(
      uid: 'google-uid-${DateTime.now().millisecondsSinceEpoch}',
      email: 'testuser@gmail.com',
      userName: 'Test User',
      isAnonymous: false,
    );

    _currentUser = user;
    return user;
  }

  @override
  Future<User?> linkAnonymousWithEmailPassword(
    String email,
    String password,
    String username,
  ) async {
    if (_currentUser == null || !_currentUser!.isAnonymous) {
      return null;
    }

    if (_shouldFailSignUp) {
      _shouldFailSignUp = false;
      return null;
    }

    final user = User(
      uid: _currentUser!.uid,
      email: email,
      userName: username,
      isAnonymous: false,
    );

    _userCredentials[email] = password;
    _registeredUsers[email] = user;
    _currentUser = user;

    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    await signInAnonymously();
  }

  @override
  User? getCurrentUser() {
    return _currentUser;
  }

  @override
  bool canUpdateCredentials() {
    // In-memory implementation always allows credential updates for non-anonymous users
    return _currentUser != null && !_currentUser!.isAnonymous;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // In memory: simulate success without leaking if the email exists.
    // No-op to mirror Firebase's behavior.
    return;
  }

  @override
  Future<void> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    if (_currentUser == null || _currentUser!.isAnonymous) {
      throw Exception('No authenticated user');
    }

    final currentEmail = _currentUser!.email;
    if (currentEmail == null) {
      throw Exception('Current email not available');
    }

    // Verify current password
    if (_userCredentials[currentEmail] != currentPassword) {
      throw Exception('Invalid password');
    }

    // Update email
    final updatedUser = User(
      uid: _currentUser!.uid,
      email: newEmail,
      userName: _currentUser!.getUserName(),
      isAnonymous: false,
    );

    // Update internal maps
    _userCredentials.remove(currentEmail);
    _userCredentials[newEmail] = currentPassword;
    _registeredUsers.remove(currentEmail);
    _registeredUsers[newEmail] = updatedUser;
    _currentUser = updatedUser;
  }

  @override
  Future<void> updatePassword({
    required String newPassword,
    required String currentPassword,
  }) async {
    if (_currentUser == null || _currentUser!.isAnonymous) {
      throw Exception('No authenticated user');
    }

    final currentEmail = _currentUser!.email;
    if (currentEmail == null) {
      throw Exception('Current email not available');
    }

    // Verify current password
    if (_userCredentials[currentEmail] != currentPassword) {
      throw Exception('Invalid password');
    }

    // Update password
    _userCredentials[currentEmail] = newPassword;

    // Sign out after password change (matching Firebase behavior)
    await signOut();
  }

  @override
  Future<void> abortEmailVerification({required bool isNewSignup}) async {
    if (isNewSignup) {
      // For new signup: clear the current user and sign in anonymously
      _currentUser = null;
      await signInAnonymously();
    } else {
      // For email update: just do nothing, user stays signed in with original email
    }
  }

  /// Clear all state (useful for test cleanup)
  void reset() {
    _currentUser = null;
    _userCredentials.clear();
    _registeredUsers.clear();
    _shouldFailSignIn = false;
    _shouldFailSignUp = false;
    _shouldFailGoogleSignIn = false;
  }
}
