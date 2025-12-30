import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/services/database/sqlite/manage_shopping_list.dart' as sqlite;
import 'package:app_code/services/database/firebase/manage_shopping_list.dart';

/// Database Manager for Shopping Lists - Implements write-ahead pattern
/// SQLite operations are executed first (synchronously),
/// Firebase operations follow in a non-blocking manner
class ShoppingListDatabaseManager {
  final FirebaseShoppingListManager _firebaseManager = FirebaseShoppingListManager();

  /// Add a new shopping list to both databases
  /// Write-ahead: SQLite first, then Firebase async
  Future<void> addShoppingList(ShoppingList shoppingList) async {
    // 1. Write to SQLite first (blocking)
    await sqlite.ManageShoppingList.addShoppingList(shoppingList);
    
    // 2. Write to Firebase in non-blocking manner
    _firebaseManager.setShoppingList(shoppingList).catchError((error) {
      print('Firebase sync error (addShoppingList): $error');
    });
  }

  /// Update an existing shopping list in both databases
  /// Write-ahead: SQLite first, then Firebase async
  Future<void> updateShoppingList(ShoppingList shoppingList) async {
    // 1. Update SQLite first (blocking)
    await sqlite.ManageShoppingList.updateShoppingList(shoppingList);
    
    // 2. Update Firebase in non-blocking manner
    _firebaseManager.setShoppingList(shoppingList).catchError((error) {
      print('Firebase sync error (updateShoppingList): $error');
    });
  }

  /// Delete a shopping list from both databases
  /// Write-ahead: SQLite first, then Firebase async
  Future<void> deleteShoppingList(ShoppingList shoppingList) async {
    // 1. Delete from SQLite first (blocking)
    await sqlite.ManageShoppingList.deleteShoppingList(shoppingList);
    
    // 2. Delete from Firebase in non-blocking manner
    _firebaseManager.deleteShoppingList(shoppingList.id).catchError((error) {
      print('Firebase sync error (deleteShoppingList): $error');
    });
  }

  /// Get shopping list by ID - reads from SQLite only (source of truth)
  Future<ShoppingList?> getShoppingListById(String id) async {
    return await sqlite.ManageShoppingList.getShoppingListById(id);
  }

  /// Get all shopping lists - reads from SQLite only (source of truth)
  Future<List<ShoppingList>> getAllShoppingLists() async {
    return await sqlite.ManageShoppingList.getAllShoppingLists();
  }

  // ========== Firebase-specific methods ==========
  
  /// Batch add multiple shopping lists (Firebase-specific feature)
  /// Write-ahead: SQLite first (one by one), then Firebase batch async
  Future<void> setAllShoppingLists(List<ShoppingList> shoppingLists) async {
    // 1. Write to SQLite first (blocking)
    for (var shoppingList in shoppingLists) {
      await sqlite.ManageShoppingList.addShoppingList(shoppingList);
    }
    
    // 2. Batch write to Firebase in non-blocking manner
    _firebaseManager.setAllShoppingLists(shoppingLists).catchError((error) {
      print('Firebase sync error (setAllShoppingLists): $error');
    });
  }
}
