import 'dart:async';
import 'package:app_code/models/user.dart';
import 'package:app_code/providers/real_app_providers/auth/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/auth/email_verification_provider.dart';
import 'package:app_code/providers/real_app_providers/auth/password_reset_cooldown_provider.dart';
import 'package:app_code/providers/real_app_providers/auth/user_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/l10n/app_localizations.dart';
import 'package:app_code/widgets/password_text_field.dart';

part 'profile_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ProfileController {
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final userDetailsAsync = ref.watch(userDetailsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: userDetailsAsync.when(
            data: (user) {
              if (user == null) {
                return Center(child: Text(l10n.noUserDataFound));
              }

              if (!_isInitialized || _lastUserId != user.uid) {
                usernameController.text = user.getUserName();
                emailController.clear();
                _lastUserId = user.uid;
                _isInitialized = true;
              }

              return _buildEditForm(user, colorScheme, textTheme);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(l10n.errorWithDetails(error.toString()))),
          ),
        ),
      ),
    );
  }

  Widget _buildEditForm(User user, ColorScheme colorScheme, TextTheme textTheme) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Section
          _buildSectionHeader(l10n.profileInformationTitle, colorScheme, textTheme),
          const SizedBox(height: 16),
          TextFormField(
            controller: usernameController,
            decoration: InputDecoration(
              labelText: l10n.usernameLabel,
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
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.currentEmailLabel,
                  style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? '',
                  style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSaving ? null : () => saveChanges(user),
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.saveProfileChanges),
            ),
          ),
          const SizedBox(height: 32),
          // Credentials Section
          _buildSectionHeader(l10n.securitySettingsTitle, colorScheme, textTheme),
          const SizedBox(height: 16),
          if (!canEditCredentials)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.primaryContainer.withOpacity(0.4)),
              ),
              child: Text(
                l10n.googleAccountManagedCredentials,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: colorScheme.primary),
              ),
            )
          else ...[
            // Email Update Section
            Text(l10n.updateEmailTitle, style: textTheme.labelLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: l10n.newEmailLabel,
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
                labelText: l10n.confirmNewEmailLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              enabled: canEditCredentials,
            ),
            const SizedBox(height: 24),
            // Password Update Section
            Text(l10n.updatePasswordTitle, style: textTheme.labelLarge),
            const SizedBox(height: 12),
            PasswordTextField(
              controller: newPasswordController,
              labelText: l10n.newPasswordLabel,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            PasswordTextField(
              controller: confirmPasswordController,
              labelText: l10n.confirmNewPasswordLabel,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Current Password Verification
            Text(l10n.verificationTitle, style: textTheme.labelLarge),
            const SizedBox(height: 12),
            PasswordTextField(
              controller: currentPasswordController,
              labelText: l10n.enterCurrentPasswordToConfirm,
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
                              ? l10n.forgotPasswordWait(cooldownRemaining)
                              : l10n.forgotPassword,
                        ),
                      ),
                      if (isOnCooldown)
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Text(
                            l10n.cooldownSeconds(cooldownRemaining),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : () => updateAuthCredentials(user),
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.updateSecuritySettings),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(height: 2, width: 60, color: colorScheme.primary),
      ],
    );
  }
}
