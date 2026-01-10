# Nearest Supermarket Feature - Implementation Guide

## Overview
This feature displays the nearest supermarket in the top navigation bar of the home screen. It shows the supermarket name and distance from the user's current location. When clicked, it opens the supermarket location in the device's default map application.

## Architecture

The implementation follows the established app design pattern:
```
UI (TopBarWithNavBar) 
  ↓
Riverpod Provider (nearestSupermarketProvider)
  ↓
Repositories (LocationRepository, SupermarketLocationRepository)
  ↓
External Services (Geolocator, Overpass API)
```

## Files Created

### 1. Models
- **`lib/models/nearby_supermarket.dart`**
  - Data model for nearby supermarkets
  - Includes distance calculation using Haversine formula
  - Formats distance for display (meters/kilometers)

### 2. Abstract Repositories
- **`lib/repositories/abstract/location_repository.dart`**
  - Interface for location services
  - Methods: check permissions, get current position, position stream

- **`lib/repositories/abstract/supermarket_location_repository.dart`**
  - Interface for fetching nearby supermarkets
  - Method: fetchNearbySupermarkets with radius parameter

### 3. Concrete Implementations
- **`lib/repositories/real_app_repo/geolocator_location_repository.dart`**
  - Implements LocationRepository using Geolocator package
  - Handles permissions, GPS accuracy checks, and location updates
  - 10-second timeout for position requests
  - Minimum 10-meter accuracy for reliable results

- **`lib/repositories/real_app_repo/overpass_supermarket_location_repository.dart`**
  - Implements SupermarketLocationRepository using Overpass API
  - Queries OpenStreetMap for supermarkets within a 5km radius
  - 15-second timeout for network requests
  - Handles both node and way elements from OSM

### 4. Riverpod Providers
- **`lib/providers/real_app_providers/location_repository_provider.dart`**
  - Provider for LocationRepository instance

- **`lib/providers/real_app_providers/supermarket_location_repository_provider.dart`**
  - Provider for SupermarketLocationRepository instance

- **`lib/providers/real_app_providers/nearest_supermarket_provider.dart`**
  - Main state management for the feature
  - Manages location updates, supermarket fetching, and error states
  - Automatic refresh: every 5 minutes or when user moves 100+ meters
  - States: loading, success with data, error/fallback message

- **`lib/providers/real_app_providers/map_launcher_service_provider.dart`**
  - Provider for MapLauncherService instance

### 5. Services
- **`lib/services/map_launcher_service.dart`**
  - Opens map applications with coordinates
  - Platform-specific support:
    - Android: Google Maps (geo: URI)
    - iOS: Apple Maps (maps: URI)
    - Fallback: Google Maps web
  - Also supports opening directions

### 6. UI Updates
- **`lib/widgets/top_bar_with_navbar.dart`**
  - Updated to display nearest supermarket
  - Visual indicators:
    - Green background when supermarket found
    - Grey background when unavailable
    - Loading spinner during fetch
    - Place icon for valid supermarket
    - Location-off icon for errors
  - Clickable to open map when supermarket is available
  - Shows SnackBar if map cannot be opened

## Configuration Files Updated

### Android
- **`android/app/src/main/AndroidManifest.xml`**
  - Added location permissions (FINE and COARSE)
  - Added INTERNET permission
  - Added intent queries for map apps and HTTPS

### iOS
- **`ios/Runner/Info.plist`**
  - Added location usage descriptions
  - NSLocationWhenInUseUsageDescription
  - NSLocationAlwaysAndWhenInUseUsageDescription

### Dependencies
- **`pubspec.yaml`**
  - `geolocator: ^13.0.2` - GPS location services
  - `http: ^1.2.2` - HTTP requests to Overpass API
  - `url_launcher: ^6.3.1` - Opening map applications
  - `permission_handler: ^11.3.1` - Managing location permissions

## Feature Behavior

### Success Case
1. App requests location permission (if not granted)
2. Gets current GPS position
3. Checks GPS accuracy (must be < 100m)
4. Queries Overpass API for nearby supermarkets (5km radius)
5. Calculates distances and finds nearest
6. Displays: "Supermarket Name - Distance"
7. On click: Opens map app with supermarket location

### Error Handling
The feature shows "Unable to detect nearby supermarkets" when:
- Location permission denied
- GPS disabled
- GPS accuracy > 100 meters (low accuracy)
- No supermarkets found within 5km
- Network timeout (>15s for API request)
- Any other error occurs

### Dynamic Updates
- **Position Stream**: Updates when user moves 100+ meters
- **Periodic Refresh**: Every 5 minutes
- **Seamless**: Updates UI without interrupting user

## State Management

### NearestSupermarketState
```dart
{
  supermarket: NearbySupermarket?,  // Found supermarket or null
  isLoading: bool,                   // Fetching in progress
  errorMessage: String?,             // Error or null if success
  currentPosition: Position?         // Last known GPS position
}
```

### Display Logic
- Loading: "Locating nearby supermarkets..."
- Success: "Name - Distance"
- Error: "Unable to detect nearby supermarkets"

## User Experience Enhancements

1. **Visual Feedback**
   - Color-coded background (green = success, grey = error)
   - Appropriate icons (place vs location-off)
   - Loading spinner during fetch

