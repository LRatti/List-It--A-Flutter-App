import 'package:app_code/repositories/abstract/location_repository.dart';
import 'package:geolocator/geolocator.dart';

/// Mock implementation of LocationRepository for testing
class MockLocationRepository implements LocationRepository {
  bool _shouldFailPositionRequest = false;
  bool _shouldFailPermissionRequest = false;
  bool _locationServiceEnabled = true;
  LocationPermission _permissionStatus = LocationPermission.whileInUse;
  Position? _mockPosition;
  List<Position>? _positionStreamSequence;

  /// Configure to fail on next position request
  void setPositionRequestFailure(bool shouldFail) {
    _shouldFailPositionRequest = shouldFail;
  }

  /// Configure to fail on next permission request
  void setPermissionRequestFailure(bool shouldFail) {
    _shouldFailPermissionRequest = shouldFail;
  }

  /// Configure location service availability
  void setLocationServiceEnabled(bool enabled) {
    _locationServiceEnabled = enabled;
  }

  /// Configure permission status
  void setPermissionStatus(LocationPermission status) {
    _permissionStatus = status;
  }

  /// Set a mock position to return
  void setMockPosition(Position position) {
    _mockPosition = position;
  }

  /// Set a sequence of positions for stream testing
  void setPositionStreamSequence(List<Position> positions) {
    _positionStreamSequence = positions;
  }

  /// Reset all configurations
  void reset() {
    _shouldFailPositionRequest = false;
    _shouldFailPermissionRequest = false;
    _locationServiceEnabled = true;
    _permissionStatus = LocationPermission.whileInUse;
    _mockPosition = null;
    _positionStreamSequence = null;
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return _locationServiceEnabled;
  }

  @override
  Future<LocationPermission> checkPermission() async {
    return _permissionStatus;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    if (_shouldFailPermissionRequest) {
      return LocationPermission.denied;
    }
    return _permissionStatus;
  }

  @override
  Future<Position?> getCurrentPosition() async {
    if (_shouldFailPositionRequest) {
      return null;
    }

    if (_mockPosition != null) {
      return _mockPosition;
    }

    // Default test position: London, UK
    return Position(
      latitude: 51.5074,
      longitude: -0.1278,
      timestamp: DateTime.now(),
      accuracy: 30.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      isMocked: true, 
      headingAccuracy: 0.0,
    );
  }

  @override
  Stream<Position> getPositionStream() {
    if (_positionStreamSequence != null && _positionStreamSequence!.isNotEmpty) {
      return Stream.fromIterable(_positionStreamSequence!);
    }

    // Default stream that emits positions periodically
    return Stream.periodic(
      const Duration(seconds: 10),
      (count) => Position(
        latitude: 51.5074 + (count * 0.001),
        longitude: -0.1278 + (count * 0.001),
        timestamp: DateTime.now(),
        accuracy: 30.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        speed: 1.0,
        speedAccuracy: 0.0,
        isMocked: true, 
        headingAccuracy: 0.0,
      ),
    );
  }
}
