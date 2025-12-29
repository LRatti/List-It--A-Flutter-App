import 'package:app_code/providers/real_app_providers/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/user_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Check verification status after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkEmailVerification();
    });
  }

  void _checkEmailVerification() {
    // Use Riverpod auth state instead of direct Firebase access
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

    // Only redirect if user has an email (not anonymous) and email is not verified
    if (currentUser != null &&
        currentUser.email != null &&
        !currentUser.isAnonymous &&
        !currentUser.emailVerified) {
      // Navigate to verification screen
      Navigator.of(context).pushReplacementNamed('/verification');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the auth provider to get real-time updates
    final authState = ref.watch(authProvider);
    final userDetails = ref.watch(userDetailsProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return authState.when(
      data: (currentUser) {
        if (currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Your Profile'),
            backgroundColor: Colors.blue[500],
            centerTitle: true,
            actions: [
              if (!currentUser.isAnonymous) ...[
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    // Implement logout functionality here
                    await authNotifier.signOut();
                  },
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                  icon: const Icon(Icons.person),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signin');
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Sign In'),
                  ),
                ),
              ],
            ],
          ),
          body: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Profile'),
                const SizedBox(height: 16),
                userDetails.when(
                  data: (user) => Text(user?.getUserName() ?? 'Anonymous'),
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Error: $err'),
                ),
                const SizedBox(height: 16),
                if (currentUser.email != null)
                  Text('Email: ${currentUser.email}'),
                const SizedBox(height: 16),
                Text('Welcome to your profile!'),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }
}
