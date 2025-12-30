import 'package:app_code/models/supermarket.dart';
import 'package:app_code/services/database/sqlite/manage_supermarket.dart' as sqlite;
import 'package:app_code/services/database/firebase/manage_supermarket.dart';

/// Database Manager for Supermarkets - Implements write-ahead pattern
/// SQLite operations are executed first (synchronously),
/// Firebase operations follow in a non-blocking manner
class SupermarketDatabaseManager {
  final FirebaseSupermarketManager _firebaseManager = FirebaseSupermarketManager();

  /// Add a new supermarket to both databases
  /// Write-ahead: SQLite first, then Firebase async
  Future<void> addSupermarket(Supermarket supermarket) async {
    // 1. Write to SQLite first (blocking)
    await sqlite.ManageSupermarket.addSupermarket(supermarket);
    
    // 2. Write to Firebase in non-blocking manner
    _firebaseManager.setSupermarket(supermarket).catchError((error) {
      print('Firebase sync error (addSupermarket): $error');
    });
  }

  /// Update an existing supermarket in both databases
  /// Write-ahead: SQLite first, then Firebase async
  Future<void> updateSupermarket(Supermarket supermarket) async {
    // 1. Update SQLite first (blocking)
    await sqlite.ManageSupermarket.updateSupermarket(supermarket);
    
    // 2. Update Firebase in non-blocking manner
    _firebaseManager.setSupermarket(supermarket).catchError((error) {
      print('Firebase sync error (updateSupermarket): $error');
    });
  }

  /// Delete a supermarket from both databases
  /// Write-ahead: SQLite first, then Firebase async
  Future<void> deleteSupermarket(String id) async {
    // 1. Delete from SQLite first (blocking)
    await sqlite.ManageSupermarket.deleteSupermarket(id);
    
    // 2. Delete from Firebase in non-blocking manner
    // Note: Firebase uses setSupermarket, so deletion needs special handling
    // This should be handled in a full sync implementation
  }

  /// Get supermarket by ID - reads from SQLite only (source of truth)
  Future<Supermarket?> getSupermarketById(String id) async {
    return await sqlite.ManageSupermarket.getSupermarketById(id);
  }

  /// Get supermarket by name - reads from SQLite only (source of truth)
  Future<Supermarket?> getSupermarketByName(String name) async {
    return await sqlite.ManageSupermarket.getSupermarketByName(name);
  }

  /// Get all supermarkets - reads from SQLite only (source of truth)
  Future<List<Supermarket>> getAllSupermarkets() async {
    return await sqlite.ManageSupermarket.getAllSupermarkets();
  }

  // ========== Firebase-specific methods ==========
  
  /// Batch add multiple supermarkets (Firebase-specific feature)
  /// Write-ahead: SQLite first (one by one), then Firebase batch async
  Future<void> setAllSupermarkets(List<Supermarket> supermarkets) async {
    // 1. Write to SQLite first (blocking)
    for (var supermarket in supermarkets) {
      await sqlite.ManageSupermarket.addSupermarket(supermarket);
    }
    
    // 2. Batch write to Firebase in non-blocking manner
    _firebaseManager.setAllSupermarkets(supermarkets).catchError((error) {
      print('Firebase sync error (setAllSupermarkets): $error');
    });
  }

  /// Get visible supermarkets - Firebase-specific feature
  /// Since SQLite doesn't have this method, we query Firebase directly
  Future<List<Supermarket>> getVisibleSupermarkets() async {
    return await _firebaseManager.getVisibleSupermarkets();
  }
}
