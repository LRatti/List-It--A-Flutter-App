import 'package:app_code/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManager {

  final _db = FirebaseFirestore.instance;

  createUpdateUser(User user) async { //to be awaited when called
    await _db.collection("Users").doc(user.uid).set(user.toJson())
      .whenComplete(  () => print("User created successfully"))
      .catchError((error) => print("Failed to create user: $error"));
  }

}