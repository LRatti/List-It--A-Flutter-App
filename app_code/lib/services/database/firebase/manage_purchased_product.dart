import 'package:app_code/models/purchased_product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class FirebasePurchasedProductManager {
  // Implementation for managing purchased products in Firebase

  static final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final _shoppingLists = FirebaseFirestore.instance.collection("Users").doc(_firebaseAuth.currentUser?.uid).collection("Shopping Lists");


  Future<void> addPurchasedProduct(PurchasedProduct product) async {
    // Code to add a purchased product to the database
    await _shoppingLists.doc(product.listId).collection("Purchased Products").doc(product.id).set(product.toJson())
      .whenComplete(() => print("Purchased Product added successfully"))
      .catchError((error) => print("Failed to add purchased product: $error"));
  }

  Future<PurchasedProduct?> getPurchasedProductById(String id) async {
    // Code to retrieve a purchased product by its ID from the database
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _shoppingLists.doc(id).collection("Purchased Products").doc(id).get();
      if (doc.exists) {
        return PurchasedProduct.fromJson(doc.data()!);
      } else {
        print("Purchased Product with id $id does not exist.");
        return null;
      }
    } catch (e) {
      print("Error fetching purchased product: $e");
      return null;
    }
  }

  Future<void> updatePurchasedProduct(PurchasedProduct product) async {
    // Code to update a purchased product in the database
    await _shoppingLists.doc(product.listId).collection("Purchased Products").doc(product.id).update(product.toJson())
      .whenComplete(() => print("Purchased Product updated successfully"))
      .catchError((error) => print("Failed to update purchased product: $error"));
  }

  Future<void> deletePurchasedProduct(String id) async {
    // Code to delete a purchased product from the database
    await _shoppingLists.doc(id).collection("Purchased Products").doc(id).delete()
      .whenComplete(() => print("Purchased Product deleted successfully"))
      .catchError((error) => print("Failed to delete purchased product: $error"));
  }

  Future<List<PurchasedProduct>> getAllPurchasedProducts() async {
    // Code to retrieve all purchased products from the database
    return [];
  }

  Future<List<PurchasedProduct>> getPurchasedProductByList() async {
    // Code to retrieve all purchased products from the database
    return [];
  }

}