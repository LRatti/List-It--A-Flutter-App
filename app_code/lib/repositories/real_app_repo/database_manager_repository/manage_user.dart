import 'package:app_code/models/user.dart';
import 'package:app_code/services/database/firebase/manage_user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Database Manager for User - Firebase-only feature
/// 
/// Note: SQLite manage_user.dart is empty, indicating user data is only stored in Firebase.
/// This makes sense as user authentication is handled by Firebase Auth,
/// and user profile data should be centralized in the cloud.
///
/// This class implements a simplified pattern since SQLite is not involved.
class UserDatabaseManager {
  final FirebaseUserManager _firebaseManager;
  final firebase_auth.FirebaseAuth _firebaseAuth;

  UserDatabaseManager({
    FirebaseUserManager? firebaseManager,
    firebase_auth.FirebaseAuth? firebaseAuth,
  })  : _firebaseManager = firebaseManager ?? FirebaseUserManager(),
        _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  /// Get user data from Firebase
  Future<User?> getUserData() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid != null) {
      return await _firebaseManager.getUserById(uid);
    } else {
      return null;
    }
  }

  /// Set/update user data in Firebase
  Future<void> setUserData(User user) async {
    await _firebaseManager.setUser(user);
  }

  /// Get user by ID from Firebase
  Future<User?> getUserById(String uid) async {
    return await _firebaseManager.getUserById(uid);
  }

  /// Delete user from Firebase
  Future<void> deleteUser(String uid) async {
    await _firebaseManager.deleteUser(uid);
  }
}
