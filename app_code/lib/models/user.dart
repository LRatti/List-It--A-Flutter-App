class User {

  final String uid;
  String? _providerId;
  String? email;
  String? _password;
  String? _userName;

  User({
    required this.uid, 
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
      providerId: json['provider_id'],
      email: json['email'],
      password: json['password'],
      userName: json['user_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': uid,
      'provider_id': _providerId,
      'email': email,
      'password': _password,
      'user_name': _userName,
    };
  }

}