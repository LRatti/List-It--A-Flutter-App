import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/utils/helper.dart';
import 'package:app_code/models/category.dart';

class ShoppingList {
 
  final String id;
  String _name;
  final DateTime createdAt;
  Supermarket _supermarket;
  double? _totalPrice;
  String? image;
  List<PurchasedProduct>? products;
  bool _isRegistered = false;
  bool _isInTheTrash = false;
  DateTime? _deletionTimestamp;
  late DateTime? lastModified;
  bool isDeleted;

  ShoppingList(
      {String? id,
      required name,
      required this.createdAt,
      supermarket,
      totalPrice,
      this.image,
      this.products,
      isRegistered = false,
      isInTheTrash = false,
      DateTime? deletionTimestamp,
      DateTime? lastModified,
      this.isDeleted = false,
  }) :  _name = name,
        _totalPrice = totalPrice,
        _supermarket = supermarket ?? _getDefaultSupermarket(),
        _isRegistered = isRegistered,
        _isInTheTrash = isInTheTrash,
        _deletionTimestamp = deletionTimestamp,
        this.id = id ?? Helper.generateId();

  String getName() {
    return this._name;
  }

  DateTime getCreatedAt() {
    return createdAt;
  }

  Supermarket? getSupermarket() {
    return this._supermarket;
  }

  double getTotalPrice() {
    return this._totalPrice ?? 0.0;
  }

  List<PurchasedProduct> getProducts() {
    return products ?? [];
  }

  bool getIsRegistered() {
    return _isRegistered;
  }

  bool getIsInTheTrash() {
    return _isInTheTrash;
  }

  DateTime? getDeletionTimestamp() {
    return _deletionTimestamp;
  }

  bool getIsDeleted() {
    return isDeleted;
  }

  factory ShoppingList.fromDatabase(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      totalPrice: json['total_price'],
      image: json['image'],
      isRegistered: json['is_registered'] == 1,
      isInTheTrash: json['is_in_the_trash'] == 1,
      deletionTimestamp: json['deletion_timestamp'] != null ? DateTime.tryParse(json['deletion_timestamp']) : null,
      lastModified: DateTime.tryParse(json['last_modified'] ?? '') ?? DateTime.now(),
      isDeleted: (json['is_deleted'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'name': _name,
      'created_at': createdAt?.toIso8601String(),
      'supermarket_id': _supermarket.id,
      'total_price': _totalPrice,
      'image': image,
      'is_registered': _isRegistered ? 1 : 0,
      'is_in_the_trash': _isInTheTrash ? 1 : 0,
      'deletion_timestamp': _deletionTimestamp?.toIso8601String(),
      'last_modified': lastModified?.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      totalPrice: json['total_price'],
      image: json['image'],
      products: (json['products'] as List<dynamic>?)
          ?.map((item) => PurchasedProduct.fromJson(item))
          .toList(),
      isRegistered: json['is_registered'] == 1,
      lastModified: DateTime.tryParse(json['lastModified'] ?? '') ?? DateTime.now(),
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': _name,
      'created_at': createdAt?.toIso8601String(),
      'supermarket_id': _supermarket.id,
      'total_price': _totalPrice,
      'image': image,
      'products': products?.map((product) => product.toDatabase()).toList(),
      'is_registered': _isRegistered ? 1 : 0,
      'lastModified': lastModified?.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  void addProduct(Product product, Category category) {
    PurchasedProduct purchasedProduct = PurchasedProduct(
      id: product.id,
      price: 0.0,
      quantity: 1,
      category: category,
      product: product, 
      listId: id,
    );
    products ??= [];
    products!.add(purchasedProduct);
  }

  void setPurchasedProducts(List<PurchasedProduct> products) {
    this.products = products;
  }

  void removeProduct(PurchasedProduct product) {
    products?.remove(product);
  }

  void removeProductById(String productId) {
    products?.removeWhere((product) => product.id == productId);
  }

  void removeAllProducts() {
    products?.clear();
  }
  
  void setName(String newName) {
    this._name = newName;
  }

  void setSupermarket(Supermarket supermarket) {
    this._supermarket = supermarket;
  }

  void setTotalPrice(double totalPrice) {
    this._totalPrice = totalPrice;
  }

  void computeTotalPrice() {
    // _totalPrice = products?.fold(0, (sum, product) => sum! + (product.getTotalPrice())) ?? 0.0;
    _totalPrice = products?.fold(0, (sum, product) => sum! + (product.price)) ?? 0.0;

  } 

  void setImage(String image) {
    this.image = image;
  }

  void setIsRegistered(bool isRegistered) {
    _isRegistered = isRegistered;
  }

  void setIsInTheTrash(bool isInTheTrash) {
    _isInTheTrash = isInTheTrash;
    if (isInTheTrash && _deletionTimestamp == null) {
      _deletionTimestamp = DateTime.now();
    } else if (!isInTheTrash) {
      _deletionTimestamp = null;
    }
  }

  void setDeletionTimestamp(DateTime? timestamp) {
    _deletionTimestamp = timestamp;
  }

  void setIsDeleted(bool isDeleted) {
    this.isDeleted = isDeleted;
  }

  //TODO: take the supermarket from the json file containing the default one
  static Supermarket _getDefaultSupermarket() {
    Category defaultCategory = Category(
      id: 'default_category',
      name: 'Default Category',
    );

    List<Category> categories = [defaultCategory];

    return Supermarket(
      id: 'default',
      name: 'Default Supermarket', 
      categories: categories,
    );
  }
}