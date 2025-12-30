import 'dart:async';
import 'package:app_code/models/user.dart';
import 'package:app_code/providers/real_app_providers/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/email_verification_provider.dart';
import 'package:app_code/providers/real_app_providers/password_reset_cooldown_provider.dart';
import 'package:app_code/providers/real_app_providers/user_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/widgets/password_text_field.dart';

part 'settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends SettingsController {
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final userDetailsAsync = ref.watch(userDetailsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue[500],
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: userDetailsAsync.when(
          data: (user) {
            if (user == null) {
              return const Center(child: Text('No user data found.'));
            }

            if (!_isInitialized || _lastUserId != user.uid) {
              usernameController.text = user.getUserName();
              emailController.clear();
              _lastUserId = user.uid;
              _isInitialized = true;
            }

            return _buildEditForm(user);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
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
            PasswordTextField(
              controller: newPasswordController,
              labelText: 'New Password',
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            PasswordTextField(
              controller: confirmPasswordController,
              labelText: 'Confirm New Password',
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Current Password Verification
            Text('Verification', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            PasswordTextField(
              controller: currentPasswordController,
              labelText: 'Enter Current Password to Confirm Changes',
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Consumer(
                builder: (context, ref, child) {
                  final cooldownRemaining = ref.watch(passwordResetCooldownNotifierProvider);
                  final isOnCooldown = cooldownRemaining > 0;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isOnCooldown 
                            ? null 
                            : () => sendPasswordResetFromSettings(user.email),
                        child: Text(
                          isOnCooldown 
                              ? 'Forgot Password? (Wait ${cooldownRemaining}s)'
                              : 'Forgot Password?',
                        ),
                      ),
                      if (isOnCooldown)
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Text(
                            'Cooldown: ${cooldownRemaining}s',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
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
