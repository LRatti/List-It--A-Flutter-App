import 'package:app_code/models/purchased_product.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/services/database/firebase/manage_purchased_product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// This class manages shopping lists in the Firebase database, including 
/// creating, retrieving, and deleting shopping lists. 
/// It also handles the association of shopping lists with supermarkets 
/// and purchased products.
class FirebaseShoppingListManager {
  // Class implementation

  FirebaseShoppingListManager({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebasePurchasedProductManager? purchasedProductManager,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _purchasedProductManager = purchasedProductManager ??
            FirebasePurchasedProductManager(
              firebaseAuth: firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
              firestore: firestore ?? FirebaseFirestore.instance,
            );

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebasePurchasedProductManager _purchasedProductManager;
  
  CollectionReference<Map<String, dynamic>> get _shoppingLists {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return _firestore.collection("Users").doc(uid).collection("Shopping Lists");
  }
  
  CollectionReference<Map<String, dynamic>> get _supermarkets {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return _firestore.collection("Users").doc(uid).collection("Supermarkets");
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
    
    WriteBatch batch = _firestore.batch();
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

  Future<ShoppingList?> getShoppingListById(String listId) async {
    // Code to retrieve a shopping list by its ID from the database
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _shoppingLists.doc(listId).get();
      if (doc.exists) {
        Supermarket supermarket;
        ShoppingList shoppingList;
        List<PurchasedProduct> purchasedProducts = [];
        if (doc.data() != null) {
          shoppingList = ShoppingList.fromDatabase(doc.data()!);
          final supermarketId = doc.data()!['supermarket_id'];
          if (supermarketId != null) {
            supermarket = await _supermarkets
                .doc(supermarketId)
                .get()
                .then((supermarketDoc) => Supermarket.fromDatabase(supermarketDoc.data()!));
            shoppingList.setSupermarket(supermarket);
          } else {
            // Shopping list without a supermarket is invalid
            print("Shopping list $listId is missing supermarket_id.");
            return null;
          }
          // Fetch and set purchased products
          purchasedProducts = await _purchasedProductManager.getPurchasedProductByList(listId);
          shoppingList.setPurchasedProducts(purchasedProducts);
          return shoppingList;
        } else {
          // Handle case where list data is missing
          print("Shopping list data is missing for id $listId.");
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


  /// Retrieves all shopping lists from the database.
  ///
  /// This method fetches all shopping lists by querying the database
  /// and returns a list of `ShoppingList` objects. 
  /// 
  /// Returns:
  /// A `Future<List<ShoppingList>>` containing all the shopping lists
  /// retrieved from the database. If no lists are found or an error
  /// occurs, an empty list is returned.
  Future<List<ShoppingList>> getAllShoppingLists() async {
    // Code to retrieve all shopping lists from the database
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _shoppingLists.get();

      List<ShoppingList?> shoppingLists = await Future.wait(
        querySnapshot.docs.map(
          (doc) => getShoppingListById(doc.id)
        )
      );

      // Filter out null values and return only found shopping lists
      return shoppingLists.whereType<ShoppingList>().toList();

    } catch (e) {
      print("Error fetching shopping lists: $e");
      return [];
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