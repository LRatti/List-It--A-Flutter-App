import 'package:app_code/models/category.dart';
import 'package:app_code/services/database/sqlite/manage_category.dart' as sqlite;
import 'package:app_code/services/database/firebase/manage_category.dart';

/// Database Manager for Categories - Implements write-ahead pattern
/// SQLite operations are executed first (synchronously),
/// Firebase operations follow in a non-blocking manner
class CategoryDatabaseManager {
  final FirebaseCategoryManager _firebaseManager = FirebaseCategoryManager();

  /// Add a new category to both databases
  /// Write-ahead: SQLite first, then Firebase async
  Future<void> addCategory(Category category) async {
    // 1. Write to SQLite first (blocking)
    await sqlite.ManageCategory.addCategory(category);
    
    // 2. Write to Firebase in non-blocking manner
    _firebaseManager.setCategory(category).catchError((error) {
      print('Firebase sync error (addCategory): $error');
    });
  }

  /// Update an existing category in both databases
  /// Write-ahead: SQLite first, then Firebase async
  Future<void> updateCategory(Category category) async {
    // 1. Update SQLite first (blocking)
    await sqlite.ManageCategory.updateCategory(category);
    
    // 2. Update Firebase in non-blocking manner
    _firebaseManager.setCategory(category).catchError((error) {
      print('Firebase sync error (updateCategory): $error');
    });
  }

  /// Delete a category from both databases
  /// Write-ahead: SQLite first, then Firebase async
  Future<void> deleteCategory(String id) async {
    // 1. Delete from SQLite first (blocking)
    await sqlite.ManageCategory.deleteCategory(id);
    
    // 2. Delete from Firebase in non-blocking manner
    // Note: Firebase uses setCategory, so deletion needs special handling
    // This should be handled in a full sync implementation
  }

  /// Get category by ID - reads from SQLite only (source of truth)
  Future<Category?> getCategoryById(String id) async {
    return await sqlite.ManageCategory.getCategoryById(id);
  }

  /// Get category by name - reads from SQLite only (source of truth)
  Future<Category?> getCategoryByName(String name) async {
    return await sqlite.ManageCategory.getCategoryByName(name);
  }

  /// Get all categories - reads from SQLite only (source of truth)
  Future<List<Category>> getAllCategories() async {
    return await sqlite.ManageCategory.getAllCategories();
  }

  // ========== Firebase-specific methods ==========
  
  /// Batch add multiple categories (Firebase-specific feature)
  /// Write-ahead: SQLite first (one by one), then Firebase batch async
  Future<void> setAllCategories(List<Category> categories) async {
    // 1. Write to SQLite first (blocking)
    for (var category in categories) {
      await sqlite.ManageCategory.addCategory(category);
    }
    
    // 2. Batch write to Firebase in non-blocking manner
    _firebaseManager.setAllCategories(categories).catchError((error) {
      print('Firebase sync error (setAllCategories): $error');
    });
  }
}
