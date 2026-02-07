import 'package:app_code/repositories/abstract/location_repository.dart';
import 'package:app_code/services/geolocator_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

/// Geolocator implementation of LocationRepository
class GeolocatorLocationRepository implements LocationRepository {
  final Logger _logger = Logger();
  final GeolocatorService _geolocatorService;

  GeolocatorLocationRepository({GeolocatorService? geolocatorService})
      : _geolocatorService = geolocatorService ?? RealGeolocatorService();

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await _geolocatorService.isLocationServiceEnabled();
    } catch (e) {
      _logger.e('Error checking location service: $e');
      return false;
    }
  }

  @override
  Future<LocationPermission> checkPermission() async {
    try {
      return await _geolocatorService.checkPermission();
    } catch (e) {
      _logger.e('Error checking permission: $e');
      return LocationPermission.denied;
    }
  }

  @override
  Future<LocationPermission> requestPermission() async {
    try {
      return await _geolocatorService.requestPermission();
    } catch (e) {
      _logger.e('Error requesting permission: $e');
      return LocationPermission.denied;
    }
  }

  @override
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      if (!await isLocationServiceEnabled()) {
        _logger.w('Location services are disabled');
        return null;
      }

      // Check permissions
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          _logger.w('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _logger.w('Location permission denied forever');
        return null;
      }

      // Get position with timeout and accuracy settings
      final position = await _geolocatorService.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Minimum distance change in meters
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Check accuracy
      if (position.accuracy > 100) {
        _logger.w('Low GPS accuracy: ${position.accuracy}m');
        // Still return the position, but caller can check accuracy
      }

      return position;
    } catch (e) {
      _logger.e('Error getting current position: $e');
      return null;
    }
  }

  @override
  Stream<Position> getPositionStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50, // Update when user moves 50m
      timeLimit: Duration(seconds: 10),
    );

    return _geolocatorService.getPositionStream(locationSettings: locationSettings);
  }
}
