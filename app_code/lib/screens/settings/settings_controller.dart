part of 'settings_screen.dart';

abstract class SettingsController extends ConsumerState<SettingsScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _confirmEmailController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _isSaving = false;
  bool _canEditCredentials = false;
  String? _lastUserId;

  // Public getters for UI access
  TextEditingController get usernameController => _usernameController;
  TextEditingController get emailController => _emailController;
  TextEditingController get confirmEmailController => _confirmEmailController;
  TextEditingController get currentPasswordController =>
      _currentPasswordController;
  TextEditingController get newPasswordController => _newPasswordController;
  TextEditingController get confirmPasswordController =>
      _confirmPasswordController;
  bool get isSaving => _isSaving;
  bool get canEditCredentials => _canEditCredentials;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _confirmEmailController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    // canEditCredentials will be set after first build when ref is available
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize canEditCredentials using authProvider after ref is available
    if (!_canEditCredentials) {
      final authNotifier = ref.read(authProvider.notifier);
      _canEditCredentials = authNotifier.canUpdateCredentials();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Displays a snack bar message to the user
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  /// Saves user changes to Firebase
  Future<void> saveChanges(User user) async {
    setState(() => _isSaving = true);
    try {
      // Only update username here. Email changes must be done via the dedicated button.
      final modifiedUser = _createModifiedUser(user);
      await ref.read(userDetailsProvider.notifier).updateUser(modifiedUser);

      if (mounted) {
        showSnackBar('Changes saved successfully!');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar('Error saving changes: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Creates a modified User object with updated field values
  User _createModifiedUser(User user) {
    return User(
      uid: user.uid,
      isAnonymous: user.isAnonymous,
      email: user.email,
      userName: _usernameController.text,
    );
  }

  /// Update authentication email and/or password based on filled inputs.
  Future<void> updateAuthCredentials(User user) async {
    if (!canEditCredentials) {
      showSnackBar(
        'Email and password managed via Google. Changes disabled.',
        isError: true,
      );
      return;
    }

    final newEmail = _emailController.text.trim();
    final confirmEmail = _confirmEmailController.text.trim();
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    final wantsEmailUpdate = newEmail.isNotEmpty || confirmEmail.isNotEmpty;
    final wantsPasswordUpdate = newPassword.isNotEmpty || confirm.isNotEmpty;

    if (!wantsEmailUpdate && !wantsPasswordUpdate) {
      showSnackBar('Enter new email and/or new password.', isError: true);
      return;
    }

    if (currentPassword.isEmpty) {
      showSnackBar('Enter current password to proceed.', isError: true);
      return;
    }

    if (wantsEmailUpdate) {
      if (newEmail.isEmpty || confirmEmail.isEmpty) {
        showSnackBar('Fill both email fields.', isError: true);
        return;
      }
      if (newEmail != confirmEmail) {
        showSnackBar('Email addresses do not match.', isError: true);
        return;
      }
    }

    if (wantsPasswordUpdate) {
      if (newPassword.isEmpty || confirm.isEmpty) {
        showSnackBar('Fill all password fields.', isError: true);
        return;
      }
      if (newPassword != confirm) {
        showSnackBar('New passwords do not match.', isError: true);
        return;
      }
      if (newPassword.length < 6) {
        showSnackBar('Password must be at least 6 characters.', isError: true);
        return;
      }
    }

    // If both email and password are being updated, handle separately
    if (wantsEmailUpdate && wantsPasswordUpdate) {
      showSnackBar(
        'Please update email and password separately.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final authNotifier = ref.read(authProvider.notifier);

      if (wantsEmailUpdate) {
        await authNotifier.updateEmail(
          newEmail: newEmail,
          currentPassword: currentPassword,
        );
        if (mounted) {
          // Set email verification session to indicate email update
          ref.read(emailVerificationSessionProvider.notifier).state =
              EmailVerificationSession(isNewSignup: false, email: newEmail);

          showSnackBar('Verification email sent to new address!');
          // Navigate to verification screen
          Navigator.pushReplacementNamed(context, '/verification');
        }
      } else if (wantsPasswordUpdate) {
        await authNotifier.updatePassword(
          newPassword: newPassword,
          currentPassword: currentPassword,
        );
        if (mounted) {
          showSnackBar('Password updated. Please sign in again.');
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/signin', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar('Failed to update credentials: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> sendPasswordResetFromSettings(String? email) async {
    if (email == null || email.isEmpty) {
      showSnackBar('No email associated with this account.', isError: true);
      return;
    }

    // Check cooldown before attempting to send
    final cooldownService = ref.read(passwordResetCooldownServiceProvider);
    final canSend = await cooldownService.canSendResetEmail();
    
    if (!canSend) {
      final remaining = await cooldownService.getRemainingCooldownSeconds();
      showSnackBar(
        'Please wait $remaining seconds before requesting another reset email.',
        isError: true,
      );
      return;
    }

    try {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.sendPasswordResetEmail(email);
      
      // Record the email was sent and start cooldown
      final cooldownNotifier = ref.read(passwordResetCooldownNotifierProvider.notifier);
      await cooldownNotifier.recordEmailSent();
      
      if (!mounted) return;
      showSnackBar('Recovery email sent. You will be signed out.');
      
      // Navigate BEFORE signing out to avoid showing "No user data found" message
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/signin', (route) => false);
      }
      
      // Sign out after navigation is initiated
      await authNotifier.signOut();
    } catch (e) {
      if (mounted) {
        showSnackBar(
          'Could not send reset email. Try again later.',
          isError: true,
        );
      }
    }
  }
}
