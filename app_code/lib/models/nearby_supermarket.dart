import 'dart:math' as math;

/// Model for nearby supermarket from location services
class NearbySupermarket {
  final String name;
  final double latitude;
  final double longitude;
  final double distanceInMeters;

  NearbySupermarket({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distanceInMeters,
  });

  /// Format distance for display
  String get formattedDistance {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  /// Create from Overpass API response
  factory NearbySupermarket.fromOverpassElement(
    Map<String, dynamic> element,
    double userLat,
    double userLon,
  ) {
    final lat = element['lat'] as double;
    final lon = element['lon'] as double;
    final tags = element['tags'] as Map<String, dynamic>? ?? {};
    
    // Extract name, with fallback options
    String name = tags['name'] ?? tags['brand'] ?? 'Supermarket';
    
    // Calculate distance using Haversine formula
    final distance = _calculateDistance(userLat, userLon, lat, lon);

    return NearbySupermarket(
      name: name,
      latitude: lat,
      longitude: lon,
      distanceInMeters: distance,
    );
  }

  /// Calculate distance between two coordinates using Haversine formula
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) * 
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  @override
  String toString() => '$name ($formattedDistance)';
}
