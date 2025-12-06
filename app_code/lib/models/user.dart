class User {

  final String uid;
  final bool isAnonymous;
  String? _providerId;
  String? email;
  String? _password;
  String? _userName;

  User({
    required this.uid,
    this.isAnonymous = false,
    providerId, 
    email, 
    password, 
    userName
  }): _providerId = providerId,
      _password = password,
      _userName = userName;

  String getProviderId() {
    return _providerId ?? '';
  }

  String getPassword() {
    return _password ?? '';
  }

  String getUserName() {
    return _userName ?? '';
  }

  int setPassword(String password) {
    this._password = password;
    return 1;
  }

  int setUserName(String userName) {
    this._userName = userName;
    return 1;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['id'],
      isAnonymous: json['is_anonymous'] ?? false,
      providerId: json['provider_id'],
      email: json['email'],
      password: json['password'],
      userName: json['user_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': uid,
      'is_anonymous': isAnonymous,
      'provider_id': _providerId,
      'email': email,
      'password': _password,
      'user_name': _userName,
    };
  }

}