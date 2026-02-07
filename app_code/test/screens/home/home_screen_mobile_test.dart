import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/screens/home/home_screen_mobile.dart';
import 'package:app_code/repositories/mock_repo/mock_shopping_list_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_auth_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_location_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_supermarket_location_repository.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/providers/real_app_providers/auth/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/nearest-supermarket/location_repository_provider.dart';
import 'package:app_code/providers/real_app_providers/nearest-supermarket/supermarket_location_repository_provider.dart';
import 'package:app_code/providers/real_app_providers/nearest-supermarket/nearest_supermarket_provider.dart';
import 'package:app_code/providers/real_app_providers/nearest-supermarket/map_launcher_service_provider.dart';
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
  late MockAuthRepository authRepository;
  late MockLocationRepository mockLocationRepository;
  late MockSupermarketLocationRepository mockSupermarketRepository;

  setUp(() async {
    authRepository = MockAuthRepository();
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

  Future<ProviderContainer> pumpHomeScreen(
    WidgetTester tester, {
    Size viewport = const Size(600, 900),
    double devicePixelRatio = 1.0,
  }) async {
    final container = ProviderContainer(
      overrides: [
        shoppingListRepositoryProvider.overrideWithValue(
          MockShoppingListRepository(),
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

    // Configure viewport to control orientation (portrait by default)
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = devicePixelRatio;

    // Dispose container and reset view after test
    addTearDown(() {
      container.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
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
    final l10n = AppLocalizations.of(tester.element(find.byType(MobileHomePage)))!;

    // Starts on Lists tab
    expect(find.byKey(const Key('lists_tab')), findsOneWidget);

    // Go to History
    await tester.tap(find.text(l10n.historyTabLabel));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history_tab')), findsOneWidget);

    // Go to Supermarkets
    await tester.tap(find.text(l10n.supermarketsTabLabel));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('supermarkets_tab')), findsOneWidget);

    // Go to Statistics
    await tester.tap(find.text(l10n.statisticsTabLabel));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('statistics_tab')), findsOneWidget);

    // Back to Lists
    await tester.tap(find.text(l10n.listsTabLabel));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lists_tab')), findsOneWidget);
  });

  testWidgets('HomePage displays TopBar with auth-aware buttons', (
    tester,
  ) async {
    await pumpHomeScreen(tester);
    final l10n = AppLocalizations.of(tester.element(find.byType(MobileHomePage)))!;

    // Verify app bar is present
    expect(find.byType(AppBar), findsWidgets);
    expect(find.text(l10n.appTitle), findsOneWidget);

    // For anonymous user, should show Sign In button
    expect(find.byKey(const Key('sign_in_button')), findsOneWidget);
    expect(find.text(l10n.signInLabel), findsOneWidget);
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
      expect(find.byKey(const Key('logout_button')), findsOneWidget);
      expect(find.byKey(const Key('sign_in_button')), findsNothing);
    },
  );

  testWidgets('HomePage shows bottom navigation bar', (tester) async {
    await pumpHomeScreen(tester);
    final l10n = AppLocalizations.of(tester.element(find.byType(MobileHomePage)))!;

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text(l10n.listsTabLabel), findsOneWidget);
    expect(find.text(l10n.historyTabLabel), findsOneWidget);
    expect(find.text(l10n.supermarketsTabLabel), findsOneWidget);
    expect(find.text(l10n.statisticsTabLabel), findsOneWidget);
  });

  testWidgets('HomePage maintains tab state during navigation', (tester) async {
    await pumpHomeScreen(tester);
    final l10n = AppLocalizations.of(tester.element(find.byType(MobileHomePage)))!;

    // Navigate to a tab
    await tester.tap(find.text(l10n.supermarketsTabLabel));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('supermarkets_tab')), findsOneWidget);

    // Navigate to another tab
    await tester.tap(find.text(l10n.statisticsTabLabel));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('statistics_tab')), findsOneWidget);

    // Go back to previous tab
    await tester.tap(find.text(l10n.supermarketsTabLabel));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('supermarkets_tab')), findsOneWidget);
  });

  testWidgets('Side menu opens and closes via scrim tap', (tester) async {
    await pumpHomeScreen(tester);

    expect(find.byKey(const Key('side_menu')), findsNothing);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('side_menu')), findsOneWidget);
    expect(find.byKey(const Key('side_menu_scrim')), findsOneWidget);

    await tester.tap(find.byKey(const Key('side_menu_scrim')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('side_menu')), findsNothing);
  });

  testWidgets('Shows navigation rail in landscape and switches tabs', (tester) async {
    await pumpHomeScreen(
      tester,
      viewport: const Size(1000, 600),
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(MobileHomePage)))!;

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.byKey(const Key('lists_tab')), findsOneWidget);

    await tester.tap(find.text(l10n.supermarketsTabLabel));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('supermarkets_tab')), findsOneWidget);
  });
}
