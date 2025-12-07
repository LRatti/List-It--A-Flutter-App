import 'package:app_code/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorFeedback;

  @override
  Widget build(BuildContext context) {
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

            // email address
            TextFormField(
              controller: _emailController,
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
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
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
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16.0),

            // submit button
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _errorFeedback = null;
                  });

                  final email = _emailController.text.trim();
                  final password = _passwordController.text.trim();
                  final user = await AuthService.linkAnonymousWithEmailPassword(email, password);

                  // // Check if current user is anonymous - if so, link the account to preserve data
                  // final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
                  // final user = currentUser?.isAnonymous ?? false
                  //     ? await AuthService.linkAnonymousWithEmailPassword(email, password)
                  //     : await AuthService.signUp(email, password);

                  if (user == null) {
                    setState(() {
                      _errorFeedback = 'Could not sign up with those details.';
                    });
                  } else {
                    // Small delay to ensure Firebase state propagates to listeners
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
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