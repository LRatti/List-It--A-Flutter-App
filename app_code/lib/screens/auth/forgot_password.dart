import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/password_reset_cooldown_provider.dart';

part 'forgot_password_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ForgotPasswordController {
  @override
  Widget build(BuildContext context) {
    // Watch the cooldown state
    final cooldownRemaining = ref.watch(passwordResetCooldownNotifierProvider);
    final isOnCooldown = cooldownRemaining > 0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recover Password'),
        centerTitle: true,
        backgroundColor: Colors.blue[500],
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
                const Text(
                  'Enter your account email to receive a password reset link.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Confirm Email'),
                  validator: (value) => validateConfirmEmail(value, emailController.text),
                ),
                const SizedBox(height: 24),
                if (errorText != null)
                  Text(
                    errorText!,
                    style: const TextStyle(color: Colors.red),
                  ),
                if (successText != null)
                  Text(
                    successText!,
                    style: const TextStyle(color: Colors.green),
                  ),
                if (isOnCooldown)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'You can request another reset in $cooldownRemaining seconds',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
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
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
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
