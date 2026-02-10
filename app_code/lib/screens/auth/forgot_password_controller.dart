part of 'forgot_password.dart';

/// Controller for the Forgot Password screen, 
/// handling form state, validation, and submission logic.
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
    
    // Schedule cooldown check after frame to avoid issues with timers in tests
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeCooldown();
      }
    });
  }

  Future<void> _initializeCooldown() async {
    final cooldownNotifier = ref.read(passwordResetCooldownNotifierProvider.notifier);
    await cooldownNotifier.checkCooldown();
  }

  @override
  void dispose() {
    emailController.dispose();
    confirmEmailController.dispose();
    super.dispose();
  }

  String? validateEmail(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return l10n.enterEmailError;
    }
    return null;
  }

  String? validateConfirmEmail(String? value, String email) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return l10n.confirmEmailError;
    }
    if (value.trim() != email.trim()) {
      return l10n.emailsDoNotMatch;
    }
    return null;
  }


  Future<void> onSubmit(BuildContext context, AuthNotifier authNotifier) async {
    if (!formKey.currentState!.validate()) return;

    // Check cooldown before attempting to send
    final cooldownService = ref.read(passwordResetCooldownServiceProvider);
    final canSend = await cooldownService.canSendResetEmail();
    
    if (!canSend) {
      final remaining = await cooldownService.getRemainingCooldownSeconds();
      setState(() {
        _errorText = AppLocalizations.of(context)!
            .waitBeforeRequestingReset(remaining);
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
      _successText = null;
    });

    final email = emailController.text.trim();
    try {
      await authNotifier.sendPasswordResetEmail(email);
      if (!mounted) return;

      // Record the email was sent and start cooldown
      final cooldownNotifier = ref.read(passwordResetCooldownNotifierProvider.notifier);
      await cooldownNotifier.recordEmailSent();

      // Feedback and cooldown
      setState(() {
        _successText = AppLocalizations.of(context)!
            .resetLinkSentIfAccountExists;
      });

      // Navigate back to sign in
      ScaffoldMessenger.of(context).showSnackBar(
        buildAppSnackBar(
          message: AppLocalizations.of(context)!
              .recoveryEmailSentCheckInbox,
          context: context,
        ),
      );
      //Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = AppLocalizations.of(context)!
            .couldNotSendResetEmail;
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
