import 'package:app_code/screens/auth/sign_in.dart';
import 'package:app_code/screens/auth/sign_up.dart';
import 'package:app_code/controllers/auth_controller.dart';
import 'package:app_code/repositories/real_app/firebase_auth_repository.dart';
import 'package:app_code/services/auth_service.dart';
import 'package:flutter/material.dart';


class WelcomeScreen extends StatefulWidget {
  final AuthController? authController;

  const WelcomeScreen({super.key, this.authController});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool isSignUpForm = true;
    late final AuthController _controller;

    @override
    void initState() {
      super.initState();
      _controller = widget.authController ?? 
          AuthController(FirebaseAuthRepository());
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Auth'),
        backgroundColor: Colors.blue[500],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Welcome.'),
        
              // sign up screen
              if (isSignUpForm)
                  Column(
                    key: const Key('sign_up_section'),
                  children: [
                      SignUpForm(authController: _controller),
                    const Text('Already have an account?'),
                    TextButton(
                      key: const Key('switch_to_sign_in'),
                      onPressed: () {
                        setState(() {
                          isSignUpForm = false;
                        });
                      },
                        child: const Text('Sign in instead'),
                    )
                  ]
                ),

              // sign in screen
              if (!isSignUpForm)
                  Column(
                    key: const Key('sign_in_section'),
                  children: [
                      SignInForm(authController: _controller),
                    const Text('Need an account?'),
                    TextButton(
                      key: const Key('switch_to_sign_up'),
                      onPressed: () {
                        setState(() {
                          isSignUpForm = true;
                        });
                      },
                        child: const Text('Sign up instead'),
                    )
                  ]
                ),
              ElevatedButton(
                  key: const Key('google_sign_in_button'),
                onPressed: () async {
                  // Check if user is anonymous and link account, otherwise sign in normally
                    final currentUser = await _controller.ensureAuthenticated();
                  final user = currentUser?.isAnonymous == true
                        ? await _controller.linkAnonymousWithGoogle()
                        : await _controller.signInWithGoogle();
                  
                  if (user != null && context.mounted) {
                    // Navigate back to profile screen after successful sign-in
                    Navigator.of(context).pop();
                  }
                }, 
                  child: const Text("Sign in with Google"),
              )   
            ]
          )
        ),
      ),
    );
  }
}