import 'package:app_code/models/user.dart';
import 'package:app_code/services/database_manager/manage_user.dart';
import 'package:app_code/repositories/abstract/auth_repository.dart';
import 'package:app_code/repositories/real_app_repo/firebase_auth_repository.dart';
import 'package:app_code/providers/email_verification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
    this.userManager,
    this.authRepository,
  });

  final UserManager? userManager;
  final AuthRepository? authRepository;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends SettingsController {
  bool _isInitialized = false;

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
            FutureBuilder<dynamic>(
              future: userManager.getUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.connectionState == ConnectionState.done) {
                  final User? user = snapshot.data;
                  if (user != null) {
                    // Initialize controllers only once with user data
                    if (!_isInitialized) {
                      usernameController.text = user.getUserName();
                      emailController.clear(); // start with empty email field
                      _isInitialized = true;
                    }

                    return _buildEditForm(user);
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

  /// Builds the user edit form
  Widget _buildEditForm(User user) {
    return Column(
      children: [
        TextFormField(
          controller: usernameController,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            //TODO: update flow so that when values are updated they reflect immediatly in the profile page
            //TODO: change logic so that the changed email affects the authentication email as well
            onPressed: isSaving ? null : () => saveChanges(user),
            child: isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Save Changes'),
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Enter New Email'),
          enabled: canEditCredentials,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: confirmEmailController,
          decoration: const InputDecoration(labelText: 'Confirm New Email'),
          enabled: canEditCredentials,
        ),
        const SizedBox(height: 12),
        if (!canEditCredentials)
          const Text(
            'Email and password are managed via Google account. Changes disabled.',
            textAlign: TextAlign.center,
          ),
        if (canEditCredentials) ...[
          
          TextFormField(
            controller: newPasswordController,
            decoration: const InputDecoration(labelText: 'Enter New Password'),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: confirmPasswordController,
            decoration: const InputDecoration(labelText: 'Confirm New Password'),
            obscureText: true,
          ),
          TextFormField(
            controller: currentPasswordController,
            decoration: const InputDecoration(labelText: 'Enter Current Password to Confirm Changes'),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSaving ? null : () => updateAuthCredentials(user),
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update'),
            ),
          ),
          const Divider(height: 24),
        ],
      ],
    );
  }
}
