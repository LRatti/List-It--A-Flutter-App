import 'package:app_code/models/user.dart';
import 'package:app_code/repositories/real_app_repo/database_manager_repository/manage_user.dart';
import 'package:app_code/providers/auth_provider.dart';
import 'package:app_code/providers/email_verification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.userManager});

  final UserManager? userManager;

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
        child: FutureBuilder<dynamic>(
          future: userManager.getUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
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
                return const Center(child: Text('No user data found.'));
              }
            } else {
              return const Center(child: Text('Something went wrong.'));
            }
          },
        ),
      ),
    );
  }

  /// Builds the user edit form
  Widget _buildEditForm(User user) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Section
          _buildSectionHeader('Profile Information'),
          const SizedBox(height: 16),
          TextFormField(
            controller: usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Current Email Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Email',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? '',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Profile Changes'),
            ),
          ),
          const SizedBox(height: 32),
          // Credentials Section
          _buildSectionHeader('Security Settings'),
          const SizedBox(height: 16),
          if (!canEditCredentials)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                'Email and password are managed via your Google account. Changes are disabled.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.blue[900]),
              ),
            )
          else ...[
            // Email Update Section
            Text('Update Email', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'New Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              enabled: canEditCredentials,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: confirmEmailController,
              decoration: InputDecoration(
                labelText: 'Confirm New Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              enabled: canEditCredentials,
            ),
            const SizedBox(height: 24),
            // Password Update Section
            Text(
              'Update Password',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: newPasswordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            // Current Password Verification
            Text('Verification', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: currentPasswordController,
              decoration: InputDecoration(
                labelText: 'Enter Current Password to Confirm Changes',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
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
                    : const Text('Update Security Settings'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds a section header with consistent styling
  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(height: 2, width: 60, color: Colors.blue[500]),
      ],
    );
  }
}
