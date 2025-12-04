import 'package:app_code/utils/helper.dart';

class Product {

  final String id; 
  String _name;
  int? categoryId;

  Product({
    String?id,
    required name, 
    this.categoryId, 
  }): this._name = name,
      this.id = id ?? Helper.generateId();
 
  String getName() {
    return this._name;
  }

  int getCategoryId() {
    return categoryId ?? 0;
  }

  void setName(String name) {
    this._name = name;
  }

  void setCategoryId(int categoryId) {
    this.categoryId = categoryId;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      categoryId: json['category_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, 
      'name': _name,
      'category_id': categoryId,
    };
  }
}