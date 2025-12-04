import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:app_code/models/user.dart';

class AuthService {

  static final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;

  // Ensure a user is authenticated, sign in anonymously if not
  static Future<User?> ensureAuthenticated() async {
    // Check if a user is already signed in
    if (_firebaseAuth.currentUser != null) {
      // User is already signed in, return existing user
      return User(
        uid: _firebaseAuth.currentUser!.uid,
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
          email: credential.user!.email!
        );
      }
      return null;

    } catch (e) {
      print('Error signing in with email and password: ${e.toString()}');
      return null;
    }
  }

  // logging out
  static Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

}