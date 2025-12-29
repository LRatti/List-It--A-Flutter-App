import 'package:app_code/models/user.dart';
import 'package:app_code/repositories/abstract/auth_repository.dart';
import 'package:app_code/services/database/firebase/manage_user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase implementation of AuthRepository.
/// Directly handles all authentication operations with Firebase.
class FirebaseAuthRepository implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  @override
  Future<User?> ensureAuthenticated() async {
    // Check if a user is already signed in
    if (_firebaseAuth.currentUser != null) {
      // User is already signed in, return existing user
      return User(
        uid: _firebaseAuth.currentUser!.uid,
        isAnonymous: _firebaseAuth.currentUser!.isAnonymous,
        email: _firebaseAuth.currentUser!.email,
      );
    }

    // No user signed in, sign in anonymously
    return await signInAnonymously();
  }

  @override
  Future<User?> signInAnonymously() async {
    try {
      final firebase_auth.UserCredential credential = await _firebaseAuth
          .signInAnonymously();

      if (credential.user != null) {
        return User(
          uid: credential.user!.uid,
          isAnonymous: credential.user!.isAnonymous,
        );
      }
      return null;
    } catch (e) {
      print('Error signing in anonymously: ${e.toString()}');
      return null;
    }
  }

  @override
  Future<User?> signUp(String email, String password) async {
    try {
      final firebase_auth.UserCredential credential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (credential.user != null) {
        return User(
          uid: credential.user!.uid,
          isAnonymous: credential.user!.isAnonymous,
          email: credential.user!.email!,
        );
      }
      return null;
    } catch (e) {
      print('Error signing up with email and password: ${e.toString()}');
      return null;
    }
  }

  @override
  Future<User?> signIn(String email, String password) async {
    try {
      final firebase_auth.UserCredential credential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      if (credential.user != null) {
        return User(
          uid: credential.user!.uid,
          isAnonymous: credential.user!.isAnonymous,
          email: credential.user!.email!,
        );
      }
      return null;
    } catch (e) {
      print('Error signing in with email and password: ${e.toString()}');
      return null;
    }
  }

  @override
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Sign out first to force account selection every time
      await googleSignIn.signOut();

      // Perform interactive sign-in to let user choose account
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.signIn();
      } catch (e) {
        // On web, signIn is deprecated and may fail - that's expected
        // Users should authenticate via the Google Sign-In button in index.html
        print(
          'Interactive sign-in unavailable (expected on web): ${e.toString()}',
        );
        return null;
      }

      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final currentUser = _firebaseAuth.currentUser;

      // If the current user is anonymous, try upgrading by linking first.
      if (currentUser != null && currentUser.isAnonymous) {
        try {
          final firebase_auth.UserCredential linked = await currentUser
              .linkWithCredential(credential);

          if (linked.user != null) {
            await FirebaseUserManager().setUser(
              User(
                uid: linked.user!.uid,
                email: linked.user!.email!,
                userName: linked.user!.displayName ?? '',
              ),
            );
            return User(
              uid: linked.user!.uid,
              isAnonymous: linked.user!.isAnonymous,
              email: linked.user!.email!,
            );
          }
          return null;
        } on firebase_auth.FirebaseAuthException catch (e) {
          // If this Google credential already belongs to an existing account,
          // sign into that account instead of forcing a registration.
          if (e.code == 'credential-already-in-use') {
            final firebase_auth.UserCredential signedIn = await _firebaseAuth
                .signInWithCredential(credential);

            if (signedIn.user != null) {
              await FirebaseUserManager().setUser(
                User(
                  uid: signedIn.user!.uid,
                  email: signedIn.user!.email!,
                  userName: signedIn.user!.displayName ?? '',
                ),
              );
              return User(
                uid: signedIn.user!.uid,
                isAnonymous: signedIn.user!.isAnonymous,
                email: signedIn.user!.email!,
              );
            }
            return null;
          }

          print('Error upgrading anonymous user with Google: ${e.code}');
          return null;
        }
      }

      // Otherwise, perform a normal Google sign-in
      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      if (userCredential.user != null) {
        await FirebaseUserManager().setUser(
          User(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email!,
            userName: userCredential.user!.displayName ?? '',
          ),
        );
        return User(
          uid: userCredential.user!.uid,
          isAnonymous: userCredential.user!.isAnonymous,
          email: userCredential.user!.email!,
        );
      }
      return null;
    } catch (e) {
      print('Error signing in with Google: ${e.toString()}');
      return null;
    }
  }

  @override
  Future<User?> linkAnonymousWithEmailPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser == null || !currentUser.isAnonymous) {
        throw Exception('No anonymous user to link');
      }

      final credential = firebase_auth.EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      final firebase_auth.UserCredential userCredential = await currentUser
          .linkWithCredential(credential);

      if (userCredential.user != null) {
        // Send email verification
        await userCredential.user!.sendEmailVerification();

        await FirebaseUserManager().setUser(
          User(uid: userCredential.user!.uid, email: email, userName: username),
        );
        return User(
          uid: userCredential.user!.uid,
          isAnonymous: userCredential.user!.isAnonymous,
          email: userCredential.user!.email!,
        );
      }
      return null;
    } catch (e) {
      print('Error linking anonymous user: ${e.toString()}');
      return null;
    }
  }

  // Removed: linkAnonymousWithGoogle(). Anonymous upgrade is handled inside signInWithGoogle.

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await signInAnonymously();
  }

  @override
  User? getCurrentUser() {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      return User(
        uid: currentUser.uid,
        isAnonymous: currentUser.isAnonymous,
        email: currentUser.email,
      );
    }
    return null;
  }

  @override
  bool canUpdateCredentials() {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.isAnonymous) return false;
    final providers = user.providerData.map((p) => p.providerId).toList();
    final isGoogle = providers.contains('google.com');
    final isPassword = providers.contains('password');
    return !isGoogle && isPassword;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      // Do not leak details; rethrow a generic error for UI handling if needed
      print('Error sending password reset email: ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<void> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    if (!canUpdateCredentials()) {
      throw Exception('Email update not allowed for Google accounts');
    }

    final email = user.email;
    if (email == null) {
      throw Exception('Current email not available');
    }

    // Reauthenticate with current email and password
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // Update email in Firebase Auth and send verification email
    await user.verifyBeforeUpdateEmail(newEmail);

    // Update Firestore user document preserving username
    final uid = user.uid;
    final manager = FirebaseUserManager();
    final existing = await manager.getUserById(uid);
    final updated = User(
      uid: uid,
      email: newEmail,
      userName: existing?.getUserName() ?? '',
    );
    await manager.setUser(updated);

    // Do NOT sign out - user will be navigated to verification screen
  }

  @override
  Future<void> updatePassword({
    required String newPassword,
    required String currentPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    if (!canUpdateCredentials()) {
      throw Exception('Password update not allowed for Google accounts');
    }

    final email = user.email;
    if (email == null) {
      throw Exception('Current email not available');
    }

    // Reauthenticate first
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // Update password in Firebase Auth
    await user.updatePassword(newPassword);

    // Force reauthentication by signing out
    await signOut();
  }

  @override
  Future<void> abortEmailVerification({required bool isNewSignup}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    if (isNewSignup) {
      // For new signup: delete the account and sign in anonymously
      try {
        // Delete user from Firestore first
        await FirebaseUserManager().deleteUser(user.uid);
        
        // Delete the Firebase Auth account
        await user.delete();
        
        // Sign in anonymously
        await signInAnonymously();
      } catch (e) {
        print('Error aborting new signup: ${e.toString()}');
        throw Exception('Failed to abort signup: $e');
      }
    } else {
        final email = user.email;
        if (email == null) {
          throw Exception('Current email not available');
        } 
        //Restore the original email in firestore
        final manager = FirebaseUserManager();
        final existing = await manager.getUserById(user.uid);
        final updated = User(
          uid: user.uid,
          email: email,
          userName: existing?.getUserName() ?? '',
        );
        await manager.setUser(updated);
    }
  }
}
