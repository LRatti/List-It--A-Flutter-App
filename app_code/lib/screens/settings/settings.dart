import 'package:app_code/models/user.dart';
import 'package:app_code/services/database_manager/manage_user.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue[500],
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Settings Page'),
            const SizedBox(height: 16),
            const Text('Your settings will go here'),
            FutureBuilder(
              future: UserManager().getUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.connectionState == ConnectionState.done){
                  if(snapshot.hasData){
                    
                    final User? user = snapshot.data as User?;
                    if (user != null) {
                      return Text('\nUsername: ${user.getUserName()}\nEmail: ${user.email ?? "N/A"}');
                    } else {
                      return const Text('No user data available.');
                    }
                  } else {
                    return const Text('No user data found.');
                  }
                } else {
                  return const Text('Something went wrong.');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
