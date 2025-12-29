import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/auth_provider.dart';

class TopBarWithNavBar extends ConsumerWidget implements PreferredSizeWidget {
  const TopBarWithNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          title: const Text("My Shopping App"),
          actions: [
            authState.when(
              data: (user) {
                if (user == null || user.isAnonymous) {
                  // Show Sign In button for anonymous users
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      key: const Key('sign_in_button'),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/signin');
                      },
                      child: const Text('Sign In'),
                    ),
                  );
                } else {
                  // Show settings and logout for authenticated users
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: const Key('settings_button'),
                        onPressed: () {
                          Navigator.of(context).pushNamed('/settings');
                        },
                        icon: const Icon(Icons.settings),
                      ),
                      IconButton(
                        key: const Key('logout_button'),
                        onPressed: () async {
                          await authNotifier.signOut();
                        },
                        icon: const Icon(Icons.logout),
                      ),
                    ],
                  );
                }
              },
              loading: () => const SizedBox(width: 48, height: 48),
              error: (_, __) => const SizedBox(width: 48, height: 48),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          color: Colors.grey[200],
          padding: const EdgeInsets.all(12),
          child: const Text(
            "Nearest supermarket: internet not available",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 48);
}
