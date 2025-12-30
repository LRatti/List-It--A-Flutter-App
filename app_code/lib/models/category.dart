import 'package:app_code/utils/helper.dart';

class Category {

  final String id;
  String _name;
  final bool isDefault;
  late DateTime lastModified;

  Category({
    String? id,
    required String name,
    this.isDefault = false,
    DateTime? lastModified,
  })  : id = id ?? Helper.generateId(),
        _name = name,
        lastModified = lastModified ?? DateTime.now();

  String getName(){
    return this._name;
  }

  factory Category.fromDatabase(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      isDefault: json['is_default'] == 1,
      lastModified: DateTime.tryParse(json['last_modified'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'name': _name,
      'is_default': isDefault ? 1 : 0,
      'last_modified': lastModified.toIso8601String(),
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      isDefault: json['is_default'] == 1,
      lastModified: DateTime.tryParse(json['lastModified'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': _name,
      'is_default': isDefault ? 1 : 0,
      'lastModified': lastModified.toIso8601String(),
    };
  }
}