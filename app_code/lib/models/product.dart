import 'package:app_code/utils/helper.dart';

class Product {
  final String id;
  String _name;
  Map<String, String> associations;
  bool isVisible;
  late DateTime lastModified;

  Product({
    String? id,
    required String name,
    Map<String, String>? associations,
    bool isVisible = true,
    DateTime? lastModified,
    bool isDeleted = false,
  })  : id = id ?? Helper.generateId(),
        _name = name,
        associations = associations ?? {},
        isVisible = isVisible,
        lastModified = lastModified ?? DateTime.now();

  String getName() {
    return _name;
  }

  void setName(String name) {
    _name = name;
  }

  void setAssociations(Map<String, String> associations) {
    this.associations = associations;
  }

  void setVisibility(bool visibility) {
    isVisible = visibility;
  }

  void addAssociation(String supermarketId, String categoryId) {
    associations[supermarketId] = categoryId;
  }

  factory Product.fromDatabase(
    Map<String, dynamic> json, {
    Map<String, String>? associations,
  }) {
    return Product(
      id: json['id'],
      name: json['name'],
      isVisible: (json['is_visible'] ?? 1) == 1,
      associations: associations,
      lastModified: DateTime.tryParse(json['last_modified'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'name': _name,
      'is_visible': isVisible ? 1 : 0,
      'last_modified': lastModified.toIso8601String(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      associations: Map<String, String>.from(json['associations'] ?? {}),
      isVisible: json['isVisible'] ?? true,
      lastModified: DateTime.tryParse(json['lastModified'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': _name,
      'isVisible': isVisible,
      'lastModified': lastModified.toIso8601String(),
    };
  }
}
