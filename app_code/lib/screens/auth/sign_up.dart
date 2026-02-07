import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/auth/auth_provider.dart';
import 'package:app_code/providers/real_app_providers/auth/email_verification_provider.dart';
import 'package:app_code/widgets/password_text_field.dart';
import 'package:app_code/l10n/app_localizations.dart';

class SignUpForm extends ConsumerStatefulWidget {
  final dynamic authNotifier; // keep for backward compatibility

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
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

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
                l10n.signUpIntro,
                style: TextStyle(color: colorScheme.onBackground),
              ),
            ),
            const SizedBox(height: 16.0),

            // Username field
            TextFormField(
              controller: _usernameController,
              key: const Key('username_field'),
              decoration: InputDecoration(
                labelText: l10n.usernamePrompt,
              ),
              validator: (value) =>
                  (value == null || value.isEmpty)
                      ? l10n.enterUsernameError
                      : null,
            ),
            const SizedBox(height: 16.0),

            // Email field
            TextFormField(
              controller: _emailController,
              key: const Key('email_field'),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.emailLabel),
              validator: (value) =>
                (value == null || value.isEmpty)
                  ? l10n.enterEmailError
                  : null,
            ),
            const SizedBox(height: 16.0),

            // Password field
            PasswordTextField(
              controller: _passwordController,
              fieldKey: const Key('password_field'),
              labelText: l10n.passwordLabel,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.enterPasswordCreateError;
                }
                if (value.length < 8) {
                  return l10n.passwordMinLength(8);
                }
                return null;
              },
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
              key: const Key('sign_up_button'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  setState(() => _errorFeedback = null);

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
                      // Set email verification session for new signup
                      ref.read(emailVerificationSessionProvider.notifier).state =
                          EmailVerificationSession(
                        isNewSignup: true,
                        email: email,
                      );

                      // Navigate to verification screen
                      Navigator.of(context).pushReplacementNamed('/verification');
                    }
                  } catch (e) {
                    setState(() {
                      _errorFeedback = l10n.signUpFailed;
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: Text(l10n.signUpLabel),
            ),
          ],
        ),
      ),
    );
  }
}
