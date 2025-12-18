import 'package:app_code/models/category.dart';
import 'package:isar/isar.dart';
import 'package:app_code/utils/helper.dart';

@collection
class Supermarket {

  final String id;
  String _name;
  List<Category> _categories;
  bool isVisible;
  
  Supermarket({
    String? id,
    name = 'Default Supermarket', 
    List<Category>? categories,
    this.isVisible = true,
  }) :  this.id = id ?? Helper.generateId(),
        _categories = categories ?? [],
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

  void setVisibility(bool visibility) {
    isVisible = visibility;
  }

  void setCategories(List<Category> categories) {
    this._categories = categories;
  }

  void addCategory(Category category){
      _categories.add(category);
  }

  factory Supermarket.fromDatabase(Map<String, dynamic> json) {
    return Supermarket(
      id: json['id'],
      name: json['name'] ?? 'Supermarket',
      isVisible: json['is_visible'],
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'name': _name,
      'categoryIds': _categories.map((cat) => cat.id).toList(),
      'is_visible': isVisible,
    };
  }
  
  factory Supermarket.fromJson(Map<String, dynamic> json) {
    return Supermarket(
      id: json['id'],
      name: json['name'] ?? 'Supermarket',
      categories: (json['categories'] as List<dynamic>?)
          ?.map((item) => Category.fromJson(item))
          .toList() ?? [],
      isVisible: json['is_visible'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': _name,
      'categories': _categories.map((cat) => cat.toJson()).toList(),
      'is_visible': isVisible,
    };
  }
}