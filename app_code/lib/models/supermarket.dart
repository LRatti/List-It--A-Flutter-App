import 'package:app_code/models/category.dart';
import 'package:isar/isar.dart';

@collection
class Supermarket {

  Id id = Isar.autoIncrement;
  String name = '';
  final int userId ;
  List<Category> categories = [];

  //TODO: add default name
  Supermarket({this.name = 'Supermarket', this.userId = 0, List<Category>? categories})
      : categories = categories ?? [];

  int getId() {
    return id;
  }

  String getName() {
    return name;
  }

  List<Category> getCategories() {
    return categories;
  }

  int getUserId() {
    return userId;
  }

  void setName(String name) {
    this.name = name;
  }

  void modifyCategories(List<Category> categories) {
    this.categories = categories;
  }

  void addCategory(Category category){
      categories.add(category);
  }
  
  factory Supermarket.fromJson(Map<String, dynamic> json) {
    return Supermarket(
      name: json['name'] ?? '',
      userId: json['userId'] ?? 0,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((item) => Category.fromJson(item))
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