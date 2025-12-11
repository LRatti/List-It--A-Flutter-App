import 'package:app_code/models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class FirebaseProductManager {
  
  // Methods to manage products in Firebase
  static final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  
  CollectionReference<Map<String, dynamic>> get _products {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return FirebaseFirestore.instance.collection("Users").doc(uid).collection("Products");
  }

  Future<void> setProduct(Product product) async {
    // Code to add and update a user product to the database
    await _products.doc(product.id).set(product.toJson())
      .whenComplete(() => print("Product added successfully"))
      .catchError((error) => print("Failed to add product: $error"));
  }

  Future<void> setAllProducts(List<Product> products) async {
    // Code to add multiple products to the database using batch writes
    if (products.isEmpty) return;
    
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var product in products) {
      batch.set(_products.doc(product.id), product.toJson());
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
        return Product.fromJson(doc.data()!);
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
        return Product.fromJson(querySnapshot.docs.first.data());
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
      return querySnapshot.docs.map((doc) => Product.fromJson(doc.data())).toList();
    } catch (e) {
      print("Error fetching products: $e");
    }
    return [];
  }


}