import 'package:cloud_firestore/cloud_firestore.dart';

class User {

  final String uid;
  final bool isAnonymous;
  String? email;
  String? _userName;

  User({
    required this.uid,
    this.isAnonymous = false,
    this.email, 
    userName, 
  }): 
      _userName = userName;

  String getUserName() {
    return _userName ?? '';
  }

  int setUserName(String userName) {
    this._userName = userName;
    return 1;
  }

  factory User.fromJson(DocumentSnapshot<Map<String, dynamic>> json) {
    final data = json.data()!;
    return User(
      uid: json.id,
      email: json['email'],
      userName: json['user_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': uid,
      'email': email,
      'user_name': _userName,
    };
  }

}