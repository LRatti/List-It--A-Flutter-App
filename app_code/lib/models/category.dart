import 'package:app_code/utils/helper.dart';

class Category {

  final String id;
  String _name;
  final bool isDefault;
  late DateTime? lastModified;
  late DateTime createdAt;

  Category({
    String? id,
    required String name,
    this.isDefault = false,
    DateTime? lastModified,
    DateTime? createdAt,
  })  : id = id ?? Helper.generateId(),
        _name = name,
        createdAt = createdAt ?? DateTime.now();

  String getName(){
    return this._name;
  }

  factory Category.fromDatabase(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      isDefault: json['is_default'] == 1,
      lastModified: DateTime.tryParse(json['last_modified'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'name': _name,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'last_modified': lastModified?.toIso8601String(),
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      isDefault: json['is_default'] == 1,
      lastModified: DateTime.tryParse(json['lastModified'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': _name,
      'is_default': isDefault ? 1 : 0,
      'lastModified': lastModified?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}