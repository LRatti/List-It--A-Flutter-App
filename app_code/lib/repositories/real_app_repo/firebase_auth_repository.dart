import 'package:app_code/models/user.dart';
import 'package:app_code/repositories/abstract/auth_repository.dart';
import 'package:app_code/services/database/firebase/manage_user.dart';
import 'package:app_code/utils/auth_logger.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase implementation of AuthRepository.
/// Directly handles all authentication operations with Firebase.
class FirebaseAuthRepository implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  @override
  Future<User?> ensureAuthenticated() async {
    AuthLogger.info('Checking current auth user');
    // Check if a user is already signed in
    if (_firebaseAuth.currentUser != null) {
      AuthLogger.info(
        'Existing Firebase user found',
        data: {
          'isAnonymous': _firebaseAuth.currentUser!.isAnonymous,
          'email': AuthLogger.maskEmail(_firebaseAuth.currentUser!.email),
        },
      );
      // User is already signed in, return existing user
      return User(
        uid: _firebaseAuth.currentUser!.uid,
        isAnonymous: _firebaseAuth.currentUser!.isAnonymous,
        email: _firebaseAuth.currentUser!.email,
      );
    }

    // No user signed in, sign in anonymously
    AuthLogger.info('No current user, signing in anonymously');
    return await signInAnonymously();
  }

  @override
  Future<User?> signInAnonymously() async {
    try {
      AuthLogger.info('Attempting anonymous sign-in');
      final firebase_auth.UserCredential credential = await _firebaseAuth
          .signInAnonymously();

      if (credential.user != null) {
        AuthLogger.info(
          'Anonymous sign-in succeeded',
          data: {'uid': credential.user!.uid},
        );
        return User(
          uid: credential.user!.uid,
          isAnonymous: credential.user!.isAnonymous,
        );
      }
      AuthLogger.warning('Anonymous sign-in returned null user');
      return null;
    } catch (e, stackTrace) {
      AuthLogger.error(
        'Error signing in anonymously',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<User?> signUp(String email, String password) async {
    try {
      AuthLogger.info(
        'Starting email sign-up',
        data: {'email': AuthLogger.maskEmail(email)},
      );
      final firebase_auth.UserCredential credential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (credential.user != null) {
        // final uid = credential.user!.uid;
        // final userEmail = credential.user!.email;
        
        // // Create Firestore document for the new user
        // await FirebaseUserManager().setUser(
        //   User(
        //     uid: uid,
        //     email: userEmail,
        //     userName: '', // Empty username, user can set it later
        //   ),
        // );
        
        AuthLogger.info(
          'Email sign-up succeeded',
          data: {'uid': credential.user!.uid},
        );
        return User(
          uid: credential.user!.uid,
          //uid: uid,
          isAnonymous: credential.user!.isAnonymous,
          email: credential.user!.email!,
          //email: userEmail,
        );
      }
      AuthLogger.warning('Email sign-up returned null user');
      return null;
    } catch (e, stackTrace) {
      AuthLogger.error(
        'Error signing up with email and password',
        error: e,
        stackTrace: stackTrace,
        data: {'email': AuthLogger.maskEmail(email)},
      );
      return null;
    }
  }

  @override
  Future<User?> signIn(String email, String password) async {
    try {
      AuthLogger.info(
        'Starting email sign-in',
        data: {'email': AuthLogger.maskEmail(email)},
      );
      final firebase_auth.UserCredential credential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      if (credential.user != null) {
        // final uid = credential.user!.uid;
        // final userEmail = credential.user!.email;
        
        // // Ensure Firestore document exists for this user
        // // Fetch existing data to preserve username if it exists
        // final manager = FirebaseUserManager();
        // final existingUser = await manager.getUserById(uid);
        
        // // Create or update the Firestore document
        // await manager.setUser(
        //   User(
        //     uid: uid,
        //     email: userEmail,
        //     userName: existingUser?.getUserName() ?? '',
        //   ),
        // );
        
        AuthLogger.info(
          'Email sign-in succeeded',
          data: {'uid': credential.user!.uid},
        );
        return User(
          uid: credential.user!.uid,
          //uid: uid,
          isAnonymous: credential.user!.isAnonymous,
          email: credential.user!.email!,
          //email: userEmail,
        );
      }
      AuthLogger.warning('Email sign-in returned null user');
      return null;
    } catch (e, stackTrace) {
      AuthLogger.error(
        'Error signing in with email and password',
        error: e,
        stackTrace: stackTrace,
        data: {'email': AuthLogger.maskEmail(email)},
      );
      return null;
    }
  }

  @override
  Future<User?> signInWithGoogle() async {
    try {
      AuthLogger.info('Starting Google sign-in');
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Sign out first to force account selection every time
      AuthLogger.debug('Signing out of Google to force account selection');
      await googleSignIn.signOut();

      // Perform interactive sign-in to let user choose account
      GoogleSignInAccount? googleUser;

      try {
        googleUser = await googleSignIn.signIn();
      } catch (e) {
        // On web, signIn is deprecated and may fail - that's expected
        // Users should authenticate via the Google Sign-In button in index.html
        AuthLogger.warning(
          'Interactive Google sign-in unavailable',
          data: {'error': e.toString()},
        );
        return null;
      }

      if (googleUser == null) {
        AuthLogger.warning('Google sign-in cancelled by user');
        return null;
      }

      AuthLogger.info('Google account selected');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final currentUser = _firebaseAuth.currentUser;

      // If the current user is anonymous, try upgrading by linking first.
      if (currentUser != null && currentUser.isAnonymous) {
        AuthLogger.info('Attempting anonymous account upgrade with Google');
        try {
          final firebase_auth.UserCredential linked = await currentUser
              .linkWithCredential(credential);

          if (linked.user != null) {
            AuthLogger.info(
              'Anonymous account upgraded with Google',
              data: {'uid': linked.user!.uid},
            );
            await FirebaseUserManager().setUser(
              User(
                uid: linked.user!.uid,
                email: linked.user!.email!,
                userName: googleUser.displayName ?? '',
              ),
            );
            return User(
              uid: linked.user!.uid,
              isAnonymous: linked.user!.isAnonymous,
              email: linked.user!.email!,
            );
          }
          AuthLogger.warning('Anonymous upgrade returned null user');
          return null;
        } on firebase_auth.FirebaseAuthException catch (e) {
          // If this Google credential already belongs to an existing account,
          // sign into that account instead of forcing a registration.
          if (e.code == 'credential-already-in-use') {
            AuthLogger.warning('Google credential already in use, signing in');
            final firebase_auth.UserCredential signedIn = await _firebaseAuth
                .signInWithCredential(credential);

            if (signedIn.user != null) {
              AuthLogger.info(
                'Signed in with existing Google credential',
                data: {'uid': signedIn.user!.uid},
              );
              await FirebaseUserManager().setUser(
                User(
                  uid: signedIn.user!.uid,
                  email: signedIn.user!.email!,
                  userName: googleUser.displayName ?? '',
                ),
              );
              return User(
                uid: signedIn.user!.uid,
                isAnonymous: signedIn.user!.isAnonymous,
                email: signedIn.user!.email!,
              );
            }
            AuthLogger.warning('Sign-in with existing Google credential failed');
            return null;
          }

        } catch (e, stackTrace) {
          AuthLogger.error(
            'Unexpected error during anonymous upgrade',
            error: e,
            stackTrace: stackTrace,
          );
          return null;
        }
      }

      // Otherwise, perform a normal Google sign-in
      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      if (userCredential.user != null) {
        AuthLogger.info(
          'Google sign-in with credential succeeded',
          data: {'uid': userCredential.user!.uid},
        );
        await FirebaseUserManager().setUser(
          User(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email!,
            userName: googleUser.displayName ?? '',
          ),
        );
        return User(
          uid: userCredential.user!.uid,
          isAnonymous: userCredential.user!.isAnonymous,
          email: userCredential.user!.email!,
        );
      }
      AuthLogger.warning('Google sign-in returned null user');
      return null;
    } catch (e, stackTrace) {
      AuthLogger.error(
        'Error signing in with Google',
        error: e,
        stackTrace: stackTrace,
      );
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
      AuthLogger.info(
        'Linking anonymous user with email and password',
        data: {'email': AuthLogger.maskEmail(email)},
      );
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
        AuthLogger.info(
          'Anonymous user linked successfully',
          data: {'uid': userCredential.user!.uid},
        );
        return User(
          uid: userCredential.user!.uid,
          isAnonymous: userCredential.user!.isAnonymous,
          email: userCredential.user!.email!,
        );
      }
      AuthLogger.warning('Anonymous linking returned null user');
      return null;
    } catch (e, stackTrace) {
      AuthLogger.error(
        'Error linking anonymous user',
        error: e,
        stackTrace: stackTrace,
        data: {'email': AuthLogger.maskEmail(email)},
      );
      return null;
    }
  }

  // Removed: linkAnonymousWithGoogle(). Anonymous upgrade is handled inside signInWithGoogle.

  @override
  Future<void> signOut() async {
    AuthLogger.info('Signing out from FirebaseAuthRepository');
    await _firebaseAuth.signOut();
    await signInAnonymously();
    AuthLogger.info('Sign-out complete, anonymous session started');
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
      AuthLogger.info(
        'Sending password reset email',
        data: {'email': AuthLogger.maskEmail(email)},
      );
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      AuthLogger.info('Password reset email sent');
    } catch (e) {
      // Do not leak details; rethrow a generic error for UI handling if needed
      AuthLogger.error(
        'Error sending password reset email',
        error: e,
        data: {'email': AuthLogger.maskEmail(email)},
      );
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
        AuthLogger.info(
          'Aborting new signup: deleting user and signing in anonymously',
          data: {'uid': user.uid},
        );
        // Delete user from Firestore first
        await FirebaseUserManager().deleteUser(user.uid);
        
        // Delete the Firebase Auth account
        await user.delete();
        
        // Sign in anonymously
        await signInAnonymously();
        AuthLogger.info('New signup aborted successfully');
      } catch (e) {
        AuthLogger.error(
          'Error aborting new signup',
          error: e,
          data: {'uid': user.uid},
        );
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
        AuthLogger.info(
          'Email verification aborted for existing user',
          data: {'uid': user.uid},
        );
    }
  }
}
