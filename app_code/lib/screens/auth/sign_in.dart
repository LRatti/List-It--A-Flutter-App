import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/auth/auth_provider.dart';
import 'package:app_code/widgets/password_text_field.dart';

class SignInForm extends ConsumerStatefulWidget {
  final dynamic authNotifier; // keep for backward compatibility

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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Intro text
            Center(
              child: Text(
                'Sign in to your account.',
                style: TextStyle(color: colorScheme.onBackground),
              ),
            ),
            const SizedBox(height: 16.0),

            // Email field
            TextFormField(
              controller: _emailController,
              key: const Key('email_field'),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Please enter your email' : null,
            ),
            const SizedBox(height: 16.0),

            // Password field
            PasswordTextField(
              controller: _passwordController,
              fieldKey: const Key('password_field'),
              labelText: 'Password',
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Please enter your password' : null,
            ),
            const SizedBox(height: 16.0),

            // Error feedback
            if (_errorFeedback != null)
              Text(
                _errorFeedback!,
                key: const Key('error_text'),
                style: TextStyle(color: colorScheme.error),
              ),
            const SizedBox(height: 16.0),

            // Submit button
            ElevatedButton(
              key: const Key('sign_in_button'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  setState(() => _errorFeedback = null);

                  final email = _emailController.text.trim();
                  final password = _passwordController.text.trim();

                  try {
                    await authNotifier.signIn(email, password);
                    if (context.mounted) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/home', (route) => false);
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
            const SizedBox(height: 8.0),

            // Forgot password button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('forgot_password_button'),
                onPressed: () {
                  Navigator.of(context).pushNamed('/forgot-password');
                },
                child: const Text('Forgot password?'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
