import 'package:flutter_riverpod/legacy.dart';

/// Tracks the context of the email verification process
class EmailVerificationSession {
  /// Whether this is a new signup flow (true) or updating existing email (false)
  final bool isNewSignup;
  
  /// The email address being verified
  final String email;

  EmailVerificationSession({
    required this.isNewSignup,
    required this.email,
  });

  EmailVerificationSession copyWith({
    bool? isNewSignup,
    String? email,
  }) {
    return EmailVerificationSession(
      isNewSignup: isNewSignup ?? this.isNewSignup,
      email: email ?? this.email,
    );
  }
}

/// Provider to track the current email verification session
/// This helps distinguish between new signup flows and email update flows
final emailVerificationSessionProvider =
    StateProvider<EmailVerificationSession?>((ref) {
  return null;
});
