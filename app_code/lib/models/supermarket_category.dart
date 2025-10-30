import 'package:app_code/models/category.dart';

class SupermarketCategory {

  final  Category category;
  final int supermarketId;
  int? order;

  SupermarketCategory({required this.category, required this.supermarketId, this.order}); 

  Category getCategory() {
    return category;
  }

  int getSupermarketId() {
    return supermarketId;
  }

  int getOrder() {  
    return order ?? 0;
  }

  void setOrder(int order) {
    this.order = order;
  }

  factory SupermarketCategory.fromJson(Map<String, dynamic> json) {
    return SupermarketCategory(
      category: Category.fromJson(json['category']),
      supermarketId: json['supermarketId'],
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category.toJson(),
      'supermarketId': supermarketId,
      'order': order,
    };
  }

}