import 'package:app_code/services/database/sqlite/manage_supermarket.dart';

/// Utility for ensuring a favorite supermarket is always initialized
/// 
/// This is called during app startup to handle:
/// 1. Fresh installs: Default supermarket is already marked as favorite in seedMockDataIfEmpty
/// 2. Upgrades: Ensures a favorite is selected if one doesn't exist
/// 3. Lifecycle: Maintains the invariant that exactly one supermarket is favorite
class FavoriteSupermarketInitializer {
  /// Ensures that there is exactly one favorite supermarket
  /// 
  /// This is called on app startup to handle upgrade scenarios where
  /// the database may not have a favorite initialized.
  /// 
  /// Returns true if a favorite was successfully ensured, false if there
  /// was an error or no supermarkets exist at all.
  static Future<bool> ensureFavoriteInitialized() async {
    try {
      // Check if there's already a favorite supermarket
      final currentFavorite = await ManageSupermarket.getFavoriteSupermarket();
      if (currentFavorite != null) {
        // A favorite already exists, nothing to do
        print('✅ Favorite supermarket already initialized: ${currentFavorite.getName()}');
        return true;
      }

      // No favorite exists, we need to set one
      final allSupermarkets = await ManageSupermarket.getAllSupermarkets();
      
      if (allSupermarkets.isEmpty) {
        // No supermarkets exist at all
        print('⚠️ No supermarkets available to set as favorite');
        return false;
      }

      // Get the first visible supermarket (or first one if none are visible)
      final visibleSupermarkets = allSupermarkets.where((s) => s.isVisible).toList();
      final supermarketToFavor = visibleSupermarkets.isNotEmpty 
          ? visibleSupermarkets.first 
          : allSupermarkets.first;

      // Set it as favorite
      await ManageSupermarket.setFavoriteSupermarket(supermarketToFavor.id);
      print('✅ Automatically initialized favorite supermarket: ${supermarketToFavor.getName()}');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error initializing favorite supermarket: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }
}
