part of 'forgot_password.dart';

abstract class ForgotPasswordController extends ConsumerState<ForgotPasswordScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final TextEditingController emailController;
  late final TextEditingController confirmEmailController;

  bool _isSubmitting = false;
  String? _errorText;
  String? _successText;

  bool get isSubmitting => _isSubmitting;
  String? get errorText => _errorText;
  String? get successText => _successText;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    confirmEmailController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    confirmEmailController.dispose();
    super.dispose();
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    return null;
  }

  String? validateConfirmEmail(String? value, String email) {
    if (value == null || value.trim().isEmpty) {
      return 'Please confirm your email';
    }
    if (value.trim() != email.trim()) {
      return 'Emails do not match';
    }
    return null;
  }


  Future<void> onSubmit(BuildContext context, AuthNotifier authNotifier) async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
      _successText = null;
    });

    final email = emailController.text.trim();
    try {
      await authNotifier.sendPasswordResetEmail(email);
      if (!mounted) return;

      // Feedback and cooldown
      setState(() {
        _successText = 'If an account exists, a reset link has been sent.';
      });

      // Navigate back to sign in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recovery email sent. Check your inbox.')),
      );
      //Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Could not send reset email. Please try again later.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
