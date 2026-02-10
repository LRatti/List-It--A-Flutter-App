import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/nearby_supermarket.dart';
import 'package:app_code/providers/real_app_providers/nearest-supermarket/location_repository_provider.dart';
import 'package:app_code/providers/real_app_providers/nearest-supermarket/supermarket_location_repository_provider.dart';
import 'package:geolocator/geolocator.dart';

/// State for nearest supermarket feature
enum NearestSupermarketError {
  locationServicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  unableToGetLocation,
  lowGpsAccuracy,
  noneWithinDistance,
  networkTimeout,
  networkIssue,
}

class NearestSupermarketState {
  final NearbySupermarket? supermarket;
  final bool isLoading;
  final NearestSupermarketError? errorType;
  final double? errorDistanceKm;
  final Position? currentPosition;

  const NearestSupermarketState({
    this.supermarket,
    this.isLoading = false,
    this.errorType,
    this.errorDistanceKm,
    this.currentPosition,
  });

  NearestSupermarketState copyWith({
    NearbySupermarket? supermarket,
    bool? isLoading,
    NearestSupermarketError? errorType,
    double? errorDistanceKm,
    Position? currentPosition,
    bool clearSupermarket = false,
    bool clearError = false,
  }) {
    return NearestSupermarketState(
      supermarket: clearSupermarket ? null : (supermarket ?? this.supermarket),
      isLoading: isLoading ?? this.isLoading,
      errorType: clearError ? null : (errorType ?? this.errorType),
      errorDistanceKm:
          clearError ? null : (errorDistanceKm ?? this.errorDistanceKm),
      currentPosition: currentPosition ?? this.currentPosition,
    );
  }

  bool get hasValidSupermarket => supermarket != null && errorType == null;
}

/// Notifier for managing nearest supermarket state
class NearestSupermarketNotifier extends Notifier<NearestSupermarketState> {
  Timer? _refreshTimer;
  Timer? _errorRetryTimer;
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;
  static const double _significantDistanceChange = 100; // meters
  static const Duration _errorRetryInterval = Duration(seconds: 20);

  @override
  NearestSupermarketState build() {
    // Schedule initialization after build completes to avoid circular dependency
    Future.microtask(() => _initialize());
    return const NearestSupermarketState(isLoading: true);
  }

  /// Initialize the feature and start listening for location updates
  Future<void> _initialize() async {
    await fetchNearestSupermarket();
    _startLocationUpdates();
    _startPeriodicRefresh();
  }

  /// Fetch nearest supermarket based on current location
  Future<void> fetchNearestSupermarket() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final locationRepo = ref.read(locationRepositoryProvider);
      final supermarketRepo = ref.read(supermarketLocationRepositoryProvider);

      // 1. Check location service availability
      final serviceEnabled = await locationRepo.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError(
          errorType: NearestSupermarketError.locationServicesDisabled,
        );
        return;
      }

      // 2. Check and request permissions
      LocationPermission permission = await locationRepo.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await locationRepo.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _setError(
          errorType: NearestSupermarketError.permissionDenied,
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _setError(
          errorType: NearestSupermarketError.permissionDeniedForever,
        );
        return;
      }

      // Get current position
      final position = await locationRepo.getCurrentPosition();

      if (position == null) {
        _setError(
          errorType: NearestSupermarketError.unableToGetLocation,
        );
        return;
      }

      // Check GPS accuracy
      if (position.accuracy > 100) {
        _setError(
          errorType: NearestSupermarketError.lowGpsAccuracy,
        );
        return;
      }

      // Update last known position
      _lastPosition = position;

      // Fetch nearby supermarkets
      final supermarkets = await supermarketRepo.fetchNearbySupermarkets(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusInMeters: 5000,
      );

      if (supermarkets.isEmpty) {
        _setError(
          errorType: NearestSupermarketError.noneWithinDistance,
          errorDistanceKm: 5.0,
          currentPosition: position,
        );
        return;
      }

      // Sort by distance and get the nearest
      supermarkets.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
      final nearest = supermarkets.first;

      state = state.copyWith(
        supermarket: nearest,
        isLoading: false,
        currentPosition: position,
        clearError: true,
      );

      _stopErrorRetry();
    } catch (e) {
      final isTimeout = e is TimeoutException;
      _setError(
        errorType: isTimeout
            ? NearestSupermarketError.networkTimeout
            : NearestSupermarketError.networkIssue,
      );
    }
  }

  /// Start listening to location updates
  void _startLocationUpdates() {
    final locationRepo = ref.read(locationRepositoryProvider);
    
    _positionSubscription = locationRepo.getPositionStream().listen(
      (position) {
        // Only refresh if user has moved significantly
        if (_lastPosition != null) {
          final distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          
          if (distance > _significantDistanceChange) {
            fetchNearestSupermarket();
          }
        }
      },
      onError: (error) {
        // Handle errors silently or log them
      },
    );
  }

  /// Start periodic refresh (every 5 minutes)
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => fetchNearestSupermarket(),
    );
  }

  /// Start a faster retry loop when in error state so recovery is reactive
  void _startErrorRetry() {
    _errorRetryTimer ??=
        Timer.periodic(_errorRetryInterval, (_) => fetchNearestSupermarket());
  }

  void _stopErrorRetry() {
    _errorRetryTimer?.cancel();
    _errorRetryTimer = null;
  }

  void _setError({
    required NearestSupermarketError errorType,
    double? errorDistanceKm,
    Position? currentPosition,
  }) {
    state = state.copyWith(
      isLoading: false,
      errorType: errorType,
      errorDistanceKm: errorDistanceKm,
      clearSupermarket: true,
      currentPosition: currentPosition ?? state.currentPosition,
    );
    _startErrorRetry();
  }

  /// Manually refresh
  Future<void> refresh() async {
    await fetchNearestSupermarket();
  }

  /// Clean up resources
  void cleanup() {
    _refreshTimer?.cancel();
    _stopErrorRetry();
    _positionSubscription?.cancel();
  }
}

/// Provider for nearest supermarket
final nearestSupermarketProvider =
    NotifierProvider<NearestSupermarketNotifier, NearestSupermarketState>(
  NearestSupermarketNotifier.new,
);
