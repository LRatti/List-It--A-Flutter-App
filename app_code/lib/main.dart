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
import 'package:app_code/providers/real_app_providers/theme_provider.dart';
import 'package:app_code/providers/real_app_providers/recipe_notification_service_provider.dart';

// Services
import 'package:app_code/services/mock/mock_data_seed.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Seed mock data only if local database is empty
  await seedMockDataIfEmpty();

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

    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,

      scaffoldMessengerKey: scaffoldMessengerKey,
      navigatorKey: navigatorKey,

      themeMode: ref.watch(themeProvider),

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        appBarTheme: AppBarTheme(
          backgroundColor: lightColorScheme.surface,
          foregroundColor: lightColorScheme.onSurface,
          elevation: 0,
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
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
      },
    );
  }
}
