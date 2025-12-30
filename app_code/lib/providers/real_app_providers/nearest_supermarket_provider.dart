import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/models/nearby_supermarket.dart';
import 'package:app_code/providers/real_app_providers/location_repository_provider.dart';
import 'package:app_code/providers/real_app_providers/supermarket_location_repository_provider.dart';
import 'package:geolocator/geolocator.dart';

/// State for nearest supermarket feature
class NearestSupermarketState {
  final NearbySupermarket? supermarket;
  final bool isLoading;
  final String? errorMessage;
  final Position? currentPosition;

  const NearestSupermarketState({
    this.supermarket,
    this.isLoading = false,
    this.errorMessage,
    this.currentPosition,
  });

  NearestSupermarketState copyWith({
    NearbySupermarket? supermarket,
    bool? isLoading,
    String? errorMessage,
    Position? currentPosition,
    bool clearSupermarket = false,
    bool clearError = false,
  }) {
    return NearestSupermarketState(
      supermarket: clearSupermarket ? null : (supermarket ?? this.supermarket),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentPosition: currentPosition ?? this.currentPosition,
    );
  }

  /// Get display text for UI
  String get displayText {
    if (isLoading) {
      return 'Locating nearby supermarkets...';
    }
    if (errorMessage != null) {
      return errorMessage!;
    }
    if (supermarket != null) {
      return '${supermarket!.name} - ${supermarket!.formattedDistance}';
    }
    return 'Unable to detect nearby supermarkets';
  }

  bool get hasValidSupermarket => supermarket != null && errorMessage == null;
}

/// Notifier for managing nearest supermarket state
class NearestSupermarketNotifier extends Notifier<NearestSupermarketState> {
  Timer? _refreshTimer;
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;
  static const double _significantDistanceChange = 100; // meters

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

      // Get current position
      final position = await locationRepo.getCurrentPosition();

      if (position == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Unable to detect nearby supermarkets',
          clearSupermarket: true,
        );
        return;
      }

      // Check GPS accuracy
      if (position.accuracy > 100) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Unable to detect nearby supermarkets',
          clearSupermarket: true,
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
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Unable to detect nearby supermarkets',
          clearSupermarket: true,
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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to detect nearby supermarkets',
        clearSupermarket: true,
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

  /// Manually refresh
  Future<void> refresh() async {
    await fetchNearestSupermarket();
  }

  /// Clean up resources
  void cleanup() {
    _refreshTimer?.cancel();
    _positionSubscription?.cancel();
  }
}

/// Provider for nearest supermarket
final nearestSupermarketProvider =
    NotifierProvider<NearestSupermarketNotifier, NearestSupermarketState>(
  NearestSupermarketNotifier.new,
);
