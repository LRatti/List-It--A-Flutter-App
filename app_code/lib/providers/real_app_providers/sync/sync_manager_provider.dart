import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/services/sync/sync_manager.dart';
import 'package:app_code/repositories/sync/sync_repository.dart';
import 'package:app_code/repositories/sync/shopping_list_repository_sync.dart';
import 'package:app_code/repositories/sync/product_repository_sync.dart';
import 'package:app_code/repositories/sync/purchased_product_repository_sync.dart';
import 'package:app_code/repositories/sync/category_repository_sync.dart';
import 'package:app_code/repositories/sync/supermarket_repository_sync.dart';
import 'package:app_code/providers/real_app_providers/auth/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/providers/real_app_providers/supermarket/supermarkets_notifier.dart';
import 'package:app_code/providers/real_app_providers/category/categories_notifier.dart';
import 'package:app_code/utils/logging_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the current authenticated user ID to detect auth state changes
/// When this changes, the syncManagerProvider will be invalidated
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.whenData((user) => user?.uid).value;
});

/// Tracks the current user's authentication status (anonymous vs authenticated)
/// Used to detect when a user logs in from anonymous state
final currentUserAuthStatusProvider = Provider<({String? uid, bool isAnonymous})>((ref) {
  final authState = ref.watch(authProvider);
  return authState.whenData((user) {
    if (user == null) {
      return (uid: null, isAnonymous: false);
    }
    return (uid: user.uid, isAnonymous: user.isAnonymous);
  }).value ?? (uid: null, isAnonymous: false);
});

/// Provides the registry of all sync-enabled repositories
/// Repositories should be added to this map as they're implemented
final syncRepositoryRegistryProvider = FutureProvider<Map<String, SyncRepository>>((ref) async {
  final shoppingListRepo = ShoppingListRepositoryWithSync();
  final productRepo = ProductRepositoryWithSync();
  final purchasedProductRepo = PurchasedProductRepositoryWithSync();
  final categoryRepo = CategoryRepositoryWithSync();
  final supermarketRepo = SupermarketRepositoryWithSync();

  return {
    ENTITY_TYPE_SHOPPING_LIST: shoppingListRepo,
    ENTITY_TYPE_PRODUCT: productRepo,
    ENTITY_TYPE_PURCHASED_PRODUCT: purchasedProductRepo,
    ENTITY_TYPE_CATEGORY: categoryRepo,
    ENTITY_TYPE_SUPERMARKET: supermarketRepo,
  };
});

/// Provides the SyncManager instance
/// Initializes it on demand and manages its lifecycle
/// 
/// IMPORTANT: This provider depends on currentUserIdProvider so that
/// when the user logs in/out, the SyncManager is automatically invalidated
/// and recreated with a clean state (including reset lastSyncedAt)
final syncManagerProvider = FutureProvider<SyncManager>((ref) async {
  // Watch the current user ID - when this changes, this provider will be invalidated
  final currentUserId = ref.watch(currentUserIdProvider);
  
  // Also watch auth status to detect anonymous -> authenticated transitions
  final authStatus = ref.watch(currentUserAuthStatusProvider);
  
  final registry = await ref.watch(syncRepositoryRegistryProvider.future);
  final prefs = await SharedPreferences.getInstance();
  final syncLogger = createSyncLogger();

  final syncManager = SyncManager(
    syncRepositoryRegistry: registry,
    prefs: prefs,
    firestore: FirebaseFirestore.instance,
    firebaseAuth: FirebaseAuth.instance,
    logger: syncLogger,
  );

  // Initialize the sync manager
  await syncManager.initialize();

  // Listen for remote sync updates and refresh UI providers
  final remoteChangesSubscription = syncManager.remoteEntityChanges.listen(
    (entityType) {
      switch (entityType) {
        case ENTITY_TYPE_SHOPPING_LIST:
        case ENTITY_TYPE_PRODUCT:
        case ENTITY_TYPE_PURCHASED_PRODUCT:
          ref.invalidate(shoppingListsProvider);
          break;
        case ENTITY_TYPE_CATEGORY:
          ref.invalidate(categoriesProvider);
          break;
        case ENTITY_TYPE_SUPERMARKET:
          ref.invalidate(supermarketsProvider);
          break;
      }
    },
  );

  // Force a refresh of local UI data after initial pull completes
  // This ensures remote data appears immediately after first login on a new device
  if (currentUserId != null && !authStatus.isAnonymous) {
    ref.invalidate(shoppingListsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(supermarketsProvider);
  }

  // If user just transitioned from anonymous to authenticated (uid exists but now not anonymous),
  // trigger a manual sync to push pending changes that were queued while offline
  if (currentUserId != null && !authStatus.isAnonymous) {
    // Small delay to ensure Firestore user document structure is ready
    await Future.delayed(const Duration(milliseconds: 200));
    
    try {
      // Trigger a manual sync to push any pending local changes to Firestore
      await syncManager.triggerManualSync();
      syncLogger.i('SyncManager: Post-login sync triggered to push queued changes');
      // Refresh UI after post-login sync
      ref.invalidate(shoppingListsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(supermarketsProvider);
    } catch (e) {
      syncLogger.w('SyncManager: Post-login sync error (non-fatal)', error: e);
      // Don't rethrow - this is informational
    }
  }

  // Ensure cleanup when provider is invalidated
  ref.onDispose(() {
    remoteChangesSubscription.cancel();
    syncManager.dispose();
  });

  return syncManager;
});

/// Provides the sync initialization status
/// Rebuild UI when sync manager is ready
final syncInitializedProvider = FutureProvider<bool>((ref) async {
  final syncManager = await ref.watch(syncManagerProvider.future);
  return syncManager.isInitialized;
});

