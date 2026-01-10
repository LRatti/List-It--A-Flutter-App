import 'package:app_code/models/user.dart';
import 'package:app_code/services/database/firebase/manage_user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class UserManager {
  static final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  Future<User?> getUserData() async {
    //Firebase
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid != null) {
      return FirebaseUserManager().getUserById(uid);
    } else {
      return null;
    }
  }

  Future<void> setUserData(User user) async {
    //Firebase
    await FirebaseUserManager().setUser(user);
  }
}