import 'package:app_code/utils/helper.dart';

class Product {
  final String id;
  String _name;
  List<String> categoryIds;
  Map<String, String> associations;
  bool isVisible;

  Product({
    String? id,
    required String name,
    List<String>? categoryIds,
    Map<String, String>? associations,
    bool isVisible = true,
  })  : id = id ?? Helper.generateId(),
        _name = name,
        categoryIds = categoryIds ?? [],
        associations = associations ?? {},
        isVisible = isVisible;

  String getName() {
    return _name;
  }

  void setName(String name) {
    _name = name;
  }

  void setCategoryIds(List<String> categoryIds) {
    this.categoryIds = categoryIds;
  }

  void setAssociations(Map<String, String> associations) {
    this.associations = associations;
  }

  void setVisibility(bool visibility) {
    isVisible = visibility;
  }

  factory Product.fromDatabase(
    Map<String, dynamic> json, {
    List<String>? categoryIds,
    Map<String, String>? associations,
  }) {
    return Product(
      id: json['id'],
      name: json['name'],
      isVisible: (json['is_visible'] ?? 1) == 1,
      categoryIds: categoryIds,
      associations: associations,
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'name': _name,
      'is_visible': isVisible ? 1 : 0,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      categoryIds: List<String>.from(json['categoryIds'] ?? []),
      associations: Map<String, String>.from(json['associations'] ?? {}),
      isVisible: json['isVisible'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': _name,
      'categoryIds': categoryIds,
      'associations': associations,
      'isVisible': isVisible,
    };
  }
}
