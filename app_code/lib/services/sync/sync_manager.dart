import 'dart:async';
import 'package:app_code/repositories/sync/sync_repository.dart';
import 'package:app_code/services/sync/sync_engine_push.dart';
import 'package:app_code/services/sync/sync_engine_pull.dart';
import 'package:app_code/services/sync/connectivity_monitor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central coordinator for all sync operations
/// Manages push/pull sync engines, connectivity monitoring, and periodic sync scheduling
class SyncManager {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final SharedPreferences _prefs;
  final Map<String, SyncRepository> _syncRepositoryRegistry;
  final Logger _logger;

  final StreamController<String> _remoteEntityChangesController =
      StreamController<String>.broadcast();

  late final SyncEnginePush _pushEngine;
  late final SyncEnginePull _pullEngine;
  late final ConnectivityMonitor _connectivityMonitor;

  Timer? _periodicSyncTimer;
  StreamSubscription? _connectivitySubscription;

  // Configuration
  static const Duration _periodicSyncInterval = Duration(seconds: 10);

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Stream of entity types updated by remote sync (pull engine).
  Stream<String> get remoteEntityChanges =>
      _remoteEntityChangesController.stream;

  SyncManager({
    required Map<String, SyncRepository> syncRepositoryRegistry,
    required SharedPreferences prefs,
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    Logger? logger,
  })  : _syncRepositoryRegistry = syncRepositoryRegistry,
        _prefs = prefs,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _logger = logger ?? Logger();

  /// Initialize the sync manager
  /// - Sets up push/pull engines
  /// - Starts periodic sync
  /// - Monitors connectivity
  /// 
  /// IMPORTANT: This method resets lastSyncedAt to enable proper cold-start sync
  /// when initializing with a new user (e.g., after login/logout transitions).
  /// This ensures changes made while logged out are synced when logging back in.
  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        _logger.w('SyncManager: Already initialized');
        return;
      }

      _logger.i('SyncManager: Initializing...');

      _prefs.remove('lastSyncedAt');
      _logger.i('SyncManager: Reset lastSyncedAt to enable full cold-start sync');

      // Initialize connectivity monitor
      _connectivityMonitor = ConnectivityMonitor(logger: _logger);
      await _connectivityMonitor.initialize();

      // Initialize engines
      _pushEngine = SyncEnginePush(
        syncRepositoryRegistry: _syncRepositoryRegistry,
        firestore: _firestore,
        firebaseAuth: _firebaseAuth,
        logger: _logger,
      );

      _pullEngine = SyncEnginePull(
        syncRepositoryRegistry: _syncRepositoryRegistry,
        prefs: _prefs,
        firestore: _firestore,
        firebaseAuth: _firebaseAuth,
        logger: _logger,
        onRemoteEntityChange: _handleRemoteEntityChange,
      );

      // Start pull sync (cold start + live listeners)
      await _pullEngine.initializeSync();

      // Start periodic push sync
      _startPeriodicSync();

      // Listen to connectivity changes
      _connectivitySubscription = _connectivityMonitor.connectivityStream.listen(
        (isConnected) {
          _logger.i('SyncManager: Connectivity changed to $isConnected');
          if (isConnected) {
            _logger.i('SyncManager: Connection restored, triggering sync');
            _triggerSync();
          }
        },
      );

      _isInitialized = true;
      _logger.i('SyncManager: Initialization complete');
    } catch (e) {
      _logger.e('SyncManager: Error during initialization', error: e);
      rethrow;
    }
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _periodicSyncTimer = Timer.periodic(_periodicSyncInterval, (_) {
      _triggerSync();
    });
    _logger.i('SyncManager: Periodic sync started (interval: ${_periodicSyncInterval.inSeconds}s)');
  }

  /// Trigger a sync cycle (push and pull)
  Future<void> _triggerSync() async {
    if (!_connectivityMonitor.isConnected) {
      _logger.d('SyncManager: No connectivity, skipping sync');
      return;
    }

    try {
      _logger.i('SyncManager: Triggering sync cycle');

      // Run push and pull in parallel
      await Future.wait([
        _pushEngine.processPendingSync().catchError((e) {
          _logger.e('SyncManager: Push sync error', error: e);
          // Don't rethrow, allow pull to complete
        }),
      ]);

      _logger.i('SyncManager: Sync cycle complete');
    } catch (e) {
      _logger.e('SyncManager: Unexpected error in sync cycle', error: e);
    }
  }

  /// Manually trigger a sync (useful for user-initiated refresh)
  Future<void> triggerManualSync() async {
    _logger.i('SyncManager: Manual sync triggered');
    await _triggerSync();
  }

  /// Dispose resources
  void dispose() {
    _logger.i('SyncManager: Disposing...');
    _periodicSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _connectivityMonitor.dispose();
    _pullEngine.dispose();
    _remoteEntityChangesController.close();
    _isInitialized = false;
    _logger.i('SyncManager: Disposed');
  }

  void _handleRemoteEntityChange(String entityType) {
    if (_remoteEntityChangesController.isClosed) return;
    _remoteEntityChangesController.add(entityType);
  }
}
