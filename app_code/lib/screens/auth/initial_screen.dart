import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Initial screen shown to first-time users
/// Allows users to either sign up or continue without signing up
class InitialScreen extends ConsumerWidget {
  const InitialScreen({super.key});

  Future<void> _markAsVisited() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time_visit', false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[400]!, Colors.blue[700]!],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Icon/Logo
              Icon(Icons.shopping_cart, size: 120, color: Colors.white),
              const SizedBox(height: 24),

              // App Title
              const Text(
              'My Shopping App',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Subtitle
            const Text(
              'Organize your shopping lists efficiently',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 60),

            // Sign Up Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                key: const Key('sign_up_button'),
                onPressed: () async {
                  await _markAsVisited();
                  if (context.mounted) {
                    // First ensure user is signed in anonymously
                    await authNotifier.ensureAuthenticated();
                    if (context.mounted) {
                      Navigator.of(context).pushNamed('/signin');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Continue without signing up Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                key: const Key('continue_without_signup_button'),
                onPressed: () async {
                  await _markAsVisited();
                  // Sign in anonymously and navigate to home
                  await authNotifier.signInAnonymously();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/home');
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue without signing up',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Info text
            const Text(
              'You can sign up later to sync your lists across devices',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white60),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
