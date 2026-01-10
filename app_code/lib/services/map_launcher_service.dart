import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import 'dart:io';

/// Service for opening maps with location
class MapLauncherService {
  final Logger _logger = Logger();

  /// Open map application with given coordinates
  /// Uses platform-specific map apps (Google Maps on Android, Apple Maps on iOS)
  Future<bool> openMap({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    try {
      // Create appropriate URL based on platform
      final Uri mapUri;
      
      if (Platform.isAndroid) {
        // Google Maps URL for Android
        mapUri = Uri.parse(
          'geo:$latitude,$longitude?q=$latitude,$longitude${label != null ? '($label)' : ''}',
        );
      } else if (Platform.isIOS) {
        // Apple Maps URL for iOS
        mapUri = Uri.parse(
          'maps://?q=${label ?? 'Supermarket'}&ll=$latitude,$longitude',
        );
      } else {
        // Fallback to Google Maps web for other platforms
        mapUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
        );
      }

      // Try to launch the map
      final canLaunch = await canLaunchUrl(mapUri);
      
      if (canLaunch) {
        final launched = await launchUrl(
          mapUri,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) {
          _logger.i('Successfully opened map for location: $latitude, $longitude');
          return true;
        }
      }

      // If platform-specific failed, try Google Maps web as fallback
      final webMapUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );
      
      final webLaunched = await launchUrl(
        webMapUri,
        mode: LaunchMode.externalApplication,
      );
      
      if (webLaunched) {
        _logger.i('Opened web map as fallback');
        return true;
      }

      _logger.w('Failed to open map');
      return false;
    } catch (e) {
      _logger.e('Error opening map: $e');
      return false;
    }
  }

  /// Open directions from current location to destination
  Future<bool> openDirections({
    required double destinationLat,
    required double destinationLon,
    String? destinationLabel,
  }) async {
    try {
      final Uri directionsUri;
      
      if (Platform.isAndroid) {
        // Google Maps directions for Android
        directionsUri = Uri.parse(
          'google.navigation:q=$destinationLat,$destinationLon',
        );
      } else if (Platform.isIOS) {
        // Apple Maps directions for iOS
        directionsUri = Uri.parse(
          'maps://?daddr=$destinationLat,$destinationLon',
        );
      } else {
        // Google Maps web directions
        directionsUri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLon',
        );
      }

      final canLaunch = await canLaunchUrl(directionsUri);
      
      if (canLaunch) {
        return await launchUrl(
          directionsUri,
          mode: LaunchMode.externalApplication,
        );
      }

      // Fallback to web
      final webUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLon',
      );
      
      return await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      _logger.e('Error opening directions: $e');
      return false;
    }
  }
}
