import 'package:app_code/models/product.dart';
import 'package:app_code/models/purchased_product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class FirebasePurchasedProductManager {
  // Implementation for managing purchased products in Firebase

  static final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final _shoppingLists = FirebaseFirestore.instance.collection("Users").doc(_firebaseAuth.currentUser?.uid).collection("Shopping Lists");
  final _products = FirebaseFirestore.instance.collection("Products");

  Future<void> setPurchasedProduct(PurchasedProduct product) async {
    // Code to add a purchased product to the database
    await _shoppingLists.doc(product.listId).collection("Purchased Products").doc(product.id).set(product.toJson())
      .whenComplete(() => print("Purchased Product added successfully"))
      .catchError((error) => print("Failed to add purchased product: $error"));
  }

  
  Future<PurchasedProduct?> getPurchasedProductById(String listId, String purchasedProductId) async {
    // Code to retrieve a purchased product by its ID from the database
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _shoppingLists.doc(listId).collection("Purchased Products").doc(purchasedProductId).get();
      if (doc.exists) {
        Product p = await _products.doc(doc.data()!['product_id']).get().then((prodDoc) => Product.fromJson(prodDoc.data()!));
        return PurchasedProduct.fromJson(doc.data()!, p);
      } else {
        print("Purchased Product with id ${purchasedProductId} does not exist.");
        return null;
      }
    } catch (e) {
      print("Error fetching purchased product: $e");
      return null;
    }
  }

  Future<void> deletePurchasedProduct(PurchasedProduct product) async {
    // Code to delete a purchased product from the database
    await _shoppingLists.doc(product.listId).collection("Purchased Products").doc(product.id).delete()
      .whenComplete(() => print("Purchased Product deleted successfully"))
      .catchError((error) => print("Failed to delete purchased product: $error"));
  }

  // Not necessary because lists are needed
  // Future<List<PurchasedProduct>> getAllPurchasedProducts( ) async {
  //   // Code to retrieve all purchased products from the database
  //   return [];
  // }

  Future<List<PurchasedProduct>> getPurchasedProductByList(String listId) async {
    // Code to retrieve all purchased products from the database
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _shoppingLists.doc(listId).collection("Purchased Products").get();
      List<PurchasedProduct> purchasedProducts = [];
      for (var doc in querySnapshot.docs) {
        Product p = await _products.doc(doc.data()['product_id']).get().then((prodDoc) => Product.fromJson(prodDoc.data()!));
        purchasedProducts.add(PurchasedProduct.fromJson(doc.data(), p));
      }
      return purchasedProducts;
    } catch (e) {
      print("Error fetching purchased products: $e");
    }
    return [];
  }

}