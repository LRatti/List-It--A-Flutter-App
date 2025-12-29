import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/auth_provider.dart';

class SignInForm extends ConsumerStatefulWidget {
  final dynamic authNotifier; // Keep for backward compatibility with tests

  const SignInForm({super.key, this.authNotifier});

  @override
  ConsumerState<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<SignInForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
            const Center(child: Text('Sign in to your account.')),
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
            TextFormField(
              controller: _passwordController,
              key: const Key('password_field'),
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
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
              key: const Key('sign_in_button'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _errorFeedback = null;
                  });

                  final email = _emailController.text.trim();
                  final password = _passwordController.text.trim();

                  try {
                    await authNotifier.signIn(email, password);
                    if (context.mounted) {
                      // Navigate to home screen after successful login
                      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                    }
                  } catch (e) {
                    setState(() {
                      _errorFeedback = 'Incorrect login credentials.';
                    });
                  }
                }
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
