import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// This class manages associations between products, supermarkets 
/// and categories in Firebase
class FirebaseManageAssociations {
  // This class manages associations between products, supermarkets and categories in Firebase
  FirebaseManageAssociations({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _associations {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return _firestore.collection("Users").doc(uid).collection("Associations");
  }

  // Set a single association using composite key: productId_supermarketId
  Future<void> setAssociation(String productId, String supermarketId, String categoryId) async {
    final associationId = '${productId}_$supermarketId';
    await _associations.doc(associationId).set({
      'productId': productId,
      'supermarketId': supermarketId,
      'categoryId': categoryId,
    }).whenComplete(() => print("Association set successfully"))
      .catchError((error) => print("Failed to set association: $error"));
  }

  // Delete a specific association
  Future<void> deleteAssociation(String productId, String supermarketId) async {
    final associationId = '${productId}_$supermarketId';
    await _associations.doc(associationId).delete()
      .whenComplete(() => print("Association deleted successfully"))
      .catchError((error) => print("Failed to delete association: $error"));
  }

  // Delete all associations for a product
  Future<void> deleteProductAssociations(String productId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _associations
          .where('productId', isEqualTo: productId)
          .get();
      
        WriteBatch batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print("All associations for product $productId deleted successfully");
    } catch (error) {
      print("Failed to delete product associations: $error");
    }
  }

  // Get all associations for a product
  Future<Map<String, String>> getProductAssociations(String productId) async {
    try {
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

  // Get all products associated with a specific supermarket
  Future<List<String>> getProductsBySupermarket(String supermarketId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _associations
          .where('supermarketId', isEqualTo: supermarketId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => doc.data()['productId'] as String)
          .toSet()
          .toList();
    } catch (e) {
      print("Error fetching products for supermarket $supermarketId: $e");
      return [];
    }
  }

  // Get all products associated with a specific category in a supermarket
  Future<List<String>> getProductsByCategory(String supermarketId, String categoryId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _associations
          .where('supermarketId', isEqualTo: supermarketId)
          .where('categoryId', isEqualTo: categoryId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => doc.data()['productId'] as String)
          .toList();
    } catch (e) {
      print("Error fetching products for category: $e");
      return [];
    }
  }

  // Get the category for a product in a specific supermarket
  Future<String?> getCategoryForProduct(String productId, String supermarketId) async {
    try {
      final associationId = '${productId}_$supermarketId';
      DocumentSnapshot<Map<String, dynamic>> doc = await _associations.doc(associationId).get();
      
      if (doc.exists) {
        return doc.data()?['categoryId'];
      }
      return null;
    } catch (e) {
      print("Error fetching category for product: $e");
      return null;
    }
  }

  // Get all categories for a product across supermarkets
  Future<List<String>> getCategoriesByProduct(String productId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _associations
          .where('productId', isEqualTo: productId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => doc.data()['categoryId'] as String)
          .toSet()
          .toList();
    } catch (e) {
      print("Error fetching categories for product $productId: $e");
      return [];
    }
  }
}