import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/password_reset_cooldown_provider.dart';
import 'package:app_code/widgets/app_snackbar.dart';

part 'forgot_password_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ForgotPasswordController {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Watch the cooldown state
    final cooldownRemaining = ref.watch(passwordResetCooldownNotifierProvider);
    final isOnCooldown = cooldownRemaining > 0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recover Password'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: formKey,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Enter your account email to receive a password reset link.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  validator: validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Confirm Email',
                    labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  validator: (value) => validateConfirmEmail(value, emailController.text),
                ),
                const SizedBox(height: 24),
                if (errorText != null)
                  Text(
                    errorText!,
                    style: TextStyle(color: colorScheme.error),
                  ),
                if (successText != null)
                  Text(
                    successText!,
                    style: TextStyle(color: colorScheme.secondary),
                  ),
                if (isOnCooldown)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer, size: 16, color: colorScheme.tertiary),
                        const SizedBox(width: 8),
                        Text(
                          'You can request another reset in $cooldownRemaining seconds',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (isSubmitting || isOnCooldown)
                        ? null
                        : () async {
                            await onSubmit(context, ref.read(authProvider.notifier));
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    child: isSubmitting
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(colorScheme.onPrimary),
                            ),
                          )
                        : Text(isOnCooldown 
                            ? 'Please wait ($cooldownRemaining s)' 
                            : 'Send recovery email'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
