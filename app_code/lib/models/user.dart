class User {

  final int id;
  String? providerId;
  String? email;
  String? password;
  String? userName;

  User({required this.id, this.providerId, this.email, this.password, this.userName});

  int getId() {
    return id;
  }

  String getProviderId() {
    return providerId ?? '';
  }

  String getEmail() {
    return email ?? '';
  }

  String getPassword() {
    return password ?? '';
  }

  String getUserName() {
    return userName ?? '';
  }

  int setPassword(String password) {
    this.password = password;
    return 1;
  }

  int setEmail(String email) {
    this.email = email;
    return 1;
  }

  int setUserName(String userName) {
    this.userName = userName;
    return 1;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      providerId: json['provider_id'],
      email: json['email'],
      password: json['password'],
      userName: json['user_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'email': email,
      'password': password,
      'user_name': userName,
    };
  }

}