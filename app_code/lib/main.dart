import 'package:app_code/screens/history/history_screen_mobile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

// Screens
import 'package:app_code/screens/auth/auth_gate.dart';
import 'package:app_code/screens/auth/welcome.dart';
import 'package:app_code/screens/auth/forgot_password.dart';
import 'package:app_code/screens/profile/verification_screen.dart';
import 'package:app_code/screens/home/home_screen_mobile.dart';
import 'package:app_code/screens/settings/settings_screen_mobile.dart';

// Providers
import 'package:app_code/providers/real_app_providers/global_keys_provider.dart';
import 'package:app_code/providers/real_app_providers/app-style/theme_provider.dart';
import 'package:app_code/providers/real_app_providers/app-style/font_size_provider.dart';
import 'package:app_code/providers/real_app_providers/recipe/recipe_notification_service_provider.dart';
import 'package:app_code/providers/real_app_providers/shopping_list/shopping_lists_notifier.dart';
import 'package:app_code/providers/real_app_providers/sync/sync_manager_provider.dart';

// Styles
import 'package:app_code/styles/scaled_typography.dart';

// Services
import 'package:app_code/services/mock/mock_data_seed.dart';

// Utils
import 'package:app_code/utils/favorite_supermarket_initializer.dart';
import 'package:app_code/utils/uncategorized_category_initializer.dart';

/// Performs all initialization tasks required at app startup.
/// This includes Firebase setup, mock data seeding, cleanup operations, and sync engine initialization.
Future<void> _runStartupTasks() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Seed mock data only if local database is empty
  await seedMockDataIfEmpty();

  // Ensure a single hidden uncategorized category exists and is attached
  await UncategorizedCategoryInitializer.ensureInitialized();

  // Ensure a favorite supermarket is initialized (handles fresh installs and upgrades)
  await FavoriteSupermarketInitializer.ensureFavoriteInitialized();

  // Create a temporary ProviderContainer to run cleanup at startup
  final container = ProviderContainer();
  try {
    // Clean up expired shopping lists (30+ days in trash)
    await container.read(shoppingListsProvider.notifier).cleanupExpiredLists();

    // NOTE: Sync Manager will be initialized on first access via Riverpod provider
    // This is handled automatically in MyApp widget via the syncInitializedProvider
  } finally {
    container.dispose();
  }
}

void main() async {
  await _runStartupTasks();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaffoldMessengerKey = ref.watch(scaffoldMessengerKeyProvider);
    final navigatorKey = ref.watch(navigatorKeyProvider);

    // Initialize notification service (side effect, no rebuild needed)
    ref.read(recipeNotificationServiceProvider);

    // Initialize sync manager (side effect)
    // This will setup pull listeners and periodic push sync
    // Errors are logged but don't block UI
    ref.watch(syncManagerProvider).whenData((_) {
      // Sync manager is ready
    });

    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    );

    // Watch font size and theme mode for reactive updates
    final fontSizeMultiplier = ref.watch(fontSizeValueProvider);
    final themeMode = ref.watch(themeModeValueProvider);

    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,

      scaffoldMessengerKey: scaffoldMessengerKey,
      navigatorKey: navigatorKey,

      themeMode: themeMode,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        textTheme: ScaledTypography.generateScaledTextTheme(
          fontSizeMultiplier: fontSizeMultiplier,
          colorScheme: lightColorScheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: lightColorScheme.surface,
          foregroundColor: lightColorScheme.onSurface,
          elevation: 0,
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        textTheme: ScaledTypography.generateScaledTextTheme(
          fontSizeMultiplier: fontSizeMultiplier,
          colorScheme: darkColorScheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: darkColorScheme.surface,
          foregroundColor: darkColorScheme.onSurface,
          elevation: 0,
        ),
      ),

      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/home': (context) => const MobileHomePage(),
        '/settings': (context) => const SettingsScreenMobile(),
        '/signin': (context) => const WelcomeScreen(),
        '/verification': (context) => const VerificationScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/history': (context) => const HistoryScreenMobile(),
      },
    );
  }
}
