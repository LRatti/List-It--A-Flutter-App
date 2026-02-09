# Libraries Used in the Project

This list is based on actual Dart imports found in lib/, test/, and integration_test/.

## Production dependencies (used in app code)
- flutter: Core Flutter SDK for UI, widgets, and application framework.
- flutter_localizations: Built-in localization delegates and locale support for Flutter.
- flutter_riverpod: State management and dependency injection for app features.
- isar: Model annotations and schema support for local data models.
- firebase_core: Firebase initialization and platform setup.
- firebase_auth: User authentication (email/password, Google sign-in integration).
- google_sign_in: Google account sign-in flow.
- cloud_firestore: Cloud Firestore database access and queries.
- uuid: Unique ID generation for entities and sync entries.
- sqflite: Local SQLite persistence for offline data and caches.
- path: File path utilities (used to build database paths).
- logger: Structured logging across services and repositories.
- shared_preferences: Persistent key-value storage for settings and sync state.
- intl: Localization and date/number formatting.
- geolocator: Device geolocation (used for nearest supermarket feature).
- http: HTTP client for remote API requests (e.g., Overpass queries).
- url_launcher: Opens map links in external apps.
- connectivity_plus: Network connectivity monitoring for sync.
- camera: Camera access for receipt capture.
- google_generative_ai: Gemini API client for recipe/product intelligence.
- google_mlkit_text_recognition: On-device OCR for receipt text extraction.

## Test-only dependencies (dev_dependencies used in tests)
- flutter_test: Flutter unit/widget testing framework.
- integration_test: Flutter integration testing framework.
- sqflite_common_ffi: SQLite FFI support for tests on desktop.
- fake_cloud_firestore: In-memory Firestore for tests.
- firebase_auth_mocks: Firebase Auth mocks for tests.
- mocktail: Mocking library for unit tests.

## Test-only transitive imports (used in tests, not declared directly)
- plugin_platform_interface: Base types used to mock platform interfaces.
- url_launcher_platform_interface: Platform interface used to test URL launching.

## Declared but not referenced in Dart imports
These appear in pubspec.yaml but are not imported in Dart code.
- provider
- permission_handler
- flutter_staggered_grid_view
- flutter_lints

---

# External Services and APIs

This section documents all external services, cloud platforms, and third-party APIs that the app integrates with.

## Firebase Platform (Google Cloud)
The app uses Firebase for authentication, cloud storage, and real-time synchronization.

- **Firebase Core**: Platform initialization and configuration for Android, iOS, and web.
- **Firebase Authentication**: User authentication with the following methods:
  - Email/password authentication
  - Google Sign-In OAuth integration
  - Password reset functionality
- **Cloud Firestore**: NoSQL cloud database for:
  - User data synchronization across devices
  - Shopping lists, products, supermarkets, and categories
  - Real-time data updates and offline persistence

## Google APIs

### Google Generative AI (Gemini)
- **Service**: Google Gemini API
- **Model**: `gemini-2.5-flash`
- **API Key**: Required via compile-time environment variable `GEMINI_API_KEY`
- **Features**:
  - **Recipe Generation**: AI-powered recipe suggestions based on available products
  - **Product Categorization**: Automatic categorization of products into supermarket categories
  - **Receipt Extraction**: Intelligent extraction of product prices and quantities from receipt text
- **Implementation**: [lib/services/gemini/](../lib/services/gemini/)

### Google Sign-In
- **Service**: Google OAuth 2.0
- **Purpose**: Provides "Sign in with Google" authentication flow
- **Integration**: Works with Firebase Authentication for seamless user login

### Google Maps (Android)
- **Platform**: Android only
- **Service**: Google Maps navigation via URL scheme
- **Purpose**: Opens device location in Google Maps for navigation to supermarkets
- **URL Format**: `geo:latitude,longitude?q=latitude,longitude(label)`

### Google ML Kit (On-Device)
- **Service**: Google ML Kit Text Recognition
- **Processing**: On-device OCR (no external API calls)
- **Purpose**: Extracts text from receipt photos captured by camera
- **Privacy**: All processing happens locally on the device

## OpenStreetMap Services

### Overpass API
- **Service**: Overpass API (OpenStreetMap data query service)
- **Endpoint**: `https://overpass-api.de/api/interpreter`
- **Purpose**: Find nearby supermarkets based on user location
- **Query Format**: Overpass QL queries for nodes/ways tagged with `shop=supermarket`
- **Radius**: Configurable search radius (default: 5000 meters)
- **Timeout**: 15 seconds
- **Implementation**: [lib/repositories/real_app_repo/overpass_supermarket_location_repository.dart](../lib/repositories/real_app_repo/overpass_supermarket_location_repository.dart)

## Apple Services

### Apple Maps (iOS)
- **Platform**: iOS only
- **Service**: Apple Maps navigation via URL scheme
- **Purpose**: Opens device location in Apple Maps for navigation to supermarkets
- **URL Format**: `maps://?q=label&ll=latitude,longitude`

## Platform-Specific Map Integration

The app intelligently selects the appropriate map service based on the platform:
- **Android**: Google Maps via `geo:` URI scheme
- **iOS**: Apple Maps via `maps://` URI scheme
- **Web/Other**: Google Maps web interface via HTTPS URL

Implementation: [lib/services/map_launcher_service.dart](../lib/services/map_launcher_service.dart)

## Device Services (Local Access)

These are not external APIs but local device capabilities accessed via platform plugins:

- **Geolocator**: Device GPS and location services for finding nearby supermarkets
- **Camera**: Device camera access for receipt photo capture
- **Connectivity Plus**: Network connectivity monitoring for sync operations
- **Shared Preferences**: Local key-value storage for app settings and sync state
- **SQLite (sqflite)**: Local database for offline data persistence

---

# API Keys and Configuration

## Required API Keys
1. **GEMINI_API_KEY**: Must be provided via compile-time define
   ```bash
   flutter run --dart-define=GEMINI_API_KEY=your_key_here
   ```

## Firebase Configuration
Firebase configuration is auto-generated via FlutterFire CLI and stored in:
- [lib/firebase_options.dart](../lib/firebase_options.dart)
- Platform-specific configuration files (google-services.json, GoogleService-Info.plist)

## No API Key Required
The following services do not require API keys:
- Overpass API (free, public OpenStreetMap data service)
- Apple Maps (platform-native iOS integration)
- Google Maps (URL scheme, no API key needed for basic navigation)
