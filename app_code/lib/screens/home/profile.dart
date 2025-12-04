import 'package:app_code/models/user.dart';
import 'package:app_code/screens/settings/settings.dart';
import 'package:app_code/services/auth_service.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        backgroundColor: Colors.blue[500],
        centerTitle: true,
        actions: [
          if (user.email != null && user.email!.isNotEmpty) ...[
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async{
                // Implement logout functionality here
                await AuthService.signOut();
              },
            ),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
              icon: Icon(Icons.person)
            )
          ] else ...[
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signin');
              }, 
              child: Padding(
                padding: const EdgeInsets.all(8.0),
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

            // output user email here later
            Text('Welcome to your profile!'),
            const SizedBox(height: 16),

          ],
        ),
      ),
    );
  }
}