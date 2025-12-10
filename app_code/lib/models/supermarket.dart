import 'package:app_code/models/category.dart';
import 'package:isar/isar.dart';
import 'package:app_code/utils/helper.dart';

@collection
class Supermarket {

  final String id;
  String _name;
  List<Category> _categories;
  
  Supermarket({
    String? id,
    //TODO: add default name
    name = 'Supermarket', 
    required categories,
  }) :  _categories = categories,
        _name = name,
        this.id = id ?? Helper.generateId();

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
  
  factory Supermarket.fromJson(Map<String, dynamic> json, {List<Category>? categories}) {
    return Supermarket(
      id: json['id'],
      name: json['name'] ?? '',
      categories: categories ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': _name,
      'categoryIds': _categories.map((cat) => cat.id).toList(),
    };
  }
}