import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/screens/home/home_screen_mobile.dart';
import 'package:app_code/repositories/test_repo/test_shopping_list_repository.dart';
import 'package:app_code/repositories/test_repo/in_memory_auth_repository.dart';
import 'package:app_code/repositories/test_repo/mock_location_repository.dart';
import 'package:app_code/repositories/test_repo/mock_supermarket_location_repository.dart';
import 'package:app_code/providers/real_app_providers/shopping_lists_notifier.dart';
import 'package:app_code/providers/real_app_providers/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/location_repository_provider.dart';
import 'package:app_code/providers/real_app_providers/supermarket_location_repository_provider.dart';
import 'package:app_code/providers/real_app_providers/nearest_supermarket_provider.dart';
import 'package:app_code/providers/real_app_providers/map_launcher_service_provider.dart';
import 'package:app_code/providers/test_providers/test_auth_provider.dart';
import 'package:app_code/services/map_launcher_service.dart';

/// Test notifier for nearest supermarket that doesn't create timers
class TestNearestSupermarketNotifier extends NearestSupermarketNotifier {
  @override
  NearestSupermarketState build() {
    // Return a simple state without initializing timers or location services
    return const NearestSupermarketState(
      isLoading: false,
      errorMessage: 'Location services disabled in test',
    );
  }
}

void main() {
  late InMemoryAuthRepository authRepository;
  late MockLocationRepository mockLocationRepository;
  late MockSupermarketLocationRepository mockSupermarketRepository;

  setUp(() async {
    authRepository = InMemoryAuthRepository();
    await authRepository.signInAnonymously();
    
    // Initialize mock repositories
    mockLocationRepository = MockLocationRepository();
    mockSupermarketRepository = MockSupermarketLocationRepository();
  });

  tearDown(() {
    authRepository.reset();
    mockLocationRepository.reset();
    mockSupermarketRepository.reset();
  });

  Future<ProviderContainer> pumpHomeScreen(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        shoppingListRepositoryProvider.overrideWithValue(
          TestShoppingListRepository(),
        ),
        authRepositoryProvider.overrideWithValue(authRepository),
        authProvider.overrideWith(() => TestAuthNotifier(authRepository)),
        // Override location-related providers to prevent real location service calls
        locationRepositoryProvider.overrideWithValue(mockLocationRepository),
        supermarketLocationRepositoryProvider.overrideWithValue(mockSupermarketRepository),
        // Override nearest supermarket provider with a simple state that doesn't create timers
        nearestSupermarketProvider.overrideWith(() => TestNearestSupermarketNotifier()),
        // Override map launcher service with a no-op implementation
        mapLauncherServiceProvider.overrideWithValue(
          MapLauncherService(),
        ),
      ],
    );
    
    // Dispose container after test
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: const MobileHomePage(),
          routes: {
            '/signin': (context) => const Scaffold(body: Text('Sign In Screen')),
            '/settings': (context) => const Scaffold(body: Text('Settings Screen')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('HomePage switches tabs correctly', (tester) async {
    await pumpHomeScreen(tester);

    // Starts on Lists tab
    expect(find.byKey(const Key('lists_tab')), findsOneWidget);

    // Go to History
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history_tab')), findsOneWidget);

    // Go to Supermarkets
    await tester.tap(find.text('Supermarkets'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('supermarkets_tab')), findsOneWidget);

    // Go to Statistics
    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('statistics_tab')), findsOneWidget);

    // Back to Lists
    await tester.tap(find.text('Lists'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lists_tab')), findsOneWidget);
  });

  testWidgets('HomePage displays TopBar with auth-aware buttons', (
    tester,
  ) async {
    await pumpHomeScreen(tester);

    // Verify app bar is present
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('My Shopping App'), findsOneWidget);

    // For anonymous user, should show Sign In button
    expect(find.byKey(const Key('sign_in_button')), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('HomePage displays auth buttons in TopBar for anonymous user', (
    tester,
  ) async {
    await pumpHomeScreen(tester);

    // Verify anonymous user sees Sign In button
    expect(find.byKey(const Key('sign_in_button')), findsOneWidget);
  });

  testWidgets(
    'HomePage displays auth buttons in TopBar for authenticated user',
    (tester) async {
      // Sign up to become authenticated
      await authRepository.signUp('user@example.com', 'password123');

      await pumpHomeScreen(tester);

      // Verify authenticated user sees settings and logout
      expect(find.byKey(const Key('settings_button')), findsOneWidget);
      expect(find.byKey(const Key('logout_button')), findsOneWidget);
    },
  );

  testWidgets('HomePage shows bottom navigation bar', (tester) async {
    await pumpHomeScreen(tester);

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Lists'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Supermarkets'), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);
  });

  testWidgets('HomePage maintains tab state during navigation', (tester) async {
    await pumpHomeScreen(tester);

    // Navigate to a tab
    await tester.tap(find.text('Supermarkets'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('supermarkets_tab')), findsOneWidget);

    // Navigate to another tab
    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('statistics_tab')), findsOneWidget);

    // Go back to previous tab
    await tester.tap(find.text('Supermarkets'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('supermarkets_tab')), findsOneWidget);
  });
}
