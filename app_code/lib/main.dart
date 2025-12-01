import 'package:app_code/models/user.dart';
import 'package:app_code/providers/auth_provider.dart';
import 'package:app_code/screens/auth/welcome.dart';
import 'package:app_code/screens/home/profile.dart';
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
      debugShowCheckedModeBanner: false ,
      home: Consumer(
        builder: (context, ref, child) {
          final AsyncValue<User?> user = ref.watch(authProvider);
          
          return user.when(
            data: (user) {
              if (user == null) {
                return const WelcomeScreen();
              }
              return ProfileScreen(user: user);
            }, 
            error: (error, __) => const Text('error loading auth status.'), 
            loading: () => const Text('loading...'),
          );
        }
      ),
    );
  }
}