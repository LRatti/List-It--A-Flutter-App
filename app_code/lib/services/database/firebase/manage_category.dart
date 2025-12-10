

import 'package:app_code/models/category.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class FirebaseCategoryManager {

  static final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  
  CollectionReference<Map<String, dynamic>> get _categories {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return FirebaseFirestore.instance.collection("Users").doc(uid).collection("Categories");
  }

  Future<void> setCategory(Category category) async {
    // Code to add and update a user category to the database
    await _categories.doc(category.id).set(category.toJson())
      .whenComplete(() => print("Category added successfully"))
      .catchError((error) => print("Failed to add category: $error"));
  }

  Future<void> setAllCategories(List<Category> categories) async {
    // Code to add multiple categories to the database using batch writes
    if (categories.isEmpty) return;
    
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var category in categories) {
      batch.set(_categories.doc(category.id), category.toJson());
    }
    
    await batch.commit()
      .whenComplete(() => print("${categories.length} Categories added successfully"))
      .catchError((error) => print("Failed to add categories: $error"));
  }

  Future<Category?> getCategoryById(String cid) async {
    // Code to retrieve a category by its ID from the database
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _categories.doc(cid).get();
      if (doc.exists) {
        return Category.fromJson(doc.data()!);
      } else {
        print("Category with id $cid does not exist.");
        return null;
      }
    } catch (e) {
      print("Error fetching category: $e");
      return null;
    }
  }

  Future<List<Category>> getAllCategories() async {
    // Code to retrieve all categories from the database
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _categories.get();
      return querySnapshot.docs.map((doc) => Category.fromJson(doc.data())).toList();
    } catch (e) {
      print("Error fetching categories: $e");
    }
    return [];
  }

    Future<void> deleteCategory(Category category) async {
    // Code to delete a category from the database
    await _categories.doc(category.id).delete()
      .whenComplete(() => print("Category deleted successfully"))
      .catchError((error) => print("Failed to delete category: $error"));
  }

}