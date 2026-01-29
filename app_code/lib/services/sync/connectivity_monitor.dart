import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

/// Monitors internet connectivity and notifies listeners of changes
class ConnectivityMonitor {
  final Connectivity _connectivity;
  final Logger _logger;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();

  bool _isConnected = true;

  ConnectivityMonitor({
    Connectivity? connectivity,
    Logger? logger,
  })  : _connectivity = connectivity ?? Connectivity(),
        _logger = logger ?? Logger();

  /// Stream of connectivity status changes
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _isConnected = !result.contains(ConnectivityResult.none);
      _logger.i('ConnectivityMonitor: Initial connectivity status: $_isConnected');

      // Listen to connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen((result) {
        final wasConnected = _isConnected;
        _isConnected = !result.contains(ConnectivityResult.none);

        if (wasConnected != _isConnected) {
          _logger.i('ConnectivityMonitor: Connectivity changed to $_isConnected');
          _connectivityController.add(_isConnected);
        }
      });
    } catch (e) {
      _logger.e('ConnectivityMonitor: Error initializing', error: e);
      // Assume connected if we can't determine
      _isConnected = true;
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
    _logger.i('ConnectivityMonitor: Disposed');
  }
}
