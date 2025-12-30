import 'dart:convert';
import 'package:app_code/models/nearby_supermarket.dart';
import 'package:app_code/repositories/abstract/supermarket_location_repository.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

/// Overpass API implementation for fetching nearby supermarkets
class OverpassSupermarketLocationRepository
    implements SupermarketLocationRepository {
  final Logger _logger = Logger();
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const Duration _timeout = Duration(seconds: 15);

  @override
  Future<List<NearbySupermarket>> fetchNearbySupermarkets({
    required double latitude,
    required double longitude,
    double radiusInMeters = 5000,
  }) async {
    try {
      // Build Overpass QL query
      // Search for nodes and ways tagged as shop=supermarket
      final query = '''
[out:json][timeout:10];
(
  node["shop"="supermarket"](around:$radiusInMeters,$latitude,$longitude);
  way["shop"="supermarket"](around:$radiusInMeters,$latitude,$longitude);
);
out center;
''';

      _logger.d('Fetching supermarkets near ($latitude, $longitude)');

      // Make HTTP request
      final response = await http
          .post(
            Uri.parse(_overpassUrl),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'data': query},
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        _logger.e('Overpass API error: ${response.statusCode}');
        return [];
      }

      // Parse response
      final data = json.decode(response.body) as Map<String, dynamic>;
      final elements = data['elements'] as List<dynamic>? ?? [];

      if (elements.isEmpty) {
        _logger.i('No supermarkets found');
        return [];
      }

      // Convert to NearbySupermarket objects
      final supermarkets = <NearbySupermarket>[];
      for (final element in elements) {
        try {
          final elementMap = element as Map<String, dynamic>;
          
          // Handle both nodes (with direct lat/lon) and ways (with center)
          double? lat;
          double? lon;
          
          if (elementMap.containsKey('lat') && elementMap.containsKey('lon')) {
            lat = elementMap['lat'] as double?;
            lon = elementMap['lon'] as double?;
          } else if (elementMap.containsKey('center')) {
            final center = elementMap['center'] as Map<String, dynamic>;
            lat = center['lat'] as double?;
            lon = center['lon'] as double?;
          }
          
          if (lat != null && lon != null) {
            final supermarket = NearbySupermarket.fromOverpassElement(
              {'lat': lat, 'lon': lon, 'tags': elementMap['tags']},
              latitude,
              longitude,
            );
            supermarkets.add(supermarket);
          }
        } catch (e) {
          _logger.w('Error parsing supermarket element: $e');
          continue;
        }
      }

      _logger.i('Found ${supermarkets.length} supermarkets');
      return supermarkets;
    } catch (e) {
      _logger.e('Error fetching supermarkets: $e');
      return [];
    }
  }
}
