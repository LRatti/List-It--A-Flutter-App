import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:app_code/models/user.dart';

class AuthService {

  static final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;

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
      return null;
    }
  }

  // logging out
  static Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

}