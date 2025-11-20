import 'package:app_code/models/category.dart';
import 'package:isar/isar.dart';

@collection
class Supermarket {

  final String id;
  String _name;
  List<Category> _categories;
  
  Supermarket({
    required this.id,
    //TODO: add default name
    name = 'Supermarket', 
    required categories,
  }) :  _categories = categories,
        _name = name;

  String getName() {
    return _name;
  }

  List<Category> getCategories() {
    return _categories;
  }

  void setName(String name) {
    _name = name;
  }

  void modifyCategories(List<Category> categories) {
    this._categories = categories;
  }

  void addCategory(Category category){
      _categories.add(category);
  }
  
  factory Supermarket.fromJson(Map<String, dynamic> json) {
    return Supermarket(
      id: json['id'],
      name: json['name'] ?? '',
      categories: (json['categories'] as List<dynamic>?)
              ?.map((item) => Category.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': _name,
      'categories': _categories.map((category) => category.toJson()).toList(),
    };
  }
}