part of 'settings_screen.dart';

abstract class SettingsController extends State<SettingsScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late UserManager _userManager;
  bool _isSaving = false;

  // Public getters for UI access
  TextEditingController get usernameController => _usernameController;
  TextEditingController get emailController => _emailController;
  UserManager get userManager => _userManager;
  bool get isSaving => _isSaving;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _userManager = UserManager();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
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
      final modifiedUser = _createModifiedUser(user);
      await _userManager.createOrUpdateUserData(modifiedUser);
      
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
      email: _emailController.text,
      userName: _usernameController.text,
    );
  }
}