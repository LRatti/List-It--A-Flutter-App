import 'package:app_code/screens/auth/auth_gate.dart';
import 'package:app_code/screens/auth/welcome.dart';
import 'package:app_code/screens/settings/settings_screen_mobile.dart';
import 'package:app_code/screens/auth/forgot_password.dart';
import 'package:app_code/screens/profile/verification_screen.dart';
import 'package:app_code/screens/home/home_screen_mobile.dart';
import 'package:app_code/providers/real_app_providers/global_keys_provider.dart';
import 'package:app_code/providers/real_app_providers/recipe_notification_service_provider.dart';
import 'package:app_code/providers/real_app_providers/theme_provider.dart';
import 'package:app_code/services/mock/mock_data_seed.dart';
import 'package:flutter/material.dart';
// firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Seed mock data to the local database if it's empty
  await seedMockDataIfEmpty();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get global keys from providers
    final scaffoldMessengerKey = ref.watch(scaffoldMessengerKeyProvider);
    final navigatorKey = ref.watch(navigatorKeyProvider);

    // Initialize side effects using ref.read() to avoid widget rebuilds
    ref.read(recipeNotificationServiceProvider);

    // MaterialApp is the root widget - always use dark theme with black background
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
      ),
      themeMode: ref.watch(themeProvider),
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => const AuthGate(),
        '/home': (context) => const MobileHomePage(),
        '/settings': (context) => const SettingsScreenMobile(),
        '/signin': (context) => const WelcomeScreen(),
        '/verification': (context) => const VerificationScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
      initialRoute: '/',
    );
  }
}
