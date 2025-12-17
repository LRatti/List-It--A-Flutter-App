import 'package:app_code/utils/helper.dart';

class Category {

  final String id;
  String _name;
  final bool isDefault;

  Category({
    String? id,
    required String name,
    this.isDefault = false,
  })  : id = id ?? Helper.generateId(),
        _name = name;

  String getName(){
    return this._name;
  }

  factory Category.fromDatabase(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      isDefault: json['is_default'] == 1,
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'name': _name,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      isDefault: json['is_default'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': _name,
      'is_default': isDefault ? 1 : 0,
    };
  }
}