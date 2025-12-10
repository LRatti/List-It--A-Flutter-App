import 'package:app_code/models/category.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class FirebaseSupermarketManager {

  static final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  
  CollectionReference<Map<String, dynamic>> get _supermarkets {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return FirebaseFirestore.instance.collection("Users").doc(uid).collection("Supermarkets");
  }
  
  CollectionReference<Map<String, dynamic>> get _categories {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return FirebaseFirestore.instance.collection("Users").doc(uid).collection("Categories");
  }
  
  // Methods to manage supermarket data in Firebase
  Future<void> setSupermarket(Supermarket supermarket) async {
    // Code to add a supermarket to the database
    await _supermarkets.doc(supermarket.id).set(supermarket.toJson())
      .whenComplete(() => print("Supermarket added successfully"))
      .catchError((error) => print("Failed to add supermarket: $error"));
  }

  Future<void> setAllSupermarkets(List<Supermarket> supermarkets) async {
    // Code to add multiple supermarkets to the database using batch writes
    if (supermarkets.isEmpty) return;
    
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var supermarket in supermarkets) {
      batch.set(_supermarkets.doc(supermarket.id), supermarket.toJson());
    }
    
    await batch.commit()
      .whenComplete(() => print("${supermarkets.length} Supermarkets added successfully"))
      .catchError((error) => print("Failed to add supermarkets: $error"));
  }

  Future<Supermarket?> getSupermarketById(String sid) async {
    // Code to retrieve a supermarket by its ID from the database
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _supermarkets.doc(sid).get();
      if (doc.exists) {
        List<Category> categories = [];
        if (doc.data() != null && doc.data()!['categoryIds'] != null) {
          // Fetch all categories in parallel
          categories = await Future.wait(
            (doc.data()!['categoryIds'] as List).map((catId) async {
              return await _categories.doc(catId).get().then((catDoc) => Category.fromJson(catDoc.data()!));
            })
          );
        }
        return Supermarket.fromJson(doc.data()!, categories: categories);
      } else {
        print("Supermarket with id $sid does not exist.");
        return null;
      }
    } catch (e) {
      print("Error fetching supermarket: $e");
      return null;
    }
  }

  Future<List<Supermarket>> getAllSupermarkets() async {
    // Code to retrieve all supermarkets from the database
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _supermarkets.get();
      // Fetch all supermarkets in parallel
      List<Supermarket> supermarkets = await Future.wait(
        querySnapshot.docs.map((doc) => getSupermarketById(doc.id).then((supermarket) => supermarket ?? Supermarket(id: doc.id, categories: [])))
      );
      return supermarkets;
    } catch (e) {
      print("Error fetching supermarkets: $e");
    }
    return [];
  }

   Future<void> deleteSupermarket(String id) async {
    // Code to delete a supermarket from the database
    await _supermarkets.doc(id).delete()
      .whenComplete(() => print("Supermarket deleted successfully"))
      .catchError((error) => print("Failed to delete supermarket: $error"));
  }

}