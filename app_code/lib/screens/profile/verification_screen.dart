import 'dart:async';
import 'package:app_code/providers/real_app_providers/auth/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/auth/email_verification_provider.dart';
import 'package:app_code/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

part 'verification_controller.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends VerificationController {
  @override
  Widget build(BuildContext context) {
    final verificationSession = ref.watch(emailVerificationSessionProvider);
    final authState = ref.watch(authProvider);
    final email =
        verificationSession?.email ?? authState.value?.email ?? 'your email';

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
              Icon(
                Icons.mark_email_unread_outlined,
                size: 100,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Verify Your Email Address',
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We have sent a verification link to:',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Please check your inbox and click the verification link to activate your account.',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Buttons section
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Resend verification email
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isResending ? null : resendVerificationEmail,
                      icon: isResending
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Icon(Icons.email),
                      label: Text(isResending ? 'Sending...' : 'Resend Verification Email'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Manual continue
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isCheckingVerification ? null : checkAndContinue,
                      icon: isCheckingVerification
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onSecondary,
                                ),
                              ),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(isCheckingVerification ? 'Checking...' : 'I\'ve Verified, Continue'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: colorScheme.onSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Abort operation
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isCheckingVerification ? null : abortOperation,
                      icon: const Icon(Icons.close),
                      label: Text(isCheckingVerification ? 'Aborting...' : 'Abort Operation'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: colorScheme.error),
                        foregroundColor: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Text(
                'The app will automatically redirect once your email is verified.',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    )
    );
  }
}
