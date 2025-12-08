import 'package:app_code/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseUserManager {

  final _db = FirebaseFirestore.instance.collection("Users");

  Future<void> createUpdateUser(User user) async { //to be awaited when called
    await _db.doc(user.uid).set(user.toJson())
      .whenComplete(  () => print("User created successfully"))
      .catchError((error) => print("Failed to create user: $error"));
  }

  Future<User?> getUserDetails(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _db.doc(uid).get();
      if (doc.exists) {
        return User.fromJson(doc);
      } else {
        print("User with uid $uid does not exist.");
        return null;
      }
    } catch (e) {
      print("Error fetching user: $e");
      return null;
    }
  }

   

}
