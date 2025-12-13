import 'package:app_code/utils/helper.dart';

class Product {

  final String id; 
  String _name;
  List<String> categoryIds;
  bool isVisible;

  Product({
    String?id,
    required name, 
    this.categoryIds = const [], 
    this.isVisible = true,
  }): this._name = name,
      this.id = id ?? Helper.generateId();
 
  String getName() {
    return this._name;
  }

  List<String> getCategoryIds() {
    return categoryIds;
  }

  void setName(String name) {
    this._name = name;
  }

  void setCategoryIds(List<String> categoryIds) {
    this.categoryIds = categoryIds;
  }

  void setVisibility(bool visibility) {
    isVisible = visibility;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      categoryIds: List<String>.from(json['categoryIds'] ?? []),
      isVisible: json['isVisible'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, 
      'name': _name,
      'categoryIds': categoryIds,
      'isVisible': isVisible,
    };
  }
}