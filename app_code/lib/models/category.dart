import 'package:app_code/utils/helper.dart';

class Category {

  final String id;
  String _name;
  bool isVisible;
  late DateTime? lastModified;
  late DateTime createdAt;

  Category({
    String? id,
    required String name,
    this.isVisible = true,
    DateTime? lastModified,
    DateTime? createdAt,
  })  : id = id ?? Helper.generateId(),
        _name = name,
        createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? (createdAt ?? DateTime.now());

  String getName(){
    return this._name;
  }

  void setName(String name) {
    _name = name;
    lastModified = DateTime.now();
  }

  void setVisibility(bool visibility) {
    isVisible = visibility;
    lastModified = DateTime.now();
  }

  factory Category.fromDatabase(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      isVisible: json['is_visible'] != 0, // Default to visible if not specified
      lastModified: DateTime.tryParse(json['last_modified'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'name': _name,
      'is_visible': isVisible ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'last_modified': lastModified?.toIso8601String(),
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      isVisible: json['isVisible'] != false,
      lastModified: DateTime.tryParse(json['lastModified'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': _name,
      'isVisible': isVisible,
      'lastModified': lastModified?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Implement equality based on category ID
  /// This is critical for proper categorization in controllers and UI
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}