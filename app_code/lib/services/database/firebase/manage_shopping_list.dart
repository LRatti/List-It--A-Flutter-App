import 'package:app_code/models/shopping_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class FirebaseShoppingListManager {
  // Class implementation

  static final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final _shoppingLists = FirebaseFirestore.instance.collection("Users").doc(_firebaseAuth.currentUser?.uid).collection("Shopping Lists");
  
  Future<void> addShoppingList(ShoppingList shoppingList) async {
    // Code to add a shopping list to the database
    await _shoppingLists.doc(shoppingList.id).set(shoppingList.toJson())
      .whenComplete(() => print("Shopping List added successfully"))
      .catchError((error) => print("Failed to add shopping list: $error"));
  }

  Future<ShoppingList?> getShoppingListById(String id) async {
    // Code to retrieve a shopping list by its ID from the database
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _shoppingLists.doc(id).get();
      if (doc.exists) {
        return ShoppingList.fromJson(doc.data()!);
      } else {
        print("Shopping List with id $id does not exist.");
        return null;
      }
    } catch (e) {
      print("Error fetching shopping list: $e");
      return null;
    }
  }

  Future<void> updateShoppingList(ShoppingList shoppingList) async {
    // Code to update a shopping list in the database
    await _shoppingLists.doc(shoppingList.id).update(shoppingList.toJson())
      .whenComplete(() => print("Shopping List updated successfully"))
      .catchError((error) => print("Failed to update shopping list: $error"));
  }

  Future<void> deleteShoppingList(String id) async {
    // Code to delete a shopping list from the database
    await _shoppingLists.doc(id).delete()
      .whenComplete(() => print("Shopping List deleted successfully"))
      .catchError((error) => print("Failed to delete shopping list: $error"));
  }

  Future<List<ShoppingList>?> getAllShoppingLists() async {
    // Code to retrieve all shopping lists from the database
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _shoppingLists.get();
      return querySnapshot.docs.map((doc) => ShoppingList.fromJson(doc.data())).toList();
    } catch (e) {
      print("Error fetching shopping lists: $e");
      return null;
    }
    
  }
}