import 'package:app_code/services/database/firebase/manage_user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:app_code/models/user.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {

  static final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;

  // Ensure a user is authenticated, sign in anonymously if not
  static Future<User?> ensureAuthenticated() async {
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

  //log in without email and password
  static Future<User?> signInAnonymously() async {
    try {
      final firebase_auth.UserCredential credential = await _firebaseAuth.signInAnonymously();

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

  // sign up a new user
  static Future<User?> signUp(String email, String password) async {

    try {
      final firebase_auth.UserCredential credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

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

  // logging in
  static Future<User?> signIn(String email, String password) async {

    try {
      final firebase_auth.UserCredential credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return User(
          uid: credential.user!.uid,
          isAnonymous: credential.user!.isAnonymous,
          email: credential.user!.email!
        );
      }
      return null;

    } catch (e) {
      print('Error signing in with email and password: ${e.toString()}');
      return null;
    }
  }

  //google sign in - always prompts for account selection
  //TODO: test on IOS simulator
  static Future<User?> signInWithGoogle() async {
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
        print('Interactive sign-in unavailable (expected on web): ${e.toString()}');
        return null;
      }
      
      if (googleUser == null) return null; // User cancelled
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final firebase_auth.UserCredential userCredential = 
          await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        await FirebaseUserManager().createUpdateUser(
          User(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email!,
            userName: userCredential.user!.displayName ?? '',
          )
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

  // Convert anonymous user to permanent account with email/password
  static Future<User?> linkAnonymousWithEmailPassword(String email, String password, String username) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      
      if (currentUser == null || !currentUser.isAnonymous) {
        throw Exception('No anonymous user to link');
      }

      final credential = firebase_auth.EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      final firebase_auth.UserCredential userCredential = 
          await currentUser.linkWithCredential(credential);

      if (userCredential.user != null) {
        await FirebaseUserManager().createUpdateUser(
          User(
            uid: userCredential.user!.uid,
            email: email,
            userName: username,
          )
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

  // Convert anonymous user to permanent account with Google
  static Future<User?> linkAnonymousWithGoogle() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      
      if (currentUser == null || !currentUser.isAnonymous) {
        throw Exception('No anonymous user to link');
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      
      // Sign out first to force account selection
      await googleSignIn.signOut();
      
      // Perform interactive sign-in
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.signIn();
      } catch (e) {
        print('Interactive sign-in unavailable (expected on web): ${e.toString()}');
        return null;
      }
      
      if (googleUser == null) return null; // User cancelled
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final firebase_auth.UserCredential userCredential = 
          await currentUser.linkWithCredential(credential);
      
      if (userCredential.user != null) {
        await FirebaseUserManager().createUpdateUser(
          User(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email!,
            userName: userCredential.user!.displayName ?? '',
          )
        );
        return User(
          uid: userCredential.user!.uid,
          isAnonymous: userCredential.user!.isAnonymous,
          email: userCredential.user!.email!,
        );
      }
      return null;
    } catch (e) {
      print('Error linking anonymous user with Google: ${e.toString()}');
      return null;
    }
  }

  // logging out - signs out and transitions to anonymous authentication
  static Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await signInAnonymously();
  }

}