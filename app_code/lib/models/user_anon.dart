class UserAnon {
  final String uid;
  final DateTime createdAt;

  UserAnon({
    required this.uid,
    required this.createdAt,
  });

  factory UserAnon.fromJson(Map<String, dynamic> json) {
    return UserAnon(
      uid: json['uid'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}