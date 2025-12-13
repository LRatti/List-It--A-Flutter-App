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

  //this method might not be used
  void setName(String newName){
    this._name = newName;
  }

  String getName(){
    return this._name;
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