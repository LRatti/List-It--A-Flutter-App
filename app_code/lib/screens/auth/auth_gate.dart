import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/auth/auth_provider.dart';
import 'package:app_code/screens/auth/initial_screen.dart';
import 'package:app_code/screens/home/home_screen_mobile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider to check if this is the first time the app is opened
final firstTimeVisitProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final isFirstTime = prefs.getBool('first_time_visit') ?? true;
  return isFirstTime;
});

/// Router widget that determines which screen to show based on auth state
/// and whether it's the user's first visit
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final firstTimeVisit = ref.watch(firstTimeVisitProvider);

    // Show loading while checking auth state and first visit
    if (authState.isLoading || firstTimeVisit.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Handle errors
    if (authState.hasError || firstTimeVisit.hasError) {
      return Scaffold(
        body: Center(
          child: Text('Error: ${authState.error ?? firstTimeVisit.error}'),
        ),
      );
    }

    final user = authState.value;
    final isFirstTime = firstTimeVisit.value ?? true;

    // If first time visit and no user, show initial screen
    if (isFirstTime && user == null) {
      return const InitialScreen();
    }

    // Otherwise show home screen
    return const MobileHomePage();
  }
}
