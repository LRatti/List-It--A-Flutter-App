import 'package:geolocator/geolocator.dart';

/// Abstract repository for location operations
abstract class LocationRepository {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled();

  /// Check location permission status
  Future<LocationPermission> checkPermission();

  /// Request location permission
  Future<LocationPermission> requestPermission();

  /// Get current position
  /// Returns null if location is not available
  Future<Position?> getCurrentPosition();

  /// Get position stream for continuous updates
  Stream<Position> getPositionStream();
}
