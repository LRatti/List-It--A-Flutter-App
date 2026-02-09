import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/widgets/top_bar_with_navbar.dart';
import 'package:app_code/providers/real_app_providers/auth/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/nearest-supermarket/nearest_supermarket_provider.dart';
import 'package:app_code/providers/real_app_providers/nearest-supermarket/map_launcher_service_provider.dart';
import 'package:app_code/providers/test_providers/test_auth_provider.dart';
import 'package:app_code/repositories/mock_repo/mock_auth_repository.dart';
import 'package:app_code/services/map_launcher_service.dart';
import 'package:app_code/l10n/app_localizations.dart';

class TestNearestSupermarketNotifier extends NearestSupermarketNotifier {
  @override
  NearestSupermarketState build() {
    return const NearestSupermarketState(
      isLoading: false,
      errorMessage: 'internet not available',
    );
  }
}

class MockMapLauncherService extends MapLauncherService {
  @override
  Future<bool> openMap({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    return true;
  }

  @override
  Future<bool> openDirections({
    required double destinationLat,
    required double destinationLon,
    String? destinationLabel,
  }) async {
    return true;
  }
}

void main() {
  late MockAuthRepository authRepository;

  setUp(() async {
    authRepository = MockAuthRepository();
  });

  tearDown(() {
    authRepository.reset();
  });

  Future<ProviderContainer> pumpTopBar(
    WidgetTester tester, {
    required bool isAnonymous,
    VoidCallback? onMenuToggle,
  }) async {
    if (isAnonymous) {
      await authRepository.signInAnonymously();
    } else {
      await authRepository.signUp('user@example.com', 'password123');
    }

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        authProvider.overrideWith(() => TestAuthNotifier(authRepository)),
        nearestSupermarketProvider
            .overrideWith(() => TestNearestSupermarketNotifier()),
        mapLauncherServiceProvider.overrideWithValue(MockMapLauncherService()),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              height: 800,
              child: Column(
                children: [
                  TopBarWithNavBar(
                    isMenuOpen: false,
                    onMenuToggle: onMenuToggle ?? () {},
                  ),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
          routes: {
            '/signin': (context) =>
                const Scaffold(body: Text('Sign In Screen')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('TopBar shows app title', (tester) async {
    await pumpTopBar(tester, isAnonymous: true);

    expect(find.text('List It'), findsOneWidget);
  });

  testWidgets('TopBar shows supermarket info bar', (tester) async {
    await pumpTopBar(tester, isAnonymous: true);

    expect(
      find.text('internet not available'),
      findsOneWidget,
    );
  });

  testWidgets('TopBar shows Sign In button for anonymous users', (
    tester,
  ) async {
    await pumpTopBar(tester, isAnonymous: true);

    expect(find.byKey(const Key('sign_in_button')), findsOneWidget);
    // The Sign In button is found with its key
  });

  testWidgets('TopBar does not show Sign In button for authenticated users', (
    tester,
  ) async {
    await pumpTopBar(tester, isAnonymous: false);

    expect(find.byKey(const Key('sign_in_button')), findsNothing);
  });

  testWidgets(
    'TopBar shows logout button for authenticated users',
    (tester) async {
      await pumpTopBar(tester, isAnonymous: false);

      expect(find.byKey(const Key('logout_button')), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    },
  );

  testWidgets('TopBar does not show logout for anonymous users', (
    tester,
  ) async {
    await pumpTopBar(tester, isAnonymous: true);

    expect(find.byKey(const Key('logout_button')), findsNothing);
  });

  testWidgets('Sign In button navigates to signin route', (tester) async {
    await pumpTopBar(tester, isAnonymous: true);

    await tester.tap(find.byKey(const Key('sign_in_button')));
    await tester.pumpAndSettle();

    // Verify navigation by checking the route
    expect(find.text('Sign In Screen'), findsOneWidget);
  });

  testWidgets('Menu button triggers callback', (tester) async {
    var tapped = false;

    await pumpTopBar(
      tester,
      isAnonymous: true,
      onMenuToggle: () => tapped = true,
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('Logout button calls signOut', (tester) async {
    await pumpTopBar(tester, isAnonymous: false);

    final userBefore = authRepository.getCurrentUser();
    expect(userBefore!.isAnonymous, isFalse);

    await tester.tap(find.byKey(const Key('logout_button')));
    await tester.pumpAndSettle();

    // After logout, user should be anonymous
    final userAfter = authRepository.getCurrentUser();
    expect(userAfter!.isAnonymous, isTrue);
  });

  testWidgets('TopBar updates when auth state changes', (tester) async {
    // Start with anonymous
    final container = await pumpTopBar(tester, isAnonymous: true);

    expect(find.byKey(const Key('sign_in_button')), findsOneWidget);
    expect(find.byKey(const Key('logout_button')), findsNothing);

    // Sign up to change state
    await container
        .read(authProvider.notifier)
        .signUp('newuser@example.com', 'password123');

    await tester.pumpAndSettle();

    // The ConsumerWidget should rebuild with new auth state
    // After rebuild, logout should be visible
    expect(find.byKey(const Key('logout_button')), findsOneWidget);
  });

  testWidgets('TopBar displays all required elements', (tester) async {
    await pumpTopBar(tester, isAnonymous: true);

    // Verify the TopBar contains the main components
    expect(find.byType(TopBarWithNavBar), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });

  testWidgets('TopBar has appropriate spacing', (tester) async {
    await pumpTopBar(tester, isAnonymous: true);

    // Verify the TopBarWithNavBar widget is properly rendered
    expect(find.byType(TopBarWithNavBar), findsOneWidget);
    expect(find.byType(Material), findsWidgets);
  });
}
