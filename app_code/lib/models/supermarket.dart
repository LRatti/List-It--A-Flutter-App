import 'package:app_code/models/category.dart';
import 'package:app_code/models/supermarket_category.dart';
import 'package:isar/isar.dart';

@collection
class Supermarket {

  Id id = Isar.autoIncrement;
  String name = '';
  final int userId ;
  List<SupermarketCategory> categories = [];

  Supermarket({this.name = '', this.userId = 0, List<SupermarketCategory>? categories})
      : categories = categories ?? [];

  int getId() {
    return id;
  }

  String getName() {
    return name;
  }

  List<SupermarketCategory> getCategories() {
    return categories;
  }

  int getUserId() {
    return userId;
  }

  void setName(String name) {
    this.name = name;
  }

  void modifyCategories(List<SupermarketCategory> categories) {
    this.categories = categories;
  }

  factory Supermarket.fromJson(Map<String, dynamic> json) {
    return Supermarket(
      name: json['name'] ?? '',
      userId: json['userId'] ?? 0,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((item) => SupermarketCategory.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      'categories': categories.map((category) => category.toJson()).toList(),
    };
  }



}