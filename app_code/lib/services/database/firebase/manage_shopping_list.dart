import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/services/database/firebase/manage_purchased_product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';

class FirebaseShoppingListManager {
  // Class implementation

  static final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  
  CollectionReference<Map<String, dynamic>> get _shoppingLists {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return FirebaseFirestore.instance.collection("Users").doc(uid).collection("Shopping Lists");
  }
  
  CollectionReference<Map<String, dynamic>> get _supermarkets {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return FirebaseFirestore.instance.collection("Users").doc(uid).collection("Supermarkets");
  }

  Future<void> setShoppingList(ShoppingList shoppingList) async {
    // Code to add a shopping list to the databases
    await _shoppingLists.doc(shoppingList.id).set(shoppingList.toDatabase())
      .whenComplete(() => print("Shopping List added successfully"))
      .catchError((error) => print("Failed to add shopping list: $error"));
  }

  Future<void> setAllShoppingLists(List<ShoppingList> shoppingLists) async {
    // Code to add multiple shopping lists to the database using batch writes
    if (shoppingLists.isEmpty) return;
    
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var shoppingList in shoppingLists) {
      batch.set(_shoppingLists.doc(shoppingList.id), shoppingList.toDatabase());
      
      // Also batch the purchased products for this shopping list
      for (var product in shoppingList.getProducts()) {
        final docRef = _shoppingLists.doc(shoppingList.id).collection("Purchased Products").doc(product.id);
        batch.set(docRef, product.toDatabase());
      }
    }
    
    await batch.commit()
      .whenComplete(() => print("${shoppingLists.length} Shopping Lists with products added successfully"))
      .catchError((error) => print("Failed to add shopping lists: $error"));
  }

  //TO CHECK utility
  Future<ShoppingList?> getShoppingListById(String listId) async {
    // Code to retrieve a shopping list by its ID from the database
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _shoppingLists.doc(listId).get();
      if (doc.exists) {
        Supermarket supermarket;
        ShoppingList shoppingList;
        List<PurchasedProduct> purchasedProducts = [];
        if (doc.data() != null && doc.data()!['supermarket'] != null) {
          supermarket = await _supermarkets.doc(doc.data()!['supermarket']).get().then((supermarketDoc) => Supermarket.fromDatabase(supermarketDoc.data()!));
          shoppingList = ShoppingList.fromDatabase(doc.data()!);
          shoppingList.setSupermarket(supermarket);
          // Fetch and set purchased products
          purchasedProducts = await FirebasePurchasedProductManager().getPurchasedProductByList(listId);
          shoppingList.setPurchasedProducts(purchasedProducts);
          return shoppingList;
        } else {
          // Handle case where supermarket data is missing
          print(  "Supermarket data is missing for shopping list with id $listId.");
          return null;
        }
      } else {
        print("Shopping List with id $listId does not exist.");
        return null;
      }
    } catch (e) {
      print("Error fetching shopping list: $e");
      return null;
    }
  }

  Future<List<ShoppingList>?> getAllShoppingLists() async {
    // Code to retrieve all shopping lists from the database
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _shoppingLists.get();
      // Fetch all shopping lists in parallel
      List<ShoppingList> shoppingLists = await Future.wait(
        querySnapshot.docs.map((doc) => getShoppingListById(doc.id).then((shoppingList) => shoppingList ?? ShoppingList(id: doc.id, supermarket: Supermarket(id: '', categories: []), name: null, createdAt: null)))
      );
      return shoppingLists;
    } catch (e) {
      print("Error fetching shopping lists: $e");
      return null;
    }
  }

  Future<void> deleteShoppingList(String id) async {
    // Code to delete a shopping list and all related subcollections from the database
    try {
      // Delete all purchased products in the subcollection first
      QuerySnapshot<Map<String, dynamic>> purchasedProducts = 
        await _shoppingLists.doc(id).collection("Purchased Products").get();
      
      for (DocumentSnapshot<Map<String, dynamic>> doc in purchasedProducts.docs) {
        await doc.reference.delete();
      }
      
      // Delete the shopping list document
      await _shoppingLists.doc(id).delete();
    } catch (error) {
      rethrow;
    }
  }
}