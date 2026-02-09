import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_code/providers/real_app_providers/auth/auth_provider.dart';
import 'package:app_code/widgets/password_text_field.dart';
import 'package:app_code/l10n/app_localizations.dart';

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
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 4,
        shadowColor: colorScheme.shadow.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon and title
                Icon(
                  Icons.login_rounded,
                  size: 48,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16.0),
                Center(
                  child: Text(
                    l10n.signInIntro,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24.0),

                // Email field
                TextFormField(
                  controller: _emailController,
                  key: const Key('email_field'),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.emailLabel,
                    prefixIcon: Icon(Icons.email_outlined, color: colorScheme.onSurfaceVariant),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  ),
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
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  ),
                  validator: (value) =>
                    (value == null || value.isEmpty)
                      ? l10n.enterPasswordError
                      : null,
                ),
                const SizedBox(height: 12.0),

                // Forgot password button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const Key('forgot_password_button'),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/forgot-password');
                    },
                    child: Text(
                      l10n.forgotPasswordLabel,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),

                // Error feedback
                if (_errorFeedback != null)
                  Container(
                    key: const Key('error_text'),
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: colorScheme.onErrorContainer, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorFeedback!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Submit button
                FilledButton(
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
                          _errorFeedback = l10n.incorrectLoginCredentials;
                        });
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.signInLabel,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
