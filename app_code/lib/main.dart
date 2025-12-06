import 'package:app_code/models/user.dart';
import 'package:app_code/providers/auth_provider.dart';
import 'package:app_code/screens/auth/welcome.dart';
import 'package:app_code/screens/home/profile.dart';
import 'package:app_code/screens/settings/settings.dart';
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
      home: Consumer(
        builder: (context, ref, child) {
          final AsyncValue<User?> user = ref.watch(authProvider);
          
          return user.when(
            data: (user) {
              // User is always authenticated (either anonymously or with credentials)
              // so we always show the ProfileScreen
              if (user != null) {
                print('User ID: ${user.uid}, Anonymous: ${user.isAnonymous}');
                return ProfileScreen(user: user);
              }
              // Fallback to loading in case user is somehow null
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }, 
            error: (error, __) => Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Error loading auth status'),
                    const SizedBox(height: 8),
                    Text(error.toString(), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            loading: () => Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Loading...'),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }
}