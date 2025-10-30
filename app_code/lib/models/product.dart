class Product {

  final int id;
  String? name;
  int? categoryId;
  int? userId;

  Product({required this.id, this.name, this.categoryId, this.userId});

  int getId() {
    return id;
  }

  String getName() {
    return name ?? '';
  }

  int getCategoryId() {
    return categoryId ?? 0;
  }

  int getUserId() {
    return userId ?? 0;
  }

  void setName(String name) {
    this.name = name;
  }

  void setCategoryId(int categoryId) {
    this.categoryId = categoryId;
  }

  void setUserId(int userId) {
    this.userId = userId;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      categoryId: json['category_id'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'user_id': userId,
    };
  }

}