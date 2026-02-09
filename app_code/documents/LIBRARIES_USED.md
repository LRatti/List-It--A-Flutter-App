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
