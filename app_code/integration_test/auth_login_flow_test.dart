import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/models/user.dart';
import 'package:app_code/models/shopping_list.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/providers/real_app_providers/auth/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/nearest-supermarket/location_repository_provider.dart';
import 'package:app_code/providers/real_app_providers/nearest-supermarket/map_launcher_service_provider.dart';
import 'package:app_code/providers/real_app_providers/nearest-supermarket/nearest_supermarket_provider.dart';
import 'package:app_code/providers/real_app_providers/nearest-supermarket/supermarket_location_repository_provider.dart';
import 'package:app_code/providers/real_app_providers/recipe/recipe_notification_service_provider.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/providers/real_app_providers/supermarket/supermarkets_notifier.dart';
import 'package:app_code/providers/real_app_providers/sync/sync_manager_provider.dart';
import 'package:app_code/repositories/mock_repo/mock_auth_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_location_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_shopping_list_repository.dart';
import 'package:app_code/repositories/mock_repo/mock_supermarket_location_repository.dart';
import 'package:app_code/repositories/sync/sync_repository.dart';
import 'package:app_code/screens/auth/auth_gate.dart';
import 'package:app_code/screens/auth/forgot_password.dart';
import 'package:app_code/screens/profile/verification_screen.dart';
import 'package:app_code/screens/auth/welcome.dart';
import 'package:app_code/screens/home/home_screen.dart';
import 'package:app_code/screens/settings/settings_screen.dart';
import 'package:app_code/services/map_launcher_service.dart';
import 'package:app_code/services/sync/sync_manager.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntegrationTestAuthNotifier extends AuthNotifier {
  IntegrationTestAuthNotifier(this.repository);

  final MockAuthRepository repository;

  @override
  Future<User?> build() async {
    return repository.getCurrentUser();
  }

  @override
  Future<void> ensureAuthenticated() async {
    final user = await repository.ensureAuthenticated();
    state = AsyncData(user);
  }

  @override
  Future<void> signInAnonymously() async {
    final user = await repository.signInAnonymously();
    state = AsyncData(user);
  }

  @override
  Future<void> signUp(String email, String password) async {
    final user = await repository.signUp(email, password);
    state = AsyncData(user);
  }

  @override
  Future<void> signIn(String email, String password) async {
    final user = await repository.signIn(email, password);
    state = AsyncData(user);
  }

  @override
  Future<void> signOut() async {
    await repository.signOut();
    state = AsyncData(repository.getCurrentUser());
  }
}

class TestNearestSupermarketNotifier extends NearestSupermarketNotifier {
  @override
  NearestSupermarketState build() {
    return const NearestSupermarketState(
      isLoading: false,
      errorMessage: 'Location services disabled in test',
    );
  }
}

class TestSupermarketsNotifier extends SupermarketsNotifier {
  @override
  Future<List<Supermarket>> build() async {
    return [];
  }
}

class NoopSyncManager extends SyncManager {
  NoopSyncManager({
    required super.syncRepositoryRegistry,
    required super.prefs,
    required super.firestore,
    required super.firebaseAuth,
  });

  @override
  Future<void> initialize() async {
    // No-op: avoid Firebase/network work during integration tests.
  }

  @override
  void dispose() {
    // No-op.
  }
}

class FakeMapLauncherService extends MapLauncherService {
  @override
  Future<bool> openMap({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    return false;
  }

  @override
  Future<bool> openDirections({
    required double destinationLat,
    required double destinationLon,
    String? destinationLabel,
  }) async {
    return false;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login opens home lists with data', (tester) async {
    final authRepository = MockAuthRepository();
    authRepository.registerTestUser('user@example.com', 'password123');

    final shoppingListRepository = MockShoppingListRepository();
    await shoppingListRepository.add(
      ShoppingList(
        name: 'Weekly groceries',
        createdAt: DateTime(2026, 2, 7),
      ),
    );

    SharedPreferences.setMockInitialValues({
      'first_time_visit': true,
    });
    final prefs = await SharedPreferences.getInstance();

    final fakeAuth = MockFirebaseAuth();
    final fakeFirestore = FakeFirebaseFirestore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          authProvider.overrideWith(
            () => IntegrationTestAuthNotifier(authRepository),
          ),
          shoppingListRepositoryProvider.overrideWithValue(
            shoppingListRepository,
          ),
          recipeNotificationServiceProvider.overrideWith((ref) {}),
          syncManagerProvider.overrideWith(
            (ref) async => NoopSyncManager(
              syncRepositoryRegistry: <String, SyncRepository>{},
              prefs: prefs,
              firestore: fakeFirestore,
              firebaseAuth: fakeAuth,
            ),
          ),
          locationRepositoryProvider.overrideWithValue(
            MockLocationRepository(),
          ),
          supermarketLocationRepositoryProvider.overrideWithValue(
            MockSupermarketLocationRepository(),
          ),
          nearestSupermarketProvider.overrideWith(
            () => TestNearestSupermarketNotifier(),
          ),
          mapLauncherServiceProvider.overrideWithValue(
            FakeMapLauncherService(),
          ),
          supermarketsProvider.overrideWith(
            () => TestSupermarketsNotifier(),
          ),
        ],
        child: MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthGate(
                  homeScreen: HomeScreenMobileView(),
                ),
            '/home': (context) => const HomeScreenMobileView(),
            '/settings': (context) => const SettingsScreenMobile(),
            '/signin': (context) => const WelcomeScreen(),
            '/verification': (context) => const VerificationScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign_up_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sign_up_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('switch_to_sign_in')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('email_field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('sign_in_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('lists_tab')), findsOneWidget);
    expect(find.text('Weekly groceries'), findsOneWidget);
  });
}
