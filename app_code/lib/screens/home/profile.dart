import 'package:app_code/providers/auth_provider.dart';
import 'package:app_code/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the auth provider to get real-time updates
    final authState = ref.watch(authProvider);
    
    return authState.when(
      data: (currentUser) {
        if (currentUser == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
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
                    await AuthService.signOut();
                  },
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                  icon: const Icon(Icons.person),
                )
              ] else ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signin');
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Sign In'),
                  ),
                )
              ]
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
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}