import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_code/utils/helper.dart';

class User {

  String? uid;
  final bool isAnonymous;
  String? email;
  String? _userName;
  late DateTime? lastModified;
  late DateTime createdAt;
  bool isDeleted;

  User({
    String? uid,
    this.isAnonymous = false,
    this.email, 
    String? userName,
    DateTime? lastModified,
    DateTime? createdAt,
    bool isDeleted = false,
  }): 
      _userName = userName,
      uid = uid ?? Helper.generateId(),
      createdAt = createdAt ?? DateTime.now(),
      isDeleted = isDeleted {
    this.uid = uid;
  }
      
  String getUserName() {
    return _userName ?? '';
  }

  int setUserName(String userName) {
    this._userName = userName;
    return 1;
  }

  factory User.fromDatabase(DocumentSnapshot<Map<String, dynamic>> json) {
    return User(
      uid: json.id,
      email: json['email'],
      userName: json['user_name'],
      lastModified: DateTime.tryParse(json['last_modified'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': uid,
      'email': email,
      'user_name': _userName,
      'last_modified': lastModified?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory User.fromJson(DocumentSnapshot<Map<String, dynamic>> json) {
    return User(
      uid: json.id,
      isAnonymous: json['is_anonymous'] ?? false,
      email: json['email'],
      userName: json['user_name'],
      lastModified: DateTime.tryParse(json['lastModified'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': uid,
      'is_anonymous': isAnonymous,
      'email': email,
      'user_name': _userName,
      'lastModified': lastModified?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }
}