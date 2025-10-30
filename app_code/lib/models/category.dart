class Category {

  final String _id;
  String? _name;
  int? _userId;
  final bool isDefault;

  Category({
    required String id,
    required String name,
    required int userId,
  })  : _id = id,
        _name = name,
        _userId = userId,
        isDefault = false;

  String getId() {
    return _id;
  }

  String getName() {
    return _name ?? '';
  }

  int getUserId() {
    return _userId ?? 0;
  }

  void setName(String name) {
    _name = name;
  }

  void setUserId(int userId) {
    _userId = userId;
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'name': _name,
      'user_id': _userId,
    };
  }


}