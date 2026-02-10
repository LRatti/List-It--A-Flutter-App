import 'dart:async';

import 'package:app_code/repositories/sync/sync_repository.dart';
import 'package:app_code/services/database/sqlite/manage_sync_box.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sync Engine for pulling remote changes from Firestore to local SQLite
/// Implements both cold start (delta sync) and live usage (snapshot listeners)
class SyncEnginePull {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final Map<String, SyncRepository> _syncRepositoryRegistry;
  final SharedPreferences _prefs;
  final Logger _logger;
  final void Function(String entityType)? _onRemoteEntityChange;

  // Store snapshot listeners to manage them
  final Map<String, StreamSubscription> _listeners = {};

  SyncEnginePull({
    required Map<String, SyncRepository> syncRepositoryRegistry,
    required SharedPreferences prefs,
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    Logger? logger,
    void Function(String entityType)? onRemoteEntityChange,
  })  : _syncRepositoryRegistry = syncRepositoryRegistry,
        _prefs = prefs,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _logger = logger ?? Logger(),
        _onRemoteEntityChange = onRemoteEntityChange;

  /// Initialize sync pull: run cold start then setup live listeners
  Future<void> initializeSync() async {
    try {
      _logger.i('SyncEnginePull: Initializing sync (cold start + live listeners)');

      // Step 1: Cold start - fetch delta from lastSyncedAt
      await _coldStartSync();

      // Step 2: Setup live listeners for continued updates
      await _setupLiveListeners();

      _logger.i('SyncEnginePull: Sync initialization complete');
    } catch (e) {
      _logger.e('SyncEnginePull: Error during initialization', error: e);
      rethrow;
    }
  }

