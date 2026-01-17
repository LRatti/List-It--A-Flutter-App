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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primaryContainer, // semantic lighter primary
                colorScheme.primary,          // main primary
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Icon/Logo
              Icon(Icons.shopping_cart, size: 120, color: colorScheme.onPrimary),
              const SizedBox(height: 24),

              // App Title
              Text(
                'My Shopping App',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Organize your shopping lists efficiently',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: colorScheme.onPrimary.withAlpha(180)),
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
                      await authNotifier.ensureAuthenticated();
                      if (context.mounted) {
                        Navigator.of(context).pushNamed('/signin');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.onPrimary, // white/contrast
                    foregroundColor: colorScheme.primary,    // primary color text
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
                    await authNotifier.signInAnonymously();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/home');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onPrimary,
                    side: BorderSide(color: colorScheme.onPrimary, width: 2),
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
              Text(
                'You can sign up later to sync your lists across devices',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colorScheme.onPrimary.withAlpha(160)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
