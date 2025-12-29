import 'package:app_code/screens/auth/sign_in.dart';
import 'package:app_code/screens/auth/sign_up.dart';
import 'package:app_code/providers/real_app_providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  final dynamic authNotifier; // Keep for backward compatibility with tests

  const WelcomeScreen({super.key, this.authNotifier});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool isSignUpForm = true;

  @override
  Widget build(BuildContext context) {
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Auth'),
        backgroundColor: Colors.blue[500],
        centerTitle: true,
        // Show back button to allow users to abort signup/signin
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Welcome.'),

              // sign up screen
              if (isSignUpForm)
                Column(
                  key: const Key('sign_up_section'),
                  children: [
                    SignUpForm(authNotifier: authNotifier),
                    const Text('Already have an account?'),
                    TextButton(
                      key: const Key('switch_to_sign_in'),
                      onPressed: () {
                        setState(() {
                          isSignUpForm = false;
                        });
                      },
                      child: const Text('Sign in instead'),
                    ),
                  ],
                ),

              // sign in screen
              if (!isSignUpForm)
                Column(
                  key: const Key('sign_in_section'),
                  children: [
                    SignInForm(authNotifier: authNotifier),
                    const Text('Need an account?'),
                    TextButton(
                      key: const Key('switch_to_sign_up'),
                      onPressed: () {
                        setState(() {
                          isSignUpForm = true;
                        });
                      },
                      child: const Text('Sign up instead'),
                    ),
                  ],
                ),
              ElevatedButton(
                key: const Key('google_sign_in_button'),
                onPressed: () async {
                  // Always defer to repository logic for Google sign-in.
                  // It will upgrade anonymous accounts or sign in existing ones.
                  await authNotifier.signInWithGoogle();

                  if (context.mounted) {
                    // Navigate back to home screen after successful sign-in
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/home', (route) => false);
                  }
                },
                child: const Text("Sign in with Google"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
