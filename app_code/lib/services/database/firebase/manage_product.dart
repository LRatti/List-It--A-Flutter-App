import 'package:app_code/models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class FirebaseProductManager {
  
  // Methods to manage products in Firebase
  FirebaseProductManager({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  
  CollectionReference<Map<String, dynamic>> get _products {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return _firestore.collection("Users").doc(uid).collection("Products");
  }

  CollectionReference<Map<String, dynamic>> get _associations {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return _firestore.collection("Users").doc(uid).collection("Associations");
  }

  Future<void> setProduct(Product product) async {
    // Code to add and update a user product to the database
    WriteBatch batch = _firestore.batch();
    
    // Save product data
    batch.set(_products.doc(product.id), product.toDatabase());
    
    // Save associations separately
    product.associations.forEach((supermarketId, categoryId) {
      final associationId = '${product.id}_$supermarketId';
      batch.set(_associations.doc(associationId), {
        'productId': product.id,
        'supermarketId': supermarketId,
        'categoryId': categoryId,
      });
    });
    
    await batch.commit()
      .whenComplete(() => print("Product added successfully"))
      .catchError((error) => print("Failed to add product: $error"));
  }

  Future<void> setAllProducts(List<Product> products) async {
    // Code to add multiple products to the database using batch writes
    if (products.isEmpty) return;
    
    WriteBatch batch = _firestore.batch();
    
    for (var product in products) {
      // Save product data
      batch.set(_products.doc(product.id), product.toDatabase());
      
      // Save associations separately
      product.associations.forEach((supermarketId, categoryId) {
        final associationId = '${product.id}_$supermarketId';
        batch.set(_associations.doc(associationId), {
          'productId': product.id,
          'supermarketId': supermarketId,
          'categoryId': categoryId,
        });
      });
    }
    
    await batch.commit()
      .whenComplete(() => print("${products.length} Products added successfully"))
      .catchError((error) => print("Failed to add products: $error"));
  }

  Future<Product?> getProductById(String pid) async {
    // Code to retrieve a product by its ID from the database
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _products.doc(pid).get();
      if (doc.exists) {
        // Fetch associations for this product
        Map<String, String> associations = await _getProductAssociations(pid);
        
        var productData = doc.data()!;
        productData['associations'] = associations;
        return Product.fromDatabase(productData, associations: associations);
      } else {
        print("Product with id $pid does not exist.");
        return null;
      }
    } catch (e) {
      print("Error fetching product: $e");
      return null;
    }
  }

  Future<Product?> getProductByName(String name) async {
    // Code to retrieve a product by its name from the database
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _products
          .where('name', isEqualTo: name)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        String pid = querySnapshot.docs.first.id;
        return getProductById(pid);
      } else {
        print("Product with name $name does not exist.");
        return null;
      }
    } catch (e) {
      print("Error fetching product: $e");
      return null;
    }
  }

  Future<List<Product>> getAllProducts() async {
    // Code to retrieve all products from the database
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _products.get();
      
      // Fetch all products with their associations in parallel
      List<Product> products = await Future.wait(
        querySnapshot.docs.map((doc) => getProductById(doc.id))
      ).then((results) => results.whereType<Product>().toList());
      
      return products;
    } catch (e) {
      print("Error fetching products: $e");
    }
    return [];
  }

  Future<List<Product>> getVisibleProducts() async {
    // Code to retrieve all visible products from the database
    try {
        QuerySnapshot<Map<String, dynamic>> querySnapshot = await _products
          .where('is_visible', isEqualTo: 1)
          .get();
      
      // Fetch all visible products with their associations in parallel
      List<Product> products = await Future.wait(
        querySnapshot.docs.map((doc) => getProductById(doc.id))
      ).then((results) => results.whereType<Product>().toList());
      
      return products;
    } catch (e) {
      print("Error fetching visible products: $e");
    }
    return [];
  }
  
  // Helper method to fetch associations for a product
  Future<Map<String, String>> _getProductAssociations(String productId) async {
    try {
      // Query associations where the document ID starts with productId
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _associations
          .where('productId', isEqualTo: productId)
          .get();
      
      Map<String, String> associations = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        associations[data['supermarketId']] = data['categoryId'];
      }
      
      return associations;
    } catch (e) {
      print("Error fetching associations for product $productId: $e");
      return {};
    }
  }
}