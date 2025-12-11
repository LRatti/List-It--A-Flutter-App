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

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
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