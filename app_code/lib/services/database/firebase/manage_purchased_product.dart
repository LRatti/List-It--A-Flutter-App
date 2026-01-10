import 'package:app_code/models/category.dart';
import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class FirebasePurchasedProductManager {
  // Implementation for managing purchased products in Firebase

  FirebasePurchasedProductManager({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  
  CollectionReference<Map<String, dynamic>> get _shoppingLists {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return _firestore.collection("Users").doc(uid).collection("Shopping Lists");
  }
  
  CollectionReference<Map<String, dynamic>> get _products {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return _firestore.collection("Users").doc(uid).collection("Products");
  }

  CollectionReference<Map<String, dynamic>> get _categories {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return _firestore.collection("Users").doc(uid).collection("Categories");
  }

  Future<void> setPurchasedProduct(PurchasedProduct product) async {
    // Code to add a purchased product to the database
    await _shoppingLists.doc(product.listId).collection("Purchased Products").doc(product.id).set(product.toDatabase())
      .whenComplete(() => print("Purchased Product added successfully"))
      .catchError((error) => print("Failed to add purchased product: $error"));
  }

  Future<void> setAllPurchasedProducts(List<PurchasedProduct> products) async {
    // Code to add multiple purchased products to the database using batch writes
    if (products.isEmpty) return;
    
    WriteBatch batch = _firestore.batch();
    for (var product in products) {
      final docRef = _shoppingLists.doc(product.listId).collection("Purchased Products").doc(product.id);
      batch.set(docRef, product.toDatabase());
    }
    
    await batch.commit()
      .whenComplete(() => print("${products.length} Purchased Products added successfully"))
      .catchError((error) => print("Failed to add purchased products: $error"));
  }
  
  Future<PurchasedProduct?> getPurchasedProductById(String listId, String purchasedProductId) async {
    // Code to retrieve a purchased product by its ID from the database
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _shoppingLists.doc(listId).collection("Purchased Products").doc(purchasedProductId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final productId = data['product_id'];
        final catId = data['category_id'];
        
        if (productId == null) return null;

        if (catId == null) return null;
        
        final prodDoc = await _products.doc(productId).get();
        if (!prodDoc.exists) return null;
        
        final catDoc = await _categories.doc(catId).get();
        if (!catDoc.exists) return null;

        final Category category = Category.fromJson(catDoc.data()!);
        final Product product = Product.fromDatabase(prodDoc.data()!);
        final PurchasedProduct purchased = PurchasedProduct.fromDatabase(data, category, product);
        return purchased;
      } else {
        print("Purchased Product with id $purchasedProductId does not exist.");
        return null;
      }
    } catch (e) {
      print("Error fetching purchased product: $e");
      return null;
    }
  }

  Future<List<PurchasedProduct>> getPurchasedProductByList(String listId) async {
    // Code to retrieve all purchased products from the database
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _shoppingLists.doc(listId).collection("Purchased Products").get();
      
      // Fetch all products in parallel
      List<PurchasedProduct?> purchasedProducts = await Future.wait(
        querySnapshot.docs.map((doc) async {
          return await getPurchasedProductById(listId, doc.id);
        })
      );
      //Returns a list without null values. If no products found, returns an empty list.
      return purchasedProducts.whereType<PurchasedProduct>().toList();
    } catch (e) {
      print("Error fetching purchased products: $e");
      return [];
    }
  }

  Future<void> deletePurchasedProduct(PurchasedProduct product) async {
    // Code to delete a purchased product from the database
    await _shoppingLists.doc(product.listId).collection("Purchased Products").doc(product.id).delete()
      .whenComplete(() => print("Purchased Product deleted successfully"))
      .catchError((error) => print("Failed to delete purchased product: $error"));
  }
}