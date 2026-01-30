import 'package:app_code/models/sync/local_sync_entry.dart';
import 'package:app_code/models/sync/sync_operation.dart';
import 'package:app_code/repositories/sync/sync_repository.dart';
import 'package:app_code/services/database/sqlite/manage_sync_box.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

/// Sync Engine for pushing local changes to Firestore
/// Implements the Local → Remote push with Last-Write-Wins conflict resolution
class SyncEnginePush {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final Map<String, SyncRepository> _syncRepositoryRegistry;
  final Logger _logger;

  SyncEnginePush({
    required Map<String, SyncRepository> syncRepositoryRegistry,
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    Logger? logger,
  })  : _syncRepositoryRegistry = syncRepositoryRegistry,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _logger = logger ?? Logger();

  /// Process all pending sync entries
  /// Triggered periodically or on connectivity restoration
  Future<void> processPendingSync() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        _logger.w('SyncEngine: No authenticated user, skipping sync');
        return;
      }

      // Skip push sync for anonymous users
      // Anonymous users should only save data locally; sync to Firestore after login
      if (user.isAnonymous) {
        _logger.d('SyncEngine: User is anonymous, skipping Firestore push (data saved locally only)');
        return;
      }

      // Get all pending sync entries
      final entries = await ManageSyncBox.getSyncEntriesByModificationTime();
      if (entries.isEmpty) {
        _logger.i('SyncEngine: No pending sync entries');
        return;
      }

      _logger.i('SyncEngine: Processing ${entries.length} pending sync entries');

      // Process each entry with limited concurrency (e.g., max 3 concurrent operations)
      const int maxConcurrency = 3;
      for (int i = 0; i < entries.length; i += maxConcurrency) {
        final batch = entries.sublist(
          i,
          i + maxConcurrency > entries.length ? entries.length : i + maxConcurrency,
        );

        await Future.wait(batch.map((entry) => _processSyncEntry(entry, user.uid)));
      }

      _logger.i('SyncEngine: Sync batch completed');
    } catch (e) {
      _logger.e('SyncEngine: Error during push sync', error: e);
      rethrow;
    }
  }

  /// Process a single sync entry with Firestore transaction
  Future<void> _processSyncEntry(LocalSyncEntry entry, String userId) async {
    try {
      final repository = _syncRepositoryRegistry[entry.entityType];
      if (repository == null) {
        _logger.w('SyncEngine: No repository found for entity type ${entry.entityType}');
        return;
      }

      // Get the local data
      final localData = await repository.getLocalData(entry.entityId);
      if (localData == null && entry.operation == SyncOperation.upsert) {
        _logger.w('SyncEngine: Local data not found for ${entry.entityType}/${entry.entityId}');
        // Delete the sync entry since local data doesn't exist
        await ManageSyncBox.deleteSyncEntry(
          entry.entityId,
          entry.entityType,
          entry.lastModified,
        );
        return;
      }

      // Push dependencies first (before the main entity)
      if (localData != null && entry.operation == SyncOperation.upsert) {
        await _pushDependencies(entry.entityType, localData, userId);
      }

      // Run Firestore transaction
      await _firestore.runTransaction((transaction) async {
        // Construct the Firestore document path
        final docRef = _firestore
            .collection('Users')
            .doc(userId)
            .collection(entry.entityType)
            .doc(entry.entityId);

        // Read the remote document
        final remoteSnapshot = await transaction.get(docRef);

        if (remoteSnapshot.exists) {
          final remoteData = remoteSnapshot.data() ?? {};
          final remoteLastModified = _parseTimestamp(remoteData['lastModified']);

          // Compare timestamps for LWW
          if (remoteLastModified != null && remoteLastModified.isAfter(entry.lastModified)) {
            // Case A: Remote is newer - apply remote data to local
            _logger.i('SyncEngine: Remote is newer for ${entry.entityType}/${entry.entityId}, applying remote update');
            // Apply the remote data via repository's silent update
            await repository.applyRemoteUpdate(remoteData);
          } else {
            // Case B: Local is newer or remote is null - write with server timestamp
            _logger.i('SyncEngine: Writing local changes for ${entry.entityType}/${entry.entityId}');
            final dataToWrite = Map<String, dynamic>.from(localData ?? {});
            dataToWrite['lastModified'] = FieldValue.serverTimestamp();

            if (entry.operation == SyncOperation.delete) {
              dataToWrite['isDeleted'] = true;
              dataToWrite['lastModified'] = FieldValue.serverTimestamp();
            }

            transaction.set(docRef, dataToWrite, SetOptions(merge: true));
          }
        } else if (entry.operation == SyncOperation.upsert) {
          // Remote document doesn't exist - create it
          _logger.i('SyncEngine: Creating remote document for ${entry.entityType}/${entry.entityId}');
          final dataToWrite = Map<String, dynamic>.from(localData ?? {});
          dataToWrite['lastModified'] = FieldValue.serverTimestamp();
          transaction.set(docRef, dataToWrite);
        } else if (entry.operation == SyncOperation.delete) {
          // Remote doesn't exist, sync entry should be cleaned up
          _logger.i('SyncEngine: Remote document already deleted for ${entry.entityType}/${entry.entityId}');
        }

        // Post-process: Clean up sync box entry after transaction success
        _logger.i('SyncEngine: Cleaning up sync_box entry for ${entry.entityType}/${entry.entityId}');
        await ManageSyncBox.deleteSyncEntry(
          entry.entityId,
          entry.entityType,
          entry.lastModified,
        );
      });

      _logger.i('SyncEngine: Successfully synced ${entry.entityType}/${entry.entityId}');
    } catch (e) {
      _logger.e('SyncEngine: Error processing sync entry: ${entry.entityType}/${entry.entityId}', error: e);
      // Leave entry in sync_box for retry in next cycle
    }
  }

  /// Parse timestamp from Firestore data
  /// Handles both Timestamp objects and ISO8601 strings
  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// Push dependencies to Firestore before pushing the main entity
  /// Ensures foreign key references exist in Firestore
  Future<void> _pushDependencies(
    String entityType,
    Map<String, dynamic> localData,
    String userId,
  ) async {
    try {
      if (entityType == ENTITY_TYPE_PURCHASED_PRODUCT) {
        // PurchasedProduct depends on Product and Category
        await _pushDependency(
          localData['product_id'],
          ENTITY_TYPE_PRODUCT,
          userId,
        );
        await _pushDependency(
          localData['category_id'],
          ENTITY_TYPE_CATEGORY,
          userId,
        );
      } else if (entityType == ENTITY_TYPE_SHOPPING_LIST) {
        // ShoppingList depends on Supermarket
        final supermarketId = localData['supermarket_id'];
        if (supermarketId != null) {
          await _pushDependency(
            supermarketId,
            ENTITY_TYPE_SUPERMARKET,
            userId,
          );
        }
      }
    } catch (e) {
      _logger.w('SyncEngine: Error pushing dependencies for $entityType', error: e);
      // Continue even if dependency push fails - main entity will still be pushed
    }
  }

  /// Push a single dependency entity to Firestore if it doesn't exist
  Future<void> _pushDependency(
    String? entityId,
    String entityType,
    String userId,
  ) async {
    if (entityId == null || entityId.isEmpty) return;

    try {
      final repository = _syncRepositoryRegistry[entityType];
      if (repository == null) {
        _logger.w('SyncEngine: No repository for dependency $entityType');
        return;
      }

      // Check if the dependency already exists in Firestore
      final docRef = _firestore
          .collection('Users')
          .doc(userId)
          .collection(entityType)
          .doc(entityId);

      final snapshot = await docRef.get();
      if (snapshot.exists) {
        _logger.d('SyncEngine: Dependency $entityType/$entityId already exists in Firestore');
        return;
      }

      // Get local data for the dependency
      final localData = await repository.getLocalData(entityId);
      if (localData == null) {
        _logger.w('SyncEngine: Local data not found for dependency $entityType/$entityId');
        return;
      }

      // Push the dependency to Firestore
      _logger.i('SyncEngine: Pushing dependency $entityType/$entityId to Firestore');
      final dataToWrite = Map<String, dynamic>.from(localData);
      dataToWrite['lastModified'] = FieldValue.serverTimestamp();
      await docRef.set(dataToWrite);

      _logger.i('SyncEngine: Successfully pushed dependency $entityType/$entityId');
    } catch (e) {
      _logger.e('SyncEngine: Error pushing dependency $entityType/$entityId', error: e);
      // Don't rethrow - allow main entity push to proceed
    }
  }
}
