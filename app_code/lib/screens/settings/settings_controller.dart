part of 'settings_screen.dart';

abstract class SettingsController extends ConsumerState<SettingsScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _confirmEmailController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  late final UserManager _userManager;
  bool _isSaving = false;
  bool _canEditCredentials = false;
  late final AuthRepository _authRepository;

  // Public getters for UI access
  TextEditingController get usernameController => _usernameController;
  TextEditingController get emailController => _emailController;
  TextEditingController get confirmEmailController => _confirmEmailController;
  TextEditingController get currentPasswordController =>
      _currentPasswordController;
  TextEditingController get newPasswordController => _newPasswordController;
  TextEditingController get confirmPasswordController =>
      _confirmPasswordController;
  UserManager get userManager => _userManager;
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
    _userManager = widget.userManager ?? UserManager();
    _authRepository = widget.authRepository ?? FirebaseAuthRepository();
    _canEditCredentials = _authRepository.canUpdateCredentials();
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
      await _userManager.setUserData(modifiedUser);

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

  /// Update the authentication email with reauthentication and navigate to verification screen.
  Future<void> updateAuthEmail(User user) async {
    if (!canEditCredentials) {
      showSnackBar('Email managed via Google. Change disabled.', isError: true);
      return;
    }
    final newEmail = _emailController.text.trim();
    final confirmEmail = _confirmEmailController.text.trim();
    final currentPassword = _currentPasswordController.text.trim();
    if (newEmail.isEmpty || confirmEmail.isEmpty || currentPassword.isEmpty) {
      showSnackBar('Enter new email, confirm email, and current password.', isError: true);
      return;
    }
    if (newEmail != confirmEmail) {
      showSnackBar('Email addresses do not match.', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _authRepository.updateEmail(
        newEmail: newEmail,
        currentPassword: currentPassword,
      );
      if (mounted) {
        // Set email verification session to indicate email update
        ref.read(emailVerificationSessionProvider.notifier).state =
            EmailVerificationSession(
          isNewSignup: false,
          email: newEmail,
        );

        showSnackBar('Verification email sent to new address!');
        // Navigate to verification screen
        Navigator.pushReplacementNamed(context, '/verification');
      }
    } catch (e) {
      showSnackBar('Failed to update email: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Update the authentication password with reauthentication and then sign out.
  Future<void> updateAuthPassword(User user) async {
    if (!canEditCredentials) {
      showSnackBar(
        'Password managed via Google. Change disabled.',
        isError: true,
      );
      return;
    }
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    if (currentPassword.isEmpty || newPassword.isEmpty || confirm.isEmpty) {
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
    setState(() => _isSaving = true);
    try {
      await _authRepository.updatePassword(
        newPassword: newPassword,
        currentPassword: currentPassword,
      );
      if (mounted) {
        showSnackBar('Password updated. Please sign in again.');
        Navigator.pop(context); // Leave settings
      }
    } catch (e) {
      showSnackBar('Failed to update password: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
      if (wantsEmailUpdate) {
        await _authRepository.updateEmail(
          newEmail: newEmail,
          currentPassword: currentPassword,
        );
        if (mounted) {
          // Set email verification session to indicate email update
          ref.read(emailVerificationSessionProvider.notifier).state =
              EmailVerificationSession(
            isNewSignup: false,
            email: newEmail,
          );

          showSnackBar('Verification email sent to new address!');
          // Navigate to verification screen
          Navigator.pushReplacementNamed(context, '/verification');
        }
      } else if (wantsPasswordUpdate) {
        await _authRepository.updatePassword(
          newPassword: newPassword,
          currentPassword: currentPassword,
        );
        if (mounted) {
          showSnackBar('Password updated. Please sign in again.');
          Navigator.pop(context); // Leave settings
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
}
