import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/email_verification_provider.dart';
import 'package:app_code/widgets/password_text_field.dart';

class SignUpForm extends ConsumerStatefulWidget {
  final dynamic authNotifier; // Keep for backward compatibility with tests

  const SignUpForm({super.key, this.authNotifier});

  @override
  ConsumerState<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<SignUpForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  String? _errorFeedback;

  @override
  Widget build(BuildContext context) {
    final authNotifier = ref.read(authProvider.notifier);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // intro text
            const Center(child: Text('Sign up for a new account.')),
            const SizedBox(height: 16.0),

            // username
            TextFormField(
              controller: _usernameController,
              key: const Key('username_field'),
              decoration: const InputDecoration(
                labelText: 'How would you like to be called?',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a username';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),

            // email address
            TextFormField(
              controller: _emailController,
              key: const Key('email_field'),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),

            // password
            PasswordTextField(
              controller: _passwordController,
              fieldKey: const Key('password_field'),
              labelText: 'Password',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please make a password';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 chars long';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),

            // error feedback
            if (_errorFeedback != null)
              Text(
                _errorFeedback!,
                key: const Key('error_text'),
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16.0),

            // submit button
            ElevatedButton(
              key: const Key('sign_up_button'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _errorFeedback = null;
                  });

                  final email = _emailController.text.trim();
                  final password = _passwordController.text.trim();
                  final username = _usernameController.text.trim();

                  try {
                    await authNotifier.linkAnonymousWithEmailPassword(
                      email,
                      password,
                      username,
                    );

                    if (context.mounted) {
                      // Set email verification session to indicate new signup
                      ref
                          .read(emailVerificationSessionProvider.notifier)
                          .state = EmailVerificationSession(
                        isNewSignup: true,
                        email: email,
                      );

                      // Navigate to verification screen
                      Navigator.of(
                        context,
                      ).pushReplacementNamed('/verification');
                    }
                  } catch (e) {
                    setState(() {
                      _errorFeedback = 'Could not sign up with those details.';
                    });
                  }
                }
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
