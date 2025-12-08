import 'package:app_code/screens/auth/welcome.dart';
import 'package:app_code/screens/home/profile.dart';
import 'package:app_code/screens/settings/settings_screen.dart';
import 'package:app_code/services/auth_service.dart';
import 'package:flutter/material.dart';
// firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Automatically sign in anonymously only if no user is signed in
  await AuthService.ensureAuthenticated();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
  
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/settings': (context) => const SettingsScreen(),
        '/signin': (context) => const WelcomeScreen(),
      },
      home: const ProfileScreen(),
    );
  }
}