2. **Click Interaction**
   - Only clickable when supermarket is found
   - Opens preferred map app
   - Shows error message if map launch fails

3. **Performance**
   - Minimum distance threshold (100m) to avoid excessive updates
   - Periodic refresh to keep data current
   - Timeout protection for network and GPS requests

## API Details

### Overpass API Query
```
[out:json][timeout:10];
(
  node["shop"="supermarket"](around:5000,latitude,longitude);
  way["shop"="supermarket"](around:5000,latitude,longitude);
);
out center;
```

- Searches for OSM elements tagged as supermarkets
- Within 5000 meters of user location
- Returns both nodes and ways with their center points
- 10-second server-side timeout

## Testing Recommendations

1. **Location Permissions**
   - Test with permissions denied
   - Test with permissions granted
   - Test permission request flow

2. **GPS Scenarios**
   - GPS disabled
   - Low GPS accuracy
   - Moving user (test automatic updates)
   - Stationary user

3. **Network Conditions**
   - Slow network (test timeout)
   - No network connection
   - Intermittent connection

4. **Supermarket Availability**
   - Urban area (many supermarkets)
   - Rural area (few or no supermarkets)
   - Edge of search radius

5. **Map Opening**
   - Android devices (Google Maps)
   - iOS devices (Apple Maps)
   - Devices without map apps (web fallback)

## Suggestions for Improvements

### 1. Caching Strategy
**Current**: Fetches from API every time
**Improvement**: Cache results for a few minutes to reduce API calls and improve responsiveness
```dart
// Add to NearestSupermarketNotifier
DateTime? _lastFetchTime;
List<NearbySupermarket>? _cachedSupermarkets;

// Check cache before fetching
if (_shouldUseCache()) {
  // Use cached data
}
```

### 2. Background Location Permission
**Current**: Only "when in use" permission
**Improvement**: Option for background location to update even when app is backgrounded
- Better for users who keep app running
- Requires additional privacy justification

### 3. User Preferences
**Current**: Fixed 5km radius
**Improvement**: Allow users to configure:
- Search radius (2km, 5km, 10km)
- Update frequency
- Enable/disable feature
```dart
// Settings screen addition
final searchRadiusProvider = StateProvider<double>((ref) => 5000);
```

### 4. Multiple Supermarkets Display
**Current**: Shows only nearest
**Improvement**: Show top 3 nearest with expandable list
- More options for users
- Better if nearest is closed/not preferred

### 5. Supermarket Details
**Current**: Only name and distance
**Improvement**: Show additional info from OSM:
- Opening hours
- Brand/chain
- Phone number
- Star rating (if available)

### 6. Offline Fallback
**Current**: Requires network for Overpass API
**Improvement**: Cache OSM data locally
- Use local database for known supermarkets
- Update periodically when online
- Works offline for frequently visited areas

### 7. Error State Differentiation
**Current**: Single error message for all failures
**Improvement**: More specific messages:
- "Location permission required"
- "Please enable GPS"
- "No supermarkets nearby"
- "Connection issue, retrying..."

### 8. Performance Optimization
**Current**: Re-fetches all supermarkets on location change
**Improvement**: 
- Use geohashing to partition space
- Only re-fetch if user crosses partition boundary
- Reduces API calls significantly

### 9. Accessibility
**Current**: Basic text display
**Improvement**: 
- Add semantic labels for screen readers
- Voice announcement of nearest supermarket
- High contrast mode support

### 10. Analytics
**Suggestion**: Track feature usage:
- How often users click to open map
- Average distance to nearest supermarket
- Success rate of location/API requests
- Help identify issues and usage patterns

## Potential Issues & Solutions

### Issue 1: Battery Drain
**Cause**: Continuous location updates
**Solution**: 
- Increase distance filter to 100m (already implemented)
- Add option to disable continuous tracking
- Use significant location change API on iOS

### Issue 2: API Rate Limiting
**Cause**: Too many requests to Overpass API
**Solution**: 
- Implement caching (see Improvement #1)
- Add exponential backoff on failures
- Consider self-hosting Overpass instance

### Issue 3: Inaccurate Location in Buildings
**Cause**: GPS doesn't work well indoors
**Solution**: 
- Show accuracy indicator to user
- Use last known outdoor location if current is inaccurate
- Add manual location entry option

### Issue 4: Map App Not Installed
**Cause**: User has no map app
**Solution**: 
- Already implemented: web fallback
- Could detect available apps first
- Provide app installation prompt

## Maintenance Notes

1. **Dependency Updates**: Monitor for breaking changes in:
   - geolocator (major version changes)
   - url_launcher (platform handling)

2. **API Changes**: Overpass API is stable but monitor:
   - Rate limiting changes
   - Schema changes for shop tags

3. **Platform Updates**: 
   - Android/iOS permission model changes
   - Background execution restrictions

4. **Testing**: Add integration tests for:
   - Location permission flows
   - API error handling
   - Map launching

## Conclusion

This implementation provides a robust, user-friendly nearest supermarket feature that:
- ✅ Follows the app's architectural patterns
- ✅ Handles errors gracefully
- ✅ Updates dynamically
- ✅ Works across platforms
- ✅ Provides good UX with visual feedback
- ✅ Is maintainable and extensible

The feature is production-ready but can be enhanced with the suggested improvements based on user feedback and usage analytics.
