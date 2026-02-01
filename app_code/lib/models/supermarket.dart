import 'package:app_code/models/category.dart';
import 'package:isar/isar.dart';
import 'package:app_code/utils/helper.dart';

@collection
class Supermarket {

  final String id;
  String _name;
  List<Category> _categories;
  bool isVisible;
  bool isFavorite;
  late DateTime? lastModified;
  late DateTime createdAt;
  
  Supermarket({
    String? id,
    required String name, 
    List<Category>? categories,
    this.isVisible = true,
    this.isFavorite = false,
    DateTime? lastModified,
    DateTime? createdAt,
    bool isDeleted = false,
  }) :  this.id = id ?? Helper.generateId(),
        _categories = categories ?? [],
        _name = name,
        createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? (createdAt ?? DateTime.now());

  String getName() {
    return _name;
  }

  List<Category> getCategories() {
    return _categories;
  }

  void setName(String name) {
    _name = name;
    lastModified = DateTime.now();
  }

  void setVisibility(bool visibility) {
    isVisible = visibility;
    lastModified = DateTime.now();
  }

  void setCategories(List<Category> categories) {
    this._categories = categories;
    lastModified = DateTime.now();
  }

  void addCategory(Category category){
      _categories.add(category);
      lastModified = DateTime.now();
  }

  factory Supermarket.fromDatabase(Map<String, dynamic> json) {
    return Supermarket(
      id: json['id'],
      name: json['name'] ?? 'Supermarket',
      isVisible: json['is_visible'] == 1,
      isFavorite: json['is_favorite'] == 1,
      lastModified: DateTime.tryParse(json['last_modified'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'name': _name,
      'categoryIds': _categories.map((cat) => cat.id).toList(),
      'is_visible': isVisible ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'last_modified': lastModified?.toIso8601String(),
    };
  }
  
  factory Supermarket.fromJson(Map<String, dynamic> json) {
    return Supermarket(
      id: json['id'],
      name: json['name'] ?? 'Supermarket',
      categories: (json['categories'] as List<dynamic>?)
          ?.map((item) => Category.fromJson(item))
          .toList() ?? [],
      isVisible: json['isVisible'] ?? true,
      isFavorite: json['isFavorite'] ?? false,
      lastModified: DateTime.tryParse(json['lastModified'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': _name,
      'categories': _categories.map((cat) => cat.toJson()).toList(),
      'isVisible': isVisible,
      'isFavorite': isFavorite,
      'lastModified': lastModified?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}