  /// Cold start: Pull all changes since lastSyncedAt
  /// Strategy A from requirements
  Future<void> _coldStartSync() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        _logger.w('SyncEnginePull: No authenticated user, skipping cold start');
        return;
      }

      // Skip pull sync for anonymous users
      // Anonymous users should only work with local data
      if (user.isAnonymous) {
        _logger.d('SyncEnginePull: User is anonymous, skipping cold start (local data only)');
        return;
      }

      _logger.i('SyncEnginePull: Starting cold start delta sync');

      // Get lastSyncedAt from persistent storage
      final lastSyncedAtStr = _prefs.getString('lastSyncedAt');
      final lastSyncedAt = lastSyncedAtStr != null ? DateTime.parse(lastSyncedAtStr) : DateTime(2000);

      _logger.i('SyncEnginePull: Last synced at: $lastSyncedAt');

      // Query each entity type for documents where lastModified > lastSyncedAt
      for (final entityType in _syncRepositoryRegistry.keys) {
        await _coldStartSyncForEntityType(entityType, lastSyncedAt, user.uid);
      }

      _logger.i('SyncEnginePull: Cold start sync complete');
    } catch (e) {
      _logger.e('SyncEnginePull: Error during cold start', error: e);
      rethrow;
    }
  }

  /// Cold start sync for a specific entity type with pagination
  Future<void> _coldStartSyncForEntityType(
    String entityType,
    DateTime lastSyncedAt,
    String userId,
  ) async {
    try {
      _logger.i('SyncEnginePull: Cold start for entity type: $entityType');

      final collectionRef = _firestore
          .collection('Users')
          .doc(userId)
          .collection(entityType);

      DateTime newestLastModified = lastSyncedAt;
      bool hasMore = true;
      DocumentSnapshot? lastDoc;

      while (hasMore) {
        // Build query for documents where lastModified > lastSyncedAt
        Query query = collectionRef
            .where('lastModified', isGreaterThan: lastSyncedAt)
            .orderBy('lastModified')
            .limit(100);

        // Pagination support
        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }

        final snapshot = await query.get();
        if (snapshot.docs.isEmpty) {
          hasMore = false;
          break;
        }

        // Process each document
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Ensure ID is in the data

          try {
            // Apply silent update (won't write to sync_box)
            await _silentUpdate(entityType, data);

            // Track the newest timestamp
            final timestamp = _parseTimestamp(data['lastModified']);
            if (timestamp != null && timestamp.isAfter(newestLastModified)) {
              newestLastModified = timestamp;
            }
          } catch (e) {
            _logger.w('SyncEnginePull: Error applying update for $entityType/${doc.id}', error: e);
            // Continue with next document
          }
        }

        // Continue pagination
        lastDoc = snapshot.docs.last;
        if (snapshot.docs.length < 100) {
          hasMore = false;
        }
      }

      // Update lastSyncedAt with the newest timestamp seen
      _prefs.setString('lastSyncedAt', newestLastModified.toIso8601String());
      _logger.i('SyncEnginePull: Updated lastSyncedAt for $entityType: $newestLastModified');
    } catch (e) {
      _logger.e('SyncEnginePull: Error in cold start for $entityType', error: e);
      // Don't rethrow to allow other entity types to sync
    }
  }

  /// Setup live snapshot listeners for continued updates
  /// Strategy B from requirements
  Future<void> _setupLiveListeners() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        _logger.w('SyncEnginePull: No authenticated user, skipping live listeners');
        return;
      }

      // Skip live listeners for anonymous users
      // Anonymous users should only work with local data
      if (user.isAnonymous) {
        _logger.d('SyncEnginePull: User is anonymous, skipping live listeners (local data only)');
        return;
      }

      _logger.i('SyncEnginePull: Setting up live listeners for ${_syncRepositoryRegistry.length} entity types');

      for (final entityType in _syncRepositoryRegistry.keys) {
        // Remove existing listener if any
        _listeners[entityType]?.cancel();

        // Setup new listener
        final subscription = _firestore
            .collection('Users')
            .doc(user.uid)
            .collection(entityType)
            .snapshots()
            .listen(
          (snapshot) async {
            try {
              _logger.d('SyncEnginePull: Received snapshot for $entityType with ${snapshot.docChanges.length} changes');

              DateTime? newestTimestamp;

              // Process all document changes (added, modified, removed)
              // Create a copy to avoid concurrent modification errors when callbacks trigger UI updates
              final changes = snapshot.docChanges.toList();
              for (final change in changes) {
                final data = change.doc.data();
                if (data == null) continue;

                data['id'] = change.doc.id;

                // Apply silent update for each change
                try {
                  await _silentUpdate(entityType, data);

                  // Track newest timestamp
                  final timestamp = _parseTimestamp(data['lastModified']);
                  if (timestamp != null && (newestTimestamp == null || timestamp.isAfter(newestTimestamp))) {
                    newestTimestamp = timestamp;
                  }
                } catch (e) {
                  _logger.w('SyncEnginePull: Error applying snapshot update for $entityType/${change.doc.id}', error: e);
                }
              }

              // Update lastSyncedAt with the newest timestamp
              if (newestTimestamp != null) {
                final existingLastSyncedStr = _prefs.getString('lastSyncedAt');
                final existingLastSynced =
                    existingLastSyncedStr != null ? DateTime.parse(existingLastSyncedStr) : DateTime(2000);

                final updatedLastSynced = newestTimestamp.isAfter(existingLastSynced) ? newestTimestamp : existingLastSynced;
                _prefs.setString('lastSyncedAt', updatedLastSynced.toIso8601String());
              }
            } catch (e) {
              _logger.e('SyncEnginePull: Error processing snapshot for $entityType', error: e);
            }
          },
          onError: (e) {
            _logger.e('SyncEnginePull: Error in listener for $entityType', error: e);
          },
        );

        _listeners[entityType] = subscription;
      }

      _logger.i('SyncEnginePull: Live listeners setup complete');
    } catch (e) {
      _logger.e('SyncEnginePull: Error setting up live listeners', error: e);
      rethrow;
    }
  }

  /// Silent Update: Apply remote data to local SQLite without generating sync_box entries
  /// This is the crucial mechanism to prevent infinite sync loops
  Future<void> _silentUpdate(String entityType, Map<String, dynamic> remoteData) async {
    try {
      final repository = _syncRepositoryRegistry[entityType];
      if (repository == null) {
        _logger.w('SyncEnginePull: No repository found for entity type $entityType');
        return;
      }

      final entityId = remoteData['id'] as String?;
      if (entityId == null) {
        _logger.w('SyncEnginePull: No ID in remote data for $entityType');
        return;
      }

      final isDirty = await ManageSyncBox.isEntityDirty(entityId, entityType);
      if (isDirty) {
        _logger.d('SyncEnginePull: Entity $entityType/$entityId is dirty (pending sync), ignoring remote update to preserve local changes');
        return;
      }

      // Compare timestamps: only proceed if remote.lastModified > local.lastModified
      final localData = await repository.getLocalData(entityId);
      if (localData != null) {
        final remoteLastModified = _parseTimestamp(remoteData['lastModified']);
        final localLastModified = _parseTimestamp(localData['last_modified']);

        if (remoteLastModified != null && localLastModified != null && localLastModified.isAfter(remoteLastModified)) {
          _logger.d('SyncEnginePull: Local is newer for $entityType/$entityId, ignoring remote');
          return;
        }
      }

      // Apply the update via repository (no sync_box write)
      _logger.d('SyncEnginePull: Applying silent update for $entityType/$entityId');
      await repository.applyRemoteUpdate(remoteData);
      _onRemoteEntityChange?.call(entityType);
    } catch (e) {
      _logger.e('SyncEnginePull: Error in silent update for $entityType', error: e);
      rethrow;
    }
  }

  /// Parse timestamp from Firestore data
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

  /// Cancel all active listeners
  /// Call this during app shutdown or logout
  void dispose() {
    for (final subscription in _listeners.values) {
      subscription.cancel();
    }
    _listeners.clear();
    _logger.i('SyncEnginePull: Disposed all listeners');
  }
}
