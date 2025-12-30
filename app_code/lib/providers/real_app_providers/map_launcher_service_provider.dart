import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/services/map_launcher_service.dart';

/// Provider for map launcher service
final mapLauncherServiceProvider = Provider<MapLauncherService>((ref) {
  return MapLauncherService();
});
