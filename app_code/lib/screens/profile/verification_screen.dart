import 'dart:async';
import 'package:app_code/providers/real_app_providers/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/email_verification_provider.dart';
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
    // Get the email being verified from the session provider
    final verificationSession = ref.watch(emailVerificationSessionProvider);
    // Fall back to current user email if session is not set
    final authState = ref.watch(authProvider);
    final email =
        verificationSession?.email ?? authState.value?.email ?? 'your email';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        backgroundColor: Colors.blue[500],
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email verification icon
              Icon(
                Icons.mark_email_unread_outlined,
                size: 100,
                color: Colors.blue[500],
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Verify Your Email Address',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                'We have sent a verification link to:',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Please check your inbox and click the verification link to activate your account.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Buttons section with safe padding for navigation bar
              Column(
                spacing: 16.0,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Resend verification email button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isResending ? null : resendVerificationEmail,
                      icon: isResending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.email),
                      label: Text(
                        isResending
                            ? 'Sending...'
                            : 'Resend Verification Email',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  // Manual continue button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isCheckingVerification
                          ? null
                          : checkAndContinue,
                      icon: isCheckingVerification
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(
                        isCheckingVerification
                            ? 'Checking...'
                            : 'I\'ve Verified, Continue',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  // Abort operation button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isCheckingVerification ? null : abortOperation,
                      icon: const Icon(Icons.close),
                      label: Text(
                        isCheckingVerification
                            ? 'Aborting...'
                            : 'Abort Operation',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.red[400]!),
                        foregroundColor: Colors.red[400],
                      ),
                    ),
                  ),
                ],
              ),

              // Helper text
              Text(
                'The app will automatically redirect once your email is verified.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
