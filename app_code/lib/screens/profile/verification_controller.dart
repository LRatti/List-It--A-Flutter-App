part of 'verification_screen.dart';

abstract class VerificationController
    extends ConsumerState<VerificationScreen> {
  Timer? _pollTimer;
  bool _isResending = false;
  bool _isCheckingVerification = false;
  DateTime? _lastResendAt;

  // Public getters for UI access
  bool get isResending => _isResending;
  bool get isCheckingVerification => _isCheckingVerification;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Start polling to check if email has been verified
  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerified();
    });
  }

  /// Check if the email has been verified
  Future<void> _checkEmailVerified() async {
    if (_isCheckingVerification) return;

    setState(() => _isCheckingVerification = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      // Get verification session first to know the context
      final verificationSession = ref.read(emailVerificationSessionProvider);
      final isNewSignup = verificationSession?.isNewSignup ?? true;
      final newEmail = verificationSession?.email;

      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Reload user to get latest verification status
        await currentUser.reload();
        final updatedUser = firebase_auth.FirebaseAuth.instance.currentUser;

        if (updatedUser != null) {
          if (isNewSignup) {
            // For new signup: check if email is verified
            if (updatedUser.emailVerified) {
              _pollTimer?.cancel();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              }
            }
          } else {
            // For email update: check if the email has actually changed
            if (newEmail != null && updatedUser.email == newEmail) {
              _pollTimer?.cancel();
              if (mounted) {
                // Email update verified: require re-login
                final authNotifier = ref.read(authProvider.notifier);
                await authNotifier.signOut();
                // Clear session
                ref.read(emailVerificationSessionProvider.notifier).state =
                    null;
                showSnackBar(l10n.emailVerifiedSignInAgain);
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/signin', (route) => false);
              }
            }
          }
        } else if (!isNewSignup) {
          // User may have been invalidated after verification; require re-login
          _pollTimer?.cancel();
          if (mounted) {
            final authNotifier = ref.read(authProvider.notifier);
            await authNotifier.signOut();
            ref.read(emailVerificationSessionProvider.notifier).state = null;
            showSnackBar(l10n.emailVerifiedSignInAgain);
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/signin', (route) => false);
          }
        }
      } else if (!isNewSignup) {
        // No current user (token invalidated) after email update verification
        _pollTimer?.cancel();
        if (mounted) {
          final authNotifier = ref.read(authProvider.notifier);
          await authNotifier.signOut();
          ref.read(emailVerificationSessionProvider.notifier).state = null;
          showSnackBar(l10n.emailVerifiedSignInAgain);
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/signin', (route) => false);
        }
      }
    } catch (e) {
      // If an error occurs, and this was an email update flow, still require re-login to recover
      final verificationSession = ref.read(emailVerificationSessionProvider);
      final isNewSignup = verificationSession?.isNewSignup ?? true;
      if (!isNewSignup) {
        _pollTimer?.cancel();
        if (mounted) {
          final authNotifier = ref.read(authProvider.notifier);
          await authNotifier.signOut();
          ref.read(emailVerificationSessionProvider.notifier).state = null;
          showSnackBar(l10n.emailVerifiedSignInAgain);
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/signin', (route) => false);
        }
      } else {
        print('Error checking email verification: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingVerification = false);
      }
    }
  }

  /// Manually check and continue if verified
  Future<void> checkAndContinue() async {
    setState(() => _isCheckingVerification = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      // Get verification session to determine if this is email update or new signup
      final verificationSession = ref.read(emailVerificationSessionProvider);
      final isNewSignup = verificationSession?.isNewSignup ?? true;
      final newEmail = verificationSession?.email;

      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
        final updatedUser = firebase_auth.FirebaseAuth.instance.currentUser;

        if (updatedUser != null) {
          bool isVerified = false;
          if (isNewSignup) {
            // For new signup: check if email is verified
            isVerified = updatedUser.emailVerified;
          } else {
            // For email update: check if the email has actually changed
            isVerified = newEmail != null && updatedUser.email == newEmail;
          }

          if (isVerified) {
            _pollTimer?.cancel();
            if (mounted) {
              if (isNewSignup) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              } else {
                final authNotifier = ref.read(authProvider.notifier);
                await authNotifier.signOut();
                ref.read(emailVerificationSessionProvider.notifier).state =
                    null;
                showSnackBar(l10n.emailVerifiedSignInAgain);
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/signin', (route) => false);
              }
            }
          } else {
            if (mounted) {
              showSnackBar(l10n.emailNotVerifiedYet, isError: true);
            }
          }
        } else if (!isNewSignup) {
          // Updated user missing after reload in email update flow: require re-login
          _pollTimer?.cancel();
          if (mounted) {
            final authNotifier = ref.read(authProvider.notifier);
            await authNotifier.signOut();
            ref.read(emailVerificationSessionProvider.notifier).state = null;
            showSnackBar(l10n.emailVerifiedSignInAgain);
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/signin', (route) => false);
          }
        }
      } else if (!isNewSignup) {
        // No current user (token invalidated) after email update verification
        _pollTimer?.cancel();
        if (mounted) {
          final authNotifier = ref.read(authProvider.notifier);
          await authNotifier.signOut();
          ref.read(emailVerificationSessionProvider.notifier).state = null;
          showSnackBar(l10n.emailVerifiedSignInAgain);
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/signin', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        // In email update flow, treat errors as needing re-login to recover
        final verificationSession = ref.read(emailVerificationSessionProvider);
        final isNewSignup = verificationSession?.isNewSignup ?? true;
        if (!isNewSignup) {
          _pollTimer?.cancel();
          final authNotifier = ref.read(authProvider.notifier);
          await authNotifier.signOut();
          ref.read(emailVerificationSessionProvider.notifier).state = null;
          showSnackBar(l10n.emailVerifiedSignInAgain);
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/signin', (route) => false);
        } else {
          showSnackBar(
            l10n.errorCheckingVerification(e.toString()),
            isError: true,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingVerification = false);
      }
    }
  }

  /// Resend verification email
  Future<void> resendVerificationEmail() async {
    // Local cooldown to avoid Firebase rate limiting
    const cooldown = Duration(seconds: 60);
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    if (_lastResendAt != null && now.difference(_lastResendAt!) < cooldown) {
      final remaining = cooldown - now.difference(_lastResendAt!);
      if (mounted) {
        showSnackBar(
          l10n.pleaseWaitBeforeResending(remaining.inSeconds),
          isError: true,
        );
      }
      return;
    }

    setState(() => _isResending = true);

    try {
      // Determine context: new signup vs email update
      final verificationSession = ref.read(emailVerificationSessionProvider);
      final isNewSignup = verificationSession?.isNewSignup ?? true;
      final newEmail = verificationSession?.email;

      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          showSnackBar(l10n.noAuthenticatedUserFound, isError: true);
        }
        return;
      }

      if (isNewSignup) {
        // New signup: resend to the current user's email if not verified yet
        await currentUser.sendEmailVerification();
        if (mounted) {
          showSnackBar(l10n.verificationEmailSentCheckInbox);
        }
        _lastResendAt = DateTime.now();
      } else {
        // Email update flow: resend to the NEW email address
        if (newEmail == null || newEmail.isEmpty) {
          if (mounted) {
            showSnackBar(
              l10n.verificationNewEmailUnavailable,
              isError: true,
            );
          }
          return;
        }
        await currentUser.verifyBeforeUpdateEmail(newEmail);
        if (mounted) {
          showSnackBar(l10n.verificationEmailResentNewAddress);
        }
        _lastResendAt = DateTime.now();
      }
    } catch (e) {
      if (mounted) {
        if (e is firebase_auth.FirebaseAuthException &&
            e.code == 'too-many-requests') {
          showSnackBar(
            l10n.tooManyRequestsTryLater,
            isError: true,
          );
        } else {
          showSnackBar(
            l10n.errorSendingVerificationEmail(e.toString()),
            isError: true,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  /// Abort the email verification process
  /// - For new signup: deletes account and redirects to signup page
  /// - For email updates: cancels verification and returns to normal app usage
  Future<void> abortOperation() async {
    _pollTimer?.cancel();

    final authNotifier = ref.read(authProvider.notifier);
    final verificationSession = ref.read(emailVerificationSessionProvider);
    final l10n = AppLocalizations.of(context)!;

    final isNewSignup = verificationSession?.isNewSignup ?? false;

    try {
      setState(() => _isCheckingVerification = true);

      await authNotifier.abortEmailVerification(isNewSignup: isNewSignup);

      if (mounted) {
        if (isNewSignup) {
          // For new signup: redirect to signup page
          showSnackBar(
            l10n.accountCreationCancelledMessage,
          );
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/signin', (route) => false);
        } else {
          // For email update: return to home without signing out
          showSnackBar(
            l10n.emailVerificationCancelledMessage,
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          l10n.errorAbortingOperation(e.toString()),
          isError: true,
        );
      }
      print('Error aborting email verification: $e');
    } finally {
      if (mounted) {
        setState(() => _isCheckingVerification = false);
      }
    }
  }

  /// Displays a snack bar message to the user
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      buildAppSnackBar(
        message: message,
        isError: isError,
        duration: const Duration(seconds: 4),
        context: context,
      ),
    );
  }
}
