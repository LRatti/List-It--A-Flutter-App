import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_code/utils/helper.dart';

class User {

  String? uid;
  final bool isAnonymous;
  String? email;
  String? _userName;

  User({
    String? uid,
    this.isAnonymous = false,
    this.email, 
    String? userName, 
  }): 
      _userName = userName,
      uid = uid ?? Helper.generateId() {
    this.uid = uid;
  }
      
  String getUserName() {
    return _userName ?? '';
  }

  int setUserName(String userName) {
    this._userName = userName;
    return 1;
  }

  factory User.fromJson(DocumentSnapshot<Map<String, dynamic>> json) {
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